#!/bin/bash
kubectl -n kube-system rollout restart ds/kube-sriov-device-plugin
