#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

bash ./01_install_prefect.sh
bash ./02_create_spark_job.sh
bash ./03_create_flow.sh
bash ./04_run_flow.sh
bash ./05_check_hive.sh
