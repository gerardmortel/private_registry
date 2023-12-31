#!/bin/bash

echo "#### Set up the environment variables"
export PRIVATE_REGISTRY_USERNAME=""
export PRIVATE_REGISTRY_PASSWORD=""
export DOCKER_USERNAME=""
export DOCKER_PASSWORD=""
export OCP_VERSION="" # 4.12.22
export TARGET_REGISTRY=""
export CASE_NAME=""
export CASE_VERSION=""
export CASE_INVENTORY_SETUP=""
export CASE_TO_BE_MIRRORED_URL=""
export REGISTRY_AUTH_FILE=""
export ICR_USERNAME=""
export API_KEY_GENERATED="" # Get entitlement key from https://myibm.ibm.com/products-services/containerlibrary
export NAMESPACE=""
export CLUSTER_USER=""
export CLUSTER_PASS=""
export CLUSTER_URL=""
export INSTALLTYPE="" # cp4ba or helm
export IBMPAKVERSION=""