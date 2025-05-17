#!/bin/bash

set -e

scp destroy-k3s-cluster.sh reset-iptables.sh ubuntu@192.168.100.2:
ssh ubuntu@192.168.100.2 ./destroy-k3s-cluster.sh
