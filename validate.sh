#!/bin/bash
set -e
set -x
kubectl get f5-spk-vlan

echo ""
echo "checking TMM Self IP's ..."
kubectl exec -ti daemonset/f5-tmm -c f5-tmm -n default -- ip -br a
