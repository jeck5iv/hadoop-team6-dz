#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if [ ! -x "${PY_BIN}" ]; then
  echo "Missing venv python: ${PY_BIN}" >&2
  echo "Run: bash ./01_install_prefect.sh" >&2
  exit 1
fi

SPARK_HOME="${SPARK_HOME}" JOB_PATH="${JOB_PATH}" HDFS_INPUT_FILE="${HDFS_INPUT_FILE}" "${PY_BIN}" "${FLOW_PATH}"
