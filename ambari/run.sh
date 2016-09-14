#!/usr/bin/env bash

NODE_NAME_PREFIX="caochong-ambari"
let N=5

docker build -t caochong-ambari .
docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=$NODE_NAME_PREFIX") 2> /dev/null
# launch master container
master_id=$(docker run -d --net caochong -p 8080:8080 --name $NODE_NAME_PREFIX-master caochong-ambari)
for i in $(seq $((N-1)));
do
    docker run -d --net caochong --name $NODE_NAME_PREFIX-$i caochong-ambari
done

# Connect to the master node
docker exec -it $NODE_NAME_PREFIX-master /bin/bash
