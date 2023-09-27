#!/bin/bash

###########################################################################################
#####                                                                                 #####
#####           Configure OCP to use secure registry and allowed registries           #####
#####                                                                                 #####
###########################################################################################

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