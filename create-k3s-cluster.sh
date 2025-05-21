#!/bin/bash
#set -x
set -e
KUBECONFIG_PATH="$HOME/.kube/config"
K3S_TOKEN_FILE="$HOME/.k3s_token"
if [[ -f $K3S_TOKEN_FILE ]]; then
    K3S_TOKEN=$(<"$K3S_TOKEN_FILE")
  else
    K3S_TOKEN=$(head -c 16 /dev/urandom | sha256sum | cut -c1-64)
    echo "$K3S_TOKEN" > "$K3S_TOKEN_FILE"
fi

# MASTER_IP="192.168.1.10"  # Set this appropriately
: "${MASTER_IP:=$(ip -4 -o addr show $(ip r | awk '/^default/ {print $5}') | awk '{print $4}' | cut -d/ -f1)}"
echo "Using MASTER_IP $MASTER_IP ..."

echo "creating /etc/k3s-resolv.conf ..."
sudo tee /etc/k3s-resolv.conf >/dev/null <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

echo ""
echo "Installing master node ..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --node-ip=$MASTER_IP \
  --token=$K3S_TOKEN \
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16 \
  --resolv-conf=/etc/k3s-resolv.conf \
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik \
  --write-kubeconfig-mode 644 \
  --write-kubeconfig ~/.kube/config" sh -

echo ""
kubectl get node -o wide

echo ""
echo "Installing Calico ..."
kubectl get ns calico-system 2>/dev/null \
  || kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml || true
sleep 5
kubectl apply -f resources/calico-custom-resources.yaml

echo ""
echo "Waiting for Kubernetes control plane to get ready ..."
sleep 10
kubectl wait --for=condition=Ready pods --all -n calico-system  --timeout 300s

# Multus and SRIOV
kubectl apply -f resources/multus.yaml
kubectl apply -f resources/cni-plugins.yaml
kubectl apply -f resources/sriovdp-config.yaml
kubectl apply -f resources/sriov-cni-daemonset.yaml
kubectl apply -f https://raw.github.com/k8snetworkplumbingwg/sriov-network-device-plugin/master/deployments/sriovdp-daemonset.yaml
kubectl apply -f resources/nad-sf.yaml

echo ""
echo "deploy gpu operator (ignore dpu nodes)"
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update
kubectl get ns gpu-operator || helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --version=v24.9.2 \
     --set toolkit.env[0].name=CONTAINERD_SOCKET \
     --set toolkit.env[0].value=/run/k3s/containerd/containerd.sock \
     --set driver.enabled=false

echo ""
echo "Install cert-manager and clustr issuer to manage pod-to-pod certs ..."
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install -n cert-manager cert-manager jetstack/cert-manager --create-namespace --version v1.16.1 --set crds.enabled=true --wait
kubectl wait --for=condition=Ready pods --all -n cert-manager
kubectl apply -f resources/cluster-issuer.yaml

echo ""
echo "Install prometheus & grafana ..."
kubectl get ns monitoring || kubectl create ns monitoring
kubectl apply -f resources/prometheus-cert.yaml -n monitoring
helm repo add prometheus-community \
   https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
   --create-namespace --namespace monitoring \
   --values resources/prometheus-values.yaml || echo "already installed"

kubectl wait --for=condition=Ready pods --all -n monitoring

kubectl apply -f resources/grafana-service.yaml -n monitoring

echo ""
PWD=$(kubectl --namespace monitoring get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo)
echo "default admin-password: admin/$PWD"

echo ""
kubectl get services -n monitoring

# echo ""
# echo "uploading bnk-grafana-dashboard ..."
# curl -X POST -H 'Content-Type: application/json' -d @resources/bnk-grafana-dashboard.json http://admin:$PWD@localhost:32000/api/dashboards/db

echo "Waiting for for kube-system pods to be ready ..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout 600s
