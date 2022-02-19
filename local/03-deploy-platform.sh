# Create a self-signed cert to be used as CA
echo "Creating CA cert"
mkdir -p ssl

openssl genrsa -out ssl/tls.key 2048
openssl req -x509 -new -nodes -key ssl/tls.key -days 3650 -sha256 -out ssl/tls.crt -subj "/CN=internal-ca"
sudo sh -c "cp tls.crt /usr/local/share/ca-certificates/internal-ca.crt \
&& update-ca-certificates"
# sudo reboot

# Add cert-manager
echo "Deploying cert-manager"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml

# Add self signed certificate authority
echo "Deploying self signed CA secrete"
kubectl create secret tls ca-key-pair --key=./ssl/tls.key --cert=./ssl/tls.crt -n cert-manager
secret/ca-key-pair created

# Add ClusterIssuer so that all Ingress objects have properly minted certs
echo "Deploying ClusterIssuer"
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOF

# import cert manager certificates into node
# this should be done to each node
# internal-ca.crt should be installed on local machine
echo "Importing ca certificates from cert-manager into node"
homedir=`echo $(cd "$(dirname ~)"; pwd)/$(basename ~)`
kubectl get secret ca-key-pair -n cert-manager -o json | jq -r '.data["tls.crt"]' | base64 -d > $homedir/internal-ca.crt
sudo sh -c "cp $homedir/internal-ca.crt /usr/local/share/ca-certifcates/internal-ca.crt \
&& update-ca-certificates"

