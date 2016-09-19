FROM centos:6

MAINTAINER Mingliang Liu <mliu@hortonworks.com>

RUN yum install -y epel-release
RUN yum -y update
RUN yum install -y wget ntp sudo

# configure ssh free key access
RUN yum install -y which openssh-clients openssh-server
RUN echo 'root:hortonworks' | chpasswd
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd
RUN echo -e "Host *\n StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN yum -y install supervisor
RUN mkdir /etc/supervisor.d/
RUN echo -e "[program:sshd]\ncommand=/sbin/service sshd start" >> /etc/supervisord.conf
RUN echo -e "[program:ntpd]\ncommand=/sbin/service ntpd start" >> /etc/supervisord.conf

# There are several available versions of Ambari
# to test the branch-2.4 build - updated on every commit to branch-2.4 (under development)
# RUN wget -O /etc/yum.repos.d/ambari.repo http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/latest/2.4.0.0/ambaribn.repo

# to test the trunk build - updated on every commit to trunk
# RUN wget -O /etc/yum.repos.d/ambari.repo http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/latest/trunk/ambaribn.repo

# to test public release 2.2.2
RUN wget -O /etc/yum.repos.d/ambari.repo http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.2.0/ambari.repo

RUN yum install ambari-server -y
RUN ambari-server setup -s

RUN yum clean all

EXPOSE 22 8080 8081 8082 8083 8084 8085 8086 8087 8088

CMD /usr/bin/supervisord -n
