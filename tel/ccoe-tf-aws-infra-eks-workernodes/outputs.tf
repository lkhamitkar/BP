################
## Node Group ##
################

output "desired_size" {
  description = "Desired worker capacity in the node group. This value is only valid upon node group creation, it will not reflect accurately if using cluster-autoscaler. Only implemented here for initial confirmation."
  value       = module.resource.desired_size
}
output "max_size" {
  description = "Maximum number of worker nodes."
  value       = module.resource.max_size
}
output "min_size" {
  description = "Minimum number of worker nodes."
  value       = module.resource.min_size
}

output "ami_id" {
  description = "ID of the default worker group AMI."
  value       = module.resource.ami_id
}

output "security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = module.resource.security_group_id
}

output "root_block_device_configuration" {
  description = "Root block device configuration."
  value       = module.resource.root_block_device_configuration
}

output "service_linked_role_arn" {
  description = "Service-Linked Role ARN which the Node Group ASG will use to call other AWS services."
  value       = module.resource.service_linked_role_arn
}

output "arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group."
  value       = module.resource.arn
}
output "id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon (:)."
  value       = module.resource.id
}
output "resources" {
  description = "List of objects containing information about underlying resources."
  value       = module.resource.resources
}
output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = module.resource.tags_all
}
output "status" {
  description = "Status of the EKS Node Group."
  value       = module.resource.status
}

#####################
## Launch Template ##
#####################

output "launch_template_arn" {
  description = "Amazon Resource Name (ARN) of the launch template."
  value       = module.resource.launch_template_arn
}
output "launch_template_id" {
  description = "The ID of the launch template."
  value       = module.resource.launch_template_id
}
output "launch_template_latest_version" {
  description = "The latest version of the launch template."
  value       = module.resource.launch_template_latest_version
}
output "launch_template_tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = module.resource.launch_template_tags_all
}

output "launch_template_metadata_option_http_endpoint" {
  description = "metadata_options http_endpoint configuration."
  value       = module.resource.launch_template_metadata_option_http_endpoint
}

output "launch_template_metadata_option_http_put_response_hop_limit" {
  description = "metadata_options http_put_response_hop_limit configuration."
  value       = module.resource.launch_template_metadata_option_http_put_response_hop_limit
}

output "launch_template_metadata_option_http_tokens" {
  description = "metadata_options http_tokens configuration."
  value       = module.resource.launch_template_metadata_option_http_tokens
}

#########
## KMS ##
#########

output "kms_key_arn" {
  description = "KMS Key ARN. If pre-existing key was provided then subsequent kms_key_ outputs will be empty."
  value       = module.resource.kms_key_arn
}

output "kms_key_alias_arn" {
  description = "KMS Key Alias ARN. This is used by the EKS cluster."
  value       = module.resource.kms_key_alias_arn
}

output "kms_key_alias_name" {
  description = "KMS Key Alias Name."
  value       = module.resource.kms_key_alias_name
}

output "kms_key_administrators" {
  description = "KMS Key administrators"
  value       = module.resource.kms_key_administrators
}

output "kms_key_users" {
  description = "KMS Key users"
  value       = module.resource.kms_key_users
}

output "kms_key_description" {
  description = "Description of CMK key that was created."
  value       = module.resource.kms_key_description
}

output "kms_key_deletion_window" {
  description = "Duration in days after which the key is deleted after destruction of the resource."
  value       = module.resource.kms_key_deletion_window
}

output "kms_key_enable_key_rotation" {
  description = "Specifies whether key rotation is enabled."
  value       = module.resource.kms_key_enable_key_rotation
}


output "workers_asg_subnets" {
  description = "List of subnet Ids that the ASGs are deployed in."
  value       = local.eks_worker_subnets
}

output "nat_az_to_ip_map" {
  description = "Map of Availability Zones and relevant NAT instance IPs"
  value       = local.az_to_ip_map
}
