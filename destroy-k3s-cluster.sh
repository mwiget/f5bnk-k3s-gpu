#!/bin/bash

set -e

[ -x /usr/local/bin/k3s-killall.sh ] && sudo /usr/local/bin/k3s-killall.sh
[ -x /usr/local/bin/k3s-uninstall.sh ] && sudo /usr/local/bin/k3s-uninstall.sh
[ -x /usr/local/bin/k3s-agent-uninstall.sh ] && sudo /usr/local/bin/k3s-agent-uninstall.sh
sudo rm -rf /etc/rancher /var/lib/rancher /var/lib/calico /etc/cni /opt/cni || true
./reset-iptables.sh

sudo rm -f ~/.kube/config ~/.k3s_token || true
