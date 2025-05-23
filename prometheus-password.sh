#!/bin/bash

echo ""
kubectl get services -n monitoring

PWD=$(kubectl --namespace monitoring get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo)
echo ""
echo "default admin-password: admin/$PWD"

# echo ""
# echo "uploading bnk-grafana-dashboard ..."
# curl -X POST -H 'Content-Type: application/json' -d @resources/bnk-grafana-dashboard.json http://admin:$PWD@localhost:32000/api/dashboards/db
