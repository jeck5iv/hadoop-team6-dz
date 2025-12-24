#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

cat > "${JOB_PATH}" <<'PY'
from pyspark.sql import SparkSession, functions as F

spark = (
    SparkSession.builder
    .appName("hw4_spark_yarn_hdfs_hive")
    .enableHiveSupport()
    .getOrCreate()
)

df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv("hdfs:///input/data.csv")
)

cols = df.columns
df2 = df
for c in cols:
    if dict(df.dtypes)[c] == "string":
        df2 = df2.withColumn(c, F.trim(F.col(c)))

df2 = (
    df2
    .withColumn("load_dt", F.current_date())
    .withColumn("year", F.year("load_dt"))
    .withColumn("month", F.month("load_dt"))
)

agg = (
    df2.groupBy("year", "month")
    .agg(F.count("*").alias("cnt_rows"))
)

spark.sql("CREATE DATABASE IF NOT EXISTS test")
spark.sql("DROP TABLE IF EXISTS test.hw4_result")

(
    agg.write
    .mode("overwrite")
    .format("parquet")
    .partitionBy("year", "month")
    .saveAsTable("test.hw4_result")
)

spark.stop()
PY

echo "Created ${JOB_PATH}"
