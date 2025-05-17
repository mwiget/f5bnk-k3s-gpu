#!/bin/bash

set -e

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "cluster not found. Please run make first"
  exit 1
fi

for d in flo-f5-lifecycle-operator f5-afm f5-cne-controller f5-ipam-operator f5-observer-operator otel-collector; do
  echo "kubectl get deployment $d -o yaml | kubectl delete -f-"
  kubectl get deployment $d -o yaml | kubectl delete -f- || true
done

for d in f5-node-labeler f5-tmm; do
  echo "kubectl get daemonset $d -o yaml | kubectl delete -f-"
  kubectl get daemonset $d -o yaml | kubectl delete -f- || true
done

for d in f5-crdconversion f5-ipam-ctlr f5-rabbit f5-spk-cwc f5-toda-fluentd; do
  echo "kubectl get -n f5-utils deployment $d -o yaml | kubectl delete -f-"
  kubectl get -n f5-utils deployment $d -o yaml | kubectl delete -f- || true
done

for d in f5-coremond f5-spk-csrc; do
  echo "kubectl get -n f5-utils daemonset $d -o yaml | kubectl delete -f-"
  kubectl get -n f5-utils daemonset $d -o yaml | kubectl delete -f- || true
done

for d in f5-observer f5-observer-receiver; do
  echo "kubectl get statefulset $d -o yaml | kubectl delete -f-"
  kubectl get statefulset $d -o yaml | kubectl delete -f- || true
done

for d in f5-dssm-db f5-dssm-sentinel; do
  echo "kubectl get -n f5-utils statefulset $d -o yaml | kubectl delete -f-"
  kubectl get -n f5-utils statefulset $d -o yaml | kubectl delete -f- || true
done

kubectl delete -f resources/nginx-red-deployment.yaml || true
kubectl delete -f resources/nginx-red-gw-api.yaml || true
kubectl delete -f resources/bnk-global-context.yaml || true
kubectl delete -f resources/bnk-logging.yaml || true
kubectl delete -f resources/vlans.yaml || true
kubectl delete -f resources/bnk-instance.yaml || true
kubectl delete -f resources/bnk-infrastructure.yaml || true
helm delete orchestrator || true
kubectl delete -f resources/zebos-bgp-cm.yaml || true
kubectl delete -f resources/cwc-qkview-cm.yaml || true
kubectl delete -f resources/cwc-cpcl-jwks.yaml || true
kubectl delete -f ~/cwc/cwc-license-certs.yaml -n f5-utils || true
kubectl delete -f ~/far/far-secret.yaml -n f5-utils || true
kubectl delete -f ~/far/far-secret.yaml -n default || true
kubectl delete -f resources/otel-cert.yaml || true
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/experimental-install.yaml || true
kubectl delete -f resources/storageclass.yaml || true
