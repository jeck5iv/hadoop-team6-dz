#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

bash ./01_install_spark.sh
bash ./02_configure_spark.sh
bash ./03_prepare_hdfs.sh
bash ./04_create_job.sh
bash ./05_run_job.sh
bash ./06_check_hive.sh
