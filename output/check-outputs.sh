#!/bin/bash

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
for nodes in 6 10 14 20; do
	NEW=$( grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
		grep -v "servers=$nodes" | \
		sed "s/\(.*\)out:\(.*\)/\1out/" | wc -l )
	N=$((N+NEW))
done
if [ $N -ge 0 ]; then
	echo "=============================================="
	echo "Ignite files with wrong number of nodes: $N"
	echo "=============================================="
		grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
			grep -v "servers=$nodes" | \
			sed "s/\(.*\)out:\(.*\)/\1out/"
fi

NAN=`grep -l NaN *.out | wc -l`
if [ $NAN -ge 0 ]; then
	echo "==============================="
	echo "Files with NaN values: $NAN
	echo "==============================="
	grep -l NaN *.out
fi
