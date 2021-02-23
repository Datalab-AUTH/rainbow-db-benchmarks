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
