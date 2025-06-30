########################
## Environment Values ##
########################
environment = "dev"
vpc_type    = "Blue"
# proxy_address = "" # Transparent proxy is now in place, this is no longer needed.

#####################
## Required Values ##
#####################
tag_infosecclass       = "Open"        # These tags are applied to all supported resources
tag_networklayer       = "Application" # These tags are applied to all supported resources
tags                   = {}            # These tags are applied to all supported resources
node_group_tags        = {}            # In addition to the above, these tags are applied only to the node group instances
cluster_name           = "dev-example"
node_group_name_prefix = "NodeGroup1"
ami_id                 = "ami-006fbefbd21325293" #Using DevSecOps Hardened Image

#####################
## Optional Values ##
#####################
# vpc_id = ""
# subnet_ids = ""
use_nat_gw = true # If set, will route worker nodes 10.0.0.0 traffic through NATGW for on-prem connectivity
# nat_purpose_tag_value = "NAT to on-prem"
# availability_zones      = ["a", "b", "c"] # May optionally narrow down to use 1, or 2 AZs
# use_new_cn_dtag_subnet = true # Set this to true if `subnets_include_cn_dtag = true`
subnets_include_cn_dtag        = false
subnets_include_private        = true
allow_instance_metadata_access = false

userdata_file = "" #Leave empty if you dont have custom userdata template file for your worker nodes. Will use default provided with proxy config
userdata_vars = {}

#Worker Configuration
desired_size              = 3
max_size                  = 6
min_size                  = 0
capacity_type             = "SPOT"
force_update_version      = true
instance_types            = ["t3.large", "t3a.large", "t4g.large", "m4.large", "m5.large", "m5a.large"]
labels                    = {}
taints                    = []
node_group_timeout_create = "30m"
node_group_timeout_update = "30m"
node_group_timeout_delete = "30m"

# Launch Template
# node_role_arn = "" # If not defined will construct the default IAM role created by the infra-eks-cluster module.
placement_tenancy = "default"
# root_device_name  = "" # Must be set otherwise get no device name error
root_volume_size  = 20 # image needs >= 20 gb
root_volume_type  = "gp3"
root_iops         = 0
key_name          = ""
ebs_optimized     = false
enable_monitoring = false
public_ip         = false
# userdata_file                      = ""
# userdata_vars                      = {}
bootstrap_extra_args = ""
kubelet_extra_args   = ""

#Security Group
# cluster_security_group_id = "" # if not set will discover automatically
worker_security_group_id      = ""
additional_security_group_ids = []
workers_sg_ingress_from_port  = 1025
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
kms_key_enable_key_rotation = true
