#############
## General ##
#############

# cluster_name = "example"
# cluster_security_group_id = ""
# vpc_id      = ""
tags        = {}
environment = "dev"
vpc_type    = "Blue"


subnet_ids              = ["subnet-01e02664935a35ff9"]
use_new_cn_dtag_subnets = false
subnets_include_cn_dtag = false
subnets_include_private = false

# Populated by Terratest
# node_group_name_prefix = "" # Set by golang tests
# name = "Hardened1"
use_nat_gw = true
# nat_purpose_tag_value = "NAT for test ekscluster"

ami_id = "ami-0157bce7e9dfe5005" #Using DevSecOps Hardened Image
# ami_owners = [
#   "773831636175", #DevSecOps dev
#   "220633687033" #DevSecOps prod
# ]
proxy_address = ""
userdata_file = "" #Leave empty if you dont have custom userdata template file for your worker nodes. Will use default provided with proxy config

################
## Node Group ##
################

# EKS Node Group

desired_size         = 3
max_size             = 6
min_size             = 1
capacity_type        = "ON_DEMAND"
force_update_version = true
instance_types       = ["t3.medium"]
labels               = {}
taints               = []
# node_role_arn          = "" # cannot be instance profile has to be role arn otherwise receive nodeRole error
# node_group_tags           = {} # Populated by test
node_group_timeout_create = "30m"
node_group_timeout_update = "30m"
node_group_timeout_delete = "30m"
# service_linked_role_arn   = ""

# Launch Template

placement_tenancy = "default"
# root_device_name  = "" # Must be set otherwise get no device name error
root_volume_size               = 20 # image needs >= 20 gb
root_volume_type               = "gp3"
root_iops                      = 0
allow_instance_metadata_access = true
key_name                       = ""
ebs_optimized                  = false
enable_monitoring              = false
public_ip                      = false
# userdata_file                      = ""
# userdata_vars                      = {}
bootstrap_extra_args          = ""
kubelet_extra_args            = ""
update_default_version        = true
eni_delete                    = true
cpu_credits                   = "standard"
worker_security_group_id      = ""
additional_security_group_ids = []
sg_ingress_from_port          = 1025
workers_egress_cidr_rules = [
  {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
    from_port   = 0
    to_port     = 65535
  }
]
workers_ingress_cidr_rules = []

#########
## KMS ##
#########
kms_key_arn                 = ""
kms_key_alias               = ""
kms_key_administrators      = []
kms_key_users               = []
kms_key_description         = "Customer Master Key"
kms_key_deletion_window     = 30
kms_key_enable_key_rotation = false

