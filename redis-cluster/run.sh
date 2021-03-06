#!/bin/bash

NODES=${NODES:-2}
REPLICAS=${REPLICAS:-1}
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
		echo "    image: datalabauth/redis-cluster"
		echo "    command: redis-server /cluster.conf"
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
if [ $BANDWIDTH -ne 0 ]; then
	for i in `seq $NODES`; do
		shape_traffic $i
	done
	sleep 3
fi

# apply configuration to nodes and start them
REDIS_CLI_OPTS=" --cluster create --cluster-yes "
for i in `seq $NODES`; do
	# create the list of nodes to put into the configuration file.
	# Current node goes first.
	IP=$( docker exec -ti $( get_node_name $i ) ifconfig | \
			grep -A1 eth0 |	grep "inet addr:" | \
			sed "s/.*inet addr:\(.*\)  Bcast.*/\1/" )
	REDIS_CLI_OPTS="$REDIS_CLI_OPTS ${IP}:6379"
done
if [ $REPLICAS -gt 0 ]; then
	REDIS_CLI_OPTS="$REDIS_CLI_OPTS --cluster-replicas $REPLICAS"
fi
echo redis-cli $REDIS_CLI_OPTS

docker exec $( get_node_name 1 ) /usr/local/bin/redis-cli $REDIS_CLI_OPTS
res=$?
if [ $res -ne 0 ]; then
	echo "ERROR: Could not create redis cluster"
	sleep 1200
	docker-compose -f $DOCKER_COMPOSE down
	exit 1
fi

# wait a bit for nodes to start
sleep $(( $NODES * 5 ))

for workload in a b c d e f; do
	for action in load run; do
		echo "Running YCSB workload $workload $action..."
		docker exec redis-cluster_ycsb_1 \
			./bin/ycsb $action redis \
			-s -P ./workloads/workload$workload \
			-p redis.host=node1 \
			-p redis.port=6379 \
			-p operationcount=$YCSB_OPERATION_COUNT \
			-p recordcount=$YCSB_RECORD_COUNT \
			-p redis.cluster=true \
			-threads $YCSB_THREAD_COUNT | \
			tee ../output/redis-$workload-$NODES-$REPLICAS-${BANDWIDTH}Mbps-${NETWORK_DELAY}ms-$YCSB_OPERATION_COUNT-$YCSB_RECORD_COUNT-$YCSB_THREAD_COUNT-$action-$REPLICATION.out
	done
done

docker-compose -f $DOCKER_COMPOSE down

