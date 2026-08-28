output "database_id" {
  description = "RDS identifier of the primary Postgres database"
  value       = aws_db_instance.primary.identifier
}


output "database_arn" {
  description = "ARN of the primary Postgres database"
  value       = aws_db_instance.primary.arn
}


output "database_endpoint" {
  description = "Connection endpoint (host:port) of the primary Postgres database"
  value       = aws_db_instance.primary.endpoint
}


output "database_address" {
  description = "Hostname of the primary Postgres database"
  value       = aws_db_instance.primary.address
}


output "database_port" {
  description = "Port of the primary Postgres database"
  value       = aws_db_instance.primary.port
}


output "database_name" {
  description = "Name of the initial Postgres database"
  value       = aws_db_instance.primary.db_name
}


output "replica_ids" {
  description = "RDS identifiers of the read replicas"
  value       = aws_db_instance.replicas[*].identifier
}


output "replica_arns" {
  description = "ARNs of the read replicas"
  value       = aws_db_instance.replicas[*].arn
}


output "replica_endpoints" {
  description = "Connection endpoints (host:port) of the read replicas"
  value       = aws_db_instance.replicas[*].endpoint
}


output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding database credentials"
  value       = aws_secretsmanager_secret.main.arn
}


output "secret_name" {
  description = "Name of the Secrets Manager secret holding database credentials"
  value       = aws_secretsmanager_secret.main.name
}


output "secret_version_id" {
  description = "Version ID of the current Secrets Manager secret value"
  value       = aws_secretsmanager_secret_version.main.version_id
}


output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.main.id
}


output "database_connection_url" {
  description = "Postgres connection URL for the primary database (includes credentials)"
  value       = "postgres://${local.username}:${local.password}@${aws_db_instance.primary.address}:${aws_db_instance.primary.port}/${aws_db_instance.primary.db_name}?sslmode=require"
  ephemeral   = true
}
