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
The following illustrates the basic procedure on how to use this tool. It provides two ways to set up Hadoop and Spark cluster:
**from-ambari** and **from-source**.
### From Ambari

[Apache Ambari](https://cwiki.apache.org/confluence/display/AMBARI/Ambari) is a tool for provisioning, managing, and monitoring Apache Hadoop clusters. If using Ambari to set up Hadoop and Spark, Spark will run in Yarn client/cluster mode.

First, run from-ambari/run.sh to set up Ambari cluster.
```
$ ./run.sh --help
Usage: ./run.sh [--rebuild] [--nodes=N]

--nodes      Specify the number of total nodes
--port       Specify the port of your local machine to access Ambari Web UI (8080 - 8088)
```
There are three repository files which can be used to install Ambari. Please go to from-ambari/Dockerfile and select/uncomment the version you wanted.

After running run.sh script successfully, Ambari Server will be started. Hit localhost:port from your browser on your local computer. The port is the parameter specified in the command line of running run.sh. By default,
it is 8080. Note that Ambari Server can take some time to fully come up and ready to accept connections. Keep hitting the URL until you get the login page.

Once you are at the login page, login with the default username admin and password admin.
On the Install Options page, use the hostnames showing in your terminal as the Fully Qualified Domain Name (FQDN). For example:
```
Using the following hostnames:
------------------------------
85f9417e3d94
b5077ffd9f7f
------------------------------
```
Upload from-ambari/id_rsa as your SSH Private Key to automatically register hosts.

Then, follow the onscreen instructions to install Hadoop (YARN + MapReduce2, HDFS) and Spark.

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

## License
Unlike all other Apache projects which use Apache license, this project uses an advanced and modern license named The Star And Thank Author License (SATA). Please see the [LICENSE](LICENSE) file for more information.
