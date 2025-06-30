#!/bin/bash -xe

#ECR login to be able to download default images
aws ecr get-login --region eu-central-1 --registry-ids 602401143452 --no-include-email | /bin/bash

# Bootstrap and join the cluster
sudo /etc/eks/bootstrap.sh --b64-cluster-ca '${cluster_auth_base64}' --apiserver-endpoint '${endpoint}' ${bootstrap_extra_args} --kubelet-extra-args "${kubelet_extra_args}" '${cluster_name}'