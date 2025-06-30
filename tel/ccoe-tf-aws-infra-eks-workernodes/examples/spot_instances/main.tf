terraform {
  required_version = ">= 0.14.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.35"
    }

    template = {
      source  = "hashicorp/template"
      version = ">= 2.1"
    }
  }
  backend "s3" {}
}

module "workers" {
  source = "git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-workernodes.git?ref=v2.0.5"

  #General
  environment               = var.environment
  tag_infosecclass          = var.tag_infosecclass
  tag_networklayer          = var.tag_networklayer
  cluster_name              = var.cluster_name
  cluster_security_group_id = var.cluster_security_group_id
  vpc_id                    = var.vpc_id
  vpc_type                  = var.vpc_type
  subnet_ids                = var.subnet_ids
  use_nat_gw                = var.use_nat_gw
  nat_purpose_tag_value     = var.nat_purpose_tag_value
  availability_zones        = var.availability_zones
  use_new_cn_dtag_az_a      = var.use_new_cn_dtag_az_a
  use_new_cn_dtag_az_b      = var.use_new_cn_dtag_az_b
  use_new_cn_dtag_az_c      = var.use_new_cn_dtag_az_c
  use_new_cn_dtag_subnets   = var.use_new_cn_dtag_subnets
  subnets_include_cn_dtag   = var.subnets_include_cn_dtag
  subnets_include_private   = var.subnets_include_private
  tags                      = var.tags

  # Node Group
  node_group_name_prefix    = var.node_group_name_prefix
  desired_size              = var.desired_size
  max_size                  = var.max_size
  min_size                  = var.min_size
  capacity_type             = var.capacity_type
  force_update_version      = var.force_update_version
  instance_types            = var.instance_types
  labels                    = var.labels
  taints                    = var.taints
  node_group_tags           = local.node_group_tags
  node_group_timeout_create = var.node_group_timeout_create
  node_group_timeout_update = var.node_group_timeout_update
  node_group_timeout_delete = var.node_group_timeout_delete
  node_role_arn             = var.node_role_arn
  service_linked_role_arn   = var.service_linked_role_arn

  # Launch Template
  ami_id                          = var.ami_id
  ami_owners                      = var.ami_owners
  placement_tenancy               = var.placement_tenancy
  root_device_name                = var.root_device_name
  root_volume_size                = var.root_volume_size
  root_volume_type                = var.root_volume_type
  root_iops                       = var.root_iops
  key_name                        = var.key_name
  ebs_optimized                   = var.ebs_optimized
  enable_monitoring               = var.enable_monitoring
  public_ip                       = var.public_ip
  proxy_address                   = var.proxy_address
  userdata_file                   = var.userdata_file
  userdata_vars                   = var.userdata_vars
  bootstrap_extra_args            = var.bootstrap_extra_args
  kubelet_extra_args              = var.kubelet_extra_args
  update_default_version          = var.update_default_version
  eni_delete                      = var.eni_delete
  cpu_credits                     = var.cpu_credits
  worker_security_group_id        = var.worker_security_group_id
  additional_security_group_ids   = var.additional_security_group_ids
  sg_ingress_from_port            = var.workers_sg_ingress_from_port
  workers_egress_cidr_rules       = var.workers_egress_cidr_rules
  workers_ingress_cidr_rules      = var.workers_ingress_cidr_rules
  workers_sg_source_egress_rules  = var.workers_sg_source_egress_rules
  workers_sg_source_ingress_rules = var.workers_sg_source_ingress_rules
  allow_instance_metadata_access  = var.allow_instance_metadata_access

  # KMS Configuration
  kms_key_arn                 = var.kms_key_arn
  kms_key_alias               = var.kms_key_alias
  kms_key_administrators      = var.kms_key_administrators
  kms_key_users               = var.kms_key_users
  kms_key_description         = var.kms_key_description
  kms_key_deletion_window     = var.kms_key_deletion_window
  kms_key_enable_key_rotation = var.kms_key_enable_key_rotation
}
