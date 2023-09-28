#!/bin/bash

###########################################################################################
#####                                                                                 #####
#####           Configure OCP to use secure registry and allowed registries           #####
#####                                                                                 #####
###########################################################################################

echo "#### Login to the OpenShift cluster"
oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

echo "#### Configure a secure registry"
echo "#### Load the domain.crt in a configmap"
rm -f /certs/ca.crt
cp /certs/domain.crt /certs/ca.crt
oc delete configmap registry-config -n openshift-config
oc create configmap registry-config -n openshift-config --from-file=$HOSTNAME..5000=/certs/ca.crt

echo "#### Patch the OpenShift cluster to trust the podman private registry"
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

echo "#### Patch the OpenShift cluster to only use certain registries"
cat <<EOF > cluster1.json
{
  "spec": {
    "allowedRegistriesForImport": [
      {
        "domainName": "${HOSTNAME}:5000",
        "insecure": false
      },
      {
        "domainName": "image-registry.openshift-image-registry.svc:5000",
        "insecure": false
      },
      {
        "domainName": "quay.io",
        "insecure": false
      },
      {
        "domainName": "cdn.quay.io",
        "insecure": false
      },
      {
        "domainName": "cdn01.quay.io",
        "insecure": false
      },
      {
        "domainName": "cdn02.quay.io",
        "insecure": false
      },
      {
        "domainName": "cdn03.quay.io",
        "insecure": false
      },
      {
        "domainName": "registry.redhat.io",
        "insecure": false
      },
      {
        "domainName": "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2",
        "insecure": false
      }
    ],
    "registrySources": {
      "allowedRegistries": [
        "${HOSTNAME}:5000",
        "image-registry.openshift-image-registry.svc:5000",
        "quay.io",
        "cdn.quay.io",
        "cdn01.quay.io",
        "cdn02.quay.io",
        "cdn03.quay.io",
        "registry.redhat.io",
        "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"
      ]
    }
  }
}
EOF

echo "#### Compact json"
cat cluster1.json | jq -c > cluster2.json
PATCH=$(cat cluster2.json)

oc patch image.config.openshift.io/cluster -p \
${PATCH} --type='merge'

echo "#### Get existing pull secret"
oc get secrets pull-secret -n openshift-config -o template='{{index .data ".dockerconfigjson"}}' | base64 -d > pull-secret.json

echo "#### Format the pull secret nicely"
cat pull-secret.json | jq > pull-secret-v2.json

echo "#### Delete the last 3 lines"
head -n -3 pull-secret-v2.json > pull-secret-v3.json

echo "#### Create the private registry credentials to put into the pull secret"
cat <<EOF > registry-secret.json
    },
    "${HOSTNAME}:5000": {
      "auth": "$( echo -n ${PRIVATE_REGISTRY_USERNAME}:${PRIVATE_REGISTRY_PASSWORD} | base64 -w0 )",
      "email": "registry@redhat.com"
    }
  }
}
EOF

echo "#### Add the registry-secret.json to the end of the pull secret"
cat pull-secret-v3.json registry-secret.json > pull-secret-v4.json

echo "#### Reformat json and verify json is well formatted"
cat pull-secret-v4.json | jq > pull-secret-v5.json

echo "#### Update the pull secret."
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./pull-secret-v5.json

#### jq -c
# {"spec":{"allowedRegistriesForImport":[{"domainName":"smelting1.fyre.ibm.com:5000","insecure":false},{"domainName":"image-registry.openshift-image-registry.svc:5000","insecure":false},{"domainName":"quay.io","insecure":false},{"domainName":"cdn.quay.io","insecure":false},{"domainName":"cdn01.quay.io","insecure":false},{"domainName":"cdn02.quay.io","insecure":false},{"domainName":"cdn03.quay.io","insecure":false},{"domainName":"registry.redhat.io","insecure":false},{"domainName":"k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2","insecure":false}],"registrySources":{"allowedRegistries":["smelting1.fyre.ibm.com:5000","image-registry.openshift-image-registry.svc:5000","quay.io","cdn.quay.io","cdn01.quay.io","cdn02.quay.io","cdn03.quay.io","registry.redhat.io","k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"]}}}