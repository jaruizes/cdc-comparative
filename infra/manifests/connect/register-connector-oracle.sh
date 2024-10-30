#!/bin/bash
set -e

echo "-----------------------------"
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" "http://$1:8083/connectors/" -d @"/tmp/oracle-connect.json"
