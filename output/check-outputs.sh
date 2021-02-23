#!/bin/bash

EMPTY_FILES_CMD='find ./ -name "*.out" -size 0 | wc -l'
EMPTY_FILES=`$EMPTY_FILES_CMD`
echo "Empty files: $EMPTY_FILES"
$EMPTY_FILES_CMD
NO_RESULTS_CMD='grep -L OVERALL *.out | wc -l'
NO_RESULTS=`$NO_RESULTS_CMD`
echo "Files with no results: $NO_RESULTS"
$NO_RESULTS_CMD

