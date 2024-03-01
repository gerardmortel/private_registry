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
export CPFS_VERSION="" # e.g. 4-4
export XDG_RUNTIME_DIR="/run/user/$UID"
# export REGISTRY_AUTH_FILE="$HOME/.docker/config.json" # Use this for docker
export REGISTRY_AUTH_FILE="${XDG_RUNTIME_DIR}/containers/auth.json" # Use this for podman
export REGISTRY_AUTH_FILE=""
export ICR_USERNAME=""
export API_KEY_GENERATED="" # Get entitlement key from https://myibm.ibm.com/products-services/containerlibrary
export NAMESPACE=""
export CLUSTER_USER=""
export CLUSTER_PASS=""
export CLUSTER_URL=""
export INSTALLTYPE="" # cp4ba or helm
export IBMPAKVERSION=""
export IBMPAK_HOME="" # e.g. /root/2302