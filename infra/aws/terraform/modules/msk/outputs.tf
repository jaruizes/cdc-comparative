output "bootstrap_brokers" {
  description = "Bootstrap brokers"
  value       = module.msk_kafka_cluster.bootstrap_brokers
}
