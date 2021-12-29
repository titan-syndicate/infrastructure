#!/bin/bash
# stop on failure
# export KUBECONFIG=$minikube_config
# minikube stop

export KUBECONFIG=$lke_config
kubectl delete all --all
terraform destroy --var-file=secrets.tfvars -auto-approve

rm ~/.kube/minikube_config
rm ~/.kube/lke_config

# TODO: add script to delete block storage