#!/bin/bash
# vim:et:sta:sts=4:sw=4:ts=8:tw=79:

OPT=$1

export REPLICATIONS=${REPLICATIONS:-1}
export YCSB_THREAD_COUNT=${YCSB_THREAD_COUNT:-4}
export VARIANT_LIST=${VARIANT_LIST-"ignite ignite-sql"}
export NODES_LIST=${NODES_LIST:-"2 4 6"}
export BANDWIDTH_LIST=${BANDWIDTH_LIST:-"1000"} # Mbps
export NETWORK_DELAY_LIST=${NETWORK_DELAY_LIST:-"3"} # ms
export YCSB_OPERATION_COUNT_LIST=${YCSB_OPERATION_COUNT_LIST:-"1000 5000 10000 20000"}
export YCSB_RECORD_COUNT_LIST=${YCSB_RECORD_COUNT_LIST:-"1000 5000 10000 20000"}

run_test() {
    echo "*********************"
    echo "*** TEST SETTINGS ***"
    echo "*********************"
    echo "Replication: $REPLICATION/$REPLICATIONS"
    echo "Variant: $VARIANT"
    echo "Number of nodes: $NODES"
    echo "Network bandwidth: $BANDWIDTH"
    echo "Network delay: $NETWORK_DELAY"
    echo "YCSB operationcount: $YCSB_OPERATION_COUNT"
    echo "YCSB recordcount: $YCSB_RECORD_COUNT"
    echo "YCSB threadcount: $YCSB_THREAD_COUNT"

    cd ignite
    ./run.sh
    cd ..
}

for REPLICATION in `seq $REPLICATIONS`; do
    export REPLICATION
    for VARIANT in $VARIANT_LIST; do
        export VARIANT
        for NODES in $NODES_LIST; do
            export NODES
            for BANDWIDTH in $BANDWIDTH_LIST; do
                export BANDWIDTH
                for NETWORK_DELAY in $NETWORK_DELAY_LIST; do
                    export NETWORK_DELAY
                    for YCSB_OPERATION_COUNT in $YCSB_OPERATION_COUNT_LIST; do
                        export YCSB_OPERATION_COUNT
                        for YCSB_RECORD_COUNT in $YCSB_RECORD_COUNT_LIST; do
                            export YCSB_RECORD_COUNT
                            # if a file named STOP is present, bail out of doing
                            # the rest of the tests. Useful when fogify starts
                            # missbehaving.
                            if [ -f STOP ]; then
                                exit 2
                            fi
                            # only run test if it hasn't run yet
                            combination=$NODES-${BANDWIDTH}Mbps
                            combination=$combination-${NETWORK_DELAY}ms
                            combination=$combination-$YCSB_OPERATION_COUNT
                            combination=$combination-$YCSB_RECORD_COUNT
                            combination=$combination-$YCSB_THREAD_COUNT
                            TEST_RUN=0
                            for workload in a b c d e f; do
                                if [ ! -f output/$VARIANT-$workload-${combination}-load-$REPLICATION.out ] \
                                     || \
                                   [ ! -f output/$VARIANT-$workload-${combination}-run-$REPLICATION.out ]; then
                                    echo "*** $VARIANT-$workload-$combination will be run. ***"
                                    TEST_RUN=1
                                else
                                    echo "*** $VARIANT-$workload-$combination already there. It will be skipped. ***"
                                fi
                            done
                            if [[ $OPT != "-s" ]]; then
                                if [ $TEST_RUN -eq 1 ]; then
                                    run_test
                                fi
                            fi
                        done
                    done
                done
            done
        done
    done
done

