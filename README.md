# Развертывание кластера HDFS

## 1. Цель
Необходимо задокументировать или реализовать автоматизированное развертывание кластера hdfs, включающего в себя 3 DataNode и обязательные для функционирования кластера сервисы: NameNode, Secondary NameNode:
- [x] 1 NameNode
- [x] 1 Secondary NameNode
- [x] 3 DataNode

---

## 2. Требования

### 2.1 Аппаратные требования
- [x] 4 виртуальные машины
- [x] 2 сетевые карты на EdgeNode для взаимодействия с интернетом и внутренней сетью

### 2.2 Сетевая конфигурация
| Хостнейм | IP адрес | Роль | Назначение |
|----------|----------|------|------------|
| jn | 192.168.1.26 | EdgeNode | Шлюз, управление |
| nn | 192.168.1.27 | NameNode | Управление метаданными HDFS |
| dn-00 | 192.168.1.28 | DataNode | Хранение данных |
| dn-01 | 192.168.1.29 | DataNode | Хранение данных |

---

 ## 3. Выполнение работы

### 3.1 Подготовка окружения
- [x] Имеется новый пользователь для управления кластером 
- [x] Имеется SSH-доступ между 4 узлами для нового пользователя
- [x] На каждом узле создан еще один пользователь (hadoop), от имени которого будут выполняться все сервисы
- [x] Скачан дистрибутив Hadoop
- [x] Узлы знают друг друга по именам
- [x] Имеется SSH-доступ между 4 узлами для пользователя hadoop


**1)** Войти на EdgeNode с помощью нового пользователя, сгенерировать SSH-ключ и разложить на все узлы, предварительно добавив новоиспеченный ключ в авторизованные.

```bash
ssh team@176.109.91.8 # Вход на EdgeNode под пользователем team
ssh-keygen # Генерация ключа
vim .ssh/id_ed25519 # Открыть и скопировать ключ
vim .ssh/authorized_keys # Вставить ключ в авторизованные ключи

# Разложить ключ по узлам
scp .ssh/authorized_keys 192.168.1.27:/home/team/.ssh/authorized_keys
scp .ssh/authorized_keys 192.168.1.28:/home/team/.ssh/authorized_keys
scp .ssh/authorized_keys 192.168.1.29:/home/team/.ssh/authorized_keys
```

**2)** Создать пользователя на каждом узле, от имени которого будут выполняться все сервисы

```bash
# На каждом узле, включая EdgeNode, создаем пользователя под именем hadoop с надежным паролем

ssh 192.168.1.26 # Вход на EdgeNode
sudo adduser hadoop # Создание пользователя hadoop
exit # Выход с пользователя hadoop
exit # Выход с EdgeNode

ssh 192.168.1.27 # Вход на NameNode
sudo adduser hadoop # Создание пользователя hadoop
exit # Выход с пользователя hadoop
exit # Выход с NameNode

ssh 192.168.1.28 # Вход на DataNode-00
sudo adduser hadoop # Создание пользователя hadoop
exit # Выход с пользователя hadoop
exit # Выход с DataNode-00

ssh 192.168.1.29 # Вход на DataNode-01
sudo adduser hadoop # Создание пользователя hadoop
exit # Выход с пользователя hadoop
exit # Выход с DataNode-01
```

**3)** Скачать дистрибутив Hadoop, используя пользователя hadoop и сессионный менеджер tmux для фоновой установки

```bash
# Вход на пользователя hadoop в EdgeNode
sudo -i -u hadoop 

# Воспользуемся сесионным менеджером tmux для скачивания Hadoop
tmux # Вход на tmux
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz # Скачивание дистрибутива Hadoop
tmux detach # На время скачивания покинем tmux (Ctrl + B, D)
```

**4)** Редактируем файл /hosts, используя пользователя team для каждого узла, присваиваем имена узлам

```bash
exit # Покидаем пользователя hadoop (используем team, EdgeNode)
sudo vim /etc/hosts # Заходим в файл /hosts

# Присваиваем имена узлам и вставляем в файл
# 192.168.1.26    tmpl-jn
# 192.168.1.27    tmpl-nn
# 192.168.1.28    tmpl-dn-00
# 192.168.1.29    tmpl-dn-01

# Проделываем то же самое для каждого узла

ssh 192.168.1.27 # Заходим на NameNode
sudo vim /etc/hosts # Вставляем имена
exit # Покидаем NameNode

ssh 192.168.1.28 # Заходим на DataNode-00
sudo vim /etc/hosts # Вставляем имена
exit # Покидаем DataNode-00

ssh 192.168.1.29 # Заходим на DataNode-01
sudo vim /etc/hosts # Вставляем имена
exit # Покидаем DataNode-01
```

**5)** Войти на EdgeNode с помощью пользователя hadoop, сгенерировать SSH-ключ и разложить на все узлы, предварительно добавив новоиспеченный ключ в авторизованные.

```bash
sudo -i -u hadoop # Переключаемся на пользователя hadoop
ssh-keygen # Генерация ключа
vim .ssh/id_ed25519 # Открыть и скопировать ключ
vim .ssh/authorized_keys # Вставить ключ в авторизованные ключи

scp -r .ssh/ tmpl-nn:/home/hadoop/
scp -r .ssh/ tmpl-dn-00:/home/hadoop/
scp -r .ssh/ tmpl-dn-01:/home/hadoop/

# Разложить ключ по узлам
scp .ssh/authorized_keys tmpl-nn:/home/hadoop/.ssh/authorized_keys
scp .ssh/authorized_keys tmpl-dn-00:/home/hadoop/.ssh/authorized_keys
scp .ssh/authorized_keys tmpl-dn-01:/home/hadoop/.ssh/authorized_keys
```

### 3.2 Реализация 
- [x] Дистрибутив Hadoop скопирован и распакован на всех узлах пользователя hadoop
- [x] Отредактирован файл profile на NameNode, прописаны HADOOP_HOME, JAVA_HOME и PATH, файл скопирован на DataNode-00 и DataNode-01
- [x] Настроена конфигурация Hadoop
- [x] Указаны демоны
- [x] Произведен запуск

**1)** Проверить установку дистрибутива Hadoop на EdgeNode пользователя hadoop и скопировать его на все остальные узлы

```bash
# Вернемся к последней сессии tmux
tmux attach -t 0

# Скопируем дистрибутив на каждый оставшийся узел
scp hadoop-3.4.0.tar.gz tmpl-nn:/home/hadoop
scp hadoop-3.4.0.tar.gz tmpl-dn-00:/home/hadoop
scp hadoop-3.4.0.tar.gz tmpl-dn-01:/home/hadoop
```

**2)** Распаковать архив с Hadoop на каждый узел пользователя hadoop

```bash
# Распаковка Hadoop на NameNode
ssh tmpl-nn
tar -xzf hadoop-3.4.0.tar.gz
exit

# Распаковка Hadoop на DataNode-00
ssh tmpl-dn-00
tar -xzf hadoop-3.4.0.tar.gz
exit

# Распаковка Hadoop на DataNode-01
ssh tmpl-dn-01
tar -xzf hadoop-3.4.0.tar.gz
exit
```

**3)** Настройка NameNode, копирование пути для Java

```bash
ssh tmpl-nn
java -version # Чтобы узнать версию Java
which java # Путь к Java
#/usr/bin/jav

readlink -f /usr/bin/java # Копируем путь Java
# /usr/lib/jvm/java-11-openjdk-amd64/bin/java
```

**4)** Редактирование файла profile на NameNode, добавление путей HADOOP_HOME, JAVA_HOME и PATH

```bash
# Отредактируем файл profile
vim .profile
# Прописываем пути 
# export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
# export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

source .profile
```

**5)** Копирование отредактировнного profile на DataNode-00 и DataNode-01, чтобы при подключении переменные попадали сразу в окружение

```bash
# Копируем .profile на обе DataNode
scp .profile tmpl-dn-00:/home/hadoop
scp .profile tmpl-dn-01:/home/hadoop
```

**6)** Настройка конфигурации

```bash
cd hadoop-3.4.0/etc/hadoop/
vim hadoop-env.sh
# Прописываем JAVA_HOME
# JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Настройка конфигурации Hadoop

vim core-site.xml
# Прописываем и указываем адрес
# <configuration>
#     <property>
#         <name>fs.defaultFS</name>
#         <value>hdfs://tmpl-nn:9000</value>
#     </property>
# </configuration>

vim hdfs-site.xml
# Прописываем
# <configuration>
#     <property>
#         <name>dfs.replication</name>
#         <value>3</value>
#     </property>
# </configuration>
```

**6)** Настройка демонов DataNode (workers)

```bash
vim workers
# Прописываем имена узлов
# tmpl-nn
# tmpl-dn-00
# tmpl-dn-01
```

**7)** Копирование настроек на DataNode-00 и DataNode-01

```bash
# Копирование hadoop-env.sh на обе DataNode
scp hadoop-env.sh tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hadoop-env.sh tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

# Копирование core-site.xml на обе DataNode
scp core-site.xml tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp core-site.xml tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

# Копирование hdfs-site.xml на обе DataNode
scp hdfs-site.xml tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp hdfs-site.xml tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

# Копирование workers на обе DataNode
scp workers tmpl-dn-00:/home/hadoop/hadoop-3.4.0/etc/hadoop
scp workers tmpl-dn-01:/home/hadoop/hadoop-3.4.0/etc/hadoop

cd ../../
```

**8)** Форматирование NameNode

```bash
bin/hdfs namenode -format
sbin/start-dfs.sh
```

### 3.3 Результат

- [x] tmpl-nn: NameNode, DataNode, SecondaryNameNode
- [x] tmpl-dn-00: DataNode
- [x] tmpl-dn-01: DataNode

```bash
# на NameNode
jps
# Jps, NameNode, DataNode, SecondaryNameNode

# на DataNode-00
ssh tmpl-dn-00
jps
# Jps, DataNode
exit

# на DataNode-01
ssh tmpl-dn-01
jps
# Jps, DataNode
exit
```



