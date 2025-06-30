################
## Node Group ##
################

output "desired_size" {
  description = "Desired worker capacity in the node group. This value is only valid upon node group creation, it will not reflect accurately if using cluster-autoscaler. Only implemented here for initial confirmation."
  value       = module.workers.desired_size
}
output "max_size" {
  description = "Maximum number of worker nodes."
  value       = module.workers.max_size
}
output "min_size" {
  description = "Minimum number of worker nodes."
  value       = module.workers.min_size
}

output "ami_id" {
  description = "ID of the default worker group AMI."
  value       = module.workers.ami_id
}

output "security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = module.workers.security_group_id
}

output "root_block_device_configuration" {
  description = "Root block device configuration."
  value       = module.workers.root_block_device_configuration
}

output "service_linked_role_arn" {
  description = "Service-Linked Role ARN which the Node Group ASG will use to call other AWS services."
  value       = module.workers.service_linked_role_arn
}

output "arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group."
  value       = module.workers.arn
}
output "id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon (:)."
  value       = module.workers.id
}
output "resources" {
  description = "List of objects containing information about underlying resources."
  value       = module.workers.resources
}
output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = module.workers.tags_all
}
output "status" {
  description = "Status of the EKS Node Group."
  value       = module.workers.status
}

output "nat_az_to_ip_map" {
  description = "Map of Availability Zones and relevant NAT instance IPs"
  value       = module.workers.nat_az_to_ip_map
}

#####################
## Launch Template ##
#####################

output "launch_template_arn" {
  description = "Amazon Resource Name (ARN) of the launch template."
  value       = module.workers.launch_template_arn
}
output "launch_template_id" {
  description = "The ID of the launch template."
  value       = module.workers.launch_template_id
}
output "launch_template_latest_version" {
  description = "The latest version of the launch template."
  value       = module.workers.launch_template_latest_version
}
output "launch_template_tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = module.workers.launch_template_tags_all
}

output "launch_template_metadata_option_http_endpoint" {
  description = "metadata_options http_endpoint configuration."
  value       = module.workers.launch_template_metadata_option_http_endpoint
}

output "launch_template_metadata_option_http_put_response_hop_limit" {
  description = "metadata_options http_put_response_hop_limit configuration."
  value       = module.workers.launch_template_metadata_option_http_put_response_hop_limit
}

output "launch_template_metadata_option_http_tokens" {
  description = "metadata_options http_tokens configuration."
  value       = module.workers.launch_template_metadata_option_http_tokens
}

#########
## KMS ##
#########

output "kms_key_arn" {
  description = "KMS Key ARN. If pre-existing key was provided then subsequent kms_key_ outputs will be empty."
  value       = module.workers.kms_key_arn
}

output "kms_key_alias_arn" {
  description = "KMS Key Alias ARN. This is used by the EKS cluster."
  value       = module.workers.kms_key_alias_arn
}

output "kms_key_alias_name" {
  description = "KMS Key Alias Name."
  value       = module.workers.kms_key_alias_name
}

output "kms_key_administrators" {
  description = "KMS Key administrators"
  value       = module.workers.kms_key_administrators
}

output "kms_key_users" {
  description = "KMS Key users"
  value       = module.workers.kms_key_users
}

output "kms_key_description" {
  description = "Description of CMK key that was created."
  value       = module.workers.kms_key_description
}

output "kms_key_deletion_window" {
  description = "Duration in days after which the key is deleted after destruction of the resource."
  value       = module.workers.kms_key_deletion_window
}

output "kms_key_enable_key_rotation" {
  description = "Specifies whether key rotation is enabled."
  value       = module.workers.kms_key_enable_key_rotation
}


output "workers_asg_subnets" {
  description = "List of subnet Ids that the ASGs are deployed in."
  value       = module.workers.workers_asg_subnets
}
