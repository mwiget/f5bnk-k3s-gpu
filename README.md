## f5bnk-k3s-gpu

Deployment scripts for F5 BNK on a server with Nvidia bluefield-3 DPU and
GPU using k3s.

## Requirements

- Server node with Bluefield-3 DPU installed
- NFS server, used in resources/storageclass.yaml. Adjust file accordingly

Example /etc/exports flags

```
/share  *(rw,sync,no_subtree_check,no_root_squash)
```

- Adjust dpu interface names in resources/sriovdp-config.yaml (set to enp193.......)


## Scripts to deploy from scratch

- [install-requirements.sh](install-requirements.sh) installs DOCA and GPU drivers plus dependencies
- [create-bf-config.sh](create-bf-config.sh) generates dpu config (name, password)
- [deploy-bf-bundle.sh](deploy-bf-bundle.sh) downloads and deploys dpu bfb bundle with the generated config
- [create-k3s-cluster.sh](create-k3s-cluster.sh) creates k3s on the local host with Calico CNI, Multus, GPU operator etc
- [add-dpu1-node.sh](add-dpu1-node.sh) adds dpu node to k3s cluster
- [deploy-bnk.sh](deploy-bnk.sh) deploys bnk on k3s cluster

## Scripts to delete/destroy

- [delete-bnk.sh](delete-bnk.sh) delete bnk from k3s cluster
- [destroy-k3s-cluster.sh](destroy-k3s-cluster.sh) destroys k3s cluster
