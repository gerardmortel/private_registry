#!/bin/bash

####################################################################
#####                                                          #####
#####             Downloading the CASE files                   #####
#####                                                          #####
####################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-downloading-case-files

echo "#### View the current config of the IBM Catalog Management Plug-in (ibm-pak) v1.6 and later"
oc ibm-pak config

echo "#### Login to the OpenShift cluster"
oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

echo "#### Configure a repository that downloads the CASE files from the cp.icr.io registry"
oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable

echo "#### List all the available CASE files to download by running the following command"
oc ibm-pak list

echo "#### Get the cp4ba-case-to-be-mirrored-23.0.1.txt file, or an interim fix, from the Cloud Pak for Business Automation CASE images technote, and rename the file to cp4ba-case-to-be-mirrored_23.0.1.yaml."
curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002.txt -o cp4ba-case-to-be-mirrored_23.0.1.yaml

echo "#### Check cp4ba-case-to-be-mirrored_23.0.1.yaml is correct"
while [ true ]
do
  grep "ibm-licensing" cp4ba-case-to-be-mirrored_23.0.1.yaml
  if [ $? -eq 0 ]; then
    echo "#### cp4ba-case-to-be-mirrored_23.0.1.yaml download successful"
    break
  else
    echo "#### dcp4ba-case-to-be-mirrored_23.0.1.yaml download FAILED"
    echo "#### Sleeping for 10 seconds"
    sleep 10
  fi
done

echo "#### Download of the CASE files"
oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored_23.0.1.yaml

echo "#### List the versions of all the downloaded CASE files."
echo "#### Check that download list contains something"
while [ true ]
do
  oc ibm-pak list --downloaded | grep "ibm-cp-automation"
  if [ $? -eq 0 ]; then
    echo "#### cp4ba-case-to-be-mirrored_23.0.1.yaml download successful"
    break
  else
    echo "#### dcp4ba-case-to-be-mirrored_23.0.1.yaml download FAILED"
    echo "#### Sleeping for 10 seconds"
    sleep 10
  fi
done