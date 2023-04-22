#!/bin/bash

psqlhms_ip=""
nodemaster_ip=""
edge_ip=""
zeppelin_ip=""

# Bring the services up
function startServices {
	docker start nodemaster node2 node3
	sleep 5
	echo ">> Starting hdfs ..."
	docker exec -u hadoop -it nodemaster start-dfs.sh
	sleep 5
	echo ">> Starting yarn ..."
	docker exec -u hadoop -d nodemaster start-yarn.sh
	sleep 5
	echo ">> Starting MR-JobHistory Server ..."
	docker exec -u hadoop -d nodemaster mr-jobhistory-daemon.sh start historyserver
	sleep 5
	echo ">> Starting Spark ..."
	docker exec -u hadoop -d nodemaster start-master.sh
	docker exec -u hadoop -d node2 start-slave.sh nodemaster:7077
	docker exec -u hadoop -d node3 start-slave.sh nodemaster:7077
	sleep 5
	echo ">> Starting Spark History Server ..."
	docker exec -u hadoop nodemaster start-history-server.sh
	sleep 5
	echo ">> Preparing hdfs for hive ..."
	docker exec -u hadoop -it nodemaster hdfs dfs -mkdir -p /tmp
	docker exec -u hadoop -it nodemaster hdfs dfs -mkdir -p /user/hive/warehouse
	docker exec -u hadoop -it nodemaster hdfs dfs -chmod g+w /tmp
	docker exec -u hadoop -it nodemaster hdfs dfs -chmod g+w /user/hive/warehouse
	sleep 5
	echo ">> Starting Hive Metastore ..."
	docker exec -u hadoop -d nodemaster hive --service metastore
	docker exec -u hadoop -d nodemaster hive --service hiveserver2
	echo ">> Starting Nifi Server ..."
	docker exec -u hadoop -d nifi /home/hadoop/nifi/bin/nifi.sh start
	echo ">> Starting kafka & Zookeeper ..."
	docker exec -u hadoop -d edge /home/hadoop/kafka/bin/zookeeper-server-start.sh -daemon  /home/hadoop/kafka/config/zookeeper.properties
	docker exec -u hadoop -d edge /home/hadoop/kafka/bin/kafka-server-start.sh -daemon  /home/hadoop/kafka/config/server.properties
	echo ">> Starting Zeppelin ..."
	docker exec -u hadoop -d zeppelin /home/hadoop/zeppelin/bin/zeppelin-daemon.sh start
	echo "Hadoop info @ nodemaster: http://$nodemaster_ip:8088/cluster"
	echo "HDFS info @ nodemaster: http://$nodemaster_ip:9870"
	echo "DFS Health @ nodemaster : http://$nodemaster_ip:50070/dfshealth"
	echo "MR-JobHistory Server @ nodemaster : http://$nodemaster_ip:19888"
	echo "Spark info @ nodemaster  : http://$nodemaster_ip:8080"
	echo "Spark History Server @ nodemaster : http://$nodemaster_ip:18080"
	echo "Hue @ huenode : https://localhost:8888"
	echo "Zookeeper @ edge : http://$edge_ip:2181"
	echo "Kafka @ edge : http://$edge_ip:9092"
	echo "Nifi @ edge : http://$edge_ip:8080/nifi & from host @ http://localhost:8080/nifi"
	echo "Zeppelin @ zeppelin : http://172.20.1.6:8081 & from host @ http://localhost:8081"
}

function stopServices {
	echo ">> Stopping Spark Master and slaves ..."
	docker exec -u hadoop -d nodemaster stop-master.sh
	docker exec -u hadoop -d node2 stop-slave.sh
	docker exec -u hadoop -d node3 stop-slave.sh
	docker exec -u hadoop -d nifi /home/hadoop/nifi/bin/nifi.sh stop
	docker exec -u hadoop -d zeppelin /home/hadoop/zeppelin/bin/zeppelin-daemon.sh stop
	echo ">> Stopping containers ..."
	docker stop nodemaster node2 node3 edge hue nifi zeppelin psqlhms
}

if [[ $1 = "install" ]]; then
	# Starting Postresql Hive metastore
	docker run -d --network=bridge --hostname psqlhms --name psqlhms -e POSTGRES_PASSWORD=hive -it t4tsster/hadoop_cluster:postgresql-hms
	psqlhms_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' psqlhms)

	# 3 hadoop nodes
	echo ">> Starting master and worker nodes ..."
	docker run -d --network=bridge -p 8088:8088 -p 9870:9870 -p 8022:22 -p 8080:8080 -p 18080:18080 -p 19888:19888 --hostname nodemaster --name nodemaster -it t4tsster/hadoop_cluster:hive
	docker run -d --network=bridge --hostname node2 --name node2 -it t4tsster/hadoop_cluster:spark
	docker run -d --network=bridge --hostname node3 --name node3 -it t4tsster/hadoop_cluster:spark
	nodemaster_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nodemaster)
	node2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' node2)
	node3_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' node3)
	docker exec nodemaster sh -c "echo '$node2_ip node2' >> /etc/hosts"
	docker exec nodemaster sh -c "echo '$node3_ip node3' >> /etc/hosts"
	docker exec node2 sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec node2 sh -c "echo '$node3_ip node3' >> /etc/hosts"
	docker exec node3 sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec node3 sh -c "echo '$node2_ip node2' >> /etc/hosts"

	# other nodes
	docker run -d --network=bridge -p 34545:34545 -p 9000:9000 -p 12000:12000 --hostname edge --name edge -it t4tsster/hadoop_cluster:edge 
	edge_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' edge)
	docker exec edge sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec edge sh -c "echo '$node2_ip node2' >> /etc/hosts"
	docker exec edge sh -c "echo '$node3_ip node3' >> /etc/hosts"
	docker exec edge sh -c "echo '$psqlhms_ip psqlhms' >> /etc/hosts"

	docker run -d --network=bridge -p 11000:8080 --hostname nifi --name nifi -it t4tsster/hadoop_cluster:nifi 
	docker exec nifi sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec nifi sh -c "echo '$node2_ip node2' >> /etc/hosts"
	docker exec nifi sh -c "echo '$node3_ip node3' >> /etc/hosts"
	docker exec nifi sh -c "echo '$psqlhms_ip psqlhms' >> /etc/hosts"
	
	docker run -d --network=bridge  -p 8888:8888 --hostname huenode --add-host psqlhms:$psqlhms_ip --name hue -it t4tsster/hadoop_cluster:hue
	docker exec hue sh -c "echo '$edge_ip edge' >> /etc/hosts"
	docker exec hue sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec hue sh -c "echo '$node2_ip node2' >> /etc/hosts"
	docker exec hue sh -c "echo '$node3_ip node3' >> /etc/hosts"
	# docker exec hue sh -c "echo '$psqlhms_ip psqlhms' >> /etc/hosts"

	docker run -d --network=bridge  -p 8081:8081 --hostname zeppelin --name zeppelin -it t4tsster/hadoop_cluster:zeppelin
	zeppelin_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zeppelin)
	docker exec zeppelin sh -c "echo '$edge_ip edge' >> /etc/hosts"
	docker exec zeppelin sh -c "echo '$nodemaster_ip nodemaster' >> /etc/hosts"
	docker exec zeppelin sh -c "echo '$node2_ip node2' >> /etc/hosts"
	docker exec zeppelin sh -c "echo '$node3_ip node3' >> /etc/hosts"
	docker exec zeppelin sh -c "echo '$psqlhms_ip psqlhms' >> /etc/hosts"

	# Format nodemaster
	echo ">> Formatting hdfs ..."
	docker exec -u hadoop -it nodemaster hdfs namenode -format
	startServices
	exit
fi


if [[ $1 = "stop" ]]; then
	stopServices
	exit
fi


if [[ $1 = "uninstall" ]]; then
	stopServices
	docker rmi t4tsster/hadoop_cluster:hadoop t4tsster/hadoop_cluster:spark t4tsster/hadoop_cluster:hive t4tsster/hadoop_cluster:postgresql-hms t4tsster/hadoop_cluster:hue t4tsster/hadoop_cluster:edge t4tsster/hadoop_cluster:nifi t4tsster/hadoop_cluster:zeppelin -f
	docker system prune -f
	exit
fi

if [[ $1 = "start" ]]; then  
	docker start psqlhms nodemaster node2 node3 edge hue nifi zeppelin
	startServices
	exit
fi

if [[ $1 = "pull_images" ]]; then  
	docker pull -a t4tsster/hadoop_cluster
	exit
fi

echo "Usage: cluster.sh pull_images|install|start|stop|uninstall"
echo "                 pull_images - download all docker images"
echo "                 install - Prepare to run and start for first time all containers"
echo "                 start  - start existing containers"
echo "                 stop   - stop running processes"
echo "                 uninstall - remove all docker images"


