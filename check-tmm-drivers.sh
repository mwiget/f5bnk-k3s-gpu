#!/bin/bash
set -x
kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed
