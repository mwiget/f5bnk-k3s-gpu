#!/bin/bash
manifest="resources/sriovdp-config.yaml"

echo "Checking if pfNames from $manifest exist on this host ..."
for pf in $(grep pfNames $manifest| grep enp | cut -d\" -f4); do
  if ! ip link show "$pf" > /dev/null 2>&1; then
    echo ""
    echo "ERROR: pfName $pf from $manifest does not exist on this host." >&2
    exit 1
  else
    echo "$pf Ok"
  fi
done
