#!/bin/bash
set -e

# install homebrew
echo "Installing homebrew"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# TODO: remove file creation
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

# helmfile
brew "helmfile"

# kubecolor
# brew "hidetatz/tap/kubecolor"

EOF

# Run brew bundle
echo "Run brew bundle"
brew bundle

rm Brewfile

# Install helm plugins
echo "Installing helm diff"
helm plugin install https://github.com/databus23/helm-diff

# Install krew
echo "Installing krew"
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew install oulogin

echo "Add this to your shell: "
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'