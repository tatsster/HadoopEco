#!/usr/bin/env bash

# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME. All others are
# optional. When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# The maximum amount of heap to use, in MB. Default is 1000.
export HADOOP_HEAPSIZE=2048

# Extra Java runtime options.
#export HADOOP_OPTS=

# Command specific options appended to HADOOP_OPTS when specified
export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HADOOP_DATANODE_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HADOOP_BALANCER_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HADOOP_JOBTRACKER_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
export HADOOP_TASKTRACKER_OPTS="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

# Where log files are stored. $HADOOP_HOME/logs by default.
export HADOOP_LOG_DIR=/var/log/hadoop

# Where log files are stored in the container.
export HADOOP_CONTAINER_LOG_DIR=/var/log/hadoop

# The directory where pid files are stored. /tmp by default.
export HADOOP_PID_DIR=/var/run/hadoop

# A string representing this instance of hadoop. $USER by default.
export HADOOP_IDENT_STRING=root

# The scheduling priority for daemon processes. See 'man nice'.
export HADOOP_NICENESS=0
