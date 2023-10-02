# Setting up the private registry on RHEL 8.6

# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=environment-setting-up-private-registry
# https://hub.docker.com/_/registry
# https://docs.docker.com/registry/insecure/
# https://docs.docker.com/registry/deploying/

# Install Docker
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc
sudo yum install -y yum-utils 
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin jq
sudo systemctl start docker
docker run hello-world 
docker --version
docker compose version

# Pull docker registry image
docker pull registry

# Make a registry directory to hold images.  We can try to copy this later to another registry.
mkdir /registry

# Create username and password and run it in a container, let it run don't stop it
mkdir /auth
docker run \
 --entrypoint htpasswd \
httpd:2 -Bbn admin Passw0rd > /auth/htpasswd

# Export this variable
export GODEBUG=x509ignoreCN=0

# Make the certificates.  Note that your hostname should go in the DNS entry
mkdir -p /certs
cd /certs
openssl req \
 -newkey rsa:4096 -nodes -sha256 -keyout /certs/domain.key \
 -addext "subjectAltName = DNS:citiswatrhel86v61.fyre.ibm.com" \
 -subj "/C=US/ST=IL/L=Chicago/O=IBM/OU=Expert Labs/CN=citiswatrhel86v61.fyre.ibm.com" \
 -x509 -days 365 -out /certs/domain.crt

openssl req \
 -newkey rsa:4096 -nodes -sha256 -keyout /certs/domain.key \
 -addext "subjectAltName = DNS:$HOSTNAME" \
 -subj "/C=US/ST=IL/L=Chicago/O=IBM/OU=Expert Labs/CN=$HOSTNAME" \
 -x509 -days 365 -out /certs/domain.crt

# Get RHEL to trust source.  Note that your hostname should be the name of your certifcate
rm -f /etc/pki/ca-trust/source/anchors/$HOSTNAME.crt
cp -p /certs/domain.crt /etc/pki/ca-trust/source/anchors/$HOSTNAME.crt
update-ca-trust

# Restart Docker
systemctl stop docker
systemctl start docker

# Run a local registry with authentication, TLS and 
docker run -d \
 -p 5000:5000 \
 --restart=always \
 --name registry \
 -v /auth:/auth \
 -e "REGISTRY_AUTH=htpasswd" \
 -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
 -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
 -v /certs:/certs \
 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
 -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
 -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
 -v /registry:/var/lib/registry \
 registry:2

# Test it - user/pass is admin/Passw0rd - Note that your hostname should be used for the docker login tag and push
sleep 20s
docker login -u admin -p Passw0rd $HOSTNAME:5000
docker pull ubuntu
docker tag ubuntu $HOSTNAME:5000/ubuntu
docker push $HOSTNAME:5000/ubuntu

# If you installed jq (yum install -q jq), display the repositories nicely
curl -ik --user admin:Passw0rd https://$HOSTNAME:5000/v2/_catalog | grep repositories | jq

# If you did not install jq, list the repositories
#curl -ik --user admin:Passw0rd https://$HOSTNAME:5000/v2/_catalog

# List tags for an image
curl -ik --user admin:Passw0rd https://localhost:5000/v2/ubuntu/tags/list | grep name | jq

# To stop registry
#docker container stop registry

#To stop registry and remove all data
#docker container stop registry && docker container rm -v registry
