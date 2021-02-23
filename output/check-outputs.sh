#!/bin/bash

EMPTY_FILES=`find ./ -name "*.out" -size 0 | wc -l`
echo "====================="
echo "Empty files: $EMPTY_FILES"
echo "====================="
find ./ -name "*.out" -size 0

NO_RESULTS=`grep -L OVERALL *.out | wc -l`
echo "==============================="
echo "Files with no results: $NO_RESULTS"
echo "==============================="
grep -L OVERALL *.out

N=0
for nodes in 6 10 14 20; do
	NEW=$( grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
		grep -v "servers=$nodes" | \
		sed "s/\(.*\)out:\(.*\)/\1out/" | wc -l )
	N=$((N+NEW))
done
echo "=============================================="
echo "Ignite files with wrong number of nodes: $N"
echo "=============================================="
	grep "Topology snap" ignite*-$nodes-* 2> /dev/null | \
		grep -v "servers=$nodes" | \
		sed "s/\(.*\)out:\(.*\)/\1out/"

NAN=`grep -l NaN *.out | wc -l`
echo "==============================="
echo "Files with NaN values: $NO_RESULTS"
echo "==============================="
grep -l NaN *.out
