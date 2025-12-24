#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

if [ ! -d "${SPARK_HOME}/conf" ]; then
  echo "Spark not installed at ${SPARK_HOME}" >&2
  exit 1
fi

PROFILE="${HOME}/.profile"

ensure_line() {
  local line="$1"
  local file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

touch "${PROFILE}"

ensure_line "export SPARK_HOME=${SPARK_HOME}" "${PROFILE}"
ensure_line "export PATH=\$PATH:\$SPARK_HOME/bin" "${PROFILE}"
ensure_line "export HADOOP_HOME=${HADOOP_HOME}" "${PROFILE}"
ensure_line "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" "${PROFILE}"
ensure_line "export HIVE_HOME=${HIVE_HOME}" "${PROFILE}"
ensure_line "export HIVE_CONF_DIR=\$HIVE_HOME/conf" "${PROFILE}"

SPARK_ENV="${SPARK_HOME}/conf/spark-env.sh"
if [ -f "${SPARK_HOME}/conf/spark-env.sh.template" ] && [ ! -f "${SPARK_ENV}" ]; then
  cp "${SPARK_HOME}/conf/spark-env.sh.template" "${SPARK_ENV}"
fi

cat > "${SPARK_ENV}" <<EOF
export JAVA_HOME=${JAVA_HOME}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
export HIVE_CONF_DIR=${HIVE_CONF_DIR}
EOF

cat > "${SPARK_HOME}/conf/spark-defaults.conf" <<EOF
spark.master                     yarn
spark.submit.deployMode          client

spark.sql.catalogImplementation  hive
spark.sql.warehouse.dir          hdfs:///user/hive/warehouse

spark.sql.shuffle.partitions     8
EOF

ln -sf "${HADOOP_CONF_DIR}/core-site.xml"   "${SPARK_HOME}/conf/core-site.xml"
ln -sf "${HADOOP_CONF_DIR}/hdfs-site.xml"   "${SPARK_HOME}/conf/hdfs-site.xml"
ln -sf "${HADOOP_CONF_DIR}/yarn-site.xml"   "${SPARK_HOME}/conf/yarn-site.xml"
ln -sf "${HADOOP_CONF_DIR}/mapred-site.xml" "${SPARK_HOME}/conf/mapred-site.xml"
ln -sf "${HIVE_CONF_DIR}/hive-site.xml"     "${SPARK_HOME}/conf/hive-site.xml"

echo "Configured: ${SPARK_HOME}"
