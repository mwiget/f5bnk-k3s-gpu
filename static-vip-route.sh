#!/bin/bash
VIP=198.19.19.0/24
set -e

external_ip=$(kubectl get f5-spk-vlan external -o jsonpath='{.spec.selfip_v4s[0]}')
echo "adding static route to vip subnet $VIP via tmm external ip $external_ip ..."

sudo route add -net $VIP gw $external_ip 2>/dev/null || true
ip route get $VIP
