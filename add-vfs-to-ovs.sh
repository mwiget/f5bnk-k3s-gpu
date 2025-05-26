#!/bin/bash

# Add pf0vf* interfaces to sf_external bridge
for iface in $(ip -br link | awk '{print $1}' | grep -E '^pf0vf[0-9]+$'); do
    echo "Adding $iface to bridge sf_external"
    ovs-vsctl --may-exist add-port sf_external "$iface"
done

# Add pf1vf* interfaces to sf_internal bridge
for iface in $(ip -br link | awk '{print $1}' | grep -E '^pf1vf[0-9]+$'); do
    echo "Adding $iface to bridge sf_internal"
    ovs-vsctl --may-exist add-port sf_internal "$iface"
done
