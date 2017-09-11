#!/usr/bin/env bash

HADOOP_SRC_HOME=$HOME/Workspace/hadoop
SPARK_SRC_HOME=$HOME/Workspace/spark

let N=3

# The hadoop home in the docker containers
HADOOP_HOME=/hadoop

function usage() {
    echo "Usage: ./run.sh hadoop|spark [--rebuild] [--nodes=N]"
    echo
    echo "hadoop       Make running mode to hadoop"
    echo "spark        Make running mode to spark"
    echo "--rebuild    Rebuild hadoop if in hadoop mode; else reuild spark"
    echo "--nodes      Specify the number of total nodes"
}

# @Return the hadoop distribution package for deployment
function hadoop_target() {
    echo $(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')
}

function build_hadoop() {
    if [[ $REBUILD -eq 1 || "$(docker images -q caochong-hadoop)" == "" ]]; then
        echo "Building Hadoop...."
        #rebuild the base image if not exist
        if [[ "$(docker images -q caochong-base)" == "" ]]; then
            echo "Building Docker...."
            docker build -t caochong-base .
        fi

        mkdir tmp

        # Prepare hadoop packages and configuration files
        mvn -f $HADOOP_SRC_HOME package -DskipTests -Dtar -Pdist -q || exit 1
        HADOOP_TARGET_SNAPSHOT=$(hadoop_target)
        cp -r $HADOOP_TARGET_SNAPSHOT tmp/hadoop
        cp hadoopconf/* tmp/hadoop/etc/hadoop/

        # Generate docker file for hadoop
cat > tmp/Dockerfile << EOF
        FROM caochong-base

        ENV HADOOP_HOME $HADOOP_HOME
        ADD hadoop $HADOOP_HOME
        ENV PATH "\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

        RUN $HADOOP_HOME/bin/hdfs namenode -format
EOF
        echo "Building image for hadoop"
        docker rmi -f caochong-hadoop
        docker build -t caochong-hadoop tmp

        # Cleanup
        rm -rf tmp
    fi
}

function build_spark() {
    if [[ $REBULD -eq 1 || "$(docker images -q caochong-spark)" == "" ]]; then
        echo "Building Spark...."
        #rebuild hadoop image if not exist
        if [[ "$(docker images -q caochong-hadoop)" == "" ]]; then
            build_hadoop
        fi

        mkdir tmp

        $SPARK_SRC_HOME/dev/make-distribution.sh --name myspark --tgz -Phive -Phive-thriftserver -Pyarn 1> /dev/null || exit 1
        tar xzf $SPARK_SRC_HOME/*.tgz -C tmp/
        mv tmp/*myspark tmp/spark

        # Generate docker file for hadoop
cat > tmp/Dockerfile << EOF
        FROM caochong-hadoop

        ENV SPARK_HOME /spark
        ENV HADOOP_CONF_DIR /hadoop/etc/hadoop
        ADD spark \$SPARK_HOME
        ENV PATH "\$PATH:\$SPARK_HOME/path"
EOF
        echo "Building image for spark"
        docker rmi -f caochong-spark
        docker build -t caochong-spark tmp

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
            hadoop)
                MODE="hadoop"
                ;;
            spark)
                MODE="spark"
                ;;
            --rebuild)
                REBUILD=1
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

    if [[ "$MODE" == "" ]]; then
        echo "Must specify either hadoop or spark mode"
        exit 2
    fi
}

parse_arguments $@

if [[ "$MODE" == "hadoop" ]]; then
    build_hadoop
elif [[ "$MODE" == "spark" ]]; then
    build_spark
fi

docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=caochong") 2>&1 > /dev/null

# launch master container
master_id=$(docker run -d --net caochong --name caochong-master caochong-$MODE)
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run -d --net caochong caochong-$MODE)
    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts $master_id:$HADOOP_HOME/etc/hadoop/slaves

# Start hdfs and yarn services
docker exec -it $master_id $HADOOP_HOME/sbin/start-dfs.sh
docker exec -it $master_id $HADOOP_HOME/sbin/start-yarn.sh

# Connect to the master node
docker exec -it caochong-master /bin/bash
