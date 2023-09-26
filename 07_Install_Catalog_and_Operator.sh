#!/bin/bash

#########################################################################################
#####                                                                               #####
#####           Installing the Cloud Pak catalog and an operator instance           #####
#####                                                                               #####
#########################################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-installing-cloud-pak-catalog-operator-instance

echo "#### Go to the namespace for the Cloud Pak operator that you created in Mirroring images to a private registry"
oc project ${CPBANAMESPACE}

echo "#### Set the environment variable of the --inventory parameter"
export CASE_INVENTORY_SETUP=cp4aOperatorSetup

echo "### Create and configure a catalog source."
cat $HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/catalog-sources.yaml | sed 's/opencloud-operators/opencloud-operators-v4-0/g' | oc apply -f -

echo "#### A script must be run to install IBM License Service and IBM Certificate Manager"

echo "#### Clone the ibm-common-service-operator scripts from Git to a client of your target cluster."
git clone -b scripts https://github.com/IBM/ibm-common-service-operator.git

echo "#### Go to the ibm-common-service-operator/cp3pt0-deployment directory."
# cd cert-kubernetes/scripts/cpfs/installer_scripts/cp3pt0-deployment
cd ibm-common-service-operator/cp3pt0-deployment

echo "#### Run the setup command."
./setup_singleton.sh --enable-licensing --license-accept

echo "#### Install the Cloud Pak operator."
oc ibm-pak launch $CASE_NAME \
--version $CASE_VERSION \
--inventory $CASE_INVENTORY_SETUP \
--action install-operator \
--namespace $CP4BANAMESPACE 

# Delete catalog sources
# cat $HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/catalog-sources.yaml | sed 's/opencloud-operators/opencloud-operators-v4-0/g' | oc delte -f -