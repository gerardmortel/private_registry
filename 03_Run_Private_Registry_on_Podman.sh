#!/bin/bash

#####################################################################
#####                                                           #####
#####     Setting up the private image registry on RHEL 9.2     #####
#####                                                           #####
#####################################################################

# Resources
# How to implement a simple personal/private Linux container image registry for internal use
# https://www.redhat.com/sysadmin/simple-container-registry

echo "#### Extra: If a firewall is running on the hosts, the exposed port (5000) will need to be permitted."
systemctl status firewalld
systemctl start firewalld
systemctl status firewalld
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public --permanent
firewall-cmd --reload

echo "#### Extra: Sleep 120 seconds to let the firewall reload work"
sleep 120

echo "#### Extra: Make registry directory to hold images, auth to hold credentials and certs to hold certs"
# rm -rf /opt/registry/{auth,certs,data}
# mkdir -p /opt/registry/{auth,certs,data}
rm -rf /{auth,certs,data}
mkdir -p /{auth,certs,data}

echo "#### Extra: Use the htpasswd utility to generate a file containing the credentials for accessing the registry"
htpasswd -bBc /auth/htpasswd ${PRIVATE_REGISTRY_USERNAME} ${PRIVATE_REGISTRY_PASSWORD}

echo "#### Extra: Create the TLS key pair"
openssl req \
 -newkey rsa:4096 -nodes -sha256 -keyout /certs/domain.key \
 -addext "subjectAltName = DNS:$HOSTNAME" \
 -subj "/C=US/ST=IL/L=Chicago/O=IBM/OU=Expert Labs/CN=$HOSTNAME" \
 -x509 -days 365 -out /certs/domain.crt

echo "#### Extra: Get RHEL to trust source.  Note that your hostname should be the name of your certifcate"
rm -f /etc/pki/ca-trust/source/anchors/$HOSTNAME.crt
cp /certs/domain.crt /etc/pki/ca-trust/source/anchors/$HOSTNAME.crt
update-ca-trust

echo "#### Extra: Login to docker to create /run/user/0/containers/auth.json"
podman login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} docker.io

echo "#### Extra: Run the registry container.  Note: On RHEL 9.2, needed to put all directories off of root "/".  Could not use /opt/registry"
podman run --name registry \
-p 5000:5000 \
-v /data:/var/lib/registry:z \
-v /auth:/auth:z \
-v /certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
-e REGISTRY_AUTH=htpasswd \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true" \
-d \
docker.io/library/registry:latest

echo "#### Extra: Test it.  Login to your private registry, pull an image, tag it and push it to the private registry."
podman pull ubuntu
podman tag ubuntu $HOSTNAME:5000/ubuntu
podman login -u ${PRIVATE_REGISTRY_USERNAME} -p ${PRIVATE_REGISTRY_PASSWORD} $HOSTNAME:5000
podman push $HOSTNAME:5000/ubuntu

echo "#### Extra: If you installed jq (yum install -q jq), display the repositories nicely"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/_catalog?n=1000| grep repositories | jq

IMAGE="ubuntu"
echo "#### Extra: List tags for a image ${IMAGE}"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/${IMAGE}/tags/list | grep name | jq

IMAGE="cpopen/ibm-common-service-operator-bundle"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/${IMAGE}/tags/list | grep name | jq

IMAGE="cpopen/ibm-cert-manager-operator-bundle"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/${IMAGE}/tags/list | grep name | jq

# If you did not install jq, list the repositories
# curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://$HOSTNAME:5000/v2/_catalog

echo "#### Extra: Verify the certificate"
# openssl s_client -connect ${HOSTNAME}:5000 -servername <servername>
openssl s_client -connect ${HOSTNAME}:5000 -servername ${HOSTNAME} <<END

END

# echo "#### Extra: Stop registry"
# podman stop registry

# echo "#### Extra: Stop registry and remove all data"
# podman container stop registry && podman container rm -v registry
