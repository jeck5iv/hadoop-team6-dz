#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

hdfs dfs -mkdir -p "${HDFS_INPUT_DIR}" >/dev/null 2>&1 || true

if ! hdfs dfs -test -e "${HDFS_INPUT_FILE}"; then
  echo "Missing ${HDFS_INPUT_FILE} in HDFS" >&2
  echo "Place input file there, e.g.: hdfs dfs -put data.csv ${HDFS_INPUT_FILE}" >&2
  exit 1
fi

hdfs dfs -ls "${HDFS_INPUT_DIR}"
