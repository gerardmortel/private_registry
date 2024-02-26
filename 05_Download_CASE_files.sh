#!/bin/bash

####################################################################
#####                                                          #####
#####             Downloading the CASE files                   #####
#####                                                          #####
####################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-downloading-case-files
# https://www.ibm.com/docs/en/odm/8.12.0?topic=installation-setting-environment-variables-downloading-case-files

echo "#### 1. Connect your host to the internet and disconnect it from the local air-gapped network."
# Nothing to script

if [ ${INSTALLTYPE} -eq "cp4ba" ]; then
  echo "#### 2a. View the current config of the IBM Catalog Management Plug-in (ibm-pak) v1.6 and later"
  oc ibm-pak config

  echo "#### 2b. Configure a repository that downloads the CASE files from the cp.icr.io registry (an OCI-compliant registry) before you run the oc ibm-pak get command. The command sets 'IBM Cloud-Pak OCI registry' as the default repository."
  oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable

  echo "#### 2c. List all the available CASE files to download by running the following command"
  oc ibm-pak list

  echo "#### 2d. Get the cp4ba-case-to-be-mirrored.txt file, or an interim fix, from the Cloud Pak for Business Automation CASE images technote, and rename the file to cp4ba-case-to-be-mirrored.txt."
  curl -L ${CASE_TO_BE_MIRRORED_URL} -o cp4ba-case-to-be-mirrored.txt

  # Sometimes the download in the previous step fails so put the download in a while loop until successful
  echo "#### Extra: 2d. Check cp4ba-case-to-be-mirrored.txt is correct"
  while [ true ]
  do
    grep "ibm-licensing" cp4ba-case-to-be-mirrored.txt
    if [ $? -eq 0 ]; then
      echo "#### Extra: 2d. cp4ba-case-to-be-mirrored.txt download SUCCEEDED"
      break
    else
      echo "#### Extra: 2d. cp4ba-case-to-be-mirrored.txt download FAILED, trying again."
      curl -L curl -L ${CASE_TO_BE_MIRRORED_URL} -o cp4ba-case-to-be-mirrored.txt
    fi
  done

  echo "#### 2e. Download of the CASE files for ${INSTALLTYPE}"
  oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored.txt # CP4BA

  echo "#### 2f. List the versions of all the downloaded CASE files."
  oc ibm-pak list --downloaded

  echo "#### Extra: 2f. Check that download list actaully contains something"
  while [ true ]
  do
    oc ibm-pak list --downloaded | grep "ibm-cp-automation"
    if [ $? -eq 0 ]; then
      echo "#### Extra: 2e. cp4ba-case-to-be-mirrored.txt download SUCCEEDED"
      break
    else
      echo "#### Extra: 2e. cp4ba-case-to-be-mirrored.txt download FAILED, trying again."
      oc ibm-pak get -c file:///root/private_registry-main/cp4ba-case-to-be-mirrored.txt
    fi
  done

else # Helm install, not CP4BA install
  echo "#### Extra: Install type is: ${INSTALLTYPE}"
  echo "#### 1. Create the following environment variables with the CASE name and version"
  # Done in 02_setup_env.sh

  echo "#### 2. Connect your host to the internet."
  # Nothing to script

  echo "#### 3. Optionally, set the locale by running the following command. The ibm-pak plug-in can detect the locale of your environment and provide textual help and messages accordingly."
  # oc ibm-pak config locale -l LOCALE

  echo "#### 4. Configure the plug-in to download the CASE files as OCI artifacts from IBM Cloud Container Registry (ICCR)."
  oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable
  
  echo "#### 5. Download of the CASE files for ${INSTALLTYPE}"
  oc ibm-pak get $CASE_NAME --version $CASE_VERSION
  tree ~/.ibm-pak/data/cases/$CASE_NAME/$CASE_VERSION

fi