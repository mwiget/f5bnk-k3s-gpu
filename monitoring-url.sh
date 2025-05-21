#!/bin/bash
set -e

kubectl get pod -n monitoring
echo ""
echo "Prometheus & Grafana ..."
kubectl get services -n monitoring prometheus-kube-prometheus-prometheus 

IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
PROMETHEUS=$(kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus -o jsonpath='{.spec.ports[?(@.port==9090)].nodePort}')
GRAFANA=$(kubectl get svc -n monitoring grafana  -o jsonpath="{.spec.ports[?(@.port==3000)].nodePort}")

echo ""
echo -n "check if prometheus web url is healthy ..."
curl -s -D - http://$IP:$PROMETHEUS/-/healthy -o /dev/null | head -n 1
echo -n "check if grafana web url is healthy ...   "
curl -s -D - http://$IP:$GRAFANA/api/health -o /dev/null | head -n 1

PWD=$(kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)

echo ""
echo "Prometheus URL: http://$IP:$PROMETHEUS"
echo "Grafana    URL: http://$IP:$GRAFANA (admin/$PWD)"


