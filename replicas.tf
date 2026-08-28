# ---------------------------------------------
# Read Replicas Of The Primary Database
# ---------------------------------------------
resource "aws_db_instance" "replicas" {
  count = var.replicas

  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = local.replica_instance_type

  identifier        = var.use_name_prefix ? null : "${local.database_identifier}-replica-${count.index}"
  identifier_prefix = var.use_name_prefix ? "${local.database_identifier}-replica-${count.index}-" : null

  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name   = local.subnet_group_name
  availability_zone      = var.availability_zone
  publicly_accessible    = var.publicly_accessible
  ca_cert_identifier     = var.ca_cert_identifier

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  parameter_group_name = try(coalesce(
    try(aws_db_parameter_group.replica.name, null),
    try(aws_db_parameter_group.primary.name, null)
  ), null)

  # No backup on replicas
  backup_retention_period = 0
  skip_final_snapshot     = true

  database_insights_mode                = var.database_insights_mode
  performance_insights_enabled          = var.performance_insights.enabled
  performance_insights_kms_key_id       = var.performance_insights.enabled ? var.performance_insights.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights.enabled ? var.performance_insights.retention_period : null

  monitoring_interval = var.monitoring_interval_sec
  monitoring_role_arn = var.monitoring_interval_sec > 0 ? coalesce(var.monitoring_role_arn, try(aws_iam_role.monitoring.arn, null)) : null

  auto_minor_version_upgrade = var.maintenance.auto_minor_version_upgrade

  timeouts {
    create = var.tofu_apply_timeouts.create
    delete = var.tofu_apply_timeouts.delete
    update = var.tofu_apply_timeouts.update
  }

  tags = merge(local.tags,
    {
      Name = "${local.database_identifier}-replica-${count.index}"
      Type = "Postgres"
      Tier = "Replica"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# Parameter Group For The Read Replicas
# ---------------------------------------------
resource "aws_db_parameter_group" "replica" {
  name        = var.use_name_prefix ? null : "${local.database_identifier}-replica-parameters"
  name_prefix = var.use_name_prefix ? "${local.database_identifier}-replica-parameters-" : null
  family      = local.parameter_group_family

  dynamic "parameter" {
    for_each = merge(
      coalesce(var.primary_parameter_group, {}),
      var.replica_parameter_group,
    )

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = contains(local.parameters_require_reboot, parameter.key) ? "pending-reboot" : "immediate"
    }
  }

  tags = merge(local.tags,
    {
      Name = "${local.database_identifier}-replica-parameters"
      Type = "Postgres Parameters"
      Tier = "Replica"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = var.replica_parameter_group != null
  }
}
