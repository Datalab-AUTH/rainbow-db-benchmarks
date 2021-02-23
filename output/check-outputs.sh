#!/bin/bash

NODES_LIST=${NODES_LIST:-"6 10 14 20"}

EMPTY_FILES=`find ./ -name "*.out" -size 0 | wc -l`
if [ $EMPTY_FILES -ge 0 ]; then
	echo "====================="
	echo "Empty files: $EMPTY_FILES"
	echo "====================="
	find ./ -name "*.out" -size 0
fi

NO_RESULTS=`grep -L OVERALL *.out | wc -l`
if [ $NO_RESULTS -ge 0 ]; then
	echo "==============================="
	echo "Files with no results: $NO_RESULTS"
	echo "==============================="
	grep -L OVERALL *.out
fi

N=0
for nodes in $NODES_LIST; do
	NEW=$( grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
		grep -v "servers=$nodes" | \
		sed "s/\(.*\)out:\(.*\)/\1out/" | wc -l )
	N=$((N+NEW))
done
if [ $N -ge 0 ]; then
	echo "=============================================="
	echo "Ignite files with wrong number of nodes: $N"
	echo "=============================================="
	for nodes in $NODES_LIST; do
		grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
			grep -v "servers=$nodes" | \
			sed "s/\(.*\)out:\(.*\)/\1out/"
	done
fi

EXC=`grep -l Exception *.out | wc -l`
if [ $EXC -ge 0 ]; then
	echo "==============================="
	echo "Files with exceptions: $EXC"
	echo "==============================="
	grep -l Exception *.out
fi
