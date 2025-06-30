#!/bin/bash
CLUSTER_PATH=$1

if [ "$environment" == "dev" ]; then
    sed -i '/# subnet_ids/s/# subnet_ids = \[\]/subnet_ids = \["subnet-01e02664935a35ff9","subnet-093b57c7b4711c892","subnet-09ffd575c82056788"\]/' ${CLUSTER_PATH}/dev.tfvars
else
    sed -i '/# subnet_ids/s/# subnet_ids = \[\]/subnet_ids = \["subnet-05154d8f27b4716a7","subnet-05e066724acf03f0c","subnet-0bce7680f3e13857a"\]/' ${CLUSTER_PATH}/${environment}.tfvars
fi;

# sed -i '/use_new_cn_dtag_subnet/s/false/false/' ${CLUSTER_PATH}/${environment}.tfvars
# sed -i '/subnets_include_cn_dtag/s/false/false/' ${CLUSTER_PATH}/${environment}.tfvars
sed -i '/subnets_include_private/s/true/false/' ${CLUSTER_PATH}/${environment}.tfvars
