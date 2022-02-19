#!/bin/bash
set -e

while getopts k:u:g:c:t: option
do
case "${option}"
in
k) K8S_DB_SECRET=${OPTARG};;
u) UNISON_KEYSTORE_PASSWORD=${OPTARG};;
c) GITHUB_OAUTH_CLIENT_ID=${OPTARG};;
g) GITHUB_SECRET_ID=${OPTARG};;
t) ORG_TEAM=${OPTARG};;
esac
done

if [[ -z "$K8S_DB_SECRET" ]]; then
    echo "Must provide K8S_DB_SECRET -k in environment" 1>&2
    exit 1
fi

if [[ -z "$UNISON_KEYSTORE_PASSWORD" ]]; then
    echo "Must provide UNISON_KEYSTORE_PASSWORD -u in environment" 1>&2
    exit 1
fi

if [[ -z "$GITHUB_OAUTH_CLIENT_ID" ]]; then
    echo "Must provide GITHUB_OAUTH_CLIENT_ID -c in environment" 1>&2
    exit 1
fi

if [[ -z "$GITHUB_SECRET_ID" ]]; then
    echo "Must provide GITHUB_SECRET_ID -g in environment" 1>&2
    exit 1
fi

if [[ -z "$ORG_TEAM" ]]; then
    echo "Must provide ORG_TEAM -t in environment" 1>&2
    exit 1
fi

# install k3s without Traefik
# https://www.suse.com/support/kb/doc/?id=000020082
# https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/#customized-flags
echo "Installing and starting k3s without Traefik"
curl -L https://get.k3s.io | bash -s -- --disable traefik

# copy kubeconfig from k3s
echo "Copying kubeconfig from k3s"
homedir=`echo $(cd "$(dirname ~)"; pwd)/$(basename ~)`
mkdir -p $homedir/.kube
sudo sh -c "cp /etc/rancher/k3s/k3s.yaml $homedir/.kube/config \
&& chown $USER $homedir/.kube/config \
&& chmod 600 $homedir/.kube/config \
&& export KUBECONFIG=$homedir/.kube/config"

echo "Adding tremolo to helm repos"
helm repo add tremolo https://nexus.tremolo.io/repository/helm/
helm repo update

# install ingress-nginx
echo "Deploying ingress-nginx to cluster"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --wait

# install kubernetes-dashboard
echo "Installing kubernetes-dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml

# install openunison
echo "Installing openunison operator"
helm upgrade --install openunison tremolo/openunison-operator \
--namespace openunison \
--create-namespace \
--wait

echo "Deploying openunison secret"
# kubectl apply -f ./openunison_secret.yaml
kubectl apply -f - <<EOF
apiVersion: v1
type: Opaque
metadata:
  name: orchestra-secrets-source
  namespace: openunison
data:
  K8S_DB_SECRET: $K8S_DB_SECRET
  unisonKeystorePassword: $K8S_DB_SECRET
  GITHUB_SECRET_ID: $GITHUB_SECRET_ID
kind: Secret
EOF

echo "Deploying ClusterRoleBinding"
kubectl apply -f - <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: github-cluster-admins
subjects:
- kind: Group
  name: $ORG_TEAM
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# query loadbalancer ip from nginx service
# transform ip nip.io format e.g. 192.168.0.1 becomes 192-168-0-1
lbip=`kubectl get service -n ingress-nginx ingress-nginx-controller -o json \
| jq -r '.status.loadBalancer.ingress[0].ip' \
| sed -e 's/\./-/g'`

openunisonValues=$(cat <<-END
network:
  openunison_host: "k8sou.$lbip.nip.io"
  dashboard_host: "k8sdb.$lbip.nip.io"
  api_server_host: "k8sapi.$lbip.nip.io"
  session_inactivity_timeout_seconds: 900
  k8s_url: https://127.0.0.1:6443
  force_redirect_to_tls: false
  createIngressCertificate: true
  ingress_type: nginx
  ingress_annotations:
    kubernetes.io/ingress.class: nginx

cert_template:
  ou: "Kubernetes"
  o: "MyOrg"
  l: "My Cluster"
  st: "State of Cluster"
  c: "MyCountry"


image: docker.io/tremolosecurity/openunison-k8s
myvd_config_path: "WEB-INF/myvd.conf"
k8s_cluster_name: kubernetes
enable_impersonation: false

impersonation:
  use_jetstack: true
  jetstack_oidc_proxy_image: docker.io/tremolosecurity/kube-oidc-proxy:latest
  explicit_certificate_trust: true

dashboard:
  namespace: "kubernetes-dashboard"
  cert_name: "kubernetes-dashboard-certs"
  label: "k8s-app=kubernetes-dashboard"
  service_name: kubernetes-dashboard
certs:
  use_k8s_cm: false

trusted_certs:
  - name: ldaps
    pem_b64: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURORENDQWh5Z0F3SUJBZ0lRYlJOajZSS3F0cVZQdlc2NXFaeFhYakFOQmdrcWhraUc5dzBCQVFVRkFEQWkKTVNBd0hnWURWUVFEREJkQlJFWlRMa1ZPVkRKTE1USXVSRTlOUVVsT0xrTlBUVEFlRncweE5EQXpNamd3TVRBMQpNek5hRncweU5EQXpNalV3TVRBMU16TmFNQ0l4SURBZUJnTlZCQU1NRjBGRVJsTXVSVTVVTWtzeE1pNUVUMDFCClNVNHVRMDlOTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEyczlKa2VOQUhPa1EKMVFZSmdqZWZVd2Nhb2dFTWNhVy9rb0ErYnU5eGJyNHJIeS8yZ04va2M4T2tvUHV3Si9uTmxPSU8rcytNYm5YUwpMOW1VVEM0T0s3dHJrRWppS1hCK0QrVlNZeTZpbVhoNnpwQnROYmVaeXgrcmRCbmFPdjNCeVpSbm5FQjhMbWhNCnZIQSs0Zi90OWZ4LzJ2dDZ3UHgvL1ZnSXE5eXVZWVVRUkxtMVdqeVVCRnJaZUdvU3BQbTBLZXdtK0IwYmhtTWIKZHlDKzNmaGFLQytVazFOUG9kRTI5NzNqTEJaSmVsWnhzWlk0MFd3OHpZUXdkR1lJYlhxb1RjKzFhL3g0ZjFFbgptNEFOcWdnSHR3K05xOHpoc3MzeVR0WStVWUtEUkJJTGRMVlpRaEhKRXhlMGtBZWlzZ014SS9iQndPMUhickZWCit6U25rK252Z1FJREFRQUJvMll3WkRBekJnTlZIU1VFTERBcUJnZ3JCZ0VGQlFjREFRWUlLd1lCQlFVSEF3SUcKQ2lzR0FRUUJnamNVQWdJR0NDc0dBUVVGQndNRE1CMEdBMVVkRGdRV0JCVHlKVWZZNjZ6WWJtOWkweGVZSHVGSQo0TU43dURBT0JnTlZIUThCQWY4RUJBTUNCU0F3RFFZSktvWklodmNOQVFFRkJRQURnZ0VCQU01a3o5T0tOU3VYCjh3NE5PZ25mSUZkYXpkMG5QbElVYnZEVmZRb055OVEwUzFTRlVWTWVrSVBOaVZoZkd6eWE5SXdSdEdiMVZhQlEKQVEyT1JJekhyOEEycjVVTkx4M21GanBKbWVPeFF3bFYwWCtnOHMrMjUzS1ZGeE9wUkU2eXlhZ24vQnh4cHRUTAphMVo0cWVRSkxENDJsZDFxR2xSd0Z0VlJtVkZaelZYVnJwdTdOdUZkM3Zsbm5PL3FLV1hVK3VNc2ZYdHNsMTNuCmVjMWt3MUV3cTJqbks4V0ltS1RRNy85V2JhSVkwZ3g4bW93Q0pTT3NScTBURTd6Sy9ONTVkck4xd1hKVnhXZTUKNE4zMmVDcW90WHk5ajlsemRrTmE3YXdiOXEzOG5XVnhQK3ZhNWpxTklEbGxqQjZ0RXh5NW4zczd0NktLNmc1agpUWmdWcXJaMyttcz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQoK

monitoring:
  prometheus_service_account: system:serviceaccount:monitoring:prometheus-k8s

github:
 client_id: $GITHUB_OAUTH_CLIENT_ID
 teams: titan-syndicate/red-team

network_policies:
  enabled: false
  ingress:
    enabled: true
    # labels:
    #   app.kubernetes.io/name: ingress-nginx
  monitoring:
    enabled: true
    labels:
      app.kubernetes.io/name: monitoring
  apiserver:
    enabled: false
    labels:
      app.kubernetes.io/name: kube-system

services:
  enable_tokenrequest: false
  token_request_audience: api
  token_request_expiration_seconds: 600
  node_selectors: []

openunison:
  replicas: 1
  non_secret_data:
    K8S_DB_SSO: oidc
    PROMETHEUS_SERVICE_ACCOUNT: system:serviceaccount:monitoring:prometheus-k8s
    SHOW_PORTAL_ORGS: "false"
  secrets: []
  html:
    image: docker.io/tremolosecurity/openunison-k8s-html
  enable_provisioning: false
END
)

# install orchestra
echo "Installing orchestra"
helm upgrade --install orchestra tremolo/orchestra \
--namespace openunison \
--wait \
-f <(echo "$openunisonValues")

echo "Configuring and restarting kube-apiserver"
# configuration file: https://rancher.com/docs/k3s/latest/en/installation/install-options/#configuration-file
# https://rancher.com/docs/k3s/latest/en/upgrades/basic/#restarting-k3s

# Cert fiddling
cert=`kubectl get secret ou-tls-certificate -n openunison -o json \
| jq -r '.data["tls.crt"]' \
| base64 -d`

sudo sh -c "mkdir -p /etc/kubernetes/pki \
&& echo '$cert' > /etc/kubernetes/pki/ou-ca.pem"

# create kube-apiserver config
sudo sh -c "mkdir -p /etc/rancher/k3s \
&& cat > /etc/rancher/k3s/config.yaml <<END
kube-apiserver-arg:
  - \"oidc-issuer-url=https://k8sou.$lbip.nip.io/auth/idp/k8sIdp\"
  - \"oidc-client-id=kubernetes\"
  - \"oidc-username-claim=sub\"
  - \"oidc-groups-claim=groups\"
  - \"oidc-ca-file=/etc/kubernetes/pki/ou-ca.pem\"
END
"

# restart kube-apiserver to use new config
systemctl restart k3s

# install orchestra
echo "Installing orchestra-login-portal"
helm upgrade --install orchestra-login-portal tremolo/orchestra-login-portal \
--namespace openunison \
--wait \
-f <(echo "$openunisonValues")

echo "All done!"
echo "Visit http://k8sou.$lbip.nip.io"