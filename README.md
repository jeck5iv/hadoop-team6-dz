# Distributed Data Processing Labs

**HDFS · YARN · Hive · Spark · Prefect**

Team coursework on setting up distributed storage, running data-processing jobs and orchestrating repeatable workflows. The repository contains deployment records and shell scripts from a four-machine teaching environment.

## Lab guide

| Stage | Focus | Materials |
| --- | --- | --- |
| Storage | HDFS services, node configuration and replication | [HDFS lab](README_HW2.md) |
| Resource management | YARN and MapReduce configuration | [YARN lab](docs/yarn-lab.md) |
| SQL access | PostgreSQL, Hive metastore, HDFS loading and Beeline | [Lab 3](hw3/README_HW3.md) |
| Distributed computation | Spark configuration and data-processing jobs | [Lab 4](hw4/README_HW4.md) |
| Orchestration | Prefect flow around a Spark job | [Lab 5](hw5/README_HW5.md) |

## Repository structure

Each `hw*/scripts/` directory groups numbered stages with a `99_run_all.sh` orchestration script. `00_vars.sh` holds the environment-specific configuration. Detailed commands and recorded setup steps remain in the corresponding lab notes.

## Reproduction scope

The scripts target the original course cluster and require its hosts, users, service accounts and infrastructure. They have not been executed as part of this documentation update. Read the relevant lab and adapt its environment configuration before attempting a deployment.

This work supports the data-engineering side of larger modelling workflows. For the mathematical and statistical research projects, see [FX signal research](https://github.com/jeck5iv/fx-signal-research) and [short-history forecasting](https://github.com/jeck5iv/highload-context-ensemble-forecasting).
