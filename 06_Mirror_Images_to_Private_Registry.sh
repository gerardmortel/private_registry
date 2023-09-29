#!/bin/bash

###########################################################################################
#####                                                                                 #####
#####           Mirroring images to a private registry with a bastion server          #####
#####                                                                                 #####
###########################################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=mipr-option-1-mirroring-images-private-registry-bastion-server


echo "#### Generate mirror manifests to be used when mirroring the image to the target registry."
echo "#### The TARGET_REGISTRY refers to the registry where the images are mirrored to and accessed by the OCP cluster."
echo "#### TARGET_REGISTRY=${TARGET_REGISTRY}" 
# oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
#   --version $CASE_VERSION
oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
  --version $CASE_VERSION \
  --filter ibmcp4baProd,ibmcp4baODMImages,ibmcp4baBASImages,ibmcp4baAAEImages,ibmEdbStandard

echo "#### list all the images in your mirror manifest and the publicly accessible registries from where the images are pulled from."
oc ibm-pak describe $CASE_NAME \
  --version $CASE_VERSION \
  --list-mirror-images

echo "#### Authenticate the registries"
echo "#### Login to the IBM Container Registry"
podman login -u ${ICR_USERNAME} -p ${API_KEY_GENERATED} cp.icr.io

echo "#### Login to ${TARGET_REGISTRY}"
podman login -u ${PRIVATE_REGISTRY_USERNAME} -p ${PRIVATE_REGISTRY_PASSWORD} ${TARGET_REGISTRY}

echo "#### Mirror the images until no errors appear in the logs"
i=1
j=0
while [ true ]
do
  nohup oc image mirror -f /root/.ibm-pak/data/mirror/ibm-cp-automation/5.0.2/images-mapping.txt \
  --filter-by-os '.*' \
  -a $REGISTRY_AUTH_FILE \
  --insecure \
  --skip-multiple-scopes \
  --max-per-registry=1 | tee mirror${i}.log
  j=$(grep "error" mirror${i}.log|wc -l)
  if [ ${j} -gt 0 ]; then
    echo "#### Mirror images FAILED.  Invoking mirror image command again."
    ((i=i+1))
  else
    echo "#### Mirror images SUCCEEDED"
    break
  fi
done

echo "#### Test listing the tags for the navigator image"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/cp/cp4a/ban/navigator-sso/tags/list | grep name | jq

echo "#### Login to the OpenShift cluster"
oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

echo "#### Run the following command to create ImageContentsourcePolicy."
oc apply -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-content-source-policy.yaml

echo "#### Check the number of updated machines equals ${NUM_OF_MACHINES}"
NUM_OF_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | wc -l)
NUM_OF_UPDATED_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $3 }' | grep "True" | wc -l)
#NUM_OF_UPDATING_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $4 }' | grep "True" | wc -l)
while [ true ]
do
  NUM_OF_UPDATED_MACHINES=$(oc get MachineConfigPool | grep -v "NAME" | awk '{ print $3 }' | grep "True" | wc -l)
  if [[ ${NUM_OF_UPDATED_MACHINES} -eq ${NUM_OF_MACHINES} ]]; then
    echo "#### Yes, the update is done."
    break
  else
    echo "#### No, the update is not done so sleep for 10 seconds"
    sleep 10
  fi
done

echo "#### Create a project for the CASE commands (cp4ba is an example)"
# Note: Before you run the command in this step, you must be logged in to your OpenShift cluster.
oc new-project $CP4BANAMESPACE

# echo "#### Optional: If you use an insecure registry, you must add the target registry to the cluster insecureRegistries list"
# oc patch image.config.openshift.io/cluster \
#   --type=merge -p '{"spec":{"registrySources":{"insecureRegistries":["'${TARGET_REGISTRY}'"]}}}' 