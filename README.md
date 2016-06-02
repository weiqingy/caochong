# Hadoop and Spark on Docker

This tool sets up a Hadoop and/or Spark cluster within Docker containers on a **single machine**. It's convenient for debugging and testing operations, especially when you run your customized Hadoop and/or Spark packages with changes of Hadoop and/or Spark source code or configuration files).

## Why Me
This tool is:

- **easy to go**: just one command, and you can't ask more.
- **customizable**: you can specify the cluster specs easily, e.g. HA-enabled, number of datanodes, LDAP, security etc.
- **configurable**: you can either change the Hadoop and/or Spark configuration files before launching the cluster or change them online by logging on the virtual machines.
- **elastic**: consider your physical machine can run as many containers as you wish.

The distributed cluster in Docker containers outperforms its counterparts:

- the psudo-distributed Hadoop cluster on a single machine (which is nontrivial to run HA, to launch multiple datanodes, to test HDFS balancer/mover etc)
- setting up a real cluster (which is complex and heavy to use, and still you need a real "cluster")

## Usage
TBD

## License
Unlike all other Apache projects which use Apache license, this project uses an advanced and modern license named The Star And Thank Author License (SATA). Please see the [LICENSE](LICENSE) file for more information.
