#!/usr/bin/env bash

NODE_NAME_PREFIX="caochong-ambari"
let N=3
let PORT=8080

function usage() {
    echo "Usage: ./run.sh [--nodes=N]"
    echo
    echo "--nodes      Specify the number of total nodes"
    echo "--port       Specify the port of your local machine to access Ambari Web UI (8080 - 8088)"
}

# Parse and validate the command line arguments
function parse_arguments() {
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            -h | --help)
                usage
                exit
                ;;
            --port)
                PORT=$VALUE
                ;;
            --nodes)
                N=$VALUE
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                usage
                exit 1
                ;;
        esac
        shift
    done
}

parse_arguments $@

docker build -t caochong-ambari .
docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=$NODE_NAME_PREFIX") 2>&1 > /dev/null

# launch containers
master_id=$(docker run -d --net caochong -p $PORT:8080 --name $NODE_NAME_PREFIX-0 caochong-ambari)
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
