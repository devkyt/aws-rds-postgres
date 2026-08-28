# ---------------------------------------------
# Generated Master Username (When None Supplied)
# ---------------------------------------------
resource "random_string" "username" {
  length  = 10
  special = false
  upper   = false
  numeric = false

  lifecycle {
    enabled = var.username == null
  }
}


# ---------------------------------------------
# Generated Master Password (Never Stored In State)
# ---------------------------------------------
ephemeral "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_special      = 2
  min_numeric      = 2
  min_upper        = 2
  min_lower        = 2
}


# ---------------------------------------------
# Secrets Manager Secret Holding The Credentials
# ---------------------------------------------
resource "aws_secretsmanager_secret" "main" {
  name        = var.use_name_prefix ? null : "${local.database_identifier}-secret"
  name_prefix = var.use_name_prefix ? "${local.database_identifier}-secret-" : null
  description = "Credentials for the ${local.database_identifier} database"

  kms_key_id = var.secret_kms_key_arn

  tags = merge(local.tags, var.secret_tags,
    {
      Name = "${local.database_identifier}-secret"
      Type = "Secret"
      For  = local.database_identifier
    }
  )

  depends_on = [aws_db_instance.primary]

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# Secret Version With The Connection Details
# ---------------------------------------------
resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id

  secret_string_wo = jsonencode({
    host           = aws_db_instance.primary.address
    port           = aws_db_instance.primary.port
    db_name        = aws_db_instance.primary.db_name
    schema         = aws_db_instance.primary.db_name
    username       = local.username
    password       = local.password
    connection_url = "postgres://${local.username}:${local.password}@${aws_db_instance.primary.address}:${aws_db_instance.primary.port}/${aws_db_instance.primary.db_name}?sslmode=require"
  })
  secret_string_wo_version = local.secret_version

  depends_on = [aws_db_instance.primary, aws_secretsmanager_secret.main]
}
