#!/bin/bash
set -e

# check sudo
if [[ "$EUID" = 0 ]]; then
    echo "(1) already root"
else
    sudo -k # make sure to ask for password on next sudo
    if sudo true; then
        echo "(2) correct password"
    else
        echo "(3) wrong password"
        exit 1
    fi
fi

mkdir /tmp/burritops-install

cd /tmp/burritops-install

# install homebrew
echo "Installing homebrew"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Creating Brewfile"
cat > ./Brewfile <<EOF
# Brewfile

# install Helm
brew "helm"

# install jq
brew "jq"

# install k9s
brew "k9s"

# install asdf
brew "asdf"

# kubectx
brew "kubectx"

# kubecolor
brew "hidetatz/tap/kubecolor"

EOF

# Run brew bundle
echo "Run brew bundle"
brew bundle

# install k3s without Traefik
# https://www.suse.com/support/kb/doc/?id=000020082
# https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/#customized-flags
# https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/#customized-flags
echo "Installing and starting k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy traefik" sh -s -

./k3s.sh --no-deploy traefik \
--kube-apiserver-arg="oidc-issuer-url=https://k8sou.192-168-1-17.nip.io/auth/idp/k8sIdp" \
--kube-apiserver-arg="oidc-client-id=kubernetes" \
--kube-apiserver-arg="oidc-username-claim=sub" \
--kube-apiserver-arg="oidc-groups-claim=groups" \
--kube-apiserver-arg="oidc-ca-file=/home/rian/Code/infrastructure/ou-ca.pem"

# copy kubeconfig from k3s
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config \
&& chown $USER ~/.kube/config \
&& chmod 600 ~/.kube/config \
&& export KUBECONFIG=~/.kube/config

# install ingress-nginx
# https://kubernetes.github.io/ingress-nginx/deploy/

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Cleanup
echo "Cleaning up"

rm -rf /tmp/burritops-install

# post setup notification

# echo "Run to set up kubeconfig:"
# echo "sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && chown $USER ~/.kube/config && chmod 600 ~/.kube/config && export KUBECONFIG=~/.kube/config"