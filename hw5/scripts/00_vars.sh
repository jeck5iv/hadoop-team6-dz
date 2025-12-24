#!/usr/bin/env bash
set -euo pipefail

HADOOP_HOME="${HADOOP_HOME:-/home/hadoop/hadoop-3.4.0}"
HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-${HADOOP_HOME}/etc/hadoop}"

HIVE_HOME="${HIVE_HOME:-/home/hadoop/apache-hive-4.0.0-alpha-2-bin}"
HIVE_CONF_DIR="${HIVE_CONF_DIR:-${HIVE_HOME}/conf}"

SPARK_HOME="${SPARK_HOME:-/home/hadoop/spark}"
JOB_PATH="${JOB_PATH:-/home/hadoop/spark_hw5_etl.py}"
FLOW_PATH="${FLOW_PATH:-/home/hadoop/hw5_flow.py}"

HDFS_INPUT_FILE="${HDFS_INPUT_FILE:-hdfs:///input/data.csv}"

DB_NAME="${DB_NAME:-test}"
TABLE_NAME="${TABLE_NAME:-hw5_result}"

HS2_HOST="${HS2_HOST:-tmpl-nn}"
HS2_PORT="${HS2_PORT:-5433}"
HIVE_JDBC_URL="${HIVE_JDBC_URL:-jdbc:hive2://${HS2_HOST}:${HS2_PORT}/${DB_NAME}}"

VENV_DIR="${VENV_DIR:-/home/hadoop/venv-prefect}"
PREFECT_BIN="${PREFECT_BIN:-${VENV_DIR}/bin/prefect}"
PY_BIN="${PY_BIN:-${VENV_DIR}/bin/python}"
