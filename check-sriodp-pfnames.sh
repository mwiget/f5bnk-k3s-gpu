#!/bin/bash
manifest="resources/sriovdp-config.yaml"

for pf in $(grep pfNames $manifest| grep enp | cut -d\" -f4); do
  if ! ip link show "$pf" > /dev/null 2>&1; then
    echo "ERROR: pfName $pf from $manifest does not exist on this host." >&2
    exit 1
  fi
done
