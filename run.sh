#!/usr/bin/env bash

HADOOP_SRC_HOME=$HOME/Workspace/hadoop
SPARK_SRC_HOME=$HOME/Workspace/spark

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
	cp hadoop/* tmp/hadoop/etc/hadoop/
}

function build_spark() {
	if [[ $DISABLE_SPARK -eq 0 ]]; then
		if [[ $BUILD_HADOOP -eq 1 || $BUILD_SPARK -eq 1 ]]; then
			echo "Building Spark...."
			mvn -f $SPARK_SRC_HOME package -DskipTests -Pyarn -q || exit 1
		fi
		cp -r $SPARK_SRC_HOME tmp/spark
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

		ENV HADOOP_HOME /hadoop
		ADD hadoop \$HADOOP_HOME

		ENV SPARK_HOME /spark
		ENV HADOOP_CONF_DIR /hadoop/etc/hadoop
		ADD spark \$SPARK_HOME

		RUN \$HADOOP_HOME/bin/hdfs namenode -format
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

let N=3
# launch master container
master_id=$(docker run -d --net hadoop-and-spark-on-docker --name master hadoop-and-spark-on-docker)
for i in $(seq $((N-1)));
do
	echo -e $(docker run -d --net hadoop-and-spark-on-docker hadoop-and-spark-on-docker) "\n" >> slaves
done

docker exec -it $master_id /bin/bash

