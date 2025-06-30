#!/bin/bash
echo "Cloning latest EC2 nat code"
EC2_FOLDER=ec2_nat
REPO=ccoe-tf-aws-infra-ec2-nat

if [ -d ${REPO} ]; then
    echo "${REPO} Folder exists, deleting..."
    rm -rf ${REPO}
fi;


git clone --depth 1 https://gitlab+deploy-token-349:8utN1gzssGwNh6tax3f-@gitlab.devops.telekom.de/ccoe/teams/evangelists/library/${REPO}.git

if [ -d ${EC2_FOLDER} ]; then
    echo "${EC2_FOLDER} exists, copying rather than creating."
    cp -R ${REPO}/examples/* ${EC2_FOLDER}
else
    echo "${EC2_FOLDER} created."
    mv  ${REPO}/examples ${EC2_FOLDER}
fi;

cd ${EC2_FOLDER}
echo "Commenting out required fields"
sed -i "/instance_name /s/instance_name/#instance_name/" dev.tfvars
sed -i "/instance_name /s/instance_name/#instance_name/" prod.tfvars

if [ -z ${EC2_NAT_BACKEND_CONFIG_PATH+x} ]; then
    echo "EC2_NAT_BACKEND_CONFIG_PATH not set. Commenting out some more fields"
    sed -i '/ backend /s/backend/#backend/' main.tf
    terraform init
else
    echo "EC2_NAT_BACKEND_CONFIG_PATH set. Validating EKS cluster"
    terraform init --backend-config=$EC2_NAT_BACKEND_CONFIG_PATH
fi
echo "Content of NAT dev.tfvars is:"
cat dev.tfvars

# echo "Remove prevent destroy"
sed -i '/ prevent_destroy /s/true/false/' .terraform/modules/nat.nat_az1/main.tf
sed -i '/ prevent_destroy /s/true/false/' .terraform/modules/nat.nat_az2/main.tf
sed -i '/ prevent_destroy /s/true/false/' .terraform/modules/nat.nat_az3/main.tf
echo "Validating NAT Node Test"
terraform validate