#!/bin/bash
classes=$(kubectl get bnkgatewayclass -o custom-columns=NAME:.metadata.name --no-headers)
for class in $classes; do
  echo "remove $class ..."
  kubectl get bnkgatewayclass $class -o yaml | kubectl delete -f-
done
