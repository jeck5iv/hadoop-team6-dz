#!/usr/bin/env bash
set -euo pipefail

SSH_USER="${SSH_USER:-team}"

HN_NN="${HN_NN:-tmpl-nn}"
HN_DN01="${HN_DN01:-tmpl-dn-01}"
HN_JN="${HN_JN:-tmpl-jn}"

HADOOP_USER="${HADOOP_USER:-hadoop}"

HIVE_VERSION="${HIVE_VERSION:-4.0.0-alpha-2}"
HIVE_TGZ="apache-hive-${HIVE_VERSION}-bin.tar.gz"
HIVE_URL="${HIVE_URL:-https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/${HIVE_TGZ}}"
HIVE_HOME="${HIVE_HOME:-/home/${HADOOP_USER}/apache-hive-${HIVE_VERSION}-bin}"
HIVE_CONF_DIR="${HIVE_CONF_DIR:-${HIVE_HOME}/conf}"

PG_VERSION="${PG_VERSION:-16}"
PG_DB="${PG_DB:-metastore}"
PG_USER="${PG_USER:-hive}"
PG_PASSWORD="${PG_PASSWORD:-hiveMegaPass}"
PG_HOST="${PG_HOST:-${HN_DN01}}"
PG_PORT="${PG_PORT:-5432}"

HS2_PORT="${HS2_PORT:-5433}"

WAREHOUSE_DIR="${WAREHOUSE_DIR:-/user/hive/warehouse}"
TMP_DIR="${TMP_DIR:-/tmp}"

DATA_URL="${DATA_URL:-https://rospatent.gov.ru/opendata/7730176088-tz/data-20241101-structure-20180828.csv}"
LOCAL_DATA_NAME="${LOCAL_DATA_NAME:-data.csv}"
HDFS_INPUT_DIR="${HDFS_INPUT_DIR:-/input}"
HDFS_INPUT_FILE="${HDFS_INPUT_FILE:-${HDFS_INPUT_DIR}/${LOCAL_DATA_NAME}}"

PROFILE_PATH="${PROFILE_PATH:-/home/${HADOOP_USER}/.profile}"
