#!/bin/bash
# set -e

# remove brew installed apps
brew remove --force $(brew list) --ignore-dependencies

# remove brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"

# remove k3s
k3s-uninstall.sh

# remove kubectl
rm /usr/local/bin/kubectl