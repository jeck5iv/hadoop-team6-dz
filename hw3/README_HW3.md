# Реализация Apache Hive

## 1. Цель
Необходимо реализовать развертывание Apache Hive таким образом, чтобы была возможность одновременного его использования более чем одним клиентом (т.е. при установке не использовать embedded подход), реализовать загрузку данных в партиционированную таблицу Hive (рекомендуется использовать версию дистрибутива Hive 4.0.0. alpha2). Необходимо развернуть 2 сервиса:
- [x] база данных PostgreSQL на DataNode-01
- [x] сервер Metastore на NameNode


---

## 2. Требования

### 2.1 Аппаратные требования
- [x] 4 виртуальные машины
- [x] 2 сетевые карты на EdgeNode для взаимодействия с интернетом и внутренней сетью

### 2.2 HDFS
- [x] Имеется новый пользователь для управления кластером 
- [x] Имеется SSH-доступ между 4 узлами для нового пользователя
- [x] На каждом узле создан еще один пользователь (hadoop), от имени которого будут выполняться все сервисы
- [x] Скачан дистрибутив Hadoop
- [x] Имеется SSH-доступ между 4 узлами для пользователя hadoop
- [x] Дистрибутив Hadoop скопирован и распакован на всех узлах пользователя hadoop
- [x] Отредактирован файл profile на NameNode, прописаны HADOOP_HOME, JAVA_HOME и PATH, файл скопирован на DataNode-00 и DataNode-01
- [x] Настроена конфигурация Hadoop и Yarn

### 2.3 Сетевая конфигурация
| Хостнейм | IP адрес | Роль | Назначение |
|----------|----------|------|------------|
| jn | 192.168.1.26 | EdgeNode | Шлюз, управление |
| nn | 192.168.1.27 | NameNode | Управление метаданными HDFS |
| dn-00 | 192.168.1.28 | DataNode | Хранение данных |
| dn-01 | 192.168.1.29 | DataNode | Хранение данных |

---

 ## 3. Выполнение работы

**1)** Установка PostgreSQL на NameNode-01 и создание базы данных и пользователя для подключения к ней.

```bash
ssh team@176.109.91.8 
ssh tmpl-dn-01

sudo apt install postgresql-16 # Устанавливаем PostgreSQL

sudo -i -u postgres # Создаем базу данных
psql
CREATE DATABASE metastore; # Создаем базу данных
CREATE USER hive with PASSWORD '___'; # Создаем пользователя, который сможет к ней подключаться
GRANT ALL PRIVILEGES ON DATABASE "metastore" TO hive; # Даем пользователю все привелегии на базу данных
ALTER DATABASE metastore OWNER to hive; # Сделаем его владельцем
\q
exit # Возвращаемся к пользователю team
```

**2)** Редактирование конфигураций Postgres, чтобы пользователи с других хостов могли к нему подключаться и работать с базой данных

```bash
sudo vim /etc/postgresql/16/main/postgresql.conf
listen_addresses = 'tmpl-dn-01'

sudo vim /etc/postgresql/16/main/pg_hba.conf # Укажем хосты, откуда будут приниматься подключения
host    metastore       hive            192.168.1.27/32         password 
```

```bash
sudo systemctl restart postgresql # Перезапускаем, чтобы изменения вступили в силу
exit
```

**3)** Установка клиента для Postgres на NameNode, установка Hive

```bash
ssh tmpl-nn
sudo apt install postgresql-client-16

sudo -i -u hadoop # Переключаемся на пользователя hadoop

tmux
wget https://archive.apache.org/dist/hive/hive-4.0.0-alpha-2/apache-hive-4.0.0-alpha-2-bin.tar.gz # Скачивание дистрибутива Hive
exit
exit

tmux
wget --no-check-certificate https://rospatent.gov.ru/opendata/7730176088-tz/data-20241101-structure-20180828.csv
exit

ssh tmpl-nn
sudo -i -u hadoop
tmux attach -t 0 # Возвращаемся к скачивающемуся дистрибутиву и ждем завершения установки
tar -xzvf apache-hive-4.0.0-alpha-2-bin.tar.gz # Распаковываем
cd apache-hive-4.0.0-alpha-2-bin/lib
wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar # Добавляем драйвер postgres
cp postgresql-42.7.4.jar ../bin # Скопируем его
cd ../conf/ # Отредактируем конфигурации
vim hive-site.xml # Создадим новый файл для конфигураций
```

```xml
<configuration>

  <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
  <property>
    <name>hive.server2.thrift.port</name>
    <value>5433</value>
    <description>TCP port number to listen on, default 10000</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://tmpl-dn-01:5432/metastore</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hiveMegaPass</value>
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
```

**4)** Добавление переменных окружения в профиль

```bash
cd ../../
vim .profile
export HIVE_HOME=/home/hadoop/apache-hive-4.0.0-alpha-2-bin
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=$HIVE_HOME/lib/*
export PATH=$PATH:$HIVE_HOME/bin

source .profile # Применяем профиль
```

**5)** Создание директории для Warehouse

```bash
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir /tmp # Создадим папку для временных данных
hdfs dfs -chmod g+w /tmp # Изменим разрешение
hdfs dfs -chmod g+w /user/hive/warehouse

# Создадим схему для Hive Metastore
cd apache-hive-4.0.0-alpha-2-bin/
bin/schematool -dbType postgres -initSchema

# Запустим сервис
hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2_e.log

jps
# JobHistoryServer
# ResourceManager
# NameNode
# RunJar
# SecondaryNameNode
# NodeManager
# Jps
# DataNode
```
**6)** Подключение

```bash
# Подключаемся так, чтобы увидеть все наши веб-сервисы
cd apache-hive-4.0.0-alpha-2-bin/
bin/beeline -u jdbc:hive2://localhost:5433 -n hadoop
cd ../
scp -r apache-hive-4.0.0-alpha-2-bin/ tmpl-jn:/home/hadoop
scp .profile tmpl-jn:/home/hadoop # Копируем профиль
exit
exit
exit
ssh -L 10002:192.168.1.27:10002 -L 9870:192.168.1.27:9870 -L 8088:192.168.1.27:8088 -L 19888:192.168.1.27:19888 team@176.109.91.8 
```

**7)** Создаем тестовую базу данных

```bash
sudo -i -u hadoop
cd apache-hive-4.0.0-alpha-2-bin/
bin/beeline -u jdbc:hive2://tmpl-nn:5433

CREATE DATABASE test # Создадим базу данных test;
```

**8)** Создание директории для сырых данных
```bash
mv data-20241101-structure-20180828.csv data.csv # Переименуем ранее скачанный файл

# Размещаем локальные данные на hdfs
hdfs dfs -mkdir /input 
hdfs dfs -chmod g+w /input 

# Перебрасываем наш файл туда
hdfs dfs -put data.csv /input
hdfs fsck /input/data.csv # Можно посмотреть информацию о файле и кластере
head -2 data.csv # Предпросмотр самих данных
```








