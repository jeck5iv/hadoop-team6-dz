#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if [ ! -f "${JOB_PATH}" ]; then
  echo "Job not found: ${JOB_PATH}" >&2
  exit 1
fi

"${SPARK_HOME}/bin/spark-submit" --master yarn "${JOB_PATH}"
