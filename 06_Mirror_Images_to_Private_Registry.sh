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
oc ibm-pak generate mirror-manifests $CASE_NAME $TARGET_REGISTRY \
  --version $CASE_VERSION

echo "#### list all the images in your mirror manifest and the publicly accessible registries from where the images are pulled from."
oc ibm-pak describe $CASE_NAME \
  --version $CASE_VERSION \
  --list-mirror-images

echo "#### Authenticate the registries"
echo "#### Login to the IBM Container Registry"
podman login -u ${ICR_USERNAME} -p ${API_KEY_GENERATED} cp.icr.io

echo "#### Login to ${TARGET_REGISTRY}"
podman login -u ${PRIVATE_REGISTRY_USERNAME} -p ${PRIVATE_REGISTRY_PASSWORD} ${TARGET_REGISTRY}

echo "#### Mirror the images"
nohup oc image mirror -f /root/.ibm-pak/data/mirror/ibm-cp-automation/5.0.2/images-mapping.txt \
--filter-by-os '.*' \
-a $REGISTRY_AUTH_FILE \
--insecure \
--skip-multiple-scopes \
--max-per-registry=1 | tee mirror.log

echo "#### List the tags for the navigator image"
curl -ik --user ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} https://${HOSTNAME}:5000/v2/cp/cp4a/ban/navigator-sso/tags/list | grep name | jq

echo "#### Run the following command to create ImageContentsourcePolicy."
oc apply -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-content-source-policy.yaml

echo "#### Verify your cluster node status."
# oc get MachineConfigPool -w

echo "#### Create a project for the CASE commands (cp4ba is an example)"
# Note: Before you run the command in this step, you must be logged in to your OpenShift cluster.
oc new-project $CP4BANAMESPACE

# echo "#### Optional: If you use an insecure registry, you must add the target registry to the cluster insecureRegistries list"
# oc patch image.config.openshift.io/cluster \
#   --type=merge -p '{"spec":{"registrySources":{"insecureRegistries":["'${TARGET_REGISTRY}'"]}}}' 

echo "#### Configure a secure registry"
echo "#### Load the domain.crt in a configmap"
rm -f /certs/ca.crt
cp /certs/domain.crt /certs/ca.crt
oc delete configmap registry-config -n openshift-config
oc create configmap registry-config -n openshift-config --from-file=$HOSTNAME..5000=/certs/ca.crt

echo "#### Patch the OpenShift cluster to trust the podman private registry"
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

echo "#### Patch the OpenShift cluster to only use certain registries"
PATCH="{"spec":{"allowedRegistriesForImport":[{"domainName":"${HOSTNAME}:5000","insecure":false},{"domainName":"image-registry.openshift-image-registry.svc:5000","insecure":false},{"domainName":"quay.io","insecure":false},{"domainName":"cdn.quay.io","insecure":false},{"domainName":"cdn01.quay.io","insecure":false},{"domainName":"cdn02.quay.io","insecure":false},{"domainName":"cdn03.quay.io","insecure":false},{"domainName":"registry.redhat.io","insecure":false},{"domainName":"k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:4.0.2","insecure":false}],"registrySources":{"allowedRegistries":["${HOSTNAME}:5000","image-registry.openshift-image-registry.svc:5000","quay.io","cdn.quay.io","cdn01.quay.io","cdn02.quay.io","cdn03.quay.io","registry.redhat.io","k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:4.0.2"]}}}"
oc patch image.config.openshift.io/cluster -p \
${PATCH} --type='merge'

echo "#### Get existing pull secret"
oc get secrets pull-secret -n openshift-config -o template='{{index .data ".dockerconfigjson"}}' | base64 -d > pull-secret.json
cat pull-secret.json | jq > pull-secret-v2.json

echo "#### Create the private registry json"
cat <<EOF > registry-secret.json
    },
    "${HOSTNAME}:5000": {
      "auth": "$( echo -n ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} | base64 -w0 )",
      "email": "registry@redhat.com"
    }
  }
}
EOF

echo "#### This is a manual step.  Replace the last 3 curly braces with our new secret data."
echo "#### The remaining commands must be run manually."
# echo <<EOF > private_registry_credentials
#     },
#     "${HOSTNAME}:5000": {
#       "auth": "YWRtaW46UGFzc3cwcmQ=",
#       "email": "registry@redhat.com"
#     }
#   }
# }
# EOF

# To Do: Automate the above substitution.  Still not working, still a manual step.
# sed -r "s/\}\n *\}\n\}//g" pull-secret-v2.json > pull-secret-v3.json

#echo "#### Reformat json and verify json is well formatted"j
#cat pull-secret-v2.json | jq > pull-secret-v3.json

# Update the pull secret
#oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./pull-secret-v3.json