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

echo "#### 1c. Generate mirror manifests to be used when mirroring the image to the target registry."
echo "#### 1c. The $TARGET_REGISTRY refers to the registry where the images are mirrored to and accessed by the OCP cluster."

if [ ${INSTALLTYPE} == "cp4ba" ]; then
  echo "#### Extra: Install type is cp4ba"
  oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
    --version $CASE_VERSION \
    --filter ibmcp4baProd,ibmcp4baODMImages,ibmcp4baBASImages,ibmcp4baAAEImages,ibmEdbStandard
else # ODM Helm install, not CP4BA install
  echo "#### Extra: Install type is NOT cp4ba, should be helm."
  oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
    --version $CASE_VERSION
fi

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

echo "#### 2c. If using Docker set REGISTRY_AUTH_FILE in 02_setup_env.sh"
# If you export REGISTRY_AUTH_FILE=~/.ibm-pak/auth.json, and then run the podman login command, you can see that the file is populated with registry credentials.
# If you use docker login, the authentication file is typically located in $HOME/.docker/config.json on Linux or %USERPROFILE%/.docker/config.json on Windows. After you run the docker login command, you can export REGISTRY_AUTH_FILE to point to that location. For example, on Linux you can run the following command:
# Set in 02_setup_env.sh
# export REGISTRY_AUTH_FILE=$HOME/.docker/config.json

if [ ${INSTALLTYPE} == "cp4ba" ]; then
  echo "#### Extra: 3. Mirror the images until no errors appear in the logs"
  i=1
  j=0
  while [ true ]
  do
    echo "#### 3a. Mirror the images to the target registry"
    nohup oc image mirror -f $IBMPAK_HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt \
    --filter-by-os '.*' \
    -a $REGISTRY_AUTH_FILE \
    --insecure \
    --skip-multiple-scopes \
    --max-per-registry=1 \
    --continue-on-error=true \
    | tee mirror${i}.log
    j=$(grep "error" mirror${i}.log|wc -l)
    if [ ${j} -gt 0 ]; then
      echo "#### Extra: 3a. Mirror images FAILED.  Invoking mirror image command again."
      ((i=i+1))
    else
      echo "#### Extra: 3a. Mirror images SUCCEEDED"
      break
    fi
  done

  echo "#### Extra: 3a. Test by listing the tags for the navigator-sso image"
  curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/cp/cp4a/ban/navigator-sso/tags/list | grep name | jq

  echo "#### Extra: 3b. Login to the OpenShift cluster"
  oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

  echo "#### 3b. Update the global image pull secret for your OpenShift cluster to have authentication credentials in place "
  echo "#### 3b. to pull images from your $TARGET_REGISTRY as specified in the image-content-source-policy.yaml file. For more information, see "
  echo "#### 3b. Updating the global cluster pull secret."
  echo "#### 3b. https://docs.openshift.com/container-platform/4.10/openshift_images/managing_images/using-image-pull-secrets.html#images-update-global-pull-secret_using-image-pull-secrets"
  echo "#### Extra: 3b. Get the existing pull secret"
  oc get secrets pull-secret -n openshift-config -o template='{{index .data ".dockerconfigjson"}}' | base64 -d > pull-secret.json

  echo "#### Extra: 3b. Format the pull secret nicely"
  cat pull-secret.json | jq > pull-secret-v2.json

  echo "#### Extra: 3b. Delete the last 3 lines from the nicely formatted pull secret file"
  head -n -3 pull-secret-v2.json > pull-secret-v3.json

  echo "#### Extra: 3b. Create the private registry credentials to add later into the pull secret"
cat <<EOF > registry-secret.json
    },
    "${HOSTNAME}:5000": {
      "auth": "$( echo -n ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} | base64 -w0 )",
      "email": "registry@redhat.com"
    }
  }
}
EOF

  echo "#### Extra: 3b. Add the registry-secret.json to the end of the pull secret"
  cat pull-secret-v3.json registry-secret.json > pull-secret-v4.json

  echo "#### Extra: 3b. Reformat json and verify json is well formatted"
  cat pull-secret-v4.json | jq > pull-secret-v5.json

  echo "#### Extra: 3b. Update the pull secret"
  oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./pull-secret-v5.json

  echo "#### 3c. Create ImageContentsourcePolicy."
  oc apply -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-content-source-policy.yaml

  echo "#### Extra: 3c. Sleep 30 seconds to let the image content source policy get created"
  sleep 30

  echo "#### 3d. Verify that the ImageContentsourcePolicy resource is created."
  oc get imageContentSourcePolicy

  echo "#### 3e. Verify your cluster node status."
  echo "#### Extra: 3e. Check the number of updated machines equals ${NUM_OF_MACHINES}"
  NUM_OF_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | wc -l)
  NUM_OF_UPDATED_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $3 }' | grep "True" | wc -l)
  #NUM_OF_UPDATING_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $4 }' | grep "True" | wc -l)

  while [ true ]
  do
    echo "#### 3e. Verify your cluster node status."
    oc get MachineConfigPool
    echo "#### Extra: 3e. Compare the number of updated machines with the number of machines.  If equal, update is complete."
    NUM_OF_UPDATED_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $3 }' | grep "True" | wc -l)
    if [[ ${NUM_OF_UPDATED_MACHINES} -eq ${NUM_OF_MACHINES} ]]; then
      echo "#### Extra: 3e. Yes, the update is done."
      break
    else
      echo "#### Extra: 3e. No, the update is not done so sleep for 10 seconds"
      sleep 10
    fi
  done

  echo "#### 3f. Create a project for the CASE commands (cp4ba is an example)"
  # Note: Before you run the command in this step, you must be logged in to your OpenShift cluster.
  oc new-project $NAMESPACE

  # echo "#### 3g. Optional: If you use an insecure registry, you must add the target registry to the cluster insecureRegistries list"
  # oc patch image.config.openshift.io/cluster \
  #   --type=merge -p '{"spec":{"registrySources":{"insecureRegistries":["'${TARGET_REGISTRY}'"]}}}'

else # ODM Helm install, not CP4bA install
  echo "#### 3. Mirror images to the final location.  Complete the steps in this section on your host that is connected to both the local Docker registry and the Kubernetes cluster."
  echo "#### 3a. Edit ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt and append -<architecture> at the end of each destination record, for example:"

  cat ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt | while read line
  do
    echo $line-amd64 >> ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping-v2.txt
  done
  rm -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt
  mv ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping-v2.txt ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt

  echo "#### 3. Mirror images to the TARGET_REGISTRY. Mirroring from a bastion host (connected mirroring):"
  oc image mirror \
  -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt \
  --filter-by-os '.*'  \
  -a $REGISTRY_AUTH_FILE \
  --insecure  \
  --skip-multiple-scopes \
  --max-per-registry=1

  echo "#### 4. Configure the cluster."
  echo "#### 4a. Log into your OCP cluster"
  oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS}

  echo "#### 4b. Create a project for the ODM installation by running the following commands"
  oc new-project $NAMESPACE

  echo "#### 4c. Create a pull secret."
  oc registry login --registry="${TARGET_REGISTRY}"\
  --auth-basic="${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD}" \
  --to=.dockerconfig.json
  oc create secret generic pull-secret --from-file .dockerconfigjson=.dockerconfig.json

  # echo "#### Optional: 4d In OpenShift, if you use an insecure registry, you must add the target registry to the insecureRegistries list of the cluster."
  # oc patch image.config.openshift.io/cluster --type=merge \
  #  -p '{"spec":{"registrySources":{"insecureRegistries":["'${TARGET_REGISTRY}'"]}}}'
fi