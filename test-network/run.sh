#!/bin/bash

NODES=${NODES:-2}
BANDWIDTH=${BANDWIDTH:-"4"}
NETWORK_DELAY=${NETWORK_DELAY:-"3"}

DOCKER_COMPOSE=${DOCKER_COMPOSE:-"docker-compose.yaml"}

create_docker_compose() {
	echo 'version: "3.8"'
	echo 'services:'
	for i in `seq $NODES`; do
		echo "  node$i:"
		echo "    image: datalabauth/alpine-tc:latest"
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

# run iperf3 server in odd numbered nodes
for i in `seq 1 2 $NODES`; do
	NODE=$( get_node_name $i )
	docker exec $NODE iperf3 -s -D > /dev/null
done

# run iperf3 client in even numbered nodes
for i in `seq 2 2 $NODES`; do
	NODE=$( get_node_name $i )
	docker exec $NODE sh -c "iperf3 -c node$((i-1)); ping -c 10 node$((i-1))" &
done

# wait for all background processes to complete
wait

docker-compose -f $DOCKER_COMPOSE down

