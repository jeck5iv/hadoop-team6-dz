# Реализация процесса обработки данных в Prefect (HW5)

## 1. Цель
Реализовать процесс обработки данных в рамках потока Prefect, состоящий из шагов:
1. Запустить сессию Apache Spark под управлением YARN в рамках кластера, развернутого в предыдущих заданиях
2. Подключиться к кластеру HDFS, развернутому в предыдущих заданиях
3. Используя Spark прочитать данные, которые были предварительно загружены на HDFS
4. Выполнить несколько трансформаций данных (например, агрегацию или преобразование типов)
5. Сохранить данные как таблицу

---

## 2. Требования

### 2.1 Аппаратные требования
- 4 виртуальные машины
- 2 сетевые карты на EdgeNode для взаимодействия с интернетом и внутренней сетью

### 2.2 Зависимости (из предыдущих заданий)
- HDFS развернут и доступен
- YARN развернут и запущен
- Hive развернут (HiveServer2 доступен), warehouse расположен в HDFS по пути `/user/hive/warehouse`
- Apache Spark установлен и настроен для работы с YARN/HDFS/Hive (см. HW4)
- Данные размещены в HDFS по пути `/input/data.csv`
- Python 3.12 установлен

### 2.3 Сетевая конфигурация
| Хостнейм | IP адрес | Роль | Назначение |
|----------|----------|------|------------|
| jn | 192.168.1.26 | EdgeNode | Шлюз, управление |
| nn | 192.168.1.27 | NameNode | Управление метаданными HDFS / ResourceManager / HiveServer2 |
| dn-00 | 192.168.1.28 | DataNode | Хранение данных / NodeManager |
| dn-01 | 192.168.1.29 | DataNode | Хранение данных / NodeManager |

---

## 3. Выполнение работы

Все команды ниже выполняются на EdgeNode (tmpl-jn) под пользователем `hadoop`, если не указано иначе.

### 3.1 Подготовка окружения

**1)** Подключиться к кластеру и перейти к пользователю `hadoop`:

```bash
ssh team@176.109.91.8
sudo -i -u hadoop
```

**2)** Проверить доступность HDFS/YARN:

```bash
hdfs dfs -ls /
yarn node -list
```

**3)** Проверить наличие входных данных:

```bash
hdfs dfs -ls /input
hdfs dfs -head /input/data.csv
```

---

### 3.2 Установка Prefect (локальный запуск потока)

Установка выполняется в user-space пользователя `hadoop`.

```bash
python3 -m pip install --user --upgrade pip
python3 -m pip install --user prefect
```

Проверка:

```bash
~/.local/bin/prefect version
```

---

### 3.3 Подготовка Spark job (ETL)

Создать файл:

```bash
vim ~/spark_hw5_etl.py
```

Содержимое:

```python
from pyspark.sql import SparkSession, functions as F

spark = (
    SparkSession.builder
    .appName("hw5_spark_yarn_hdfs_hive")
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
spark.sql("DROP TABLE IF EXISTS test.hw5_result")

(
    agg.write
    .mode("overwrite")
    .format("parquet")
    .partitionBy("year", "month")
    .saveAsTable("test.hw5_result")
)

spark.stop()
```

---

### 3.4 Создание и запуск потока Prefect

**1)** Создать файл потока Prefect:

```bash
vim ~/hw5_flow.py
```

Содержимое:

```python
import os
import subprocess
from prefect import flow, task

SPARK_HOME = os.environ.get("SPARK_HOME", "/home/hadoop/spark")
JOB_PATH = os.environ.get("JOB_PATH", "/home/hadoop/spark_hw5_etl.py")

@task
def check_hdfs():
    p = subprocess.run(["hdfs", "dfs", "-test", "-e", "hdfs:///input/data.csv"])
    if p.returncode != 0:
        raise RuntimeError("Missing hdfs:///input/data.csv")

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
```

**2)** Запустить поток:

```bash
~/.local/bin/python3 ~/hw5_flow.py
```

---

### 3.5 Проверка результата через Hive

```bash
cd /home/hadoop/apache-hive-4.0.0-alpha-2-bin
bin/beeline -u jdbc:hive2://tmpl-nn:5433 -n hadoop -e "
USE test;
SHOW TABLES;
DESCRIBE FORMATTED hw5_result;
SELECT * FROM hw5_result LIMIT 20;
"
```

---

## 4. Результат
В рамках потока Prefect выполняется запуск Spark под управлением YARN, чтение данных из HDFS, трансформация данных и сохранение результата как таблицы Hive `test.hw5_result`.
