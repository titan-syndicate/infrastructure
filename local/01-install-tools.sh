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

