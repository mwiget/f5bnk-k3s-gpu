#!/bin/bash

set -e
SECONDS=0

node=dpu1     # HACK name of the bf3 dpu worker node
host=rome1    # HACK name of the host node hosting the dpu
echo "check cluster node $hostname ..."
kubectl get node $node -o wide

echo ""
echo "label and annotate node $node to deploy TMM via operator"
#IP=$(ip -br a |grep 198.18.100|cut -d/ -f1 | awk '{print $3}')  # HACK
#kubectl annotate --overwrite node $node "k8s.ovn.org/node-primary-ifaddr={\"ipv4\":\"$IP\"}"
kubectl annotate --overwrite node $host 'k8s.ovn.org/node-primary-ifaddr={"ipv4":"198.18.100.62"}'
kubectl label node $node app=f5-tmm || true
kubectl taint node $node dpu=true:NoSchedule || true

echo ""
echo "Install BIG-IP Next for Kubernetes BNKGatewayClass for host TMM ..."
kubectl apply -f resources/bnkgatewayclass-bf3-dpu.yaml

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
echo "kubectl exec -ti ds/f5-tmm -c debug tmctl -d blade tmm/xnet/device_proved ..."
echo ""
kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug -- ip -br a ..."
kubectl exec -ti ds/f5-tmm -c debug -- ip -br a

./static-vip-route.sh 

echo ""
echo "kubectl get f5-spk-vlan ..."
kubectl get f5-spk-vlan

echo ""
echo "Deployment completed in $SECONDS secs"
