#!/bin/bash
set -e

helm repo add teleport https://charts.releases.teleport.dev

helm install teleport-cluster teleport/teleport-cluster --create-namespace --namespace=teleport-cluster \
  --set clusterName='teleport.burritops.com' --set acme=true --set acmeEmail='rianf@me.com'
helm upgrade teleport-cluster teleport/teleport-cluster --create-namespace --namespace=teleport-cluster \
  --set clusterName='teleport.burritops.com' --set acme=true --set acmeEmail='rianf@me.com'

kubectl config set-context --current --namespace=teleport-cluster

kubectl get services
MYIP=$(kubectl get services teleport-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $MYIP

curl https://teleport.burritops.com/webapi/ping

# Add role
# POD=$(kubectl get pod -l app=teleport-cluster -o jsonpath='{.items[0].metadata.name}')
# kubectl exec -i ${POD?} -- tctl create -f < member.yaml
# kubectl exec -ti ${POD?} -- tctl  users add alice --roles=member

POD=$(kubectl get pod -l app=teleport-cluster -o jsonpath='{.items[0].metadata.name}')
kubectl exec -i teleport-cluster-67f7586bb4-m89fc -- tctl create -f < member.yaml
kubectl exec -ti teleport-cluster-67f7586bb4-m89fc -- tctl  users add alice --roles=member

# Install CLIs


curl -L -O https://get.gravitational.com/teleport-v8.3.0-linux-amd64-bin.tar.gz
tar -xzf teleport-v8.3.0-linux-amd64-bin.tar.gz
sudo mv teleport/tsh /usr/local/bin/tsh
sudo mv teleport/tctl /usr/local/bin/tctl

# test login
KUBECONFIG=./teleport.yaml tsh login --proxy=teleport.burritiops.com:443 --user=alice

# run admin tool from pod
kubectl config set-context --current --namespace=teleport-cluster
POD=$(kubectl get po -l app=teleport-cluster -o jsonpath='{.items[0].metadata.name}')
kubectl exec -i teleport-cluster-67f7586bb4-m89fc -- tctl create -f < github.yaml
# kubectl exec -i ${POD?} -- tctl create -f < github.yaml


# deploy kubernetes dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml

# Configure teleport to work with dashboard
kubernetes-dashboard.kubernetes-dashboard.svc.cluster.local


app_service:
    enabled: yes
    # Teleport provides a small debug app that can be used to make sure application
    # access is working correctly. It'll output JWTs so it can be useful
    # when extending your application.
    debug_app: false
    # This section contains definitions of all applications proxied by this
    # service. It can contain multiple items.
    apps:
      # Name of the application. Used for identification purposes.
    - name: "grafana"
      # URI and port the application is available at.
      uri: "http://kubernetes-dashboard.kubernetes-dashboard.svc.cluster.local"
      # Optional application public address to override.
      # public_addr: "dashboard.teleport.example.com"
      # Optional static labels to assign to the app. Used in RBAC.
      # labels:
      #  env: "prod"
      # Optional dynamic labels to assign to the app. Used in RBAC.
      # commands:
      # - name: "os"
      #   command: ["/usr/bin/uname"]
      #   period: "5s"


# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  teleport.yaml: |
    teleport:
      log:
        severity: INFO
        output: stderr
        format:
          output: text
          extra_fields: ["timestamp","level","component","caller"]
    auth_service:
      enabled: true
      cluster_name: teleport.burritops.com
      authentication:
        type: local
    kubernetes_service:
      enabled: true
      listen_addr: 0.0.0.0:3027
      kube_cluster_name: teleport.burritops.com
    proxy_service:
      public_addr: 'teleport.burritops.com:443'
      kube_listen_addr: 0.0.0.0:3026
      mysql_listen_addr: 0.0.0.0:3036
      enabled: true
      acme:
        enabled: true
        email: rianf@me.com
    ssh_service:
      enabled: false
    app_service:
      enabled: yes
      # Teleport provides a small debug app that can be used to make sure application
      # access is working correctly. It'll output JWTs so it can be useful
      # when extending your application.
      debug_app: true
      # This section contains definitions of all applications proxied by this
      # service. It can contain multiple items.
      apps:
        # Name of the application. Used for identification purposes.
      - name: "dashboard"
        # URI and port the application is available at.
        uri: "https://kubernetes-dashboard.kubernetes-dashboard.svc.cluster.local:443"
        # Optional application public address to override.
        # public_addr: "dashboard.teleport.example.com"
        # Optional static labels to assign to the app. Used in RBAC.
        # labels:
        #  env: "prod"
        # Optional dynamic labels to assign to the app. Used in RBAC.
        # commands:
        # - name: "os"
        #   command: ["/usr/bin/uname"]
        #   period: "5s"
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: teleport-cluster
    meta.helm.sh/release-namespace: teleport-cluster
  creationTimestamp: "2022-02-20T20:08:23Z"
  labels:
    app.kubernetes.io/managed-by: Helm
  name: teleport-cluster
  namespace: teleport-cluster
  resourceVersion: "3139"
  uid: b84298b7-ba40-4f02-af79-192fe19ea92c

  # install argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml