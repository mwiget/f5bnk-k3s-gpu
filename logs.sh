#!/bin/bash
kubectl logs ds/f5-tmm -c f5-fluentbit $1 $2 $3 $4
