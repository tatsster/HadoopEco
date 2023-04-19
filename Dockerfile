FROM ubuntu:20.04

# Set the timezone to avoid the prompt during the installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y wget openjdk-8-jdk bash curl tar gnupg vim \
    openssh-client openssh-server rsync python3.8-dev python3-distutils python3-pip maven && \
    apt-get clean
RUN pip3 install --upgrade pip setuptools\
    && rm -rf /var/cache/apk/*

# Install Java 8
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV PATH $PATH:$JAVA_HOME/bin

# Install Hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-2.10.1/hadoop-2.10.1.tar.gz && \
    tar -xzf hadoop-2.10.1.tar.gz && \
    rm hadoop-2.10.1.tar.gz && \
    mv hadoop-2.10.1 /usr/local/hadoop
COPY conf/core-site.xml /usr/local/hadoop/etc/hadoop/
COPY conf/hdfs-site.xml /usr/local/hadoop/etc/hadoop/
COPY conf/mapred-site.xml /usr/local/hadoop/etc/hadoop/
COPY conf/yarn-site.xml /usr/local/hadoop/etc/hadoop/
COPY conf/hadoop-env.sh /usr/local/hadoop/etc/hadoop/
RUN mkdir -p /usr/local/hadoop/logs && \
    chmod -R 777 /usr/local/hadoop/logs
# HDFS DataNode data transfer
EXPOSE 50010      
# HDFS DataNode metadata operations
EXPOSE 50020      
# HDFS DataNode web UI
EXPOSE 50060      
# HDFS SecondaryNameNode web UI
EXPOSE 50070      
# HDFS DataNode HTTP web UI
EXPOSE 50075      
# HDFS NameNode metadata backup service
EXPOSE 50090      
# HDFS NameNode metadata service
EXPOSE 8020       
# YARN ResourceManager scheduler
EXPOSE 8032       
# YARN ResourceManager web UI
EXPOSE 8088
# HDFS NameNode web UI
EXPOSE 10070   
# Set Hadoop environment variables
ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Install MapReduce JobHistory server
RUN mkdir -p /usr/local/hadoop/logs/history && \
    chmod -R 777 /usr/local/hadoop/logs/history
# MapReduce Shuffle
EXPOSE 50030      
# MapReduce JobTracker
EXPOSE 10020    
# MapReduce JobHistory web UI
EXPOSE 19888    

# Install Hive
RUN wget https://archive.apache.org/dist/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz \
    && tar -xzf apache-hive-2.3.9-bin.tar.gz \
    && mv apache-hive-2.3.9-bin /usr/local/hive && \
    rm apache-hive-2.3.9-bin.tar.gz
# Configure Hive
COPY conf/hive-site.xml /usr/local/hive/conf/
# Set Hive environment variables
ENV HIVE_HOME /usr/local/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH=$PATH:$HIVE_HOME/bin

# Install MySQL and set up Hive metastore
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.28.tar.gz && \
    tar -xzf mysql-connector-java-8.0.28.tar.gz && \
    mv mysql-connector-java-8.0.28/mysql-connector-java-8.0.28.jar /usr/local/hive/lib/ && \
    rm -rf mysql-connector-java-8.0.28.tar.gz mysql-connector-java-8.0.28/

RUN apt-get update && \
    apt-get install -y mysql-server && \
    apt-get clean
COPY metastore/ /usr/local/hive/scripts/metastore/upgrade/mysql/

# Start MySQL
RUN usermod -d /var/lib/mysql/ mysql && \
    service mysql start && \
    mysql -u root -e "CREATE DATABASE metastore;" && \
    mysql -u root -e "CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost';" && \
    mysql -u root -e "FLUSH PRIVILEGES;" && \
    schematool --verbose -initSchema -dbType mysql
# HiveServer2
EXPOSE 10000  
# Hive Metastore service
EXPOSE 10002      
# Hive Metastore port
EXPOSE 9083
# HiveServer2 thrift API
# EXPOSE 16000       
# HiveServer2 Thrift service
EXPOSE 60000

# Install Oozie
RUN wget https://archive.apache.org/dist/oozie/5.2.0/oozie-5.2.0.tar.gz && \
    tar -xzf oozie-5.2.0.tar.gz && \
    rm oozie-5.2.0.tar.gz && \
    mv oozie-5.2.0 /usr/local/oozie
COPY conf/oozie-site.xml /usr/local/oozie/conf/
RUN mkdir -p /usr/local/oozie/logs && \
    chmod -R 777 /usr/local/oozie/logs
# Oozie web UI
EXPOSE 11000      
# Oozie service
EXPOSE 11002   
# Set Oozie environment variables
ENV OOZIE_HOME /usr/local/oozie
ENV OOZIE_URL=http://localhost:11000/oozie
ENV PATH=$PATH:$OOZIE_HOME/bin   

# Install Sqoop
RUN wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -xzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

# Install Spark
RUN wget https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop2.7.tgz && \
    tar -xzf spark-3.1.2-bin-hadoop2.7.tgz && \
    rm spark-3.1.2-bin-hadoop2.7.tgz && \
    mv spark-3.1.2-bin-hadoop2.7 /usr/local/spark
COPY conf/spark-env.sh /usr/local/spark/conf/
COPY conf/spark-defaults.conf /usr/local/spark/conf/
RUN mkdir -p /usr/local/spark/logs && \
    chmod -R 777 /usr/local/spark/logs
# Spark Master web UI
EXPOSE 8080       
# Spark Worker web UI
EXPOSE 8081       
# Spark Master RPC
EXPOSE 10002      
# Spark Worker RPC
EXPOSE 10004      
# Spark BlockManager
EXPOSE 10008      
# Spark Executor
EXPOSE 10010      
# Spark History Server
EXPOSE 18080      
# Spark REST server
EXPOSE 10012      
# Spark Thrift server
EXPOSE 10014     
# Set Spark environment variables
ENV SPARK_HOME /usr/local/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin 

# Install Zookeeper
RUN wget https://archive.apache.org/dist/zookeeper/zookeeper-3.6.3/apache-zookeeper-3.6.3-bin.tar.gz && \
    tar -xzf apache-zookeeper-3.6.3-bin.tar.gz && \
    rm apache-zookeeper-3.6.3-bin.tar.gz && \
    mv apache-zookeeper-3.6.3-bin /usr/local/zookeeper
COPY conf/zoo.cfg /usr/local/zookeeper/conf/
RUN mkdir -p /usr/local/zookeeper/data && \
    chmod -R 777 /usr/local/zookeeper/data && \
    mkdir -p /usr/local/zookeeper/logs && \
    chmod -R 777 /usr/local/zookeeper/logs
# ZooKeeper client connection port
EXPOSE 2181   
# Set ZooKeeper environment variables
ENV ZOOKEEPER_HOME /usr/local/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin

# Install HBase
RUN wget https://archive.apache.org/dist/hbase/2.4.8/hbase-2.4.8-bin.tar.gz && \
    tar -xzf hbase-2.4.8-bin.tar.gz && \
    rm hbase-2.4.8-bin.tar.gz && \
    mv hbase-2.4.8 /usr/local/hbase
COPY conf/hbase-site.xml /usr/local/hbase/conf/
RUN mkdir -p /usr/local/hbase/logs && \
    chmod -R 777 /usr/local/hbase/logs
# HBase Master web UI
EXPOSE 16010      
# HBase RegionServer web UI
EXPOSE 16020      
# HBase REST server
EXPOSE 16030      
# HBase Thrift service
EXPOSE 17000      
# HBase RegionServer RPC
EXPOSE 60010      
# HBase RegionServer web UI
EXPOSE 60020      
# HBase RegionServer info port
EXPOSE 60030
# Set HBase environment variables
ENV HBASE_HOME /usr/local/hbase
ENV PATH=$PATH:$HBASE_HOME/bin      

# Install dependencies
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

ENV PYTHON_VER=python3.8
# RUN apt-get install -y software-properties-common && \
#     add-apt-repository universe
RUN apt-get update && \
    apt-get install -y git ant gcc g++ libffi-dev libkrb5-dev libmysqlclient-dev \
    libsasl2-dev libsasl2-modules-gssapi-mit libsqlite3-dev libssl-dev libxml2-dev \
    libxslt-dev make libldap2-dev libgmp3-dev && \
    apt-get clean
RUN pip3 install future
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs
# Install dependencies for npm packages
RUN apt-get install -y build-essential
# Install global npm packages
RUN npm install -g nodemon
# Install npm packages
RUN npm install
# RUN apt-get install -y libnode64 libnode-dev build-essential checkinstall node-gyp && \
#     apt-get install -y --fix-missing npm && npm install --global npm

# Install Hue
RUN git clone https://github.com/cloudera/hue.git && \
    cd hue && \
    make apps
COPY conf/pseudo-distributed.ini /usr/local/hue/desktop/conf/
EXPOSE 8000
ENV HUE_HOME /usr/local/hue
ENV PATH=$PATH:$HUE_HOME/bin

# SSH
EXPOSE 22

COPY conf/bootstrap.sh /
CMD ["/bin/bash", "/bootstrap.sh"]