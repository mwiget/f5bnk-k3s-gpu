## f5bnk-k3s-gpu

Deployment scripts for F5 BNK on a server with Nvidia bluefield-3 DPU and
GPU using k3s.

## Requirements

- Server node with Bluefield-3 DPU or Mellanox nic to run host only
- NFS server, referenced in resources/storageclass.yaml. Adjust accordingly

Example /etc/exports flags

```
/share/bnk  *(rw,sync,no_subtree_check,no_root_squash)
```

- Adjust dpu interface names in resources/sriovdp-config.yaml (set to enp193.......)

Check out Makefile on how various deployment can be installed.

## Check TMM drivers

Example when using bluefield-3 TMM on dpu1 node:

```
$ ./check-tmm-drivers.sh 
id           available_drivers    driver_selected driver_in_use
------------ -------------------- --------------- -------------
xeth0        sock,                sock            Yes          
0000:c1:00.7 mlxvf5, sock, dpdk,  dpdk            Yes          
0000:c1:02.5 mlxvf5, sock, dpdk,  dpdk            Yes   
```

Example when using TMM on host in demo mode via linux bridges:

```
$ ./check-tmm-drivers.sh 
+ kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed
id    available_drivers driver_selected driver_in_use
----- ----------------- --------------- -------------
xeth0 sock,             sock            Yes          
net1  sock,             sock            Yes          
net2  sock,             sock            Yes          
```

## labs

Folder labs contains a few example LB use cases

## Resources

- https://clouddocs.f5.com/bigip-next-for-kubernetes/2.0.0-GA/
- https://github.com/f5devcentral/f5-bnk-nvidia-bf3-installations
