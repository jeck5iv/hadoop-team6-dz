#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

ssh "${SSH_USER}@${HN_NN}" bash -lc "'
set -euo pipefail
sudo -i -u ${HADOOP_USER} bash -lc "
set -euo pipefail
cd /home/${HADOOP_USER}
scp -r apache-hive-${HIVE_VERSION}-bin ${HN_JN}:/home/${HADOOP_USER}/
scp ${PROFILE_PATH} ${HN_JN}:${PROFILE_PATH}
"
'"
