# Развертывание YARN

## 1. Цель
Необходимо создать условия для распределенных вычислений: реализовать развертывание YARN и опубликовать веб-интерфейсы основных и вспомогательных демонов кластера для внешнего использования:
- [x] 1 ResourceManager
- [x] 1 HistoryServer
- [x] 3 NodeManager

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
- [x] Настроена конфигурация Hadoop

### 2.3 Сетевая конфигурация
| Хостнейм | IP адрес | Роль | Назначение |
|----------|----------|------|------------|
| jn | 192.168.1.26 | EdgeNode | Шлюз, управление |
| nn | 192.168.1.27 | NameNode | Управление метаданными HDFS |
| dn-00 | 192.168.1.28 | DataNode | Хранение данных |
| dn-01 | 192.168.1.29 | DataNode | Хранение данных |

---

 ## 3. Выполнение работы

### 3.1 Подготовка окружения

**1)** Настройка конфигурации для YARN с указанием необходимых библиотек, переменных окружения, описанием адресов для работы распределенных вычислений и shuffle

```bash
# Заходим на NameNode через пользователя hadoop
ssh team@176.109.91.8 
sudo -i -u hadoop
ssh tmpl-nn
```

```bash
# Настраиваем конфигурации для YARN
cd hadoop-3.4.0/etc/hadoop/
vim yarn-site.xml
```
```xml
<configuration>

    <property>
      <name>yarn.application.classpath</name>
      <value>
            $HADOOP_HOME/etc/*,
            $HADOOP_HOME/etc/hadoop/*,
            $HADOOP_HOME/lib/*,
            $HADOOP_HOME/share/hadoop/common/*,
            $HADOOP_HOME/share/hadoop/common/lib/*,
            $HADOOP_HOME/share/hadoop/hdfs/*,
            $HADOOP_HOME/share/hadoop/hdfs/lib/*,
            $HADOOP_HOME/share/hadoop/mapreduce/*,
            $HADOOP_HOME/share/hadoop/mapreduce/lib/*,
            $HADOOP_HOME/share/hadoop/yarn/*,
            $HADOOP_HOME/share/hadoop/yarn/lib/*
      </value>
    </property>

    <property>
      <name>yarn.resourcemanager.hostname</name>
      <value>192.168.1.27</value>
    </property>
    <property>
      <name>yarn.resourcemanager.address</name>
      <value>192.168.1.27:8032</value>
    </property>
    <property>
      <name>yarn.resourcemanager.resource-tracker.address</name>
      <value>192.168.1.27:8031</value>
    </property>

    <property>
      <name>yarn.nodemanager.aux-services</name>
      <value>mapreduce_shuffle</value>
    </property>

    <property>
      <name>yarn.nodemanager.env-whitelist</name>
      <value>JAVA_HOME,HADOOP_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTACHE,HADOOP_MAPRED_HOME,HADOOP_TARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>

</configuration>
```

**2)** Настройка конфигурации для MapReduce с указанием необходимых библиотек, переменных окружения, фреймворка YARN, исполняемых файлов при дистрибутиве Hadoop и свойств для хранения истории MapReduce

```bash
vim mapred-site.xml
```
```xml
<configuration>

  <property>
    <name>yarn.application.classpath</name>
    <value>
          $HADOOP_HOME/etc/*,
          $HADOOP_HOME/etc/hadoop/*,
          $HADOOP_HOME/lib/*,
          $HADOOP_HOME/share/hadoop/common/*,
          $HADOOP_HOME/share/hadoop/common/lib/*,
          $HADOOP_HOME/share/hadoop/hdfs/*,
          $HADOOP_HOME/share/hadoop/hdfs/lib/*,
          $HADOOP_HOME/share/hadoop/mapreduce/*,
          $HADOOP_HOME/share/hadoop/mapreduce/lib/*,
          $HADOOP_HOME/share/hadoop/yarn/*,
          $HADOOP_HOME/share/hadoop/yarn/lib/*
    </value>
  </property>


  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>


  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop-3.4.0</value>
  </property>
  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop-3.4.0</value>
  </property>

  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop-3.4.0</value>
  </property>


  <property>
    <name>mapreduce.jobhistory.done-dir</name>
    <value>/mr-history/done</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.intermediate-done-dir</name>
    <value>/mr-history/tmp</value>
  </property>
  <property>
    <name>yarn.log.server.url</name>
    <value>http://176.109.91.8:19888/jobhistory/logs</value>
  </property>

</configuration>
```

**3)** Копирование файлов конфигураций на DataNode-00 и DataNode-01

```bash
# Копирование yarn-site.xml на обе DataNode
scp yarn-site.xml tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp yarn-site.xml tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

# Копирование mapred-site.xml на обе DataNode
scp mapred-site.xml tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp mapred-site.xml tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop
```

**4)** Добавление сервиса HistoryServer
```bash
# Запускаем YARN
cd ../../
sbin/start-yarn.sh

# Добавляем HistoryServer
mapred --daemon start historyserver

# Проверка результатов на узлах

# На NameNode
jps
# ResourceManager, NodeManager, JobHistoryServer, NameNode, SecondaryNameNode, DataNode

# На DataNode-00
ssh tmpl-dn-00
# NodeManager, DataNode
exit

# На DataNode-01
ssh tmpl-dn-01
# NodeManager, DataNode
exit
```