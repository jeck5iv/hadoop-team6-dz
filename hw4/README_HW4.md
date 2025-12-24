# Реализация Apache Spark под управлением YARN

## 1. Цель
Необходимо описать или реализовать использование Apache Spark под управлением YARN для чтения, трансформации и записи данных. Решение должно включать в себя:
- Запуск сессии Apache Spark под управлением YARN, развернутого на кластере из предыдущих заданий
- Подключение к кластеру HDFS, развернутому в предыдущих заданиях
- Использование созданной ранее сессии Spark для чтения данных, которые были предварительно загружены на HDFS
- Применение нескольких трансформаций данных (например, агрегаций или преобразований типов)
- Применение партиционирования при сохранении данных
- Сохранение преобразованных данных как таблицы
- Проверку возможности чтения данных стандартным клиентом hive


---

## 2. Требования

### 2.1 Аппаратные требования
- 4 виртуальные машины
- 2 сетевые карты на EdgeNode для взаимодействия с интернетом и внутренней сетью

### 2.2 Зависимости (из предыдущих заданий)
- HDFS развернут и доступен
- YARN развернут и запущен
- Hive развернут (HiveServer2 доступен), warehouse расположен в HDFS по пути `/user/hive/warehouse`
- Данные размещены в HDFS по пути `/input/data.csv`
- Java 11 установлен

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

**2)** Проверить, что HDFS/YARN/Hive доступны:

```bash
# HDFS
hdfs dfs -ls /

# YARN
yarn node -list

# Hive (HS2 порт 5433)
cd /home/hadoop/apache-hive-4.0.0-alpha-2-bin
bin/beeline -u jdbc:hive2://tmpl-nn:5433 -n hadoop -e "SHOW DATABASES;"
```

---

### 3.2 Установка Apache Spark на EdgeNode

**1)** Скачать дистрибутив Spark (пример: Spark 3.5.x “hadoop3”):

```bash
cd ~
tmux
wget https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz
```

**2)** Распаковать архив и создать удобную ссылку:

```bash
tar -xzf spark-3.5.1-bin-hadoop3.tgz
ln -s spark-3.5.1-bin-hadoop3 spark
```

---

### 3.3 Настройка переменных окружения

**1)** Отредактировать профиль пользователя `hadoop` на EdgeNode:

```bash
vim ~/.profile
```

Добавить в конец (не удаляя существующее из предыдущих заданий):

```bash
# Spark
export SPARK_HOME=/home/hadoop/spark
export PATH=$PATH:$SPARK_HOME/bin

# Hadoop configs
export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# Hive configs
export HIVE_HOME=/home/hadoop/apache-hive-4.0.0-alpha-2-bin
export HIVE_CONF_DIR=$HIVE_HOME/conf
```

Применить:

```bash
source ~/.profile
```

---

### 3.4 Конфигурация Spark для YARN + HDFS + Hive

**1)** Настроить `spark-env.sh`:

```bash
cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh
vim $SPARK_HOME/conf/spark-env.sh
```

Вписать:

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_CONF_DIR=/home/hadoop/hadoop-3.4.0/etc/hadoop
export HIVE_CONF_DIR=/home/hadoop/apache-hive-4.0.0-alpha-2-bin/conf
```

**2)** Создать `spark-defaults.conf`:

```bash
vim $SPARK_HOME/conf/spark-defaults.conf
```

Вписать:

```properties
spark.master                     yarn
spark.submit.deployMode          client

spark.sql.catalogImplementation  hive
spark.sql.warehouse.dir          hdfs:///user/hive/warehouse

spark.sql.shuffle.partitions     8
```

**3)** Подложить конфиги Hadoop/Hive в classpath Spark (симлинки):

```bash
ln -sf $HADOOP_CONF_DIR/core-site.xml    $SPARK_HOME/conf/core-site.xml
ln -sf $HADOOP_CONF_DIR/hdfs-site.xml    $SPARK_HOME/conf/hdfs-site.xml
ln -sf $HADOOP_CONF_DIR/yarn-site.xml    $SPARK_HOME/conf/yarn-site.xml
ln -sf $HADOOP_CONF_DIR/mapred-site.xml  $SPARK_HOME/conf/mapred-site.xml

ln -sf $HIVE_CONF_DIR/hive-site.xml      $SPARK_HOME/conf/hive-site.xml
```

---

### 3.5 Проверка запуска Spark-сессии под управлением YARN

**1)** Запустить интерактивную сессию:

```bash
spark-shell --master yarn
```

**2)** Убедиться, что приложение появилось в YARN:

```bash
yarn application -list
```

**3)** Выйти из spark-shell:

```scala
:quit
```

---

### 3.6 Чтение данных из HDFS, трансформация и запись как таблицы

**1)** Проверить, что файл существует в HDFS:

```bash
hdfs dfs -ls /input
hdfs dfs -head /input/data.csv
```

**2)** Создать PySpark-job:

```bash
vim ~/spark_hw4_etl.py
```

Вставить код:

```python
from pyspark.sql import SparkSession, functions as F

spark = (
    SparkSession.builder
    .appName("hw4_spark_yarn_hdfs_hive")
    .enableHiveSupport()
    .getOrCreate()
)

# 1) чтение из HDFS
df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv("hdfs:///input/data.csv")
)

# 2) несколько трансформаций:
#    - trim строк
#    - агрегация
cols = df.columns
df2 = df
for c in cols:
    if dict(df.dtypes)[c] == "string":
        df2 = df2.withColumn(c, F.trim(F.col(c)))

# Добавление партиционирования по дате загрузки
df2 = (
    df2
    .withColumn("load_dt", F.current_date())
    .withColumn("year", F.year("load_dt"))
    .withColumn("month", F.month("load_dt"))
)

# Пример агрегации по партициям (год/месяц)
agg = (
    df2.groupBy("year", "month")
    .agg(F.count("*").alias("cnt_rows"))
)

# 3) запись партиционированной таблицы Hive
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
```

**3)** Запустить job под YARN:

```bash
spark-submit --master yarn ~/spark_hw4_etl.py
```

---

### 3.7 Проверка чтения таблицы Hive стандартным клиентом

**1)** Подключиться к HiveServer2:

```bash
cd /home/hadoop/apache-hive-4.0.0-alpha-2-bin
bin/beeline -u jdbc:hive2://tmpl-nn:5433 -n hadoop
```

**2)** Выполнить проверки:

```sql
USE test;

SHOW TABLES;
DESCRIBE FORMATTED hw4_result;

SELECT * FROM hw4_result LIMIT 20;
```

---

## 4. Результат
- Spark запускается под управлением YARN
- Данные читаются из HDFS `/input/data.csv`
- Применены трансформации данных (обработка строк и агрегация)
- Результат сохранён партиционированно (`year`, `month`)
- Результат зарегистрирован как Hive-таблица `test.hw4_result`
- Таблица читается через стандартный Hive клиент (beeline)
