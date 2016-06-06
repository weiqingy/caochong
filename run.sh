#!/usr/bin/env bash

# build Hadoop
HADOOP_SRC_HOME=$HOME/Workspace/hadoop
echo "Building Hadoop...."
mvn -f $HADOOP_SRC_HOME package -DskipTests -Dtar -Pdist -q || exit 1
HADOOP_TARGET_SNAPSHOT=$(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')

# build Spark
#SPARK_SRC_HOME=$HOME/Workspace/spark
#cd $SPARK_SRC_HOME
#echo "Building Spark...."
#mvn package -DskipTests -Dtar -Pdist -q || exit 1
#cd -

docker build -t hadoop-and-spark-on-docker-base .

# Prepare hadoop and spark packages and configuration files
mkdir tmp
cp -r $HADOOP_TARGET_SNAPSHOT tmp/hadoop
cp hadoop/* tmp/hadoop/etc/hadoop/

# Generate docker file
cat > tmp/Dockerfile << EOF
FROM hadoop-and-spark-on-docker-base

ENV HADOOP_HOME /hadoop
ADD hadoop \$HADOOP_HOME
EOF

docker rmi -f hadoop-and-spark-on-docker
docker build -t "hadoop-and-spark-on-docker" tmp

# Cleanup
rm -rf tmp

#for i in $(seq 10);
#do
    #docker run hadoop-and-spark-on-docker
#done

docker run -it hadoop-and-spark-on-docker
