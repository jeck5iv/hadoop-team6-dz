#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

"${HIVE_HOME}/bin/beeline" -u "${HIVE_JDBC_URL}" -n hadoop -e "
USE ${DB_NAME};
SHOW TABLES LIKE '${TABLE_NAME}';
DESCRIBE FORMATTED ${TABLE_NAME};
SELECT * FROM ${TABLE_NAME} LIMIT 20;
"
