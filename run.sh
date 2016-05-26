#!/usr/bin/env bash

# build Hadoop
HADOOP_SRC_HOME=$HOME/Workspace/hadoop
cd $HADOOP_SRC_HOME
echo "Building Hadoop...."
#mvn package -DskipTests -Dtar -Pdist -q || exit 1
HADOOP_TARGET_SNAPSHOT=$(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')
echo $HADOOP_TARGET_SNAPSHOT
cd -

# build Spark
#SPARK_SRC_HOME=$HOME/Workspace/spark
#cd $SPARK_SRC_HOME
#echo "Building Spark...."
#mvn package -DskipTests -Dtar -Pdist -q || exit 1
#cd -

docker rmi -f hadoop-and-spark-on-docker

docker build -t "hadoop-and-spark-on-docker" - << EOF
FROM hadoop-and-spark-on-docker-base

ENV HADOOP_HOME /usr/lib/hadoop

ADD $HADOOP_TARGET_SNAPSHOT \$HADOOP_HOME
ADD files/* \$HADOOP_HOME/etc/hadoop/conf
EOF

#for i in $(seq 10);
#do
    #docker run hadoop-and-spark-on-docker
#done

#ssh nn
