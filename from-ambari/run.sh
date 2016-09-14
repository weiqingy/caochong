#!/usr/bin/env bash

NODE_NAME_PREFIX="caochong-ambari"
let N=3

docker build -t caochong-ambari .
docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=$NODE_NAME_PREFIX") 2>&1 > /dev/null

# launch containers
master_id=$(docker run -d --net caochong -p 8080:8080 --name $NODE_NAME_PREFIX-0 caochong-ambari)
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run -d --net caochong --name $NODE_NAME_PREFIX-$i caochong-ambari)
    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:/root
# print the hostnames
echo "Using the following hostnames:"
echo "------------------------------"
cat hosts
echo "------------------------------"

# print the private key
echo "Copying back the private key..."
docker cp $master_id:/root/.ssh/id_rsa .

# Start the ambari server
docker exec $NODE_NAME_PREFIX-0 ambari-server start
