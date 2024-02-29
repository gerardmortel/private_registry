#!/bin/bash

###########################################################################################
#####                                                                                 #####
#####           Mirroring images to a private registry with a bastion server          #####
#####                                                                                 #####
###########################################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=mipr-option-1-mirroring-images-private-registry-bastion-server
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=o2mipruoim-option-2a-mirroring-images-private-registry-bastion-server
# https://www.ibm.com/docs/en/odm/8.12.0?topic=mipr-option-1-mirroring-images-private-container-registry-bastion-server

echo "#### 1. Generate the required mirror manifests."
echo '#### 1a. Define the environment variable $TARGET_REGISTRY'
echo "#### 1a. The TARGET_REGISTRY refers to the registry where the images are mirrored to and accessed by the OCP cluster."
echo "#### 1a. TARGET_REGISTRY=${TARGET_REGISTRY}"

echo "#### 1b. Create the following environment variables with the installer image name and the version."
echo "#### 1b. CASE_NAME=${CASE_NAME}"
echo "#### 1b. CASE_VERSION=${CASE_VERSION}"

echo "#### 1c. Run the following command to set the preferred tool parameter in the YAML file to oc-mirror."
oc ibm-pak config mirror-tools --enabled oc-mirror

echo "#### 1d. Generate mirror manifests to be used when mirroring the catalog to the target registry."
oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
  --version $CASE_VERSION

echo "##### 1c. Show the .ibm-pak directory structure"
tree $IBMPAK_HOME/.ibm-pak

echo "#### 1c. List all the images in your mirror manifest and the publicly accessible registries from where the images are pulled from."
oc ibm-pak describe $CASE_NAME \
  --version $CASE_VERSION \
  --list-mirror-images

echo "#### 2. Authenticate the registries"
echo "#### 2a. Login to the IBM Container Registry"
podman login -u ${ICR_USERNAME} -p ${API_KEY_GENERATED} cp.icr.io

echo "#### 2b. Login to ${TARGET_REGISTRY}"
podman login -u ${PRIVATE_REGISTRY_USERNAME} -p ${PRIVATE_REGISTRY_PASSWORD} ${TARGET_REGISTRY}

echo "#### 2c. REGISTRY_AUTH_FILE=$REGISTRY_AUTH_FILE"
# If you export REGISTRY_AUTH_FILE=~/.ibm-pak/auth.json, and then run the podman login command, you can see that the file is populated with registry credentials.
# If you use docker login, the authentication file is typically located in $HOME/.docker/config.json on Linux or %USERPROFILE%/.docker/config.json on Windows. After you run the docker login command, you can export REGISTRY_AUTH_FILE to point to that location. For example, on Linux you can run the following command:
# Set in 02_setup_env.sh

echo "#### 3a. Mirror the images to the target registry"
  nohup oc mirror --config $IBMPAK_HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-set-config.yaml \
    docker://$TARGET_REGISTRY/cp4ba-2301 \
    --dest-skip-tls \
    --max-per-registry=6 > ~/cp4ba-511.txt 2>&1 &

echo "#### Extra: 3a. Test by listing the tags for the navigator-sso image"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/cp/cp4a/ban/navigator-sso/tags/list | grep name | jq
