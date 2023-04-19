#!/bin/bash

# Start SSH, MySQL
service ssh start
service mysql start

# Start ZooKeeper
echo "Starting ZooKeeper..."
/opt/zookeeper/bin/zkServer.sh start

# Start Hadoop HDFS NameNode
echo "Starting Hadoop HDFS NameNode..."
/usr/local/hadoop/sbin/hadoop-daemon.sh --config /usr/local/hadoop/etc/hadoop/ --script hdfs start namenode

# Start Hadoop HDFS DataNode
echo "Starting Hadoop HDFS DataNode..."
/usr/local/hadoop/sbin/hadoop-daemon.sh --config /usr/local/hadoop/etc/hadoop/ --script hdfs start datanode

# Format Hadoop HDFS
echo "Formatting Hadoop HDFS..."
/usr/local/hadoop/bin/hdfs namenode -format

# Start Hadoop YARN ResourceManager
echo "Starting Hadoop YARN ResourceManager..."
/usr/local/hadoop/sbin/yarn-daemon.sh --config /usr/local/hadoop/etc/hadoop/ start resourcemanager

# Start Hadoop YARN NodeManager
echo "Starting Hadoop YARN NodeManager..."
/usr/local/hadoop/sbin/yarn-daemon.sh --config /usr/local/hadoop/etc/hadoop/ start nodemanager

# Start Hive Metastore
echo "Starting Hive Metastore..."
/usr/local/hive/bin/hive --service metastore &

# Start Oozie
echo "Starting Oozie..."
/usr/local/oozie/bin/oozied.sh start

# Start Spark Master
echo "Starting Spark Master..."
/usr/local/spark/sbin/start-master.sh

# Start Spark Worker
echo "Starting Spark Worker..."
/usr/local/spark/sbin/start-worker.sh spark://localhost:7077

# Start Sqoop Server
echo "Starting Sqoop Server..."
/usr/local/sqoop/bin/sqoop.sh server start

# Start HBase
echo "Starting HBase..."
/usr/local/hbase/bin/start-hbase.sh

# Start Hue Server
echo "Starting Hue..."
/usr/local/hue/bin/hue runserver

# Keep the container running
echo "Ready to serve requests."
tail -f /dev/null
