#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

ssh "${SSH_USER}@${HN_NN}" bash -lc "'
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y postgresql-client-${PG_VERSION} wget ca-certificates

sudo -i -u ${HADOOP_USER} bash -lc "
set -euo pipefail
cd ~
if [ ! -f \"${HIVE_TGZ}\" ]; then
  wget -O \"${HIVE_TGZ}\" \"${HIVE_URL}\"
fi
if [ ! -d \"${HIVE_HOME}\" ]; then
  tar -xzf \"${HIVE_TGZ}\"
fi

cd \"${HIVE_HOME}/lib\"
if [ ! -f postgresql-42.7.4.jar ]; then
  wget -O postgresql-42.7.4.jar https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
fi
cp -f postgresql-42.7.4.jar \"${HIVE_HOME}/bin\"

mkdir -p \"${HIVE_CONF_DIR}\"
cat > \"${HIVE_CONF_DIR}/hive-site.xml\" <<XML
<configuration>

  <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
  </property>

  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>${WAREHOUSE_DIR}</value>
  </property>

  <property>
    <name>hive.server2.thrift.port</name>
    <value>${HS2_PORT}</value>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://${PG_HOST}:${PG_PORT}/${PG_DB}</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>${PG_USER}</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>${PG_PASSWORD}</value>
  </property>

  <property>
    <name>hive.execution.engine</name>
    <value>mr</value>
  </property>

  <property>
    <name>hive.cbo.enable</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.stats.autogather</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.optimize.ppd</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.optimize.dynamic.partition.pruning</name>
    <value>true</value>
  </property>

</configuration>
XML

touch \"${PROFILE_PATH}\"
grep -q '^export HIVE_HOME=' \"${PROFILE_PATH}\" || echo 'export HIVE_HOME=${HIVE_HOME}' >> \"${PROFILE_PATH}\"
grep -q '^export HIVE_CONF_DIR=' \"${PROFILE_PATH}\" || echo 'export HIVE_CONF_DIR=\$HIVE_HOME/conf' >> \"${PROFILE_PATH}\"
grep -q '^export HIVE_AUX_JARS_PATH=' \"${PROFILE_PATH}\" || echo 'export HIVE_AUX_JARS_PATH=\$HIVE_HOME/lib/*' >> \"${PROFILE_PATH}\"
grep -q ':\$HIVE_HOME/bin' \"${PROFILE_PATH}\" || echo 'export PATH=\$PATH:\$HIVE_HOME/bin' >> \"${PROFILE_PATH}\"

source \"${PROFILE_PATH}\"

hdfs dfs -mkdir -p ${WAREHOUSE_DIR} || true
hdfs dfs -mkdir -p ${TMP_DIR} || true
hdfs dfs -chmod g+w ${TMP_DIR} || true
hdfs dfs -chmod g+w ${WAREHOUSE_DIR} || true

cd \"${HIVE_HOME}\"
if [ ! -f /tmp/hive_schema_inited.flag ]; then
  bin/schematool -dbType postgres -initSchema
  touch /tmp/hive_schema_inited.flag
fi

nohup hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2_e.log &
sleep 2
"
'"
