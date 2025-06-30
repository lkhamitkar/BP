# Changelog

All notable changes to this project will be documented in this file.

## v2.0.5 - (August 13, 2021)

### Added

- [gitlab ci] Output testing for metadata access

## v2.0.4 - (August 11, 2021)

### Added

- Added variable `allow_instance_metadata_access` to control access to workers EC2 instance metadata.

## v2.0.3 - (August 4, 2021)

### Added

- Added variable `kms_key_alias` and improved `kms_*` variables description.
- Updated to ccoe-tf-aws-res-ecs-service-task module v0.1.23 which disables IAM permission delegation to other IAM entities (EnableRootAccessAndPreventPermissionDelegation) when creating a new KMS CMK.

## v2.0.2 - (August 2, 2021)

### Added

- Node group tags to launch template

## v2.0.1 - (July 26, 2021)

### Fixed

- Incorrect discovery of default worker node role ARN

## v2.0.0 - (July 19, 2021)

This major version changes the solution from having used a self-managed node group, to now using a **managed** node group. This is **NOT AN IN-PLACE UPDATE**, to use this version please create a new node group Terraform composition and then delete your old node group composition, instead of attempting to update your current nodes. Managed node group adds a number of additional benefits, just to highlight a few:

- Easily use _SPOT_ instances.
- Managed node draining from cluster when scalling in or replacing nodes.
- Automatic rollout of nodes upon updating.

The [following documentation](UPDATE.md#updating-to-v200) provides high level instructions on how to achieve this.

### Added

- Spot Instance example

### Changed

- Now using managed node groups instead of self-managed ASGs
- [gitlab ci] A myriad of major changes across the automated pipelines tests

## v1.0.0 - (April 15, 2021)

### Breaking Changes

This version has two major modifications. Updating to minimum Terraform version of 0.14.9 and AWS provider major version 3. In order for your existing deployments to utilise this upgrade there are some key steps to be performed across all your environments and Terraform deployments. Please review the [Upgrade Terraform to v0.14+](https://gitlab.devops.telekom.de/ccoe/teams/evangelists/examples/ccoe-tf-aws-examples#upgrade-terraform-to-v014).

### Changed

- Using latest v3.x.x version of the AWS Provider
- Terraform upgraded to v0.14.9 as minimum
- All other providers updated to latest version

## v0.3.5 (March 31, 2021)

### Added

- [Gitlab CI] Automated tests for AWS Ingress Controller
- [README] Destroy section to the documentation

## v0.3.4 (March 19, 2021)

### Fixed

- ASG Launch Template now correctly updates the default version to be the latest version

### Changed

- Updated README with improved documentation

## v0.3.3 (March 18, 2021)

### Changed

- Interpolate pipeline image tag usage in preparation for Terraform and AWS provider upgrade

## v0.3.2 (March 9, 2021)

### Fixed

- URL of Pipeline scripts to reference devops gitlab CICD instead of Codeshare
- Limiting AZ usage now correctly finds the relevant NAT ENIs

## v0.3.1 (March 4, 2021)

### Fixed

- Passing of variable `worker_security_group_id` to resource module

## v0.3.0 (February 19, 2021)

### Added

- Allow possibility to set tags for the ASG

## v0.2.9 (February 18, 2021)

### Added

- Minor fixes after Migration to Magenta CI/CD

## v0.2.8 (November 23, 2020)

### Added

- `use_new_cn_dtag_subnet` variable for new subnet usage

### Changed

- [Test] Improved GitLab CI workflow and pipelines
- Update DevSecOps hardened image usage
- Remove proxy config usage

## v0.2.7 - (September 14, 2020)

### Added

- Added Security section to README

### Changed

- KMS key rotation enabled by default

## v0.2.6 - (August 17, 2020)

### Changed

- Use pesimistic operator on minor version instead of patch version for TF AWS provider

## v0.2.5 - (August 12, 2020)

### Fixed

- Terraform provider version pinning

## v0.2.4 - (July 13, 2020)

### Added

- Added test, ref and staging environment VPC and subnet discovery
- [test] Added test for ALB Ingress controller pods

### Changed

- Remove proxy configuration as default setting.

## v0.2.3 - (July 3, 2020)

### Changed

- Default AMI to latest DevSecOps provided hardened image.

## v0.2.2 - (July 2, 2020)

### Added

- Added variable `ami_owners` to be able to provide custom account id list to aws_ami data call for EBS encryption

### Changed

- Default AMI now uses DevSecOps provided hardened image for EKS Worker Nodes

### Fixed

- KMS admin and users output now display the entire list of users instead of the first entry in the list.

## v0.2.1 - (June 26, 2020)

### Changed

- Fixed incorrect descriotion for `kms_key_arn` and added link for existing CMK requirements.

## v0.2.0 - (June 22, 2020)

### Breaking Changes

- Added default creation and encryption using AWS KMS Customer Managed Keys. Relevant variables are optional and prefixed with `kms_key_`.
- All EBS volumes are encrypted using the created CMK

### Updating to v0.2.0

- This version requires key steps to update existing worker nodes. Please follow the steps documented in the [UPDATE](UPDATE.md) file.

### Added

- Missing outputs for worker nodes

## v0.1.20 - (June 12, 2020)

### Added

- The following variables which configure corresponding tags to ensure they match the minimum required for DTIT:
  - `InfoSecClass` configures `dtit:sec:InfoSecClass`
  - `NetworkLayer` configures `dtit:sec:NetworkLayer`

## v0.1.19 - (June 8, 2020)

### Changed

- Scripted GitLab CI pipeline configuration for cloning EKS cluster and NAT instance pre-requisites.
- Added master branch for tagging repository revisions.

## v0.1.18 - (June 5, 2020)

### Fixed

- Set the correct default values for `subnets_include_cn_dtag` and `subnets_include_private` variables.

## v0.1.17 - (June 4, 2020)

### Fixed

- [Testing] Now removes the "kubernetes.io/cluster/<cluster_id>=shared" tag

## v0.1.16 - (June 2, 2020)

### Changed

- Removed commented s3 backend config in example code

## v0.1.15 - (June 2, 2020)

### Added

- GitLab CI yaml file and instruction usage

## v0.1.14 - (May 28, 2020)

### Changed

- Improved Gitlab CI Workflow
- Use latest dev proxy

## v0.1.13 - (May 15, 2020)

### Add

- Auto-discover NAT use SG if nat gw has been specified

## v0.1.11 - (May 5, 2020)

### Add

- Add cn-dtag NAT GW Usage