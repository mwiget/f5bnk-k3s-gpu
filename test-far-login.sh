#!/bin/bash
for helm in https://get.helm.sh/helm-v3.18.0-linux-amd64.tar.gz https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz; do
  echo "$helm ..."
  curl -sL $helm | tar -xz --strip-components=1 linux-amd64/helm
  ./helm version
  tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | ./helm registry login -u _json_key_base64 --password-stdin https://repo.f5.com
  echo ""
done
