#!/bin/bash

set -e
SECONDS=0

DPU_IP="192.168.100.2"
KUBECONFIG_PATH="$HOME/.kube/config"
K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# MASTER_IP="192.168.1.10"  # Set this appropriately
: "${MASTER_IP:=$(ip -4 -o addr show $(ip r | awk '/^default/ {print $5}') | awk '{print $4}' | cut -d/ -f1)}"
echo "Using MASTER_IP $MASTER_IP ..."

ssh-copy-id ubuntu@$DPU_IP

scp -p /etc/k3s-resolv.conf ubuntu@$DPU_IP:
ssh ubuntu@$DPU_IP "sudo mv k3s-resolv.conf /etc/"

ssh ubuntu@$DPU_IP "curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} INSTALL_K3S_EXEC='--resolv-conf=/etc/k3s-resolv.conf' sh -"

for node in $(kubectl get nodes | grep ' Ready '| awk '{print $1}' | grep 'dpu'); do
  echo kubectl taint node $node dpu=true:NoSchedule || true
done

kubectl label nodes dpu1 nvidia.com/gpu.deploy.operands=false

kubectl wait --for=condition=Ready pods --all -n kube-system --timeout 300s
kubectl wait --for=condition=Ready pods --all -n calico-system --timeout 300s
