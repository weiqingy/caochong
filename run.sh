#!/usr/bin/env bash

HADOOP_SRC_HOME=$HOME/Workspace/hadoop
SPARK_SRC_HOME=$HOME/Workspace/spark

let BUILD_HADOOP=0
let BUILD_SPARK=0
let BUILD_DOCKER=0

function usage() {
	echo "Usage"
}

function build_hadoop() {
	echo "Building Hadoop...."
	mvn -f $HADOOP_SRC_HOME package -DskipTests -Dtar -Pdist -q || exit 1
	HADOOP_TARGET_SNAPSHOT=$(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-*-SNAPSHOT')
}

function build_spark() {
	echo "Building Spark...."
	#mvn -f $SPARK_SRC_HOME package -DskipTests -Dtar -Pdist -q || exit 1
}

function build_docker() {
	echo "Building Docker...."
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
}

# main process starts here
while [ "$1" != "" ]; do
	PARAM=`echo $1 | awk -F= '{print $1}'`
	VALUE=`echo $1 | awk -F= '{print $2}'`
	case $PARAM in
		-h | --help)
			usage
			exit
			;;
		--build-hadoop)
			BUILD_HADOOP=1
			BUILD_SPARK=1
			BUILD_DOCKER=1
			;;
		--build-spark)
			BUILD_SPARK=1
			BUILD_DOCKER=1
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


if [[ $BUILD_HADOOP -eq 1 ]]; then
	build_hadoop
fi

if [[ $BUILD_SPARK -eq 1 ]]; then
	build_spark
fi

if [[ $BUILD_DOCKER -eq 1 ]]; then
	build_docker
fi

for i in $(seq 1);
do
	container_id=$(docker run -d hadoop-and-spark-on-docker)
done

docker exec -it $container_id /bin/bash

