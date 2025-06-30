# ccoe-tf-aws-infra-eks-workernodes <!-- omit in toc -->

- [Getting Started](#getting-started)
- [Overview](#overview)
  - [Hardened AMI](#hardened-ami)
  - [Updating Node Group Instances](#updating-node-group-instances)
  - [Using Spot Instances](#using-spot-instances)
  - [Access to Corporate Systems](#access-to-corporate-systems)
- [Assumptions](#assumptions)
- [PSA Compliance](#psa-compliance)
- [Updating Module Version](#updating-module-version)
- [v2.0.0](#v200)
- [v1.0.0](#v100)
- [Example Usage](#example-usage)
  - [Gitlab CI Pipeline](#gitlab-ci-pipeline)
  - [Node Labels](#node-labels)
  - [Taints](#taints)
  - [On-prem NAT](#on-prem-nat)
- [Destroying Deployment](#destroying-deployment)
  - [Steps](#steps)
  - [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Getting Started

This is an Infrastructure Module for the creation of node groups for an EKS cluster. It is only intended to be called from customer created Terraform Compositions and not used directly. This page demonstrates how to use the provided Infrastructure Module with examples.

If you are unfamiliar with Terraform then we suggest you review the [simple-eks-cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-simple-eks-cluster) repository. It is a clonable repository designed to get you started with creating your own Terraform cluster using this and other relevant Terraform modules, it comes with a dedicated Gitlab pipeline that will show you changes to the infrastructure prior to applying them.

## Overview

This Infrastructure Module creates **managed** node groups for your EKS cluster. It does so by creating **one** node group across all the subnets you have specified. If you need to have per-AZ node groups then you will need to have multiple Terraform compositions, one for each AZ.

AWS **managed** node groups are an abstraction of having to run and manage the Automatic Scaling Group (ASG) of worker nodes yourself including the removal of instances from the cluster. You *will* see an ASG in your EC2 console, **do not modify** this ASG directly as this is handled by AWS managed node groups. For more information please read the AWS documentation on [Managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html).

You can utilise spot instances by setting the `capacity_type` to `SPOT`. More information about using spot instances is documented in the [Using Spot Instances](#using-spot-instances) section of this document.

>For additional information about cluster configuration such as Fargate nodes, connecting to your cluster, exposing your workloads to end users, etc, please review the [ccoe-tf-aws-infra-eks-cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-cluster) module documentation

![architecture diagram](images/architecture.png)

### Hardened AMI

This template **does not use the latest Hardened AMI** but rather what was available at the time of creating the module. It is your responsitibility to update the `ami_id` variable with the correct latest version.

You can use the following command to find the correct AMI ID: `aws ec2 describe-images  --filters "Name=name,Values=DevSecOps-eks-node-*" --query 'reverse(sort_by(Images, &CreationDate))[].[Name,ImageId,CreationDate]'`

You can read more about the DevSecOps hardened images on their [Hardening - EKS](https://ccoe-wbench.workbench.telekom.de/pages/teamdevsecops/user-documentation/public/docs/hardening/eks/) page.

### Updating Node Group Instances

Managed node group updates are automatically handled by AWS. AWS will wait for the node to join the cluster, and it will also ensure that a node gracefully leaves a cluster and shifts workloads to other nodes, when it is no longer needed. You no longer need to worry about tainting and draining a node.

It will also handle the rolling out of new instances in a rolling fashion. You can read more about it within the following articles:

- [Updating Managed Node Group](https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html)
- [Managed Node Update Behaviour](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html)

### Using Spot Instances

You can easily use spot instances with this module by specifying the `capacity_type` variable to `SPOT`. There are a number of items to consider when using spot instances, and it is not the purpose of this README to cover them in detail but we link to relevant AWS blogs. We highlight some of the main points below:

- Use a base `ON_DEMAND` node group to run critical system workloads (i.e. CoreDNS).
- On top of this run one or more `SPOT` node group(s) to run your workloads.
- Utilise multiple instance types for increasing resiliency.
- Ensure you utilise Cluster Autoscaler. You may install it yourself or use the configuration provided by the [infra-eks-cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-cluster#cluster-autoscaler) module.

There is an example of a node group using spot instances within the [examples/spot_instances](examples/spot_instances) folder.

The following AWS blogs will help you understand utilising spot instances with EKS.

- [Amazon EKS now supports provisioning and managing EC2 Spot Instances in managed node groups](https://aws.amazon.com/blogs/containers/amazon-eks-now-supports-provisioning-and-managing-ec2-spot-instances-in-managed-node-groups/)
- [Building for Cost optimization and Resilience for EKS with Spot Instances](https://aws.amazon.com/blogs/compute/cost-optimization-and-resilience-eks-with-spot-instances/)

### Access to Corporate Systems

A common scenario for workloads on AWS is to be able to access centralised systems within the corporate network that does not reside on AWS (i.e. Artifactory, or on-premise systems). The current network design may impose two restrictions for such network connectivity:

- Only allowed for workloads running on CN-DTAG.
- Access on corporate firewalls are whitelisted to specific source IP address.

This presents a problem as most workloads run within the private subnets, therefore the current solution is to run some EC2 instances within the CN-DTAG subnets that can both NAT your traffic to other corporate networks, and be whitelisted against any required firewalls. The [ccoe-tf-aws-infra-ec2-nat](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-ec2-nat) Terraform module can create these for you.

If your workloads require access to corporate systems then please review the [On-prem NAT](#on-prem-nat) section of this document.
## Assumptions

* You want to create a managed node group.
* You have previously created an [EKS cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-cluster).
* If you require on-prem connectivity, then you have previously created [EC2 NAT instances](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-ec2-nat).

## PSA Compliance

This template was created with PSA compliance in mind. There are many security points which are outside the scope of this module (such as EKS configuration, Network and PodSecurity policies) and are dependant on how the EKS cluster configuration were created.

**The [following table](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-security/-/blob/master/SECURITY.md) outlines all security related configuration**

The following Terraform modules for the creation of these EKS resources are also configured with PSA compliance in mind. For the best security posture use the following Terraform modules, otherwise you need to ensure your configuration matches the requirements yourself:

* [ccoe-tf-aws-infra-eks-cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-cluster) - EKS Cluster that has security settings enabled by default.
* **Work In Progress** [ccoe-tf-aws-infra-eks-security](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-security) - EKS Security creates required components to ensure an EKS cluster is configured with security best practices to align with the PSA approval process. Can be executed on any EKS cluster regardless of how it was created.

## Updating Module Version

Some updates might require special consideration. The [CHANGELOG](CHANGELOG.md) will always direct you on this and the instructions will be documented in the [UPDATE](UPDATE.md) file.

## v2.0.0

This major version changes the solution from having used a self-managed node group, to now using a **managed** node group. This is **NOT AN IN-PLACE UPDATE**, to use this version please create a new node group Terraform composition and then delete your old node group composition, instead of attempting to update your current nodes. Managed node group adds a number of additional benefits, just to highlight a few:

- Easily use _SPOT_ instances.
- Managed node draining from cluster when scalling in or replacing nodes.
- Automatic rollout of nodes upon updating.

The [following documentation](UPDATE.md#updating-to-v200) provides high level instructions on how to achieve this.

## v1.0.0

This version has two major modifications. Updating to minimum Terraform version of 0.14.9 and AWS provider major version 3. In order for your existing deployments to utilise this upgrade there are some key steps to be performed across all your environments and Terraform deployments. Please review the [Upgrade Terraform to v0.14+](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-examples#upgrade-terraform-to-v014).

## Example Usage

You can find the examples solution within the [examples](examples/) subfolder.

To download the example code and copy it into your repository, please follow the instructions [outlined here](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-examples#creating-your-composition).

### Gitlab CI Pipeline

The example is provided with a Gitlab CI yaml file you can use to automate the deployment.

#### Prerequisites

Your main Gitlab CI yaml file needs to contain job configuration that is then extended by the provided file. You can review an example main [Gitlab CI file](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-simple-eks-cluster/-/blob/dev/.gitlab-ci.yml) :

#### Usage

To use this simply do the following:

1. (Conditional) If you have copied the example code to a directory other than `eu-central-1/eks-workernodes/`, update line 6 to reflect the correct directory:

```hcl
.directory_name: &directory-name
  - eu-central-1/eks-workernodes/*
```

2. Update your main Gitlab CI file (located in repository root directory named `.gitlab-ci.yml`) with the following (appending the `include` values if key is already present):

##### Using Simple Repository

```yaml
include:
  - local: 'eu-central-1/eks-workernodes/gitlab-ci.yml'

.job:eks-workernodes:
  variables:
    <<: *global-vars
    TERRAFORM_DIR: eu-central-1/eks-workernodes
    COMP_SPECIFIC_TFVARS: --var-file ${CI_PROJECT_DIR}/${AWS_DEFAULT_REGION}/cluster_name.tfvars --var-file ${CI_PROJECT_DIR}/${AWS_DEFAULT_REGION}/worker_group.tfvars
```

##### Using Other Repository

Only difference is not specifying the `COMP_SPECIFIC_TFVARS` key.

```yaml
include:
  - local: 'eu-central-1/eks-workernodes/gitlab-ci.yml'

.job:eks-workernodes:
  variables:
    <<: *global-vars
    TERRAFORM_DIR: eu-central-1/eks-workernodes
```

### Node Labels

You can add node labels by using the `labels` variable which accepts a key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed.

### Taints

You can add taints to the node group by specifying the `taints` variable which accepts a list of objects with `key`, `value`, and `effect` attributes, for the Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group.

### On-prem NAT

#### Pre-requisites

In order to NAT traffic to the on-prem environment, the relevant EC2 instances with a `Purpose` tag need to be created. You can use the following [EC2 NAT instances](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-ec2-nat) Terraform module.

#### Worker Node Configuration

In order to configure worker nodes to use the NAT instances for on-prem connectivity, the following variable needs to be configured:

`use_nat_gw = true`

If a custom `Purpose` tag (only needed in exceptional circumstances) was specified on the EC2 instances then the following variable also needs to be specified with the correct value (below value shows the default value):

`nat_purpose_tag_value = "NAT to on-prem"`

Setting `use_nat_gw` performs the following within this module:

1) Search for EC2 instances with the `nat_purpose_tag_value`, obtain their Availability Zone and Private IP for network interfaces that are in the same subnet as worker nodes
2) Modify the worker nodes Userdata with IP routing configuration, with mapping of AZ to NAT's private IP to ensure each worker node is using the corresponding NAT EC2 instance.
3) Add the security group created by the NAT infrastructure module that ends in `*-use-sg` and contains the `Purpose` tag.

## Destroying Deployment

> :warning: **Only destroy the deployment if you really need to**: If you are attempting to modify a deployment, or fix a deployment, you most likely do not need to delete the deployment! Modifications to the deployment can be performed in place.

This stack does not have any pre-requisites in order to successfully remove it, but it serves as a pre-requisite for being able to destroy other stacks:

- [ccoe-tf-aws-infra-eks-cluster](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-eks-cluster)
- [ccoe-tf-aws-infra-ec2-nat](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-infra-ec2-nat)

### Steps

> :warning: If you delete a managed node group that uses a node IAM role that isn't used by any other managed node group in the cluster, the role is removed from the aws-auth ConfigMap. If any self-managed node groups in the cluster are using the same node IAM role, the self-managed nodes move to the NotReady status, and the cluster operation are also disrupted. You can add the mapping back to the ConfigMap to minimize disruption.
> This was obtained from the following AWS documentation [Deleting a managed node group](https://docs.aws.amazon.com/eks/latest/userguide/delete-managed-node-group.html).

Once you are ready to delete this module's deployment follow the steps located within the [Destroying Deployment](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-examples#destroying-deployment) section of the [ccoe-tf-aws-examples](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-example) page.

### Troubleshooting

#### Dependency Violation

The following error may appear when attempting to delete the stack:

```
│ Error: Error deleting security group: DependencyViolation: resource sg-08d33e0d469b6a642 has a dependent object
│ 	status code: 400, request id: 3783565a-8c05-465a-88de-dbbee07c1752
│ 
│ 
╵}
```

This error indicates that Terraform is attempting to delete the worker node security group but it is currently in use. In our tests this is due to the fact that AWS deletes the managed node group but has not completely cleaned up all resources, so we will need to do this ourselves.

1. Find the Elastic Network Interfaces that are still using this security group:

```bash
aws ec2 describe-network-interfaces --filters Name=group-id,Values=<security group id> --query "NetworkInterfaces[*].[Description,NetworkInterfaceId]"

[
  [
    "aws-K8S-i-06951fad9a03b8d80",
    "eni-0928ef87da90167f5"
  ],
  [
    "aws-K8S-i-011020c7b3bad0b54",
    "eni-0383b1d259fdeccd7"
  ]
]
```

2. Delete the found ENIs:

```bash
aws ec2 delete-network-interface --network-interface-id <eni-id-1>
aws ec2 delete-network-interface --network-interface-id <eni-id-2>
```

3. Now re-run the destroy.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.35 |
| <a name="requirement_template"></a> [template](#requirement\_template) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.48.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nats"></a> [nats](#module\_nats) | git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-sup-nat.git | v1.2.0 |
| <a name="module_resource"></a> [resource](#module\_resource) | git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-res-eks-workernodes.git | v2.0.4 |
| <a name="module_worker_subnets"></a> [worker\_subnets](#module\_worker\_subnets) | git::https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/ccoe-tf-aws-sup-vpc.git | v1.0.4 |

## Resources

| Name | Type |
|------|------|
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_kms_key.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_security_group.cluster_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [template_file.userdata](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | A list of additional security group ids to attach to worker instances | `list(string)` | `[]` | no |
| <a name="input_allow_instance_metadata_access"></a> [allow\_instance\_metadata\_access](#input\_allow\_instance\_metadata\_access) | Allow or disallow access to the workers EC2 instance Metadata Service. Defaults to `true` | `bool` | `true` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for the eks workers. | `string` | n/a | yes |
| <a name="input_ami_owners"></a> [ami\_owners](#input\_ami\_owners) | List of AWS account IDs to include in AMI ID data call. | `list(string)` | <pre>[<br>  "773831636175",<br>  "220633687033"<br>]</pre> | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | If specified will automatically select the specified availability zones for auto discovered subnets. Possible values are a list containing one or more of the following availability zone characters; "a", "b", "c". | `list(string)` | `[]` | no |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | Extra arguments passed to the bootstrap.sh script from the EKS AMI (Amazon Machine Image). | `string` | n/a | yes |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Type of capacity associated with the EKS Node Group. Valid values: ON\_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. Also used as a prefix in names of related resources. | `string` | n/a | yes |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Security group ID of the EKS cluster control plane, used to create the relevant ingress and egress rules. | `string` | `""` | no |
| <a name="input_cpu_credits"></a> [cpu\_credits](#input\_cpu\_credits) | T2/T3 unlimited mode, can be 'standard' or 'unlimited'. Used 'standard' mode as default to avoid paying higher costs | `string` | n/a | yes |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired worker capacity in the node group and changing its value will not affect the node group's desired capacity because the cluster-autoscaler manages up and down scaling of the nodes. Cluster-autoscaler add nodes when pods are in pending state and remove the nodes when they are not required by modifying the desired\_capacity of the node group. | `number` | `3` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Sets whether to use ebs optimization on supported types. | `bool` | n/a | yes |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enables/disables detailed monitoring. | `bool` | n/a | yes |
| <a name="input_eni_delete"></a> [eni\_delete](#input\_eni\_delete) | Delete the Elastic Network Interface (ENI) on termination (if set to false you will have to manually delete before destroying) | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of this AWS environment (either Dev, Test, UAT or Prod). Used for naming resources and is prefixed to the cluster\_name | `string` | n/a | yes |
| <a name="input_force_update_version"></a> [force\_update\_version](#input\_force\_update\_version) | Force version update if existing pods are unable to be drained due to a pod disruption budget issue. | `bool` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided. | `list(string)` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The key name that should be used for the instances in the node group | `string` | n/a | yes |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | If creating a new CMK then this variable will define KMS key administrators for this key. A list of IAM user or role ARN(s) is expected. The user or role who is performing the Terraform deployment is provided admin access automatically. Also the role `ADFS_DTIT_Project_Key_Admin` is added as key admin per default. Furthermore the root account user will have full access to the generated key, but without IAM permission delegation to other IAM entities (EnableRootAccessAndPreventPermissionDelegation). | `list(string)` | `[]` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | Alias of an existing Customer Managed Key (CMK) to use for encrypting EBS volumes of EKS worker nodes. If not specified, a new CMK in AWS KMS with attributes of the other variables starting with `kms_` will be created. This variable is exclusive to `kms_key_arn`. However, if both are specified, the key alias will take precedence. | `string` | `""` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of an existing Customer Managed Key (CMK) to use for encrypting EBS volumes of EKS worker nodes. If not specified, a new CMK in AWS KMS with attributes of the other variables starting with `kms_` will be created. This variable is exclusive to `kms_key_alias`. However, if both are specified, `kms_key_alias` will take precedence. | `string` | `""` | no |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | If creating a new CMK then this variable will define the duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days. | `number` | `30` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | If creating a new CMK then this variable will define the description of the key. The description is always prepended with the name of the auto scaling group. | `string` | `"Customer Master Key"` | no |
| <a name="input_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#input\_kms\_key\_enable\_key\_rotation) | If creating a new CMK then this variable will specify whether key rotation is enabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | If creating a new CMK then this variable will define KMS key users for this key. A list of IAM user or role ARN(s) is expected. The user or role who is performing the Terraform deployment is provided user access automatically. Also the service-linked role `AWSServiceRoleForAutoScaling` is added as key user per default. Other AWS IAM users or roles will only have very limited access to resources that are encrypted with this key. | `list(string)` | `[]` | no |
| <a name="input_kubelet_extra_args"></a> [kubelet\_extra\_args](#input\_kubelet\_extra\_args) | This string is passed directly to kubelet if set. Useful for adding labels or taints. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed. | `map(string)` | n/a | yes |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of worker nodes. | `number` | `6` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of worker nodes. | `number` | `0` | no |
| <a name="input_nat_purpose_tag_value"></a> [nat\_purpose\_tag\_value](#input\_nat\_purpose\_tag\_value) | Value to search for the 'Purpose' tag of the NAT EC2 instances. This only needs to be specified if the 'purpose\_tag\_value' variable in infra-ec2-nat module has been customised. | `string` | `"NAT to on-prem"` | no |
| <a name="input_node_group_name_prefix"></a> [node\_group\_name\_prefix](#input\_node\_group\_name\_prefix) | Name prefix of the node group. | `string` | n/a | yes |
| <a name="input_node_group_tags"></a> [node\_group\_tags](#input\_node\_group\_tags) | An optional list of tags to be applied to the Node Group in addition to those specified in the `tags` variable. | `map(string)` | `{}` | no |
| <a name="input_node_group_timeout_create"></a> [node\_group\_timeout\_create](#input\_node\_group\_timeout\_create) | Node Group timeout for create operations | `string` | `"30m"` | no |
| <a name="input_node_group_timeout_delete"></a> [node\_group\_timeout\_delete](#input\_node\_group\_timeout\_delete) | Node Group timeout for delete operations | `string` | `"30m"` | no |
| <a name="input_node_group_timeout_update"></a> [node\_group\_timeout\_update](#input\_node\_group\_timeout\_update) | Node Group timeout for update operations | `string` | `"30m"` | no |
| <a name="input_node_role_arn"></a> [node\_role\_arn](#input\_node\_role\_arn) | IAM Role ARN to be used on nodes. Ensure this is NOT the instance profile ARN. If not specified will construct the default IAM role ARN used by the infra-eks-cluster module. | `string` | `""` | no |
| <a name="input_placement_tenancy"></a> [placement\_tenancy](#input\_placement\_tenancy) | The tenancy of the instance. Valid values are "default" or "dedicated". | `string` | n/a | yes |
| <a name="input_proxy_address"></a> [proxy\_address](#input\_proxy\_address) | (DEPRECATED) Specifying a proxy address will automatically select the proxy\_userdata.sh.tpl userdata script for the worker nodes and configure all relevant services with the proxy as required. | `string` | `""` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Enables/disables a public ip address for a worker | `bool` | n/a | yes |
| <a name="input_root_device_name"></a> [root\_device\_name](#input\_root\_device\_name) | Root device name for workers. If non is provided, will assume default AMI was used. | `string` | `""` | no |
| <a name="input_root_iops"></a> [root\_iops](#input\_root\_iops) | The amount of provisioned IOPS. This must be set with a volume\_type of "io1". | `number` | n/a | yes |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | root volume size of workers instances. | `number` | n/a | yes |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | root volume type of workers instances, can be 'standard', 'gp2', or 'io1' | `string` | n/a | yes |
| <a name="input_service_linked_role_arn"></a> [service\_linked\_role\_arn](#input\_service\_linked\_role\_arn) | (Reserved for future use) Service-linked role ARN to be used by Node Group. This is currently not configurable, leaving this empty will default to 'AWSServiceRoleForAutoScaling'. | `string` | `""` | no |
| <a name="input_sg_ingress_from_port"></a> [sg\_ingress\_from\_port](#input\_sg\_ingress\_from\_port) | Minimum port number from which pods will accept communication. Must be changed to a lower value if some pods in your cluster will expose a port lower than 1025 (e.g. 22, 80, or 443). | `number` | `1025` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnets to launch the EKS Worker Nodes. If not specified then the subnets are found dynamically using the values from the following variables: 'subnets\_include\_cn\_dtag' and 'subnets\_include\_private' | `list(string)` | `[]` | no |
| <a name="input_subnets_include_cn_dtag"></a> [subnets\_include\_cn\_dtag](#input\_subnets\_include\_cn\_dtag) | Whether the EKS Worker Nodes should be launched within the cn-dtag subnets (can also be combined with subnets\_include\_private). Default value is 'false' | `bool` | `false` | no |
| <a name="input_subnets_include_private"></a> [subnets\_include\_private](#input\_subnets\_include\_private) | Whether the EKS Worker Nodes should be launched within the private subnets (can also be combined with subnets\_include\_cn\_dtag). Default value is 'true' | `bool` | `true` | no |
| <a name="input_tag_infosecclass"></a> [tag\_infosecclass](#input\_tag\_infosecclass) | Configures the value for the 'dtit:sec:InfoSecClass' tag. Valid choices are 'Open', 'Internal' or 'Confidential' | `string` | `"Open"` | no |
| <a name="input_tag_networklayer"></a> [tag\_networklayer](#input\_tag\_networklayer) | Configures the value for the 'dtit:sec:NetworkLayer' tag. Valid choices are 'Presentation', 'Application' or 'Database' | `string` | `"Application"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | An optional map of tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | A list of objects with `key`, `value`, and `effect` attributes, for the Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group. | <pre>list(object({<br>    key    = string<br>    value  = string<br>    effect = string<br>  }))</pre> | n/a | yes |
| <a name="input_update_default_version"></a> [update\_default\_version](#input\_update\_default\_version) | Whether to update Default Version for Launch Template on each update | `bool` | n/a | yes |
| <a name="input_use_nat_gw"></a> [use\_nat\_gw](#input\_use\_nat\_gw) | Whether to configure routing for CN-DTAG range to previously created NAT instances. It will search for EC2 instances with the tag 'Purpose=NAT to on-prem' and create a map of AZ to NAT prviate IP to be used by worker nodes routing. | `bool` | `false` | no |
| <a name="input_use_new_cn_dtag_az_a"></a> [use\_new\_cn\_dtag\_az\_a](#input\_use\_new\_cn\_dtag\_az\_a) | Whether to use the new cn-dtag subnet in AZ a. | `bool` | `false` | no |
| <a name="input_use_new_cn_dtag_az_b"></a> [use\_new\_cn\_dtag\_az\_b](#input\_use\_new\_cn\_dtag\_az\_b) | Whether to use the new cn-dtag subnet in AZ b. | `bool` | `false` | no |
| <a name="input_use_new_cn_dtag_az_c"></a> [use\_new\_cn\_dtag\_az\_c](#input\_use\_new\_cn\_dtag\_az\_c) | Whether to use the new cn-dtag subnet in AZ c. | `bool` | `false` | no |
| <a name="input_use_new_cn_dtag_subnets"></a> [use\_new\_cn\_dtag\_subnets](#input\_use\_new\_cn\_dtag\_subnets) | Whether to use all the new cn-dtag subnets across all AZs. | `bool` | `false` | no |
| <a name="input_userdata_file"></a> [userdata\_file](#input\_userdata\_file) | Userdata template file used for the EKS Workers launch configuration. Must include section to interpolate cluster\_name, endpoint, cluster\_auth\_base64, bootstrap\_extra\_args and kubelet\_extra\_args. | `string` | `""` | no |
| <a name="input_userdata_vars"></a> [userdata\_vars](#input\_userdata\_vars) | Allows interpolation of additional variables specified in the custom userdata\_file. Not required if only have default variables of cluster\_name, endpoint, cluster\_auth\_base64, bootstrap\_extra\_args and kubelet\_extra\_args. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The Vpc Id to launch the EKS Worker Nodes. If not specified it will automatically be determined by using the values specified in 'environment' and 'vpc\_type'. | `string` | `""` | no |
| <a name="input_vpc_type"></a> [vpc\_type](#input\_vpc\_type) | Type of the VPC to be used to deploy EKS cluster. Used to find the relevant VPC id and subnets. | `string` | n/a | yes |
| <a name="input_worker_security_group_id"></a> [worker\_security\_group\_id](#input\_worker\_security\_group\_id) | If provided, all workers will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the EKS cluster. | `string` | `""` | no |
| <a name="input_workers_egress_cidr_rules"></a> [workers\_egress\_cidr\_rules](#input\_workers\_egress\_cidr\_rules) | Custom CIDR Egress rules for the workers security group. | <pre>list(object({<br>    description = string<br>    protocol    = string<br>    cidr_blocks = string<br>    from_port   = number<br>    to_port     = number<br>  }))</pre> | n/a | yes |
| <a name="input_workers_ingress_cidr_rules"></a> [workers\_ingress\_cidr\_rules](#input\_workers\_ingress\_cidr\_rules) | Custom CIDR ingress rules for the workers security group. | <pre>list(object({<br>    description = string<br>    protocol    = string<br>    cidr_blocks = string<br>    from_port   = number<br>    to_port     = number<br>  }))</pre> | n/a | yes |
| <a name="input_workers_sg_source_egress_rules"></a> [workers\_sg\_source\_egress\_rules](#input\_workers\_sg\_source\_egress\_rules) | List of egress SG source security group rules. By default the `workers_egress_cidr_rules` variable allows all outbound access so restrict that too if you want more granular policies. | <pre>list(object({<br>    from_port                = number<br>    to_port                  = number<br>    protocol                 = string<br>    source_security_group_id = string<br>    description              = string<br>  }))</pre> | `[]` | no |
| <a name="input_workers_sg_source_ingress_rules"></a> [workers\_sg\_source\_ingress\_rules](#input\_workers\_sg\_source\_ingress\_rules) | List of ingress SG source security group rules. | <pre>list(object({<br>    from_port                = number<br>    to_port                  = number<br>    protocol                 = string<br>    source_security_group_id = string<br>    description              = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | ID of the default worker group AMI. |
| <a name="output_arn"></a> [arn](#output\_arn) | Amazon Resource Name (ARN) of the EKS Node Group. |
| <a name="output_desired_size"></a> [desired\_size](#output\_desired\_size) | Desired worker capacity in the node group. This value is only valid upon node group creation, it will not reflect accurately if using cluster-autoscaler. Only implemented here for initial confirmation. |
| <a name="output_id"></a> [id](#output\_id) | EKS Cluster name and EKS Node Group name separated by a colon (:). |
| <a name="output_kms_key_administrators"></a> [kms\_key\_administrators](#output\_kms\_key\_administrators) | KMS Key administrators |
| <a name="output_kms_key_alias_arn"></a> [kms\_key\_alias\_arn](#output\_kms\_key\_alias\_arn) | KMS Key Alias ARN. This is used by the EKS cluster. |
| <a name="output_kms_key_alias_name"></a> [kms\_key\_alias\_name](#output\_kms\_key\_alias\_name) | KMS Key Alias Name. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | KMS Key ARN. If pre-existing key was provided then subsequent kms\_key\_ outputs will be empty. |
| <a name="output_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#output\_kms\_key\_deletion\_window) | Duration in days after which the key is deleted after destruction of the resource. |
| <a name="output_kms_key_description"></a> [kms\_key\_description](#output\_kms\_key\_description) | Description of CMK key that was created. |
| <a name="output_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#output\_kms\_key\_enable\_key\_rotation) | Specifies whether key rotation is enabled. |
| <a name="output_kms_key_users"></a> [kms\_key\_users](#output\_kms\_key\_users) | KMS Key users |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | Amazon Resource Name (ARN) of the launch template. |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | The ID of the launch template. |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | The latest version of the launch template. |
| <a name="output_launch_template_metadata_option_http_endpoint"></a> [launch\_template\_metadata\_option\_http\_endpoint](#output\_launch\_template\_metadata\_option\_http\_endpoint) | metadata\_options http\_endpoint configuration. |
| <a name="output_launch_template_metadata_option_http_put_response_hop_limit"></a> [launch\_template\_metadata\_option\_http\_put\_response\_hop\_limit](#output\_launch\_template\_metadata\_option\_http\_put\_response\_hop\_limit) | metadata\_options http\_put\_response\_hop\_limit configuration. |
| <a name="output_launch_template_metadata_option_http_tokens"></a> [launch\_template\_metadata\_option\_http\_tokens](#output\_launch\_template\_metadata\_option\_http\_tokens) | metadata\_options http\_tokens configuration. |
| <a name="output_launch_template_tags_all"></a> [launch\_template\_tags\_all](#output\_launch\_template\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
| <a name="output_max_size"></a> [max\_size](#output\_max\_size) | Maximum number of worker nodes. |
| <a name="output_min_size"></a> [min\_size](#output\_min\_size) | Minimum number of worker nodes. |
| <a name="output_nat_az_to_ip_map"></a> [nat\_az\_to\_ip\_map](#output\_nat\_az\_to\_ip\_map) | Map of Availability Zones and relevant NAT instance IPs |
| <a name="output_resources"></a> [resources](#output\_resources) | List of objects containing information about underlying resources. |
| <a name="output_root_block_device_configuration"></a> [root\_block\_device\_configuration](#output\_root\_block\_device\_configuration) | Root block device configuration. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID attached to the EKS workers. |
| <a name="output_service_linked_role_arn"></a> [service\_linked\_role\_arn](#output\_service\_linked\_role\_arn) | Service-Linked Role ARN which the Node Group ASG will use to call other AWS services. |
| <a name="output_status"></a> [status](#output\_status) | Status of the EKS Node Group. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
| <a name="output_workers_asg_subnets"></a> [workers\_asg\_subnets](#output\_workers\_asg\_subnets) | List of subnet Ids that the ASGs are deployed in. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
