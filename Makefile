#
# all install software packages, creates k3s cluster and 
# installs F5 BNK FLO with required CRDs
#
all: requirements cluster bnk

# From here, either use bridge, dpu or host:
#
# - bridge: deploy TMM in demo mode using linux bridges 
# - dpu:    adds bluefield-3 node (dpu1) to the cluster and installs TMM
# - host:   deploys TMM on host node using SR-IOV VFs on bluefield-3

bridge: bnkgatewayclass-bridge

dpu: bnkgatewayclass-bf3-dpu

host: bnkgatewayclass-bf3-host

requirements:
	./install-requirements.sh

cluster:
	./create-k3s-cluster.sh

bnk:
	./deploy-bnk.sh

bnkgatewayclass-bf3-dpu:
	./delete-bnkgwc.sh
	./deploy-bnkgwc-bf3-dpu.sh

bnkgatewayclass-bf3-host:
	./delete-bnkgwc.sh
	./deploy-bnkgwc-bf3-host.sh

bnkgatewayclass-intel-host:
	./delete-bnkgwc.sh
	./deploy-bnkgwc-intel-host.sh

bnkgatewayclass-bridge:
	./delete-bnkgwc.sh
	./deploy-bnkgwc-bridge.sh

clean-all: 
	./destroy-dpu1-node.sh
	./destroy-k3s-cluster.sh
