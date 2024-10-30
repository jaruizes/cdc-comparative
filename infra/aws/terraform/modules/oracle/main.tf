module "oracledb" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier = var.db_name

  engine               = "oracle-se2"
  engine_version       = "19.0.0.0.ru-2024-04.rur-2024-04.r1"
  major_engine_version = "19"
  instance_class       = "db.t3.xlarge"
  family               = "oracle-se2-19"
  license_model        = "license-included"

  allocated_storage     = 100
  max_allocated_storage = 400
  storage_encrypted     = false
  auto_minor_version_upgrade = false

  db_name  = var.db_name
  manage_master_user_password = false
  username = "admin"
  password = "oracledb"
  port     = 1521

  multi_az               = false
  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = var.vpc_public_subnets
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = true

  backup_retention_period         = 1  // Enable backups to enable ARCHIVELOG
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  delete_automated_backups        = true
  #enabled_cloudwatch_logs_exports = ["oracle", "upgrade"]

  skip_final_snapshot     = true
  deletion_protection     = false

  parameters = [
    {
      name  = "enable_goldengate_replication"
      value = "TRUE"
    }
  ]
  character_set_name = "AL32UTF8"

  tags = {
    app = var.db_name
  }

}
