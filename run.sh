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

mkdir tmp
# Copy hadoop and spark packages
cp -r $HADOOP_TARGET_SNAPSHOT tmp
cp files/* tmp

# Generate docker file
cat > tmp/Dockerfile << EOF
FROM hadoop-and-spark-on-docker-base

ENV HADOOP_HOME /hadoop
ADD $(basename $HADOOP_TARGET_SNAPSHOT) \$HADOOP_HOME
ADD *.xml \$HADOOP_HOME/etc/hadoop/
EOF

docker rmi -f hadoop-and-spark-on-docker
docker build -t "hadoop-and-spark-on-docker" tmp
rm -rf tmp

#for i in $(seq 10);
#do
    #docker run hadoop-and-spark-on-docker
#done

docker run -it hadoop-and-spark-on-docker
