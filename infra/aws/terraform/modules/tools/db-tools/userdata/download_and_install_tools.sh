#!/bin/bash

curl https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm --output /tmp/oracle-instantclient.rpm
curl https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm --output /tmp/oracle-sqlplus.rpm

sudo rpm -i /tmp/oracle-instantclient.rpm
sudo rpm -i /tmp/oracle-sqlplus.rpm
