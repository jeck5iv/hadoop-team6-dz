#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if [ ! -x "${HIVE_HOME}/bin/beeline" ]; then
  echo "beeline not found at ${HIVE_HOME}/bin/beeline" >&2
  exit 1
fi

"${HIVE_HOME}/bin/beeline" -u "${HIVE_JDBC_URL}" -n hadoop -e "
USE ${DB_NAME};
SHOW TABLES;
DESCRIBE FORMATTED ${TABLE_NAME};
SELECT * FROM ${TABLE_NAME} LIMIT 20;
"
