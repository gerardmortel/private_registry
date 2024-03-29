# Install a private registry on OpenShift on Fyre
# https://github.com/gerardmortel/private_registry

# Purpose
The purpose of this repo is to assist in creating a private registry running on podman on RHEL 9.2

# Prerequisites
1. OpenShift 4.12+ cluster on Fyre
2. NFS Storage configured https://github.com/gerardmortel/nfs-storage-for-fyre
3. Entitlement key https://myibm.ibm.com/products-services/containerlibrary

# Instructions
1. ssh into the infrastructure node as root (e.g. ssh root@api.slavers.cp.fyre.ibm.com)
2. yum install -y git unzip podman httpd-tools jq
3. cd
4. rm -rf private_registry-main
5. rm -f main.zip
6. curl -L https://github.com/gerardmortel/private_registry/archive/refs/heads/main.zip -o main.zip
7. unzip main.zip
8. rm -f main.zip
9. cd private_registry-main
10. STOP! Put your values for ALL VARIABLES inside file 02_setup_env.sh
11. ./01_driver.sh | tee install_private_registry.log

# Resources used to create this
[IBM Pak Releases to set variable IBMPAKVERSION](https://github.com/IBM/ibm-pak/releases)

[CP4BA IFIX Download to set CASE_TO_BE_MIRRORED_URL](https://www.ibm.com/support/pages/cloud-pak-business-automation-interim-fix-download-document)

[To get the lastest CASE version for CP4BA](https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cp-automation/index.yaml)

[Red Hat OpenShift: How to create and integrate a private registry with stronger security capabilities](https://www.redhat.com/en/blog/openshift-private-registry)

[How to implement a simple personal/private Linux container image registry for internal use](https://www.redhat.com/sysadmin/simple-container-registry)

[Using image pull secrets](https://docs.openshift.com/container-platform/4.13/openshift_images/managing_images/using-image-pull-secrets.html)

[Image configuration resources](https://docs.openshift.com/container-platform/4.12/openshift_images/image-configuration.html)

[Important firewall changes for customers pulling container images](https://access.redhat.com/announcements/7000333)

[Operator installation or upgrade fails with DeadlineExceeded error](https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.2?topic=issues-operator-installation-upgrade-fails-deadlineexceeded-error)