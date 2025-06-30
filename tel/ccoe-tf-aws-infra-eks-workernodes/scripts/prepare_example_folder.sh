#!/bin/bash

set -ex

sed -i "s/cluster_name/#cluster_name/" dev.tfvars
sed -i "s/node_group_name_prefix/#node_group_name_prefix/" dev.tfvars
sed -i "s/cluster_name/#cluster_name/" prod.tfvars
sed -i "s/node_group_name_prefix/#node_group_name_prefix/" prod.tfvars
sed -i "s/backend/#backend/" main.tf