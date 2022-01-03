#!/bin/bash
#
# A script to update your /etc/hosts file from minikube ingest records
#
# Installation
# ------------
# curl -L https://gist.github.com/jacobtomlinson/4b835d807ebcea73c6c8f602613803d4/raw/minikube-update-hosts.sh > /usr/local/bin/minikube-update-hosts
# chmod +x /usr/local/bin/minikube-update-hosts

set -e

INGRESSES=$(kubectl --context=minikube --all-namespaces=true get ingress -o jsonpath='{.items[*].spec.rules[*].host}')

# MINIKUBE_IP=$(minikube ip)
MINIKUBE_IP="127.0.0.1"

HOSTS_ENTRY="$MINIKUBE_IP $INGRESSES"

if grep -Fq "$MINIKUBE_IP" /etc/hosts > /dev/null
then
    sudo sed -i '' "s/^$MINIKUBE_IP.*/$HOSTS_ENTRY/" /etc/hosts
    echo "Updated hosts entry"
else
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
    echo "Added hosts entry"
fi