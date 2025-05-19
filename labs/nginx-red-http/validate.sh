#!/bin/bash

set -e

client=lake1    # host with route to external BNK interface p0

echo ""
echo "$PWD"
echo ""
echo "Test reachability to virtual server 198.19.19.100 from $client ..."
until ssh $client ping -c3 198.19.19.100; do
  echo "waiting 10 secs and try again ..."
  sleep 10
done

echo ""
set -x
kubectl get f5-bnkgateways
kubectl get gatewayclass f5-gateway-class
kubectl get gateway -n red my-httproute-gateway
kubectl get httproute -n red
set +x
echo ""

echo ""
echo "Test with curl from client $client ..."
echo ""
set -x
ssh $client curl -Is -H "http.example.com" http://198.19.19.100
set +x
