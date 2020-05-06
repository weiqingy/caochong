#!/usr/bin/env bash

HADOOP_SRC_HOME=${HADOOP_SRC_HOME:-$HOME/Workspace/hadoop}
HBASE_SRC_HOME=${HBASE_SRC_HOME:-$HOME/Workspace/hbase}
SPARK_SRC_HOME=${SPARK_SRC_HOME:-$HOME/Workspace/spark}

let N=3

# The hadoop home in the docker containers
HADOOP_HOME=/hadoop
# The hbase home in the docker containers
HBASE_HOME=/hbase

function usage() {
    echo "Usage: ./run.sh hadoop|hbase|spark [--rebuild] [--nodes=N]"
    echo
    echo "hadoop       Make running mode be hadoop"
    echo "hbase        Make running mode be hbase"
    echo "spark        Make running mode be spark"
    echo "--rebuild    Rebuild hadoop if in hadoop mode, rebuild hbase in hbase mode, else reuild spark"
    echo "--nodes      Specify the number of total nodes (default 3)"
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

        # Prepare hadoop packages and configuration files
        cd $HADOOP_SRC_HOME
        mvn clean
        git clean -f -d
        mvn package -DskipTests -Dtar -Pdist -q || exit 1
        cd -

        mkdir -p tmp
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

# @Return the hbase distribution package for deployment
function hbase_target() {
    echo $(find $HBASE_SRC_HOME/hbase-assembly/target/ -type d -name 'hbase-*-SNAPSHOT-bin.tar.gz')
}

function build_hbase() {
    # Build Hadoop first since we use that as base image
    if [[ "$(docker images -q caochong-hadoop)" == "" ]]; then
        build_hadoop
    fi

    if [[ $REBUILD -eq 1 || "$(docker images -q caochong-hbase)" == "" ]]; then
        echo "Building HBase...."
        #rebuild the base image if not exist
        if [[ "$(docker images -q caochong-base)" == "" ]]; then
            echo "Building Docker...."
            docker build -t caochong-base .
        fi

        # Prepare hadoop packages and configuration files
        cd $HBASE_SRC_HOME
        git clean -f -d
        mvn clean install -DskipTests && mvn -DskipTests package assembly:single
        cd -

        mkdir -p tmp
        tar -xf $(hadoop_target) -C tmp
        mv tmp/hbase* tmp/hbase
        cp hadoopconf/* tmp/hbase/conf/

        # Generate docker file for hadoop
cat > tmp/Dockerfile << EOF
        FROM caochong-hadoop

        ENV HBASE_HOME $HBASE_HOME
        ADD hbase $HBASE_HOME
        ENV PATH "\$PATH:$HBASE_HOME/bin:$HBASE_HOME/sbin"
EOF
        echo "Building image for hbase"
        docker rmi -f caochong-hbase
        docker build -t caochong-hbase tmp

        # Cleanup
        rm -rf tmp/
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
            hbase)
                MODE="hbase"
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

case $MODE in
    hadoop)
        build_hadoop
        ;;
    hbase)
        build_hbase
        ;;
    spark)
        build_spark
        ;;
esac

docker network create caochong 2> /dev/null

# remove the outdated master
for d in $(docker ps -a -q -f "label=caochong")
do
    docker rm -f $d 2>&1 > /dev/null
done

# launch master container
master_id=$(docker run -d --net caochong --name caochong-master -l caochong caochong-$MODE)
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run -d --net caochong -name caochong-$MODE-$i -l caochong caochong-$MODE)
    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts $master_id:$HADOOP_HOME/etc/hadoop/slaves

# Start hdfs and yarn services
docker exec -it $master_id $HADOOP_HOME/sbin/start-dfs.sh
docker exec -it $master_id $HADOOP_HOME/sbin/start-yarn.sh

if [[ "$MODE" == "hbase" ]]; then
    docker cp hosts $master_id:$HBASE_HOME/conf/regionservers
    tail -1 hosts >> backup-masters
    docker cp backup-masters $master_id:$HBASE_HOME/conf/backup-masters

    docker exec -it $master_id $HBASE_HOME/bin/start-hbase.sh
fi

# Connect to the master node
docker exec -it caochong-master /bin/bash
