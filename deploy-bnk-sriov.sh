#!/bin/bash

set -e

SECONDS=0

test -e ~/far/f5-far-auth-key.tgz || (echo "Please download far-f5-auth-key.tz from myf5.com into ~/far/" && exit 1)
test -e ~/.jwt || (echo "Please store your JWT token in ~/.jwt, required todeploy resources/bnk-infrastructure.yaml" && exit 1)

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "cluster not found. Please run ./create-k3s-cluster.sh"
  exit 1
fi

./check-nfs-server.sh 
# ./check-sriodp-pfnames.sh

echo ""
echo "label all nodes to make them deploy TMM"
IP=$(ip route get 1 | awk '{print $7}')
for node in $(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers); do
  kubectl label node $node app=f5-tmm || true
  kubectl label node $node pf0-mac="00_11" || true
  kubectl annotate --overwrite node $node 'k8s.ovn.org/node-primary-ifaddr={"ipv4":"$IP"}'
done

echo ""
echo "Create sriovdp-config for ConnectX-5 p0 and p1 ..."
kubectl apply -f resources/sriovdp-cx5.yaml

echo ""
echo "Create network-attachment-definitions for VFS on p0 and p1  ..."
kubectl apply -f resources/nad-vf.yaml

echo ""
echo "Deploy alpine1 pod, connected to p0 and p1 ..."
kubectl apply -f resources/alpine-sriov-vf.yaml

echo ""
echo "Helm Registry Login ..."
tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | helm registry login -u _json_key_base64 --password-stdin https://repo.f5.com

# echo ""
# echo "Docker Registry Login ..."
# tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | docker login -u _json_key_base64 --password-stdin https://repo.f5.com

echo ""
echo "Create f5-utils namespace for SPK supporting software, such as DSSM and CRD conversion ..."
kubectl create ns f5-utils || true
kubectl create ns f5-operators || true

echo ""
echo "F5 Artifacts Registry (FAR) authentication token ..."

# Read the content of cne_pull_64.json into the SERVICE_ACCOUNT_KEY variable
SERVICE_ACCOUNT_KEY=$(tar zxOf ~/far/f5-far-auth-key.tgz)
# Create the SERVICE_ACCOUNT_K8S_SECRET variable by appending "_json_key_base64:" to the base64 encoded SERVICE_ACCOUNT_KEY
SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

echo "Create the secret.yaml file with the provided content ..."
cat << EOF > ~/far/far-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: far-secret
data:
  .dockerconfigjson: $(echo "{\"auths\": {\
\"repo.f5.com\":\
{\"auth\": \"$SERVICE_ACCOUNT_K8S_SECRET\"}}}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF

kubectl -n default  apply -f ~/far/far-secret.yaml
kubectl -n f5-utils apply -f ~/far/far-secret.yaml
kubectl -n f5-operators apply -f ~/far/far-secret.yaml

echo ""
echo "Install OTEL prerequired cert ..."
kubectl apply -f resources/otel-cert.yaml

echo ""
echo "Install Cluster Wide Controller (CWC) to manage license and debug API ..."
rm -rf ~/cwc || true
helm pull oci://repo.f5.com/utils/f5-cert-gen --version 0.9.1  --untar --untardir ~/cwc
mv ~/cwc/f5-cert-gen ~/cwc/cert-gen
pushd ~/cwc && sh cert-gen/gen_cert.sh -s=api-server -a=f5-spk-cwc.f5-utils -n=1 && popd
kubectl apply -f ~/cwc/cwc-license-certs.yaml -n f5-utils

echo "Create directory for API client certs for easier reference ..."
pushd ~/cwc && \
  mkdir -p cwc_api && \
  cp api-server-secrets/ssl/client/certs/client_certificate.pem \
  api-server-secrets/ssl/ca/certs/ca_certificate.pem \
  api-server-secrets/ssl/client/secrets/client_key.pem \
  cwc_api
popd

echo ""
echo "install CSI driver for NFS ..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --set kubeletDir=/var/lib/kubelet

echo "waiting for pods be ready in kube-system namespace ..."
sleep 2
kubectl wait --for=condition=Ready pods --all -n kube-system
kubectl get pods --selector app.kubernetes.io/name=csi-driver-nfs --namespace kube-system
kubectl apply -f resources/storageclass.yaml
kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sleep 2
kubectl get storageclass

echo ""
echo "Install FLO ..."

export JWT=$(cat ~/.jwt)
envsubst < resources/flo-value.yaml >/tmp/flo-value.yaml
helm upgrade --install flo oci://repo.f5.com/charts/f5-lifecycle-operator --version v1.7.8-0.3.37 -f /tmp/flo-value.yaml

# echo ""
# echo "Download Manifest File ..."
# helm pull oci://repo.f5.com/release/f5-bnk-manifest --version 2.0.0-1.7.8-0.3.37
# ls -l f5-bnk-manifest*tgz
# tar zxvf f5-bnk-manifest*tgz
# cat f5-bnk-manifest*/bnk-manifest*yaml | grep f5-spk-crds-common -A 5

echo ""
echo "Install F5 common CRDs ..."
helm upgrade --install f5-spk-crds-common oci://repo.f5.com/charts/f5-spk-crds-common --version 8.7.4 -f resources/crd-values.yaml

echo ""
echo "InstallF5 service proxy CRDs ..."
helm upgrade --install f5-spk-crds-service-proxy oci://repo.f5.com/charts/f5-spk-crds-service-proxy --version 8.7.4 -f resources/crd-values.yaml

echo ""
echo "Verify installed use case CRD helm charts and version ..."
helm list |grep crds

echo ""
echo "List installed F5 use case CRDs ..."
kubectl get crd | grep k8s.f5net.com

echo ""
echo "Install Gateway API CRDs ..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml

echo ""
echo "List installed Gateway API CRDs ..."
kubectl get crd | grep gateway.networking.k8s.io

echo ""
echo "Install BIG-IP Next for Kubernetes ..."
kubectl apply -f resources/bnkgatewayclass-nodpu-sriov-cr.yaml

echo ""
echo "waiting for pods ready in f5-utils ..."
until kubectl wait --for=condition=Ready pods --all -n f5-utils; do
  echo "Waiting for pods to become Ready..."
  sleep 5
done
echo "All pods in f5-utils namespace are Ready."

echo ""
echo "waiting for f5-tmm daemonset be ready ..."
until [ "$(kubectl get daemonset f5-tmm -o jsonpath='{.status.numberReady}')" = "$(kubectl get daemonset f5-tmm -o jsonpath='{.status.desiredNumberScheduled}')" ]; do
  echo "Waiting for f5-tmm DaemonSet to be ready..."
  sleep 5
done
echo "f5-tmm DaemonSet is ready."


echo ""
echo "Installing vlan (selfIP) ..."
kubectl apply -f resources/vlans.yaml

echo ""
echo "Install zebos bgp config  ..."
# BGP ConfigMap that includes ZebOS config
kubectl apply -f resources/zebos-bgp-cm.yaml

echo ""
echo "Deployment completed in $SECONDS secs"
