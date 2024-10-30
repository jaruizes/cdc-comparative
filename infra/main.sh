#!/bin/bash
set -e

ROOT_FOLDER="$(pwd)"
AWS_ZONE="eu-west-1"


executeTerraform() {
  echo "TF_BACKEND_KEY=$TF_BACKEND_KEY"
  echo "CLUSTER_NAME=$CLUSTER_NAME"
  echo "CLUSTER_ZONE=$AWS_ZONE"

  cd "$ROOT_FOLDER/aws/terraform"

  terraform init
  terraform plan
  terraform apply -auto-approve
}

setPermissionsSSH() {
  chmod 400 "$ROOT_FOLDER/aws/ssh/toolskey"
}

configureKubectl() {
  aws eks --profile paradigma --region "$AWS_ZONE" update-kubeconfig --name cdc
}

setupOracleLogMiner() {
  DB_TOOLS_IP=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw dbtools_public_ip)
  ORACLE_RDS_ENDPOINT=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw db_rds_oracle_endpoint)

  echo "-------------------------------------------"
  echo "Configuring Oracle for CDC (Debezium)"

  scp -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "$ROOT_FOLDER"/scripts/db/setup/setup_logminer.sql "ec2-user@$DB_TOOLS_IP:/tmp"
  scp -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "$ROOT_FOLDER"/scripts/db/setup/setup_logminer.sh "ec2-user@$DB_TOOLS_IP:/tmp"

  ssh -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "ec2-user@$DB_TOOLS_IP" "sh /tmp/setup_logminer.sh $ORACLE_RDS_ENDPOINT"

  echo "Oracle for CDC (Debezium) configured!"
  echo "-------------------------------------------"
}

setupOracleKafkaConnect() {
  BROKER=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw kafka_bootstrap | awk -F "," '{print $1}')

  echo "-------------------------------------------"
  echo "Installing and configuring Debezium (CDC from Oracle) - Kafka Connect"

  sed 's/#BROKER#/'"$BROKER"'/g' "$K8S_FOLDER/oracle_kafka_connect/oracle-kafka-connect.yml" | kubectl apply -n "$RETAIL_NAMESPACE" -f -
  sleep 20
  oracle_kafka_connect_pod_name=$(kubectl get pods -n $RETAIL_NAMESPACE --selector="app=oracleconnect" -o jsonpath='{.items[*].metadata.name}')

  printf "\nWaiting for Oracle Kafka Connect Pod ($oracle_kafka_connect_pod_name)..."
  while [ "$(kubectl get pod $oracle_kafka_connect_pod_name -n $RETAIL_NAMESPACE -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
    printf '.'
    sleep 5
  done

  sed 's/#ORACLE_IP#/'"$ORACLE_RDS_ENDPOINT_WITHOUT_PORT"'/g ; s/#BROKER#/'"$BROKER"'/g' "$K8S_FOLDER/oracle_kafka_connect/register-oracle-logminer-template.json" >"$K8S_FOLDER/oracle_kafka_connect/register-oracle-logminer.json"

  kubectl cp "$K8S_FOLDER/oracle_kafka_connect/register-oracle-logminer.json" "$oracle_kafka_connect_pod_name":/tmp -n "$RETAIL_NAMESPACE"
  kubectl cp "$K8S_FOLDER/oracle_kafka_connect/register-oracle-connector.sh" "$oracle_kafka_connect_pod_name":/tmp -n "$RETAIL_NAMESPACE"

  sleep 10
  kubectl exec "$oracle_kafka_connect_pod_name" -n "$RETAIL_NAMESPACE" -- bash /tmp/register-oracle-connector.sh "$oracle_kafka_connect_pod_name"
  rm "$K8S_FOLDER/oracle_kafka_connect/register-oracle-logminer.json"

  echo "Debezium - Kafka Connect installed and configured!"
  echo "-------------------------------------------"
}



setupLoader() {

  DB_TOOLS_IP=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw dbtools_public_ip)
  ORACLE_RDS_ENDPOINT=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw db_rds_oracle_endpoint)

  echo "-------------------------------------------"
  echo "Installing and configuring Oracle DB"

  scp -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "$ROOT_FOLDER"/scripts/db/loader/create_tables.sql "ec2-user@$DB_TOOLS_IP:/tmp"
  scp -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "$ROOT_FOLDER"/scripts/db/loader/create_tables.sh "ec2-user@$DB_TOOLS_IP:/tmp"

  ssh -o StrictHostKeyChecking=no -i "$ROOT_FOLDER/aws/ssh/toolskey" "ec2-user@$DB_TOOLS_IP" "sh /tmp/create_tables.sh $ORACLE_RDS_ENDPOINT"

  echo "Oracle DB installed and configured!"
  echo "-------------------------------------------"

}


installKafdrop() {
  BROKERS=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -json kafka_bootstrap | awk '{gsub(/[\[\]\"]/,""); print $1;}' | awk -F "," '{print $1}')

  echo "-------------------------------------------"
  echo "Installing and configuring Kafdrop"
  echo "Broker: $BROKERS"

  kubectl create namespace kafka | true
  sed 's/#BROKERS#/'"$BROKERS"'/g' "$ROOT_FOLDER"/manifests/kafdrop/kafdrop.yml | kubectl apply -n kafka -f -

  sleep 5

  echo "Kafdrop installed and configured!"
  echo "-------------------------------------------"

}

createECR() {
  echo "-------------------------------------------"
  echo "Installing and configuring Kafdrop"

  aws ecr create-repository --repository-name cdc/debezium-oracle-connector

  echo "-------------------------------------------"
}

setupConnectDbz() {
  ORACLE_RDS_ENDPOINT=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw db_rds_oracle_endpoint)
  BROKERS=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -json kafka_bootstrap | awk '{gsub(/[\[\]\"]/,""); print $1;}' | awk -F "," '{print $1}')

  echo "-------------------------------------------"
  echo "Deploying connect in K8s cluster"

  if [[ "$(kubectl get deployment c-connect-v1 -n kafka -o 'jsonpath={..status.readyReplicas}')" == 1 ]]
    then
        echo "Removing previous deployment......"
        kubectl delete -f "$ROOT_FOLDER"/manifests/connect/connect.yaml -n kafka
        secs=300
        while [ $secs -gt 0 ]
        do
          printf "\r\033[KWaiting %.d seconds to everything is deleted..." $((secs))
          secs=$(($secs-1))
          sleep 1
        done
    fi

  sed 's/#BROKERS#/'"$BROKERS"'/g' "$ROOT_FOLDER"/manifests/connect/connect.yaml | kubectl apply -n kafka -f -
  secs=60
  while [ $secs -gt 0 ]
  do
    printf "\r\033[KWaiting %.d seconds to everything is created..." $((secs))
    secs=$(($secs-1))
    sleep 1
  done

  connect_pod_name=$(kubectl get pods -n kafka --selector="app=c-connect" -o jsonpath='{.items[*].metadata.name}')
  echo "connect_pod_name=$connect_pod_name"

  printf "\nWaiting for Connect Pod ($connect_pod_name)..."
  while [ "$(kubectl get pod $connect_pod_name -n kafka -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
    printf '.'
    sleep 10
  done
  echo .

#  kubectl cp "$ROOT_FOLDER/manifests/connect/volumes/debezium-connector-oracle/" "$connect_pod_name":/usr/share/confluent-hub-components/ -n kafka | true
#  kubectl delete pod "$connect_pod_name" -n kafka

#  sleep 60

  ORACLE_RDS_ENDPOINT_WITHOUT_PORT=$(echo "$ORACLE_RDS_ENDPOINT" | awk -F ":" '{print $1}')
  sed 's/#ORACLE_ENDPOINT#/'"$ORACLE_RDS_ENDPOINT_WITHOUT_PORT"'/g ; s/#BROKERS#/'"$BROKERS"'/g' "$ROOT_FOLDER/manifests/connect/oracle-connect-template.json" > "$ROOT_FOLDER/manifests/connect/oracle-connect.json"

#  connect_pod_name=$(kubectl get pods -n kafka --selector="app=c-connect" -o jsonpath='{.items[*].metadata.name}')
  kubectl cp "$ROOT_FOLDER/manifests/connect/oracle-connect.json" "$connect_pod_name":/tmp/ -n kafka
  kubectl cp "$ROOT_FOLDER/manifests/connect/register-connector-oracle.sh" "$connect_pod_name":/tmp/ -n kafka

  sleep 10
  kubectl exec "$connect_pod_name" -n kafka -- bash /tmp/register-connector-oracle.sh "$connect_pod_name"

  rm "$ROOT_FOLDER/manifests/connect/oracle-connect.json"

  echo "Connect deployed!"
  echo "-------------------------------------------"
}


setupConnectDbz2() {
  ORACLE_RDS_ENDPOINT=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw db_rds_oracle_endpoint)
  BROKERS=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -json kafka_bootstrap | awk '{gsub(/[\[\]\"]/,""); print $1;}' | awk -F "," '{print $1}')

  echo "-------------------------------------------"
  echo "Deploying connect in K8s cluster"

  if [[ "$(kubectl get deployment c-connect-v1 -n kafka -o 'jsonpath={..status.readyReplicas}')" == 1 ]]
    then
        echo "Removing previous deployment......"
        kubectl delete -f "$ROOT_FOLDER"/manifests/connect/connect.yaml -n kafka
        secs=300
        while [ $secs -gt 0 ]
        do
          printf "\r\033[KWaiting %.d seconds to everything is deleted..." $((secs))
          secs=$(($secs-1))
          sleep 1
        done
    fi

  sed 's/#BROKERS#/'"$BROKERS"'/g' "$ROOT_FOLDER"/manifests/connect/connect.yaml | kubectl apply -n kafka -f -
  secs=60
  while [ $secs -gt 0 ]
  do
    printf "\r\033[KWaiting %.d seconds to everything is created..." $((secs))
    secs=$(($secs-1))
    sleep 1
  done

  connect_pod_name=$(kubectl get pods -n kafka --selector="app=c-connect" -o jsonpath='{.items[*].metadata.name}')
  echo "connect_pod_name=$connect_pod_name"

  printf "\nWaiting for Connect Pod ($connect_pod_name)..."
  while [ "$(kubectl get pod $connect_pod_name -n kafka -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
    printf '.'
    sleep 10
  done
  echo .

  kubectl cp "$ROOT_FOLDER/manifests/connect/volumes/debezium-connector-oracle/" "$connect_pod_name":/usr/share/confluent-hub-components/ -n kafka | true
  kubectl delete pod "$connect_pod_name" -n kafka

  sleep 60

  ORACLE_RDS_ENDPOINT_WITHOUT_PORT=$(echo "$ORACLE_RDS_ENDPOINT" | awk -F ":" '{print $1}')
  sed 's/#ORACLE_ENDPOINT#/'"$ORACLE_RDS_ENDPOINT_WITHOUT_PORT"'/g ; s/#BROKERS#/'"$BROKERS"'/g' "$ROOT_FOLDER/manifests/connect/oracle-connect-template.json" > "$ROOT_FOLDER/manifests/connect/oracle-connect.json"

  connect_pod_name=$(kubectl get pods -n kafka --selector="app=c-connect" -o jsonpath='{.items[*].metadata.name}')
  kubectl cp "$ROOT_FOLDER/manifests/connect/oracle-connect.json" "$connect_pod_name":/tmp/ -n kafka
  kubectl cp "$ROOT_FOLDER/manifests/connect/register-connector-oracle.sh" "$connect_pod_name":/tmp/ -n kafka

  sleep 10
  kubectl exec "$connect_pod_name" -n kafka -- bash /tmp/register-connector-oracle.sh "$connect_pod_name"

  rm "$ROOT_FOLDER/manifests/connect/oracle-connect.json"

  echo "Connect deployed!"
  echo "-------------------------------------------"
}

showInfo() {
  KafdropURL=$(kubectl get service kafdrop -n kafka -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}/')
  prometheusURL=$(kubectl get service kube-prometheus-stack-prometheus -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}/')
  grafanaURL=$(kubectl get service kube-prometheus-stack-grafana -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}/')
  grafanaPassword=$(kubectl get secret kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)

  clear
  echo ""
  echo ""
  echo "----------------- TOOLS ------------------------"
  echo " - Kafdrop: $KafdropURL"
  echo " - Prometheus: $prometheusURL"
  echo " - Grafana: $grafanaURL"
  echo ""
  echo ""
  echo ""
  echo " - Grafana credentials: admin/$grafanaPassword"
  echo ""

  echo ""
  echo ""

}

createDMSOracleSourceEndpoint() {
  echo "-------------------------------------------"
  echo "Creating DMS Oracle Source Endpoint"

  ORACLE_RDS_ENDPOINT=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw db_rds_oracle_endpoint)
  ORACLE_RDS_ENDPOINT_WITHOUT_PORT=$(echo "$ORACLE_RDS_ENDPOINT" | awk -F ":" '{print $1}')

  aws --no-paginate --region "$AWS_ZONE" dms create-endpoint \
      --endpoint-identifier src-orcl-endpoint \
      --endpoint-type source \
      --engine-name oracle \
      --username dbzuser \
      --password dbz \
      --server-name "$ORACLE_RDS_ENDPOINT_WITHOUT_PORT" \
      --port 1521 \
      --database-name cdc \
      --resource-identifier src-orcl-endpoint

  echo "-------------------------------------------"
}

createDMSKafkaTargetEndpoint() {
  echo "-------------------------------------------"
  echo "Creating DMS Kafka Target Endpoint"

  BROKERS=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -json kafka_bootstrap | awk '{gsub(/[\[\]\"]/,""); print $1;}' | awk -F "," '{print $1}')

  aws --no-paginate --region "$AWS_ZONE" dms create-endpoint \
      --endpoint-identifier target-kafka-endpoint \
      --endpoint-type target \
      --engine-name kafka \
      --kafka-settings Broker="${BROKERS}",Topic="dmscdc" \
      --resource-identifier target-kafka-endpoint

  echo "-------------------------------------------"
}

createDMSReplicationSubnetGroup() {
  echo "-------------------------------------------"
  echo "Creating DMS Replication Instance"

  SUBNETS=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -json vpc_private_subnets)
  echo $SUBNETS


  aws --no-paginate --region "$AWS_ZONE" dms create-replication-subnet-group \
      --replication-subnet-group-identifier cdcreplicationsubnetgroup \
      --replication-subnet-group-description dmscdc \
      --subnet-ids "$SUBNETS"

  echo "-------------------------------------------"

}

createDMSReplicationInstance() {
  echo "-------------------------------------------"
  echo "Creating DMS Replication Instance"

  SECURITY_GROUP=$(terraform -chdir="$ROOT_FOLDER/aws/terraform" output -raw general_security_group_id)
#  SECURITY_GROUP="sg-03fa0dec534c0c06b"

  aws --no-paginate --region "$AWS_ZONE" dms create-replication-instance \
      --replication-instance-identifier cdcora2kafkainst \
      --replication-instance-class dms.r5.xlarge \
      --vpc-security-group-ids "$SECURITY_GROUP"  \
      --replication-subnet-group-identifier cdcreplicationsubnetgroup \
      --resource-identifier cdc-ora2kafka-inst

  echo "-------------------------------------------"
}

createDMSTaskOracle2Kafka() {
  echo "-------------------------------------------"
  echo "Creating DMS Task for Initial Load Oracle to Kafka"

  aws --region "$AWS_ZONE" dms wait replication-instance-available \
      --filters Name=replication-instance-arn,Values=arn:aws:dms:eu-west-1:043264546031:rep:cdc-ora2kafka-inst

  aws --region "$AWS_ZONE" dms create-replication-task \
      --replication-task-identifier cdcoracle2kafkatask \
      --resource-identifier cdc-oracle2kafka-task \
      --source-endpoint-arn arn:aws:dms:eu-west-1:043264546031:endpoint:src-orcl-endpoint \
      --target-endpoint-arn arn:aws:dms:eu-west-1:043264546031:endpoint:target-kafka-endpoint \
      --migration-type full-load-and-cdc \
      --replication-instance-arn arn:aws:dms:eu-west-1:043264546031:rep:cdc-ora2kafka-inst \
      --table-mappings file://"$ROOT_FOLDER/manifests/dms/orcl-table-mappings.json" \
      --replication-task-settings file://"$ROOT_FOLDER/manifests/dms/oracle2kafka-task-settings.json"

  echo "-------------------------------------------"
}

runDMSTaskOracle2Kafka() {
  echo "-------------------------------------------"
  echo "Running DMS Task for Initial Load Oracle to Kafka"

  echo "Waiting for 'cdc-oracle2kafka-task' be ready....."
  aws --region "$AWS_ZONE" dms wait replication-task-ready --filters Name=replication-task-id,Values=cdcoracle2kafkatask

  echo "Starting task 'cdc-oracle2kafka-task'....."
  aws --no-paginate --region "$AWS_ZONE" dms start-replication-task \
      --replication-task-arn arn:aws:dms:eu-west-1:043264546031:task:cdc-oracle2kafka-task \
      --start-replication-task-type start-replication

  echo "Waiting for 'cdc-oracle2kafka-task....."
  aws --region "$AWS_ZONE" dms wait replication-task-running \
     --filters Name=replication-task-id,Values=cdcoracle2kafkatask

  echo "-------------------------------------------"
}


setupDMS() {
  echo "-------------------------------------------"
  echo "Configuring DMS"

  export AWS_PAGER=""

  createDMSOracleSourceEndpoint
  createDMSKafkaTargetEndpoint
  createDMSReplicationSubnetGroup
  createDMSReplicationInstance
  createDMSTaskOracle2Kafka
  runDMSTaskOracle2Kafka

  echo "-------------------------------------------"
}

createECRandPublishDbzImage() {
  echo "-------------------------------------------"
  echo "Creating ECR"

  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 043264546031.dkr.ecr.eu-west-1.amazonaws.com
  aws ecr create-repository --repository-name cdc/dbz_oracle --region eu-west-1 --tags Key=app,Value=cdc

  cd "$ROOT_FOLDER/manifests/connect"
  docker build . -t dbz-oracle:1.0
  docker tag dbz-oracle:1.0 043264546031.dkr.ecr.eu-west-1.amazonaws.com/cdc/dbz_oracle:1.0
  docker push 043264546031.dkr.ecr.eu-west-1.amazonaws.com/cdc/dbz_oracle:1.0

  echo "-------------------------------------------"
}

monitoring() {
  echo "-------------------------------------------"
  echo "Monitoring"

  cd "$ROOT_FOLDER/manifests/monitoring"
  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f values.yaml
}

main() {
#  setPermissionsSSH
#  executeTerraform
#  setupOracleLogMiner
#  setupLoader
#  configureKubectl
#  installKafdrop
#  createECRandPublishDbzImage
  setupConnectDbz
#  setupDMS
  showInfo
}

main
