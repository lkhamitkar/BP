#!/bin/bash

export CI_PROJECT_DIR=$(pwd)
export TEST_FOLDER=test
export GITLAB_CI_SCRIPTS=scripts
export environment=dev

echo "Executing Terraform Eks cluster unit test"
if [ -f terraform.tfstate ]; then
    echo "Cluster already deployed, will backup the tfstate file."
    cp terraform.tfstate terraform.tfstate.script.backup
fi;

if [ ! -d ${CI_PROJECT_DIR}/${TEST_FOLDER}/eks_cluster ]; then
    echo "Cloning EKS Cluster Repo"
    cd ${CI_PROJECT_DIR}/${TEST_FOLDER}
    ${CI_PROJECT_DIR}/${GITLAB_CI_SCRIPTS}/eks_clone_and_validate.sh
else
    echo "Skipping cloning of EKS cluster."
fi;

if [ ! -d ${CI_PROJECT_DIR}/${TEST_FOLDER}/ec2_nat ]; then
    echo "Cloning EC2 Nat Repo"
    cd ${CI_PROJECT_DIR}/${TEST_FOLDER}
    ${CI_PROJECT_DIR}/${GITLAB_CI_SCRIPTS}/ec2_nat_clone_and_validate.sh
else
    echo "Skipping cloning of EC2 Nat instances."
fi;

echo "Executing Terraform Eks Workernodes unit test"
cd ${CI_PROJECT_DIR}/${TEST_FOLDER}

export SKIP_cleanup_eks_cluster=true
export SKIP_cleanup_ec2_nat=true
export SKIP_cleanup_worker_nodes1=true
export SKIP_cleanup_ingress_resources=true

go test -v -timeout 70m -run TestTerraformAwsInfraEksWorkerNodesBase