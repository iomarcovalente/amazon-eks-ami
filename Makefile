PACKER_BINARY ?= packer
PACKER_VARIABLES := aws_region ami_name binary_bucket_name binary_bucket_region kubernetes_version kubernetes_build_date docker_version cni_version cni_plugin_version source_ami_id source_ami_owners arch instance_type additional_yum_repos vpc_id subnet_id security_group_id ami_users

K8S_VERSION_PARTS := $(subst ., ,$(kubernetes_version))
K8S_VERSION_MINOR := $(word 1,${K8S_VERSION_PARTS}).$(word 2,${K8S_VERSION_PARTS})

NAT_BUILD := $(NAT_BUILD)

aws_region ?= $(AWS_DEFAULT_REGION)
binary_bucket_region ?= $(AWS_DEFAULT_REGION)
ami_name ?= amazon-eks-node-$(K8S_VERSION_MINOR)-v$(shell date +'%Y%m%d%H%M')

vpc_id ?= $(AWS_DEFAULT_VPC)
subnet_id ?= $(AWS_DEFAULT_SUBNET)
security_group_id ?= $(AWS_PACKER_SECURITY_GROUP_ID)
ami_users ?= $(AWS_AMI_USERS)

arch ?= x86_64
ifeq ($(arch), arm64)
instance_type ?= a1.large
else
instance_type ?= m4.large
endif

ifeq ($(aws_region), cn-northwest-1)
source_ami_owners ?= 141808717104
endif

T_RED := \e[0;31m
T_GREEN := \e[0;32m
T_YELLOW := \e[0;33m
T_RESET := \e[0m

.PHONY: validate
validate:
ifeq ($(NAT_BUILD),ON)
	$(PACKER_BINARY) validate NAT-build $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) eks-worker-al2-nat.json
else
	$(PACKER_BINARY) validate $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) eks-worker-al2.json
endif

.PHONY: k8s
k8s: validate
ifeq ($(NAT_BUILD),ON)
	@echo "$(T_GREEN)Building AMI for NAT-build version $(T_YELLOW)$(kubernetes_version)$(T_GREEN) on $(T_YELLOW)$(arch)$(T_RESET)"
	$(PACKER_BINARY) build $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) eks-worker-al2-nat.json
else
	@echo "$(T_GREEN)Building AMI for version $(T_YELLOW)$(kubernetes_version)$(T_GREEN) on $(T_YELLOW)$(arch)$(T_RESET)"
	$(PACKER_BINARY) build $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) eks-worker-al2.json
endif

# Build dates and versions taken from https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html

.PHONY: 1.12
1.12:
	$(MAKE) k8s kubernetes_version=1.12.10 kubernetes_build_date=2020-01-22

.PHONY: 1.13
1.13:
	$(MAKE) k8s kubernetes_version=1.13.12 kubernetes_build_date=2020-01-22

.PHONY: 1.14
1.14:
	$(MAKE) k8s kubernetes_version=1.14.9 kubernetes_build_date=2020-01-22
