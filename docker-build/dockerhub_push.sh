#!/bin/bash

# push to dockerhub

# Hadoop
docker push t4tsster/hadoop_cluster:hadoop

# Spark
docker push t4tsster/hadoop_cluster:spark

# PostgreSQL Hive Metastore Server
docker push t4tsster/hadoop_cluster:postgresql-hms

# Hive
docker push t4tsster/hadoop_cluster:hive

# Nifi
docker push t4tsster/hadoop_cluster:nifi

# Edge
docker push t4tsster/hadoop_cluster:edge

# hue
docker push t4tsster/hadoop_cluster:hue

# zeppelin
docker push t4tsster/hadoop_cluster:zeppelin
