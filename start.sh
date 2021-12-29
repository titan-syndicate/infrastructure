#!/bin/bash

# stop on failure
set -e

# TODO: pull secrets to 1Password

# TODO: start minikube
# export KUBECONFIG=~/.kube/minikube_config
# minikube start

# deploy k8s cluster
export KUBECONFIG=~/.kube/lke_config
terraform apply --var-file=secrets.tfvars -auto-approve

CLUSTER_ID=$(linode-cli lke clusters-list --json | jq -r '.[0].id')

linode-cli --json lke kubeconfig-view $CLUSTER_ID | jq -r '.[].kubeconfig | @base64d' > ~/.kube/lke_config
#
# kubectl apply -f ./
# kubectl apply -k ./
# kubectl apply -f argocd-namespace.yaml
# kubectl apply -f argocd-crd.yaml