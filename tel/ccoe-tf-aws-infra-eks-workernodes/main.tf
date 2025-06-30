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
}

module "resource" {
  source = "git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-res-eks-workernodes.git?ref=v2.0.4"

  cluster_name                         = var.cluster_name
  cluster_security_group_id            = local.cluster_security_group_id
  vpc_id                               = local.vpc_id
  tags                                 = merge(var.tags, local.common_tags)
  node_group_name_prefix               = var.node_group_name_prefix
  desired_size                         = var.desired_size
  max_size                             = var.max_size
  min_size                             = var.min_size
  capacity_type                        = var.capacity_type
  force_update_version                 = true
  instance_types                       = var.instance_types
  labels                               = var.labels
  taints                               = var.taints
  node_group_tags                      = var.node_group_tags
  node_group_timeout_create            = var.node_group_timeout_create
  node_group_timeout_update            = var.node_group_timeout_update
  node_group_timeout_delete            = var.node_group_timeout_delete
  service_linked_role_arn              = var.service_linked_role_arn
  ami_id                               = var.ami_id
  node_role_arn                        = local.default_worker_iam_role_name
  placement_tenancy                    = var.placement_tenancy
  root_device_name                     = local.root_device_name
  root_volume_size                     = var.root_volume_size
  root_volume_type                     = var.root_volume_type
  root_iops                            = var.root_iops
  metadata_http_endpoint_enabled       = local.metadata_http_endpoint_enabled
  metadata_http_put_response_hop_limit = local.metadata_http_put_response_hop_limit
  metadata_http_tokens_required        = local.metadata_http_tokens_required
  key_name                             = var.key_name
  ebs_optimized                        = var.ebs_optimized
  enable_monitoring                    = var.enable_monitoring
  public_ip                            = var.public_ip
  subnets                              = local.eks_worker_subnets
  userdata                             = base64encode(data.template_file.userdata.rendered)
  update_default_version               = true
  eni_delete                           = var.eni_delete
  cpu_credits                          = var.cpu_credits
  security_group_id                    = var.worker_security_group_id
  additional_security_group_ids        = local.additional_security_group_ids
  sg_ingress_from_port                 = var.sg_ingress_from_port
  workers_egress_cidr_rules            = var.workers_egress_cidr_rules
  workers_ingress_cidr_rules           = var.workers_ingress_cidr_rules
  workers_sg_source_egress_rules       = var.workers_sg_source_egress_rules
  workers_sg_source_ingress_rules      = var.workers_sg_source_ingress_rules
  kms_key_arn                          = local.kms_key_arn
  kms_key_administrators               = local.kms_key_administrators
  kms_key_users                        = var.kms_key_users
  kms_key_description                  = var.kms_key_description
  kms_key_deletion_window              = var.kms_key_deletion_window
  kms_key_enable_key_rotation          = var.kms_key_enable_key_rotation
}
