#!/bin/bash -xe

#Set the proxy hostname and port

PROXY="${proxy_address}"
MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac/)
VPC_CIDR=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-ipv4-cidr-blocks | xargs | tr ' ' ',')

#Create the docker systemd directory
mkdir -p /etc/systemd/system/docker.service.d

#Configure yum to use the proxy
cloud-init-per instance yum_proxy_config cat << EOF >> /etc/yum.conf

proxy=http://$PROXY

EOF

#Set the proxy for future processes, and use as an include file
cloud-init-per instance proxy_config cat << EOF >> /etc/environment

http_proxy=http://$PROXY
https_proxy=http://$PROXY
HTTP_PROXY=http://$PROXY
HTTPS_PROXY=http://$PROXY

no_proxy=$VPC_CIDR,localhost,127.0.0.1,10.0.0.0/8,172.20.0.0/12,192.168.0.0/16,10.91.48.0/20,100.64.0.0/16,10.175.0.0/17,169.254.169.254,169.254.170.2,.internal,.eu-central-1.eks.amazonaws.com

NO_PROXY=$VPC_CIDR,localhost,127.0.0.1,10.0.0.0/8,172.20.0.0/12,192.168.0.0/16,10.91.48.0/20,100.64.0.0/16,10.175.0.0/17,169.254.169.254,169.254.170.2,.internal,.eu-central-1.eks.amazonaws.com

EOF


#Configure docker with the proxy
cloud-init-per instance docker_proxy_config tee <<EOF /etc/systemd/system/docker.service.d/proxy.conf >/dev/null

[Service]

EnvironmentFile=/etc/environment

EOF

#Configure the kubelet with the proxy
cloud-init-per instance kubelet_proxy_config tee <<EOF /etc/systemd/system/kubelet.service.d/proxy.conf >/dev/null

[Service]

EnvironmentFile=/etc/environment

EOF

#Reload daemon and restart docker to reflect proxy configuration at launch of instance
cloud-init-per instance reload_daemon systemctl daemon-reload 
cloud-init-per instance enable_docker systemctl enable --now --no-block docker
cloud-init-per instance restart_docker systemctl restart docker

set -o xtrace

#Set the proxy variables before running the bootstrap.sh script
set -a
source /etc/environment

#ECR login to be able to download default images
aws ecr get-login --region eu-central-1 --registry-ids 602401143452 --no-include-email | /bin/bash

#If specified then configure CN-DTAG NAT
${az_to_natgw}

# Bootstrap and join the cluster
sudo /etc/eks/bootstrap.sh --b64-cluster-ca '${cluster_auth_base64}' --apiserver-endpoint '${endpoint}' ${bootstrap_extra_args} --kubelet-extra-args "${kubelet_extra_args}" '${cluster_name}'