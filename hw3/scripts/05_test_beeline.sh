#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

ssh "${SSH_USER}@${HN_NN}" bash -lc "'
set -euo pipefail

sudo -i -u ${HADOOP_USER} bash -lc "
set -euo pipefail
cd ${HIVE_HOME}
bin/beeline -u jdbc:hive2://localhost:${HS2_PORT} -n ${HADOOP_USER} -e \\"
CREATE DATABASE IF NOT EXISTS test;
SHOW DATABASES;
\\\"
"
'"
