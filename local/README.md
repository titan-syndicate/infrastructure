# Run it
- don't use the 01-install-tools.sh yet
- don't use with existing k3s installation- run k3s-uninstall.sh first
- tools needed: helm
- example:
```
./02-install-k3s.sh \
-k base64-K8S_DB_SECRET\
-u base64-UNISON_KEYSTORE_PASSWORD \
-c GITHUB_OAUTH_CLIENT_ID \
-g base-64-GITHUB_SECRET_ID \
-t github-org-name/github-team-name
```
- base64 encode example:
```
echo -n MY_PASSWORD | base64
```