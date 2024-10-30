module "msk_kafka_cluster" {
  source = "terraform-aws-modules/msk-kafka-cluster/aws"

  name                   = var.msk_cluster_name
  kafka_version          = var.msk_cluster_version
  number_of_broker_nodes = 3

  broker_node_client_subnets = var.vpc_private_subnets
  broker_node_storage_info = {
    ebs_storage_info = { volume_size = 100 }
  }

  broker_node_instance_type   = var.msk_cluster_nodes_instance_type
  broker_node_security_groups = [var.security_group_id]
  encryption_in_transit_client_broker = "PLAINTEXT"

  configuration_name        = "base-configuration"
  configuration_description = "Base configuration"
  configuration_server_properties = {
    "auto.create.topics.enable" = true
    "delete.topic.enable"       = true
  }

  jmx_exporter_enabled    = true
  node_exporter_enabled   = true
  cloudwatch_logs_enabled = true

  tags = {
    app = var.msk_cluster_name
  }
}

