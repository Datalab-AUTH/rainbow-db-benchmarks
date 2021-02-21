#!/bin/bash

VARIANT=${VARIANT:-"ignite"}
NODES=${NODES:-2}
BANDWIDTH=${BANDWIDTH:-"4"}
NETWORK_DELAY=${NETWORK_DELAY:-"3"}
YCSB_OPERATION_COUNT=${YCSB_OPERATION_COUNT:-"100"}
YCSB_RECORD_COUNT=${YCSB_RECORD_COUNT:-"100"}
YCSB_THREAD_COUNT=${YCSB_THREAD_COUNT:-"4"}
REPLICATION=${REPLICATION:-"1"}

DOCKER_COMPOSE=${DOCKER_COMPOSE:-"docker-compose.yaml"}

create_docker_compose() {
	echo 'version: "3.8"'
	echo 'services:'
	echo '  ycsb:'
	echo '    image: datalabauth/docker-ycsb'
	echo '    command: /sleep.sh'
	for i in `seq $NODES`; do
		echo "  node$i:"
		echo "    image: datalabauth/docker-ignite"
		echo "    command: sh -c \"while true; do sleep 10; done\""
		echo "    cap_add:"
		echo "      - NET_ADMIN"
	done
}

get_node_name() {
	NODE_NUMBER=$1
	NODE_NAME=$( basename $( pwd ) )_node${NODE_NUMBER}_1
	echo $NODE_NAME
}

shape_traffic() {
	NODE_NUMBER=$1
	NODE=$( get_node_name $NODE_NUMBER )
	tc_cmd="tc qdisc add dev eth0 handle 1: root htb default 11; \
		tc class add dev eth0 parent 1: classid 1:1 htb rate 1000Mbps; \
		tc class add dev eth0 parent 1:1 classid 1:11 htb rate ${BANDWIDTH}Mbit; \
		tc qdisc add dev eth0 parent 1:11 handle 10: netem delay ${NETWORK_DELAY}ms"
	echo "Shaping traffic for node$NODE_NUMBER..."
	docker exec $NODE sh -c "$tc_cmd"
}

create_docker_compose > $DOCKER_COMPOSE

docker-compose -f $DOCKER_COMPOSE up --detach

# wait a few seconds for each node to spin up
for i in `seq $NODES`; do
	sleep 3
done

# shape traffic for all nodes
for i in `seq $NODES`; do
	shape_traffic $i
done
sleep 3

# create the list of nodes to put into the configuration file
NODE_LIST=""
for i in `seq $NODES`; do
	export NODE_LIST="$NODE_LIST<value>node$i</value>"
done

# apply configuration to nodes and start them
for i in `seq $NODES`; do
	docker exec $( get_node_name $i ) \
		sed -i "s|<!--IP_LIST-->|$NODE_LIST|" /$VARIANT.xml
	docker exec $( get_node_name $i ) \
		cp /$VARIANT.xml config/default-config.xml
	docker exec $( get_node_name $i ) \
		./run.sh &
done

# wait a bit for nodes to start
sleep $(( $NODES * 20 ))

for workload in a b c d e f; do
	for action in load run; do
		docker exec ignite_ycsb_1 \
			./bin/ycsb load ignite -p hosts=node1 \
			-s -P ./workloads/workloada \
			-p operationcount=100 \
			-p recordcount=100 \
			-threads 4 | \
			tee ../output/$VARIANT-$workload-$NODES-${BANDWIDTH}Mbps-${NETWORK_DELAY}ms-$YCSB_OPERATION_COUNT-$YCSB_RECORD_COUNT-$YCSB_THREAD_COUNT-$REPLICATION.out
	done
done

docker-compose -f $DOCKER_COMPOSE down

