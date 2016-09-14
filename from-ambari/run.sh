#!/usr/bin/env bash

NODE_NAME_PREFIX="caochong-ambari"
let N=3

docker build -t caochong-ambari .
docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=$NODE_NAME_PREFIX") 2> /dev/null
# launch master container
master_id=$(docker run -d --net caochong -p 8080:8080 --name $NODE_NAME_PREFIX-0 caochong-ambari)
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    docker run -d --net caochong --name $NODE_NAME_PREFIX-$i caochong-ambari
    echo ${container_id:0:12} >> hosts
done

# print the hostnames
echo "Using the following hostnames:"
cat hosts
# print the private key
echo "Using the following private key to ssh:"
docker exec -it $NODE_NAME_PREFIX-0 cat /root/.ssh/id_rsa

# Connect to the master node
docker exec -it $NODE_NAME_PREFIX-0 /bin/bash
