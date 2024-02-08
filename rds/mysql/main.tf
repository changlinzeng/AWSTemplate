resource "random_id" "db_instance_id" {
  prefix = "${var.region}-${var.engine}"
  byte_length = 8
  keepers = {
    db_name = var.db_name
  }
}

locals {
  db_id = random_id.db_instance_id.hex
}

resource "aws_db_subnet_group" "this_subnet_group" {
  name       = "subnet-group-${local.db_id}"
  subnet_ids = data.aws_subnets.private_subnets.ids
  tags = merge(var.tags, {
    Usage = "RDS"
  })
}

resource "aws_db_instance" "this" {
  identifier          = local.db_id
  publicly_accessible = false

  db_name               = var.db_name
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  storage_type          = var.storage_type
  iops                  = var.iops == 0 ? null : var.iops
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_arn
  license_model         = var.license_model

  username                            = var.master_username
  password                            = var.master_password
  port                                = var.port
  domain                              = null
  domain_iam_role_name                = null
  iam_database_authentication_enabled = false
  character_set_name                  = var.character_set_name
  timezone                            = var.time_zone

  vpc_security_group_ids = var.security_groups_ids
  db_subnet_group_name   = var.db_subnet_group_name != "" && var.db_subnet_group_name != null ? var.db_subnet_group_name : aws_db_subnet_group.this_subnet_group.name
  parameter_group_name   = var.parameter_group_name
  option_group_name      = var.option_group_name

  availability_zone  = var.multi_az ? null : var.availability_zone
  multi_az           = var.multi_az
  ca_cert_identifier = var.ca_cert_identifier

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = true
  maintenance_window          = var.maintenance_window

  skip_final_snapshot         = true
  #  snapshot_identifier       = var.snapshot_identifier
  #  copy_tags_to_snapshot     = true
  #  skip_final_snapshot       = var.skip_final_snapshot
  #  final_snapshot_identifier = local.final_snapshot_identifier
  #
  #  performance_insights_enabled          = var.performance_insights_enabled
  #  performance_insights_retention_period = var.performance_insights_retention_period
  #  performance_insights_kms_key_id       = local.kms_key_arn
  #
  #  replicate_source_db = var.replicate_source_db
  #
  #  backup_retention_period = var.backup_retention_period
  #  backup_window           = var.backup_window
  #  max_allocated_storage   = var.max_allocated_storage
  #  monitoring_interval     = var.monitoring_interval
  #  monitoring_role_arn     = var.monitoring_interval > 0 ? local.monitoring_role_arn : null
  #
  #  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection      = var.deletion_protection
  delete_automated_backups = var.delete_automated_backups

  tags = merge(var.tags, {
    Usage = "RDS"
    Name  = local.db_id
  })

  timeouts {
    create = lookup(local.timeouts, "create", null)
    delete = lookup(local.timeouts, "delete", null)
    update = lookup(local.timeouts, "update", null)
  }

  lifecycle {
    ignore_changes = [
      password
    ]
    precondition {
      condition     = var.iops == 0 || var.iops == null || var.iops > 0 && contains(["gp3", "io1"], var.storage_type)
      error_message = "Storage type must be gp3 or io1 when IOPS specified"
    }
    precondition {
      condition     = (var.iops == 0 || var.iops == null) && contains(["standard", "gp2"], var.storage_type) || !contains(["standard", "gp2"], var.storage_type)
      error_message = "IOPS should not be set when storage type is standard or gp2"
    }
    precondition {
      condition     = !var.storage_encrypted || var.storage_encrypted && var.kms_key_arn != ""
      error_message = "KMS key arn should be sepcified when storage encrypted"
    }
  }
}

#resource "aws_db_proxy" "this" {
#  engine_family  = ""
#  name           = ""
#  role_arn       = ""
#  vpc_subnet_ids = []
#}