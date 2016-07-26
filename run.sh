#!/usr/bin/env bash

HADOOP_SRC_HOME=$HOME/Workspace/hadoop
SPARK_SRC_HOME=$HOME/Workspace/spark

# The hadoop home in the docker containers
HADOOP_HOME=/hadoop

# The spark home in the docker containers
SPARK_HOME=/spark

let DISABLE_SPARK=0
let BUILD_HADOOP=0
let BUILD_SPARK=0
let BUILD_DOCKER=0

function usage() {
    echo "Usage"
}

# @Return the hadoop distribution package for deployment
function hadoop_target() {
    echo $(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')
}

function build_hadoop() {
    HADOOP_TARGET_SNAPSHOT=$(hadoop_target)
    if [[ -z $HADOOP_TARGET_SNAPSHOT && $BUILD_HADOOP -eq 0 ]]; then
        echo "No Hadoop target found, will forcefully build hadoop."
        BUILD_HADOOP=1
    fi

    if [[ $BUILD_HADOOP -eq 1 ]]; then
        echo "Building Hadoop...."
        mvn -f $HADOOP_SRC_HOME package -DskipTests -Dtar -Pdist -q || exit 1
        HADOOP_TARGET_SNAPSHOT=$(hadoop_target)
    fi

    # Prepare hadoop packages and configuration files
    cp -r $HADOOP_TARGET_SNAPSHOT tmp/hadoop
    cp hadoopconf/* tmp/hadoop/etc/hadoop/
}

function build_spark() {
    if [[ $DISABLE_SPARK -eq 0 ]]; then
        if [[ $BUILD_HADOOP -eq 1 || $BUILD_SPARK -eq 1 ]]; then
            echo "Building Spark...."
            $SPARK_SRC_HOME/dev/make-distribution.sh --name myspark --tgz -Phive -Phive-thriftserver -Pyarn 1> /dev/null || exit 1
        fi
        tar xzf $SPARK_SRC_HOME/*.tgz -C tmp/
        mv tmp/*myspark tmp/spark
    fi
}

function build_docker() {
    if [[ $BUILD_DOCKER -eq 1 ]]; then
        echo "Building Docker...."
        docker build -t hadoop-and-spark-on-docker-base .
    fi

    if [[ $BUILD_HADOOP -eq 1 || $BUILD_SPARK -eq 1 || $BUILD_DOCKER -eq 1 ]]; then
        rm -rf tmp/ && mkdir tmp

        build_hadoop

        build_spark

        # Generate docker file
cat > tmp/Dockerfile << EOF
        FROM hadoop-and-spark-on-docker-base

        ENV HADOOP_HOME $HADOOP_HOME
        ADD hadoop $HADOOP_HOME

        ENV SPARK_HOME $SPARK_HOME
        ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop
        ADD spark $SPARK_HOME

        RUN $HADOOP_HOME/bin/hdfs namenode -format
EOF

        docker rmi -f hadoop-and-spark-on-docker
        docker build -t "hadoop-and-spark-on-docker" tmp

        # Cleanup
        rm -rf tmp
    fi
}

# Parse and validatet the command line arguments
function parse_arguments() {
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            -h | --help)
                usage
                exit
                ;;
            --disable-spark)
                DISABLE_SPARK=1
                ;;
            --build-hadoop)
                BUILD_HADOOP=1
                ;;
            --build-spark)
                BUILD_SPARK=1
                ;;
            --build-docker)
                BUILD_DOCKER=1
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                usage
                exit 1
                ;;
        esac
        shift
    done

    if [[ $DISABLE_SPARK -eq 1 ]]; then
        if [[ $BUILD_SPARK -eq 1 ]]; then
            echo "Options --disable-spark and --build-spark are mutually exclusive"
            exit 2
        elif [[ $BUILD_DOCKER -eq 0 ]]; then
            echo "Option --disable-spark needs to work with --build-docker"
            exit 3
        fi
    fi
}

parse_arguments $@

build_docker

docker network create hadoop-and-spark-on-docker 2> /dev/null

let N=3
# launch master container
master_id=$(docker run -d --net hadoop-and-spark-on-docker --name master hadoop-and-spark-on-docker)
echo ${master_id:0:12} > workers
for i in $(seq $((N-1)));
do
    container_id=$(docker run -d --net hadoop-and-spark-on-docker hadoop-and-spark-on-docker)
    echo ${container_id:0:12} >> workers
done

# Copy the workers file to the master container
docker cp workers $master_id:$HADOOP_HOME/etc/hadoop/

# Start hdfs and yarn services
docker exec -it $master_id $HADOOP_HOME/sbin/start-dfs.sh
docker exec -it $master_id $HADOOP_HOME/sbin/start-yarn.sh

# Connect to the master node
docker exec -it master /bin/bash
