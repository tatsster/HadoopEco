export SPARK_HOME=/opt/spark-3.2.0-bin-hadoop3.2
export HADOOP_HOME=/opt/hadoop-3.3.1
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)
export SPARK_LOCAL_IP=localhost
