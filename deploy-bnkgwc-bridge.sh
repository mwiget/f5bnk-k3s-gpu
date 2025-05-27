#!/bin/bash

set -e
SECONDS=0

node=$(hostname)
echo "check cluster node $hostname ..."
kubectl get node $node -o wide

echo ""
echo "label and annotate node $node to deploy TMM via operator"
IP=$(ip route get 1 | awk '{print $7}')
kubectl label node $node app=f5-tmm || true
kubectl annotate --overwrite node $node "k8s.ovn.org/node-primary-ifaddr={\"ipv4\":\"$IP\"}"

echo ""
echo "Install BIG-IP Next for Kubernetes BNKGatewayClass for host TMM ..."
kubectl apply -f resources/bnkgatewayclass-bridge.yaml

echo ""
echo "deploying pod alpine1 with nad bridge-br0-p0 and bridge-br1-p1 ..."
kubectl apply -f resources/alpine-bridge.yaml

echo ""
echo "waiting for pods ready in f5-utils ..."
until kubectl wait --for=condition=Ready pods --all -n f5-utils; do
  echo "Waiting for pods to become Ready..."
  sleep 5
done
echo "All pods in f5-utils namespace are Ready."

echo ""
echo "label node $node with pf0-mac to force TMM deployment on host ..."
kubectl label node $node pf0-mac="00_11" || true

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
echo "check if pod alpine1 is running with bf3 sriov vf's attached ..."
kubectl exec alpine1 -- ip -br a

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug tmctl -d blade tmm/xnet/device_proved ..."
echo ""
kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug -- ip -br a ..."
kubectl exec -ti ds/f5-tmm -c debug -- ip -br a

./static-vip-route.sh 

echo ""
echo "Deployment completed in $SECONDS secs"
