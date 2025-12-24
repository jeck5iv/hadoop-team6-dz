#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

bash ./01_postgres_dn01.sh
bash ./02_hive_nn.sh
bash ./03_copy_hive_to_jn.sh
bash ./04_load_data_to_hdfs.sh
bash ./05_test_beeline.sh
