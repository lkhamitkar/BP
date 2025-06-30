#!/bin/bash

kubectl delete -f ${CI_PROJECT_DIR}/test/templates/ingress-tests/ --kubeconfig kubeconfigfile