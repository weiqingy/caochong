# Dockerfile for installing the necessary dependencies for running Hadoop and Spark

FROM ubuntu:14.04

MAINTAINER Mingliang Liu <mliu@hortonworks.com>

RUN apt-get update -y
RUN apt-get upgrade -y

# install openssh-server and openjdk
RUN apt-get install -y openssh-server
RUN apt-get install -y openjdk-7-jdk
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

RUN mkdir /var/run/sshd && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# configure ssh free key access
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

EXPOSE 22 7373 7946 9000 50010 50020 50070 50075 50090 50475 8030 8031 8032 8033 8040 8042 8060 8088 50060
