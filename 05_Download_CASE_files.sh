#!/bin/bash

####################################################################
#####                                                          #####
#####             Downloading the CASE files                   #####
#####                                                          #####
####################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-downloading-case-files

echo "#### 2a. View the current config of the IBM Catalog Management Plug-in (ibm-pak) v1.6 and later"
oc ibm-pak config

echo "#### 2b. Configure a repository that downloads the CASE files from the cp.icr.io registry (an OCI-compliant registry) before you run the oc ibm-pak get command."
echo "#### 2b. The command sets 'IBM Cloud-Pak OCI registry' as the default repository."
oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable

echo "#### 2c. List all the available CASE files to download by running the following command"
oc ibm-pak list

echo "#### 2d. Get the cp4ba-case-to-be-mirrored-23.0.1.txt file, or an interim fix, from the Cloud Pak for Business Automation CASE images technote, and rename the file to cp4ba-case-to-be-mirrored_23.0.1.yaml."
# Cloud Pak for Business Automation: CASE image digests
# https://www.ibm.com/support/pages/node/6596381

# 22.0.2_IF005
# https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-22.0.2-IF005.txt
# curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-22.0.2-IF005.txt -o cp4ba-case-to-be-mirrored_22.0.2.yaml

# 22.0.2_IF006
# https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-22.0.2-IF006_0.txt
# curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-22.0.2-IF006_0.txt -o cp4ba-case-to-be-mirrored_22.0.2.yaml

# 23.0.1_IF002
# https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002_2.txt
curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002_2.txt -o cp4ba-case-to-be-mirrored_23.0.1.yaml

# https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002.txt
# curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002.txt -o cp4ba-case-to-be-mirrored_23.0.1.yaml

# 23.0.1_IF003
# https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF003_7.txt
# curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF003_7.txt -o cp4ba-case-to-be-mirrored_23.0.1.yaml

# Sometimes the download in the previous step fails so put the download in a while loop until successful
echo "#### Extra: 2d. Check cp4ba-case-to-be-mirrored_23.0.1.yaml is correct"
while [ true ]
do
  grep "ibm-licensing" cp4ba-case-to-be-mirrored_23.0.1.yaml
  if [ $? -eq 0 ]; then
    echo "#### Extra: 2d. cp4ba-case-to-be-mirrored_23.0.1.yaml download SUCCEEDED"
    break
  else
    echo "#### Extra: 2d. cp4ba-case-to-be-mirrored_23.0.1.yaml download FAILED, trying again."
    curl -L https://www.ibm.com/support/pages/system/files/inline-files/cp4ba-case-to-be-mirrored-23.0.1-IF002.txt -o cp4ba-case-to-be-mirrored_23.0.1.yaml
  fi
done

echo "#### 2e. Download of the CASE files"
# oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored_22.0.2.yaml
oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored_23.0.1.yaml

echo "#### 2f. List the versions of all the downloaded CASE files."
oc ibm-pak list --downloaded

echo "#### Extra: 2f. Check that download list actaully contains something"
while [ true ]
do
  oc ibm-pak list --downloaded | grep "ibm-cp-automation"
  if [ $? -eq 0 ]; then
    echo "#### Extra: 2e. cp4ba-case-to-be-mirrored_23.0.1.yaml download SUCCEEDED"
    break
  else
    echo "#### Extra: 2e. cp4ba-case-to-be-mirrored_23.0.1.yaml download FAILED, trying again."
    oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored_23.0.1.yaml
  fi
done