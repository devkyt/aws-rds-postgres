# ---------------------------------------------
# Primary Postgres Database Instance
# ---------------------------------------------
resource "aws_db_instance" "primary" {
  engine         = "postgres"
  engine_version = var.postgres_version

  snapshot_identifier = var.snapshot_identifier
  instance_class      = var.instance_type

  identifier        = var.use_name_prefix ? null : local.database_identifier
  identifier_prefix = var.use_name_prefix ? "${local.database_identifier}-" : null
  db_name           = var.database_name
  port              = var.port

  username            = local.username
  password_wo         = local.password
  password_wo_version = local.secret_version

  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name   = local.subnet_group_name
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : var.availability_zone
  publicly_accessible    = var.publicly_accessible
  ca_cert_identifier     = var.ca_cert_identifier

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  storage_type          = var.storage.type
  storage_encrypted     = var.database_kms_key_arn != null || var.storage.encrypted
  kms_key_id            = var.database_kms_key_arn
  allocated_storage     = var.storage.size_gb
  max_allocated_storage = var.storage.max_size_gb
  iops                  = var.storage.iops
  storage_throughput    = var.storage.throughput

  parameter_group_name = try(aws_db_parameter_group.primary.name, null)

  maintenance_window         = var.maintenance.window
  auto_minor_version_upgrade = var.maintenance.auto_minor_version_upgrade

  backup_window            = var.backup.window
  backup_retention_period  = var.backup.retention
  delete_automated_backups = var.backup.delete_automated_backups

  database_insights_mode                = var.database_insights_mode
  performance_insights_enabled          = var.performance_insights.enabled
  performance_insights_kms_key_id       = var.performance_insights.enabled ? var.performance_insights.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights.enabled ? var.performance_insights.retention_period : null

  monitoring_interval = var.monitoring_interval_sec
  monitoring_role_arn = var.monitoring_interval_sec > 0 ? coalesce(var.monitoring_role_arn, try(aws_iam_role.monitoring.arn, null)) : null

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.protect_from_deletion

  skip_final_snapshot       = var.backup.skip_final_snapshot
  final_snapshot_identifier = coalesce(var.backup.final_snapshot_id, "${local.database_identifier}-final")
  copy_tags_to_snapshot     = var.backup.copy_tags_to_snapshot

  timeouts {
    create = var.tofu_apply_timeouts.create
    delete = var.tofu_apply_timeouts.delete
    update = var.tofu_apply_timeouts.update
  }

  tags = merge(local.tags,
    {
      Name = local.database_identifier
      Type = "Postgres"
      Tier = "Primary"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      snapshot_identifier
    ]
  }
}


# ---------------------------------------------
# Parameter Group For The Primary Instance
# ---------------------------------------------
resource "aws_db_parameter_group" "primary" {
  name        = var.use_name_prefix ? null : "${local.database_identifier}-parameters"
  name_prefix = var.use_name_prefix ? "${local.database_identifier}-parameters-" : null
  family      = local.parameter_group_family

  dynamic "parameter" {
    for_each = var.primary_parameter_group

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = contains(local.parameters_require_reboot, parameter.key) ? "pending-reboot" : "immediate"
    }
  }

  tags = merge(local.tags,
    {
      Name = "${local.database_identifier}-parameters"
      Type = "Postgres Parameters"
      Tier = "Primary"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = var.primary_parameter_group != null
  }
}


# ---------------------------------------------
# DB Subnet Group (Skipped When No Subnets Given)
# ---------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = var.use_name_prefix ? null : "${local.database_identifier}-subnet-group"
  name_prefix = var.use_name_prefix ? "${local.database_identifier}-subnet-group-" : null
  subnet_ids  = var.subnet_ids

  tags = merge(local.tags,
    {
      Name = "${local.database_identifier}-subnet-group"
      Type = "DB Subnet Group"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = local.create_subnet_group
  }
}
