#!/bin/bash
# in case dpu node is tainted before sriov-device-plugin is deployed

kubectl patch daemonset kube-sriov-device-plugin -n kube-system \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/tolerations", "value": [{"effect": "NoSchedule", "operator": "Exists"}]}]'
