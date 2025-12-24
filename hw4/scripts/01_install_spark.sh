#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if ! command -v wget >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y wget ca-certificates
  else
    echo "wget not found and sudo unavailable" >&2
    exit 1
  fi
fi

cd /home/hadoop

if [ ! -f "/home/hadoop/${SPARK_TGZ}" ]; then
  wget -O "/home/hadoop/${SPARK_TGZ}" "${SPARK_URL}"
fi

if [ ! -d "${SPARK_DIR}" ]; then
  tar -xzf "/home/hadoop/${SPARK_TGZ}" -C /home/hadoop
fi

if [ -L "${SPARK_HOME}" ] || [ -d "${SPARK_HOME}" ]; then
  rm -rf "${SPARK_HOME}"
fi
ln -s "${SPARK_DIR}" "${SPARK_HOME}"

echo "SPARK_HOME=${SPARK_HOME}"
