#!/bin/bash
PCI="c1:00.0"
t=$(sudo mget_temp -d $PCI | cut -d\  -f1)
echo -n "$t C "
lspci|grep $PCI
