#!/bin/bash
# set -e

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

# uninstall helm plugins
helm plugin uninstall diff

# remove k3s
echo "Removing k3s"
k3s-uninstall.sh

# remove brew installed apps
echo "Removing brew installled utilities"
brew remove --force $(brew list) --ignore-dependencies

# remove brew
echo "Removing brew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"

# remove certificate
echo "Removing openunison certificate"
rm -rf /etc/kubernetes

# sometimes it installs something here- run the uninstall
# ls /usr/local/bin
# crictl  k3s  k3s-killall.sh  k3s-traefik-uninstall.sh