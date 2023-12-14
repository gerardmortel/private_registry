#!/bin/bash

###########################################################################################
#####           Extra                                                                 #####
#####           Configure OCP to use secure private registry                          #####
#####                                                                                 #####
###########################################################################################

echo "#### Extra: Login to the OpenShift cluster"
oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

echo "#### Extra: Configure a secure registry"
echo "#### Extra Load the domain.crt in a configmap"
rm -f /certs/ca.crt
cp /certs/domain.crt /certs/ca.crt
oc delete configmap registry-config -n openshift-config
oc create configmap registry-config -n openshift-config --from-file=$HOSTNAME..5000=/certs/ca.crt

echo "#### Extra: Patch the OpenShift cluster to trust the podman private registry"
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge