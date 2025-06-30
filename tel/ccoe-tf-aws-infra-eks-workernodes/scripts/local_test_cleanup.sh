#!/bin/bash
set -e

export CI_PROJECT_DIR=$(pwd)
export TEST_FOLDER=test
export GITLAB_CI_SCRIPTS=scripts
export environment=dev

if [ ! -d ${CI_PROJECT_DIR}/${TEST_FOLDER}/eks_cluster ]; then
    echo "EKS Cluster folder not there, this won't work!"
    exit 1
fi;

if [ ! -d ${CI_PROJECT_DIR}/${TEST_FOLDER}/ec2_nat ]; then
    echo "EC2 NAT folder not there, this won't work!"
    exit 1
fi;

echo "Unsetting all SKIP env vars"
unset "${!SKIP@}"

echo "Setting required SKIP_ env vars"
# Skip creation of resources
export SKIP_eks_cluster=true
export SKIP_ec2_nat=true
export SKIP_worker_nodes1=true
export SKIP_test_nat_stack_config=true
export SKIP_test_subnet_definition=true
export SKIP_test_nat_ip_map=true
export SKIP_test_subnets=true
export SKIP_test_subnet_definition=true
export SKIP_test_kubernetes_cluster=true
export SKIP_test_ingress_resource=true

echo "Deleting resources"
cd ${CI_PROJECT_DIR}/${TEST_FOLDER}
go test -v -timeout 70m -run TestTerraformAwsInfraEksWorkerNodesBase

echo "Removing copied files"

rm ${CI_PROJECT_DIR}/dev.tfvars
rm -rf ${CI_PROJECT_DIR}/${TEST_FOLDER}/eks_cluster
rm -rf ${CI_PROJECT_DIR}/${TEST_FOLDER}/ec2_nat