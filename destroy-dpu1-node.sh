#!/bin/bash

set -e

kubectl delete node dpu1 || true
scp destroy-k3s-cluster.sh reset-iptables.sh ubuntu@192.168.100.2:
ssh ubuntu@192.168.100.2 ./destroy-k3s-cluster.sh
