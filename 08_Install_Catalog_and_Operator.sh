#!/bin/bash

#########################################################################################
#####                                                                               #####
#####           Installing the Cloud Pak catalog and an operator instance           #####
#####                                                                               #####
#########################################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-installing-cloud-pak-catalog-operator-instance

echo "#### 1. Go to the namespace for the Cloud Pak operator that you created in Mirroring images to a private registry"
oc project ${CPBANAMESPACE}

echo "#### 2. Set the environment variable of the --inventory parameter"
echo "#### 2. CASE_INVENTORY_SETUP=${CASE_INVENTORY_SETUP}"

echo "### 3. Create and configure a catalog source."
cat $HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/catalog-sources.yaml | sed "s/opencloud-operators/opencloud-operators-v$CPFS_VERSION/g" | oc apply -f -

echo "#### 4. Verify that the CatalogSource for Cloud Pak for Business Automation and its dependencies are created."
echo "#### 4. Check that the following pods are recently created."
echo "#### Extra: 4. sleep 20 seconds to let the catalog source creation to spin up pods"
sleep 20

while [ true ]
do
  oc get pods -n openshift-marketplace
  echo "#### Extra: 4. Check if the number of not ready pods is greater than zero."
  if [[ $(oc get pods -n openshift-marketplace | grep -v NAME | grep -v Completed | awk '{print $2}' | grep -v "1/1" | wc -l) -gt 0 ]]; then
    echo "#### Extra: 4. Not all pods in openshift-marketplace are ready, sleep for 10 seconds."
    sleep 10
  else
    echo "#### Extra: 4. All pods in openshift-marketplace are ready."
    break
  fi
done

echo "#### 4. Check that the following catalog sources are recently created:"
# To Do: while loop until the catalog sources are created
oc get catalogsource -n openshift-marketplace

echo "#### 5. A script must be run to install IBM License Service and IBM Certificate Manager"
echo "#### 5a. Clone the ibm-common-service-operator scripts from Git to a client of your target cluster."
git clone -b scripts https://github.com/IBM/ibm-common-service-operator.git

echo "#### 5a. Go to the ibm-common-service-operator/cp3pt0-deployment directory."
# cd cert-kubernetes/scripts/cpfs/installer_scripts/cp3pt0-deployment
cd ibm-common-service-operator/cp3pt0-deployment

echo "#### 5b. Log in to the target cluster from a client."
oc login ${CLUSTER_URL} --username=${CLUSTER_USER} --password=${CLUSTER_PASS} --insecure-skip-tls-verify

echo "#### 5c. Run the command to install IBM License Service and IBM Certificate Manager"
./setup_singleton.sh --enable-licensing --license-accept

echo "#### 6. Install the Cloud Pak operator."
oc ibm-pak launch $CASE_NAME \
--version $CASE_VERSION \
--inventory $CASE_INVENTORY_SETUP \
--action install-operator \
--namespace $NAMESPACE 

echo "#### 7. Verify that the operators are installed."
echo "#### 7a. Run the commands to check your cluster:"
oc get pods -n $NAMESPACE

echo "#### 7b. If you set any subscriptions to manual, then you must approve any pending operator updates. It is not recommended to set subscriptions to manual "
echo "#### 7b. because it can make the installation error prone when some of the dependency operators are not approved. By default, all subscriptions are set to "
echo "#### 7b. automatic."
oc get subscriptions.operators.coreos.com -n $NAMESPACE

echo "#### 7b. Check for subscriptions that are waiting for approval, get the install plans by running the following command."
oc get installPlan

echo "#### 7c. Check cluster service version"
oc get csv -n $NAMESPACE

echo "#### 7d. Monitor the operator logs with the following command."
# oc logs -f deployment/ibm-cp4a-operator -c operator

# Delete catalog sources
#  cat $HOME/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/catalog-sources.yaml | sed "s/opencloud-operators/opencloud-operators-v$CPFS_VERSION/g" | oc delte -f -