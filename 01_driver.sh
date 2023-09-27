#!/bin/bash

echo "#### Running the driver file"
. ./02_setup_env.sh
./03_Run_Private_Registry_on_Podman.sh
./04_Configure_Host_to_Mirror_Images.sh
# ./05_Download_CASE_files.sh
# ./06_Mirror_Images_to_Private_Regsistry.sh
# ./07_Install_Catalog_and_Operator