#!/usr/bin/env bash

# build Hadoop
HADOOP_SRC_HOME=$HOME/Workspace/hadoop
cd $HADOOP_SRC_HOME
echo "Building Hadoop...."
#mvn package -DskipTests -Dtar -Pdist -q || exit 1
HADOOP_TARGET_SNAPSHOT=$(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')
cd -

# build Spark
#SPARK_SRC_HOME=$HOME/Workspace/spark
#cd $SPARK_SRC_HOME
#echo "Building Spark...."
#mvn package -DskipTests -Dtar -Pdist -q || exit 1
#cd -

docker build -t hadoop-and-spark-on-docker-base .

cat > files/Dockerfile << EOF
FROM hadoop-and-spark-on-docker-base

ENV HADOOP_HOME /hadoop
ADD $HADOOP_TARGET_SNAPSHOT \$HADOOP_HOME
RUN mkdir -p \$HADOOP_HOME/etc/hadoop/conf
ADD *.xml \$HADOOP_HOME/etc/hadoop/conf/
EOF

docker rmi hadoop-and-spark-on-docker
docker build -t "hadoop-and-spark-on-docker" files
rm -f files/Dockerfile

#for i in $(seq 10);
#do
    #docker run hadoop-and-spark-on-docker
#done

docker run -it hadoop-and-spark-on-docker
