#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

cat > "${FLOW_PATH}" <<'PY'
import os
import subprocess
from prefect import flow, task

SPARK_HOME = os.environ.get("SPARK_HOME", "/home/hadoop/spark")
JOB_PATH = os.environ.get("JOB_PATH", "/home/hadoop/spark_hw5_etl.py")
HDFS_INPUT_FILE = os.environ.get("HDFS_INPUT_FILE", "hdfs:///input/data.csv")

@task
def check_hdfs():
    p = subprocess.run(["hdfs", "dfs", "-test", "-e", HDFS_INPUT_FILE])
    if p.returncode != 0:
        raise RuntimeError(f"Missing {HDFS_INPUT_FILE}")

@task
def run_spark():
    cmd = [f"{SPARK_HOME}/bin/spark-submit", "--master", "yarn", JOB_PATH]
    subprocess.run(cmd, check=True)

@flow(name="hw5_prefect_spark_yarn_etl")
def hw5_flow():
    check_hdfs()
    run_spark()

if __name__ == "__main__":
    hw5_flow()
PY

echo "${FLOW_PATH}"
