#!/bin/bash

set -e

client=lake1    # host with route to external BNK interface p0

echo ""
set -x
kubectl get f5-bnkgateways
kubectl get gatewayclass f5-gateway-class
kubectl get gateway -n red f5-l4-gateway
kubectl get l4route -n red
kubectl get services -n red
set +x
echo ""

echo ""
echo -n "extract assigned IP address from f5-l4-gateway ... "
ip=$(kubectl get gateway -n red f5-l4-gateway -o json | jq -r '.status.addresses[] | select(.type == "IPAddress") | .value')
echo $ip

echo ""
echo "$PWD"
echo ""
echo "Test reachability to virtual server $ip from $client ..."
until ssh $client ping -c3 $ip; do
  echo "waiting 10 secs and try again ..."
  sleep 10
done

echo ""
echo "Test with curl from client $client ..."
echo ""
ssh $client curl -Is http://$ip

echo ""
echo "Downloading 512kb payload from $ip ..."
ssh $client "curl -s -w \"\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n\" -o /dev/null http://198.19.19.50/test/512kb"
