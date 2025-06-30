#!/bin/bash
echo "Cloning latest EKS cluster code"
EKS_FOLDER=eks_cluster
REPO=ccoe-tf-aws-infra-eks-cluster

CLUSTER_NAME=$(echo "${CI_COMMIT_REF_SLUG}" | cut -d '-' -f2-3)
DEV_CLUSTER_NAME="wn-${CLUSTER_NAME}"

if [ -d ${REPO} ]; then
    echo "${REPO} Folder exists, deleting..."
    rm -rf ${REPO}
fi;

git clone --depth 1 https://gitlab+deploy-token-347:oNKnFJyZC8bxgWx3eSMJ@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/${REPO}.git

if [ -d ${EKS_FOLDER} ]; then
    echo "${EKS_FOLDER} exists, copying rather than creating."
    cp -R ${REPO}/examples/single_cluster/* ${EKS_FOLDER}
else
    echo "${EKS_FOLDER} created."
    mv  ${REPO}/examples/single_cluster ${EKS_FOLDER}
fi;

cd ${EKS_FOLDER}
echo "Commenting out required fields"
sed -i '/write_kubeconfig /s/false/true/' dev.tfvars
sed -i '/cluster_name /s/cluster_name/#cluster_name/' dev.tfvars
sed -i '/write_kubeconfig /s/false/true/' prod.tfvars
sed -i '/cluster_name /s/cluster_name/#cluster_name/' prod.tfvars

if [ -z ${EKS_CLUSTER_BACKEND_CONFIG_PATH+x} ]; then
    echo "EKS_CLUSTER_BACKEND_CONFIG_PATH not set. Commenting out some more fields"
    sed -i '/ backend /s/backend/#backend/' main.tf
    sed -i '/write_kubeconfig /s/false/true/' dev.tfvars
    terraform init
else
    echo "EKS_CLUSTER_BACKEND_CONFIG_PATH set. Validating EKS cluster"
    terraform init --backend-config=$EKS_CLUSTER_BACKEND_CONFIG_PATH
    echo "Content of EKS Cluster dev.tfvars is:"
    cat dev.tfvars
fi
terraform validate