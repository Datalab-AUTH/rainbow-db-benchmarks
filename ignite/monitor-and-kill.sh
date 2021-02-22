#!/bin/bash

while true; do
  tail -n 20 ../LOG | \
    grep -v 'sec: 0 operations; est completion in 0 second' | \
    grep 'sec: 0 operations; est completion in' && \
    docker-compose down && sleep 120
  sleep 10
done

