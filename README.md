# Hadoop and Spark on Docker

This tool sets up a Hadoop and/or Spark **cluster** running within Docker **containers** on a **single** physical machine (e.g. your laptop). It's convenient for debugging, testing and operating a real cluster, especially when you run customized packages with changes of Hadoop/Spark source code and configuration files.

## Why Me
This tool is:

- **easy to go**: just one command `run.sh` (Tell me, friend, can you ask for anything more? ).
- **customizable**: you can specify the cluster specs easily, e.g. HA-enabled, number of datanodes, LDAP, security etc.
- **configurable**: you can either change the Hadoop and/or Spark configuration files before launching the cluster or change them online by logging on the virtual machines.
- **elastic**: imagine your physical machine can run as many containers as you wish.

The distributed cluster in Docker containers outperforms its counterparts:

1. _[psudo-distributed Hadoop cluster](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html) on a single machine_, which is nontrivial to run HA, to launch multiple datanodes, to test HDFS balancer/mover etc.
1. _[setting up a real cluster](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html)_, which is complex and heavy to use, and in the first place you can afford a real cluster.
1. _[building Ambari cluster using vbox/vmware virtual machines](https://cwiki.apache.org/confluence/display/AMBARI/Quick+Start+Guide)_, nice try. But let's see who runs faster.

## Usage
The following illustrates the basic procedure on how to use this tool. It provides two ways to set up Hadoop and Spark cluster: **from-ambari** and **from-source**.

### From Source
The only one step is to run from-source/run.sh.

```
$ ./run.sh --help
Usage: ./run.sh hadoop|spark [--rebuild] [--nodes=N]

hadoop       Make running mode to hadoop
spark        Make running mode to spark
--rebuild    Rebuild hadoop if in hadoop mode; else reuild spark
--nodes      Specify the number of total nodes
```

### From Ambari

[Apache Ambari](https://cwiki.apache.org/confluence/display/AMBARI/Ambari) is a tool for provisioning, managing, and monitoring Apache Hadoop clusters. If using Ambari to set up Hadoop and Spark, Spark will run in Yarn client/cluster mode.

1. [Optional] Choose Ambari version in `from-ambari/Dockerfile` file (default Ambari 2.2)
1. Run `from-ambari/run.sh` to set up an Ambari cluster and launch it

	```
	$ ./run.sh --help
	Usage: ./run.sh [--nodes=3] [--port=8080] --secure
	
	--nodes      Specify the number of total nodes
	--port       Specify the port of your local machine to access Ambari Web UI (8080 - 8088)
	--secure     Specify the cluster to be secure
	```
	
1. Hit `http://localhost:port` from your browser on your local computer. The _port_ is the parameter specified in the command line of running `run.sh`. By default, it is [http://localhost:8080](http://localhost:8080). NOTE: Ambari Server can take some time to fully come up and ready to accept connections. Keep hitting the URL until you get the login page.
1. Login the Ambari webpage with the default username:password is `admin:admin`.
1. [Optional] Customize the repository Base URLs in the Select Stack step.
1. On the _Install Options_ page, use the hostnames reported by `run.sh` as the Fully Qualified Domain Name (FQDN). For example:

	```
	Using the following hostnames:
	------------------------------
	85f9417e3d94
	b5077ffd9f7f
	------------------------------
	```
	
1. Upload `from-ambari/id_rsa` as your SSH Private Key to automatically register hosts when asked.
1. Follow the onscreen instructions to install Hadoop (YARN + MapReduce2, HDFS) and Spark.
1. [Optional] Log in to any of the nodes and you're all set to use an Ambari cluster!

	```
	# login to your Ambari server node
	$ docker exec -it caochong-ambari-0 /bin/bash
	```
1. [Optional] If you want to make the cluster secure, you need to login to your Ambari server node, and run install_Kerberos.sh (you may need to do "chmod 777 install_Kerberos.sh").
Then go back to Ambari web page, follow the onscreen instructions to configure Kerberos.
