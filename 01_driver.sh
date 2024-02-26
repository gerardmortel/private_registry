#!/bin/bash

echo "#### Running the driver file"
. ./02_setup_env.sh
./03_Set_up_host_to_mirror_images_to_a_private_registry.sh
./04_Set_up_a_private_registry_on_Podman.sh
./05_Download_CASE_files.sh
./06_Mirror_Images_to_Private_Registry.sh
./07_Configure_Secure_Private_Registry.sh
./08_Install_Catalog_and_Operator.sh
# ./09_Configure_Allowed_Registries.sh