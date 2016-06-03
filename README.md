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

## Usage
TBD

## License
Unlike all other Apache projects which use Apache license, this project uses an advanced and modern license named The Star And Thank Author License (SATA). Please see the [LICENSE](LICENSE) file for more information.
