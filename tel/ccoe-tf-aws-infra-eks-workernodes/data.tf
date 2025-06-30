module "worker_subnets" {
  source = "git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-sup-vpc.git?ref=v1.0.4"

  environment             = var.environment
  vpc_type                = var.vpc_type
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  availability_zones      = var.availability_zones
  use_new_cn_dtag_az_a    = var.use_new_cn_dtag_az_a
  use_new_cn_dtag_az_b    = var.use_new_cn_dtag_az_b
  use_new_cn_dtag_az_c    = var.use_new_cn_dtag_az_c
  use_new_cn_dtag_subnets = var.use_new_cn_dtag_subnets
  subnets_include_cn_dtag = var.subnets_include_cn_dtag
  subnets_include_private = var.subnets_include_private
}

locals {
  eks_worker_subnets           = module.worker_subnets.subnet_ids
  vpc_id                       = module.worker_subnets.vpc_id
  default_worker_iam_role_name = var.node_role_arn != "" ? var.node_role_arn : "arn:aws:iam::${local.account_id}:role/${var.cluster_name}-WorkerNodes-InstanceRole"
  cluster_security_group_id    = var.cluster_security_group_id == "" ? coalescelist(data.aws_security_group.cluster_sg[*].id, [""])[0] : var.cluster_security_group_id

  common_tags = {
    "Environment"           = var.environment
    "dtit:sec:InfoSecClass" = var.tag_infosecclass
    "dtit:sec:NetworkLayer" = var.tag_networklayer
  }

  kubelet_default_args = "--cloud-provider=aws"
  kubelet_args         = "${local.kubelet_default_args} ${var.kubelet_extra_args}"
}

data "aws_security_group" "cluster_sg" {
  count = var.cluster_security_group_id == "" ? 1 : 0

  name = "${var.cluster_name}-eks_cluster_sg"
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

module "nats" {
  source = "git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-sup-nat.git?ref=v1.2.0"

  use_nat_gw            = var.use_nat_gw
  nat_purpose_tag_value = var.nat_purpose_tag_value
  subnet_ids            = local.eks_worker_subnets
}

locals {
  nat_to_gw_string = module.nats.nat_to_gw_string
  az_to_ip_map     = module.nats.az_to_ip_map

  additional_security_group_ids = compact(concat(
    var.additional_security_group_ids,
    [module.nats.nat_use_sg_id]
  ))
}

locals {
  userdata_file = var.userdata_file == "" ? var.proxy_address == "" ? "${path.module}/templates/userdata.sh.tpl" : "${path.module}/templates/proxy_userdata.sh.tpl" : var.userdata_file
}

data "template_file" "userdata" {
  template = file(local.userdata_file)

  vars = merge({
    cluster_name         = var.cluster_name
    endpoint             = data.aws_eks_cluster.cluster.endpoint
    cluster_auth_base64  = data.aws_eks_cluster.cluster.certificate_authority.0.data
    bootstrap_extra_args = var.bootstrap_extra_args
    kubelet_extra_args   = local.kubelet_args
    az_to_natgw          = local.nat_to_gw_string
    },
    var.proxy_address != "" ? { proxy_address = var.proxy_address } : {},
    var.userdata_vars
  )
}

data "aws_caller_identity" "this" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  kms_key_administrators = concat(
    var.kms_key_administrators,
    [
      "arn:aws:iam::${local.account_id}:role/ADFS_DTIT_Project_Key_Admin"
    ]
  )
}

data "aws_ami" "this" {

  owners = concat(["self", "amazon", "aws-marketplace", "microsoft"], var.ami_owners)

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

locals {
  root_device_name = data.aws_ami.this.root_device_name
}

data "aws_kms_key" "kms_key" {
  count = var.kms_key_alias != "" ? 1 : 0

  key_id = "alias/${var.kms_key_alias}"
}

locals {
  kms_key_arn = var.kms_key_alias != "" ? data.aws_kms_key.kms_key[0].arn : var.kms_key_arn != "" ? var.kms_key_arn : ""

  metadata_http_endpoint_enabled       = true
  metadata_http_put_response_hop_limit = var.allow_instance_metadata_access ? null : 1
  metadata_http_tokens_required        = var.allow_instance_metadata_access ? false : true
}
