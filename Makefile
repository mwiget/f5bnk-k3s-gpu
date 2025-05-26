#
#
all: requirements cluster bnk bnkgatewayclass-bf3-dpu

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

clean-all: 
	./destroy-dpu1-node.sh
	./destroy-k3s-cluster.sh
