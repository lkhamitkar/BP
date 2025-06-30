#############
## General ##
#############

variable "environment" {
  description = "Name of this AWS environment (either Dev, Test, UAT or Prod). Used for naming resources and is prefixed to the cluster_name"
  type        = string
}

variable "tag_infosecclass" {
  description = "Configures the value for the 'dtit:sec:InfoSecClass' tag. Valid choices are 'Open', 'Internal' or 'Confidential'"
  type        = string
  default     = "Open"
}

variable "tag_networklayer" {
  description = "Configures the value for the 'dtit:sec:NetworkLayer' tag. Valid choices are 'Presentation', 'Application' or 'Database'"
  type        = string
  default     = "Application"
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources."
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane, used to create the relevant ingress and egress rules."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The Vpc Id to launch the EKS Worker Nodes. If not specified it will automatically be determined by using the values specified in 'environment' and 'vpc_type'."
  type        = string
  default     = ""
}

variable "vpc_type" {
  description = "Type of the VPC to be used to deploy EKS cluster. Used to find the relevant VPC id and subnets."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnets to launch the EKS Worker Nodes. If not specified then the subnets are found dynamically using the values from the following variables: 'subnets_include_cn_dtag' and 'subnets_include_private'"
  type        = list(string)
  default     = []
}

variable "use_nat_gw" {
  description = "Whether to configure routing for CN-DTAG range to previously created NAT instances. It will search for EC2 instances with the tag 'Purpose=NAT to on-prem' and create a map of AZ to NAT prviate IP to be used by worker nodes routing."
  type        = bool
  default     = false
}

variable "nat_purpose_tag_value" {
  description = "Value to search for the 'Purpose' tag of the NAT EC2 instances. This only needs to be specified if the 'purpose_tag_value' variable in infra-ec2-nat module has been customised."
  type        = string
  default     = "NAT to on-prem"
}

variable "availability_zones" {
  description = "If specified will automatically select the specified availability zones for auto discovered subnets. Possible values are a list containing one or more of the following availability zone characters; \"a\", \"b\", \"c\"."
  type        = list(string)
  default     = []
}

variable "use_new_cn_dtag_az_a" {
  description = "Whether to use the new cn-dtag subnet in AZ a."
  type        = bool
  default     = false
}
variable "use_new_cn_dtag_az_b" {
  description = "Whether to use the new cn-dtag subnet in AZ b."
  type        = bool
  default     = false
}
variable "use_new_cn_dtag_az_c" {
  description = "Whether to use the new cn-dtag subnet in AZ c."
  type        = bool
  default     = false
}

variable "use_new_cn_dtag_subnets" {
  description = "Whether to use all the new cn-dtag subnets across all AZs."
  type        = bool
  default     = false
}


variable "subnets_include_cn_dtag" {
  description = "Whether the EKS Worker Nodes should be launched within the cn-dtag subnets (can also be combined with subnets_include_private). Default value is 'false'"
  type        = bool
  default     = false
}

variable "subnets_include_private" {
  description = "Whether the EKS Worker Nodes should be launched within the private subnets (can also be combined with subnets_include_cn_dtag). Default value is 'true'"
  type        = bool
  default     = true
}

variable "tags" {
  description = "An optional map of tags to be applied to all resources"
  default     = {}
  type        = map(string)
}

################
## Node Group ##
################

# EKS Node Group

variable "node_group_name_prefix" {
  description = "Name prefix of the node group."
  type        = string
}

variable "desired_size" {
  description = "Desired worker capacity in the node group and changing its value will not affect the node group's desired capacity because the cluster-autoscaler manages up and down scaling of the nodes. Cluster-autoscaler add nodes when pods are in pending state and remove the nodes when they are not required by modifying the desired_capacity of the node group."
  type        = number
  default     = 3
}
variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 6
}
variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 0
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided."
  type        = string
}
variable "force_update_version" {
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue."
  type        = bool
}
variable "instance_types" {
  description = "List of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided."
  type        = list(string)
}
variable "labels" {
  description = "Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed."
  type        = map(string)
}
variable "taints" {
  description = "A list of objects with `key`, `value`, and `effect` attributes, for the Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group. "
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
}


variable "node_group_tags" {
  description = "An optional list of tags to be applied to the Node Group in addition to those specified in the `tags` variable."
  default     = {}
  type        = map(string)
}

variable "node_group_timeout_create" {
  description = "Node Group timeout for create operations"
  type        = string
  default     = "30m"
}
variable "node_group_timeout_update" {
  description = "Node Group timeout for update operations"
  type        = string
  default     = "30m"
}
variable "node_group_timeout_delete" {
  description = "Node Group timeout for delete operations"
  type        = string
  default     = "30m"
}

variable "service_linked_role_arn" {
  description = "(Reserved for future use) Service-linked role ARN to be used by Node Group. This is currently not configurable, leaving this empty will default to 'AWSServiceRoleForAutoScaling'."
  type        = string
  default     = ""
}


# Launch Template

variable "ami_id" {
  description = "AMI ID for the eks workers."
  type        = string
}

variable "ami_owners" {
  description = "List of AWS account IDs to include in AMI ID data call."
  type        = list(string)
  default = [
    "773831636175",
    "220633687033"
  ]
}

variable "node_role_arn" {
  description = "IAM Role ARN to be used on nodes. Ensure this is NOT the instance profile ARN. If not specified will construct the default IAM role ARN used by the infra-eks-cluster module."
  type        = string
  default     = ""
}

variable "placement_tenancy" {
  description = "The tenancy of the instance. Valid values are \"default\" or \"dedicated\"."
  type        = string
}

variable "root_device_name" {
  description = "Root device name for workers. If non is provided, will assume default AMI was used."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "root volume size of workers instances."
  type        = number
}

variable "root_volume_type" {
  description = "root volume type of workers instances, can be 'standard', 'gp2', or 'io1'"
  type        = string
}

variable "root_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of \"io1\"."
  type        = number
}

variable "allow_instance_metadata_access" {
  description = "Allow or disallow access to the workers EC2 instance Metadata Service. Defaults to `true`"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "The key name that should be used for the instances in the node group"
  type        = string
}

variable "ebs_optimized" {
  description = "Sets whether to use ebs optimization on supported types."
  type        = bool
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring."
  type        = bool
}

variable "public_ip" {
  description = "Enables/disables a public ip address for a worker"
  type        = bool
}

variable "proxy_address" {
  description = "(DEPRECATED) Specifying a proxy address will automatically select the proxy_userdata.sh.tpl userdata script for the worker nodes and configure all relevant services with the proxy as required."
  type        = string
  default     = ""
}

variable "userdata_file" {
  description = "Userdata template file used for the EKS Workers launch configuration. Must include section to interpolate cluster_name, endpoint, cluster_auth_base64, bootstrap_extra_args and kubelet_extra_args."
  type        = string
  default     = ""
}

variable "userdata_vars" {
  description = "Allows interpolation of additional variables specified in the custom userdata_file. Not required if only have default variables of cluster_name, endpoint, cluster_auth_base64, bootstrap_extra_args and kubelet_extra_args."
  type        = map(string)
  default     = {}
}

variable "bootstrap_extra_args" {
  description = "Extra arguments passed to the bootstrap.sh script from the EKS AMI (Amazon Machine Image)."
  type        = string
}

variable "kubelet_extra_args" {
  description = "This string is passed directly to kubelet if set. Useful for adding labels or taints."
  type        = string
}

variable "update_default_version" {
  description = "Whether to update Default Version for Launch Template on each update"
  type        = bool
  default     = true
}

variable "eni_delete" {
  description = "Delete the Elastic Network Interface (ENI) on termination (if set to false you will have to manually delete before destroying)"
  type        = bool
  default     = true
}

variable "cpu_credits" {
  description = "T2/T3 unlimited mode, can be 'standard' or 'unlimited'. Used 'standard' mode as default to avoid paying higher costs"
  type        = string
  default     = "standard"
}

variable "worker_security_group_id" {
  description = "If provided, all workers will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the EKS cluster."
  type        = string
  default     = ""
}

variable "additional_security_group_ids" {
  description = "A list of additional security group ids to attach to worker instances"
  type        = list(string)
  default     = []
}

variable "workers_sg_ingress_from_port" {
  description = "Minimum port number from which pods will accept communication. Must be changed to a lower value if some pods in your cluster will expose a port lower than 1025 (e.g. 22, 80, or 443)."
  type        = number
  default     = 1025
}

variable "workers_egress_cidr_rules" {
  description = "Custom CIDR Egress rules for the workers security group."
  type = list(object({
    description = string
    protocol    = string
    cidr_blocks = string
    from_port   = number
    to_port     = number
  }))
}
variable "workers_ingress_cidr_rules" {
  description = "Custom CIDR ingress rules for the workers security group."
  type = list(object({
    description = string
    protocol    = string
    cidr_blocks = string
    from_port   = number
    to_port     = number
  }))
}

variable "workers_sg_source_egress_rules" {
  description = "List of egress SG source security group rules. By default the `workers_egress_cidr_rules` variable allows all outbound access so restrict that too if you want more granular policies."
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
    description              = string
  }))
  default = []
}

variable "workers_sg_source_ingress_rules" {
  description = "List of ingress SG source security group rules."
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
    description              = string
  }))
  default = []
}

#######################
## KMS Configuration ##
#######################

variable "kms_key_arn" {
  description = "ARN of an existing Customer Managed Key (CMK) to use for encrypting EBS volumes of EKS worker nodes. If not specified, a new CMK in AWS KMS with attributes of the other variables starting with `kms_` will be created. This variable is exclusive to `kms_key_alias`. However, if both are specified, `kms_key_alias` will take precedence."
  type        = string
  default     = ""
}

variable "kms_key_alias" {
  description = "Alias of an existing Customer Managed Key (CMK) to use for encrypting EBS volumes of EKS worker nodes. If not specified, a new CMK in AWS KMS with attributes of the other variables starting with `kms_` will be created. This variable is exclusive to `kms_key_arn`. However, if both are specified, the key alias will take precedence."
  type        = string
  default     = ""
}

variable "kms_key_administrators" {
  description = "If creating a new CMK then this variable will define KMS key administrators for this key. A list of IAM user or role ARN(s) is expected. The user or role who is performing the Terraform deployment is provided admin access automatically. Also the role `ADFS_DTIT_Project_Key_Admin` is added as key admin per default. Furthermore the root account user will have full access to the generated key, but without IAM permission delegation to other IAM entities (EnableRootAccessAndPreventPermissionDelegation)."
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "If creating a new CMK then this variable will define KMS key users for this key. A list of IAM user or role ARN(s) is expected. The user or role who is performing the Terraform deployment is provided user access automatically. Also the service-linked role `AWSServiceRoleForAutoScaling` is added as key user per default. Other AWS IAM users or roles will only have very limited access to resources that are encrypted with this key."
  type        = list(string)
  default     = []
}

variable "kms_key_description" {
  description = "If creating a new CMK then this variable will define the description of the key. The description is always prepended with the name of the auto scaling group."
  type        = string
  default     = "Customer Master Key"
}

variable "kms_key_deletion_window" {
  description = "If creating a new CMK then this variable will define the duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days."
  type        = number
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "If creating a new CMK then this variable will specify whether key rotation is enabled. Defaults to false."
  type        = bool
  default     = false
}