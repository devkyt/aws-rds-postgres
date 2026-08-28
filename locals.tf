locals {
  database_identifier = coalesce(var.database_identifier, "${var.app}-${var.env}")
  secret_version      = var.secret_version

  username = var.username != null ? var.username : try(random_string.username.result, null)
  password = var.password != null ? var.password : ephemeral.random_password.password.result

  create_monitoring_role = var.monitoring_role_arn == null && var.monitoring_interval_sec > 0

  create_subnet_group = var.subnet_group_name == null && length(var.subnet_ids) > 0
  subnet_group_name   = var.subnet_group_name != null ? var.subnet_group_name : try(aws_db_subnet_group.main.name, null)

  replica_instance_type = coalesce(var.replica_instance_type, var.instance_type)

  parameter_group_family = coalesce(
    var.parameter_group_family,
    "postgres${split(".", var.postgres_version)[0]}"
  )

  parameters_require_reboot = [
    "max_connections",
    "max_prepared_transactions",
    "max_worker_processes",
    "max_locks_per_transaction",
    "track_commit_timestamp",
    "shared_preload_libraries",
  ]

  default_tags = var.include_default_tags ? {
    App         = var.app
    Environment = var.env
    Env         = var.env
    Terraform   = "true"
    ManagedBy   = "Terraform"
  } : {}

  tags = merge(local.default_tags, var.tags)
}
