#!/bin/bash

####################################################################
#####                                                          #####
##### Setting up a host to mirror images to a private registry #####
#####                                                          #####
####################################################################
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.1?topic=deployment-setting-up-host-mirror-images-private-registry

echo "#### 1. Install the oc OCP CLI tool. For more information, see OCP CLI tools."
curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz -o openshift-client-linux-${OCP_VERSION}.tar.gz

echo "#### 1a. Extra: Untar oc tar"
tar -xzvf openshift-client-linux-${OCP_VERSION}.tar.gz

echo "#### 1b. Extra: Move oc to /usr/local/bin"
mv oc /usr/local/bin/
chmod +x /usr/local/bin/oc
oc version

echo "#### 1c. Extra: Move kubectl to /usr/local/bin"
mv kubectl /usr/local/bin/
chmod +x /usr/local/bin/kubectl
kubectl version

echo "#### 2. Install Podman on an RHEL machine. For more information, see Podman installation instructions."
yum install -y git unzip podman

echo "#### 3a. Download and install the most recent version of the IBM Catalog Management Plug-in"
curl -L ${IBMPAKVERSION} -o oc-ibm_pak-linux-amd64.tar.gz

echo "#### 3b. Untar IBM Catalog Management Plug-in"
tar -zxvf oc-ibm_pak-linux-amd64.tar.gz

echo "#### 3c. Move oc-ibmpak to /usr/local/bin"
mv oc-ibm_pak-linux-amd64 /usr/local/bin/oc-ibm_pak
oc-ibm_pak --version

echo "#### 3d. Confirm ibm-pak is installed"
oc ibm-pak --help

echo "#### 4. Make sure that the following network ports are available on the host."
# *.icr.io:443 for the IBM Entitled Registry.
# *.quay.io:443 for foundational services. For more information, see Important firewall changes for customers pulling container images.
# github.com for CASE and tools.
# redhat.com for OpenShift upgrades.

# Tip: If the bastion host is unable to retrieve the source images from the public registries, you might need to allow specific access to these sites. 
# A HTTP 403 response is an indication of such a parsing error. Docker and quay image registries might use proxies or mirror sites, so if you see images 
# blocked check whether it is related to one of these image registries. If one of the registries is blocked, you must add that URL to the website allowlist. 
# The following websites can be added to the allowlist to prevent pulling image errors.

# cp.icr.io/cp
# *.quay.io/opencloudio
# *.icr.io/cpopen