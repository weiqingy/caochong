#!/usr/bin/env bash

NODE_NAME_PREFIX="caochong-ambari"
let N=3
let PORT=8080
let S=0

function usage() {
    echo "Usage: ./run.sh [--nodes=3] [--port=8080] [--secure]"
    echo
    echo "--nodes      Specify the number of total nodes"
    echo "--port       Specify the port of your local machine to access Ambari Web UI (8080 - 8088)"
    echo "--secure     Specify the cluster to be secure"
}

# Parse and validate the command line arguments
function parse_arguments() {
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            -h | --help)
                usage
                exit
                ;;
            --port)
                PORT=$VALUE
                ;;
            --nodes)
                N=$VALUE
                ;;
            --secure)
                S=1
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                usage
                exit 1
                ;;
        esac
        shift
    done
}

parse_arguments $@

docker build -t caochong-ambari .
docker network create caochong 2> /dev/null

# remove the outdated master
docker rm -f $(docker ps -a -q -f "name=$NODE_NAME_PREFIX") 2>&1 > /dev/null

# launch containers
master_id=$(docker run -d --net caochong -p $PORT:8080 --name $NODE_NAME_PREFIX-0 caochong-ambari)
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run -d --net caochong --name $NODE_NAME_PREFIX-$i caochong-ambari)
    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:/root
# print the hostnames
echo "Using the following hostnames:"
echo "------------------------------"
cat hosts
echo "------------------------------"

# print the private key
echo "Copying back the private key..."
docker cp $master_id:/root/.ssh/id_rsa .

# the following functionality (run in secure mode) is IN PROGRESS
if [ $S -eq 1 ]; then
    echo '
#!/bin/sh

echo "Installing Kerberos"
yum install -y krb5-server krb5-libs krb5-workstation

echo "Using default configuration"
REALM="EXAMPLE.COM"

HOSTNAME=`hostname`
cat >/etc/krb5.conf <<EOF
[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    default_realm = ${REALM}
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    ${REALM} = {
        kdc = ${HOSTNAME}
        admin_server = ${HOSTNAME}
    }

[domain_realm]
    .${HOSTNAME} = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

echo "Creating kadm5.acl file"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

echo "Creating KDC database"
kdb5_util create -s -P hadoop

echo "Creating administriative account. Principal: admin/admin. Password: ambari"
kadmin.local -q "addprinc -pw ambari admin/admin"

echo "Starting services"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on' >> install_Kerberos.sh

    # Copy the Kerberos installation script to the master container
    echo "Copying the Kerberos installation script..."
    docker cp install_Kerberos.sh $master_id:/root

fi

# Start the ambari server
docker exec $NODE_NAME_PREFIX-0 ambari-server start
