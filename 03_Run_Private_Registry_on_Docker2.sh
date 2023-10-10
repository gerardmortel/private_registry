#!/bin/bash

#####################################################################################
#####                                                                           #####
#####     Setting up a 2nd instance of a private image registry on RHEL 9.2     #####
#####                                                                           #####
#####################################################################################

echo "#### Extra: Make data2 directory to hold images, auth to hold credentials and certs to hold certs"
rm -rf /{data2}
mkdir -p /{data2}

echo "#### Extra: export GODEBUG=x509ignoreCN=0"
export GODEBUG=x509ignoreCN=0

echo "#### Extra: Login to docker to create /run/user/0/containers/auth.json"
docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} docker.io

echo "#### Extra: Run the registry container.  Note: On RHEL 9.2, needed to put all directories off of root "/".  Could not use /opt/registry"
docker run --name registry2 \
-p 5001:5000 \
-v /data2:/var/lib/registry:z \
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
docker pull ubuntu
docker tag ubuntu $HOSTNAME:5001/ubuntu
docker login -u ${PRIVATE_REGISTRY_USERNAME} -p ${PRIVATE_REGISTRY_PASSWORD} $HOSTNAME:5001
docker push $HOSTNAME:5001/ubuntu

echo "#### Extra: If you installed jq (yum install -q jq), display the repositories nicely"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5001/v2/_catalog?n=1000| grep repositories | jq

IMAGE="ubuntu"
echo "#### Extra: List tags for a image ${IMAGE}"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5001/v2/${IMAGE}/tags/list | grep name | jq

IMAGE="cpopen/ibm-common-service-operator-bundle"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5001/v2/${IMAGE}/tags/list | grep name | jq

IMAGE="cpopen/ibm-cert-manager-operator-bundle"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5001/v2/${IMAGE}/tags/list | grep name | jq

# If you did not install jq, list the repositories
# curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://$HOSTNAME:5001/v2/_catalog

echo "#### Extra: Verify the certificate"
# openssl s_client -connect ${HOSTNAME}:5001 -servername <servername>
openssl s_client -connect ${HOSTNAME}:5001 -servername ${HOSTNAME} <<END

END

# echo "#### Extra: Stop registry"
# docker stop registry

# echo "#### Extra: Stop registry and remove all data"
# docker container stop registry && docker container rm -v registry
