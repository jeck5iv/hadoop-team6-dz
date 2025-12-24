#!/usr/bin/env bash
set -euo pipefail

SPARK_VERSION="${SPARK_VERSION:-3.5.1}"
SPARK_TGZ="spark-${SPARK_VERSION}-bin-hadoop3.tgz"
SPARK_URL="${SPARK_URL:-https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TGZ}}"

HADOOP_HOME="${HADOOP_HOME:-/home/hadoop/hadoop-3.4.0}"
HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-${HADOOP_HOME}/etc/hadoop}"

HIVE_HOME="${HIVE_HOME:-/home/hadoop/apache-hive-4.0.0-alpha-2-bin}"
HIVE_CONF_DIR="${HIVE_CONF_DIR:-${HIVE_HOME}/conf}"

SPARK_BASE="${SPARK_BASE:-/home/hadoop}"
SPARK_DIR="${SPARK_DIR:-${SPARK_BASE}/spark-${SPARK_VERSION}-bin-hadoop3}"
SPARK_HOME="${SPARK_HOME:-${SPARK_BASE}/spark}"

HDFS_INPUT_DIR="${HDFS_INPUT_DIR:-/input}"
HDFS_INPUT_FILE="${HDFS_INPUT_FILE:-${HDFS_INPUT_DIR}/data.csv}"

DB_NAME="${DB_NAME:-test}"
TABLE_NAME="${TABLE_NAME:-hw4_result}"

HS2_HOST="${HS2_HOST:-tmpl-nn}"
HS2_PORT="${HS2_PORT:-5433}"
HIVE_JDBC_URL="${HIVE_JDBC_URL:-jdbc:hive2://${HS2_HOST}:${HS2_PORT}/${DB_NAME}}"

JOB_PATH="${JOB_PATH:-/home/hadoop/spark_hw4_etl.py}"

JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}"
