#!/bin/bash

# This script builds Hadoop package using current directory as source directory,
# and deploy a pseudo signle node Hadoop cluster with HDFS/YARN configured.
# 
# Before usage, please change current working directory to your Hadoop source code,
# and set the HADOOP_HOME to the target directory where Hadoop will be installed.
#
# Running the script without any parameter will simply restart the existing built and deployed cluster;
# 'build' parameter will build from source and deploy the newly built package to start a Hadoop cluster;
# 'deploy' parameter will deploy the existing built package and start the cluster.

export HADOOP_HOME=$HOME/Applications/hadoop

main() {
    if [ "$1" == "build" ]; then
        pseudo_build
        pseudo_deploy
    elif [ "$1" == "deploy" ]; then
        pseudo_deploy
    fi
    pseudo_start
}

pseudo_build() {
    echo "Building...."
    mvn clean install package -DskipTests -Dtar -Pdist -q || exit 1
    rm -rf $HADOOP_HOME
    cp -r $(pwd)/hadoop-dist/target/hadoop-*-SNAPSHOT $HADOOP_HOME
}

pseudo_deploy() {
    echo "Configuring..."
    cd $HADOOP_HOME
    rm -f logs/*.*
    if [ -d $HADOOP_HOME/etc/hadoop/conf ]; then
        HADOOP_CONF_HOME=$HADOOP_HOME/etc/hadoop/conf
    else
        HADOOP_CONF_HOME=$HADOOP_HOME/etc/hadoop
    fi

    echo 'export HDFS_AUDIT_LOGGER=INFO,RFAAUDIT'  >> $HADOOP_CONF_HOME/hadoop-env.sh
    echo 'export HADOOP_OPTIONAL_TOOLS="hadoop-aws,hadoop-azure-datalake"' >> $HADOOP_CONF_HOME/hadoop-env.sh

cat > $HADOOP_CONF_HOME/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

cat > $HADOOP_CONF_HOME/hdfs-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

cat > $HADOOP_CONF_HOME/mapred-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>\$HADOOP_HOME/share/hadoop/mapreduce/*:\$HADOOP_HOME/share/hadoop/mapreduce/lib/*:\$HADOOP_HOME/share/hadoop/tools/lib/*</value>
    </property>
</configuration>
EOF

cat > $HADOOP_CONF_HOME/yarn-site.xml << EOF
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOF
}

pseudo_start() {
    echo "Stopping old services..."
    $HADOOP_HOME/sbin/stop-dfs.sh
    $HADOOP_HOME/sbin/stop-yarn.sh
    echo "Starting..."
    rm -rf /tmp/hadoop-$USER/
    $HADOOP_HOME/bin/hdfs namenode -format -force
    $HADOOP_HOME/sbin/start-dfs.sh
    $HADOOP_HOME/sbin/start-yarn.sh
}

main "$@"
