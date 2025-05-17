#!/bin/bash

YAML_FILE="resources/storageclass.yaml"

# Extract server and share path from YAML file
server=$(awk '/server:/ { print $2 }' "$YAML_FILE")
share=$(awk '/share:/ { print $2 }' "$YAML_FILE")

if [[ -z "$server" || -z "$share" ]]; then
  echo "Error: Could not extract server or share path from $YAML_FILE"
  exit 1
fi

echo -n "check NFS export $share on server $server based on $YAML_FILE ... "

# Get exported paths
exports=$(showmount -e "$server" 2>/dev/null | awk 'NR > 1 { print $1 }')

for path in $exports; do
  if [[ "$share" == "$path"* ]]; then
    echo "Ok"
    exit 0
  fi
done

echo ""
echo "ERROR: Share $share is NOT within exported paths on $server"
exit 3
