#!/bin/bash

aws eks update-kubeconfig --name $1 --kubeconfig kubeconfigfile

kubectl apply -f ${CI_PROJECT_DIR}/test/templates/ingress-tests/ --kubeconfig kubeconfigfile