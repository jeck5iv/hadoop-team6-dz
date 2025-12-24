#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

ssh "${SSH_USER}@${HN_NN}" bash -lc "'
set -euo pipefail

sudo -i -u ${HADOOP_USER} bash -lc "
set -euo pipefail
cd ~
if [ ! -f \"${LOCAL_DATA_NAME}\" ]; then
  wget --no-check-certificate -O \"${LOCAL_DATA_NAME}\" \"${DATA_URL}\"
fi

hdfs dfs -mkdir -p ${HDFS_INPUT_DIR} || true
hdfs dfs -chmod g+w ${HDFS_INPUT_DIR} || true
hdfs dfs -put -f \"${LOCAL_DATA_NAME}\" ${HDFS_INPUT_FILE}

hdfs dfs -ls ${HDFS_INPUT_DIR}
"
'"
