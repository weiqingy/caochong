# Dockerfile for installing the necessary dependencies for running Hadoop and Spark

FROM ubuntu:latest

MAINTAINER Mingliang Liu <mliu@hortonworks.com>
MAINTAINER Weiqing Yang <wyang@hortonworks.com>

RUN apt-get update -y
RUN apt-get upgrade -y

# install openjdk
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

# install and configure ssh service
RUN apt-get install -y openssh-server
RUN echo 'root:hortonworks' | chpasswd
RUN mkdir /var/run/sshd && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# configure ssh free key access
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# set supervisor
RUN apt-get install -y supervisor
RUN echo -e "[program:sshd]\ncommand=/usr/sbin/sshd -D" >> /etc/supervisor/supervisord.conf

# install general tools
RUN apt-get install -y iproute2 vim inetutils-ping

EXPOSE 22 9000 50020 50030

CMD /usr/bin/supervisord -n
