# Install a private registry on OpenShift on Fyre
# https://github.com/gerardmortel/private_registry

# Resources used to create this
# Red Hat OpenShift: How to create and integrate a private registry with stronger security capabilities
# https://www.redhat.com/en/blog/openshift-private-registry

# How to implement a simple personal/private Linux container image registry for internal use
# https://www.redhat.com/sysadmin/simple-container-registry

# Using image pull secrets
# https://docs.openshift.com/container-platform/4.13/openshift_images/managing_images/using-image-pull-secrets.html

# Image configuration resources
# https://docs.openshift.com/container-platform/4.12/openshift_images/image-configuration.html

# Important firewall changes for customers pulling container images
# https://access.redhat.com/announcements/7000333

# Operator installation or upgrade fails with DeadlineExceeded error
# https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.2?topic=issues-operator-installation-upgrade-fails-deadlineexceeded-error

# Purpose
The purpose of this repo is to assist in creating a private registry running on podman on RHEL 9.1

# Prerequisites
1. OpenShift 4.10+ cluster on Fyre
2. NFS Storage configured https://github.com/gerardmortel/nfs-storage-for-fyre
3. Entitlement key https://myibm.ibm.com/products-services/containerlibrary
4. kubectl 1.21+
5. ocp cli
6. podman

# Instructions
1. ssh into the infrastructure node as root (e.g. ssh root@api.slavers.cp.fyre.ibm.com)
2. yum install -y git unzip podman httpd-tools jq
3. cd
4. rm -rf private_registry
5. rm -f main.zip
6. curl -L https://github.com/gerardmortel/private_registry/archive/refs/heads/main.zip -o main.zip
7. unzip main.zip
8. rm -f main.zip
9. cd private_registry
10. STOP! Put your values for ALL VARIABLES inside file 02_setup_env.sh
11. ./01_driver.sh