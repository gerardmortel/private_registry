#!/bin/bash

###########################################################################################
#####           Extra                                                                 #####
#####           Configure OCP to use allowed registries                               #####
#####                                                                                 #####
###########################################################################################

echo "#### Extra: Patch the OpenShift cluster to only use only specific allowed registries"
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
      },
      {
        "domainName": "gcr.io/google_containers/busybox:1.24",
        "insecure": false
      },
      {
        "domainName": "icr.io",
        "insecure": false
      },
      {
        "domainName": "cp.icr.io",
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
        "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2",
        "gcr.io/google_containers/busybox:1.24",
        "icr.io",
        "cp.icr.io"
      ]
    }
  }
}
EOF

echo "#### Extra: Compact the json"
cat cluster1.json | jq -c > cluster2.json
PATCH=$(cat cluster2.json)

echo "#### Extra: Patch the OpenShift cluster to use only allowed registries "
oc patch image.config.openshift.io/cluster -p \
${PATCH} --type='merge'