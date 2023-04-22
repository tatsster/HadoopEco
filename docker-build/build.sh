#!/bin/bash

# generate ssh key
echo "Y" | ssh-keygen -t rsa -P "" -f configs/id_rsa

# Hadoop build
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH = "amd64"
fi
docker build -f ./hadoop/Dockerfile --build-arg ARCH=$ARCH . -t t4tsster/hadoop_cluster:hadoop 

# Spark
docker build -f ./spark/Dockerfile . -t t4tsster/hadoop_cluster:spark

# PostgreSQL Hive Metastore Server
docker build -f ./postgresql-hms/Dockerfile . -t t4tsster/hadoop_cluster:postgresql-hms

# Hive
docker build -f ./hive/Dockerfile . -t t4tsster/hadoop_cluster:hive

# Nifi
docker build -f ./nifi/Dockerfile --build-arg ARCH=$ARCH . -t t4tsster/hadoop_cluster:nifi

# Edge
docker build -f ./edge/Dockerfile . -t t4tsster/hadoop_cluster:edge

# hue
docker build -f ./hue/Dockerfile . -t t4tsster/hadoop_cluster:hue

# zeppelin
docker build -f ./zeppelin/Dockerfile . -t t4tsster/hadoop_cluster:zeppelin
