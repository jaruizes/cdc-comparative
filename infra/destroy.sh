#!/bin/bash
set -e

ROOT_FOLDER="$(pwd)"
AWS_ZONE="eu-west-1"

configureKubectl() {
  aws eks --profile paradigma --region "$AWS_ZONE" update-kubeconfig --name cdc
}

removeNamespaces() {
  echo "-------------------------------------------"
  echo "Removing namespaces...."

  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

  for namespace in $namespaces; do
    echo ""
    echo ""
    echo "Removing namespaces: $namespace"
    if [ $namespace != "default" ] && [ $namespace != "kube-public" ] && [ $namespace != "kube-system" ] && [ $namespace != "kube-node-lease" ]; then
      kubectl delete namespace "$namespace"
      kubectl create namespace "$namespace"
    fi

  done

  ## Remove all in default namespace
  kubectl delete all --all

  echo "Removing services with type LoadBalancer to force AWS to remove ELBs objects.....OK!"
  echo "-------------------------------------------"
}

removeTerraform() {
  echo "TF_BACKEND_KEY=$TF_BACKEND_KEY"
  echo "CLUSTER_NAME=$CLUSTER_NAME"
  echo "CLUSTER_ZONE=$AWS_ZONE"

  cd "$ROOT_FOLDER/aws/terraform"

  terraform destroy -auto-approve
}

removeDMS() {
  echo "-------------------------------------------"
  echo "Removing DMS...."

  export AWS_PAGER=""

  aws --no-paginate --region "$AWS_ZONE" dms stop-replication-task \
      --replication-task-arn arn:aws:dms:eu-west-1:043264546031:task:cdc-oracle2kafka-task

  aws --region "$AWS_ZONE" dms wait replication-task-stopped --filters Name=replication-task-id,Values=cdcoracle2kafkatask | true

  aws --no-paginate --region "$AWS_ZONE" dms delete-replication-task --replication-task-arn arn:aws:dms:eu-west-1:043264546031:task:cdc-oracle2kafka-task | true

  aws --region "$AWS_ZONE" dms wait replication-task-deleted \
      --filters Name=replication-task-id,Values=cdcoracle2kafkatask

  aws --no-paginate --region "$AWS_ZONE" dms delete-replication-instance \
      --replication-instance-arn arn:aws:dms:eu-west-1:043264546031:rep:cdc-ora2kafka-inst

  aws --region "$AWS_ZONE" dms wait replication-instance-deleted \
      --filters Name=replication-instance-id,Values=cdcora2kafkainst

  aws --no-paginate --region "$AWS_ZONE" dms delete-endpoint \
      --endpoint-arn arn:aws:dms:eu-west-1:043264546031:endpoint:src-orcl-endpoint

  aws --no-paginate --region "$AWS_ZONE" dms delete-endpoint \
      --endpoint-arn arn:aws:dms:eu-west-1:043264546031:endpoint:target-kafka-endpoint

  aws --no-paginate --region "$AWS_ZONE" dms delete-replication-subnet-group \
      --replication-subnet-group-identifier cdcreplicationsubnetgroup
}

deleteECR() {
  echo "-------------------------------------------"
  echo "Removing ECR...."

  aws ecr delete-repository --repository-name cdc/dbz_oracle --region eu-west-1 --force
  docker rmi dbz-oracle:latest --force
  docker rmi dbz-oracle:1.0 --force
  docker rmi 043264546031.dkr.ecr.eu-west-1.amazonaws.com/cdc/dbz_oracle --force


  echo "-------------------------------------------"
}


main() {
#  removeDMS
  deleteECR
  configureKubectl
  removeNamespaces
  removeTerraform
}

main
