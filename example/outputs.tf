output "database_id" {
  description = "RDS identifier of the primary database"
  value       = module.postgres.database_id
}

output "database_arn" {
  description = "ARN of the primary database"
  value       = module.postgres.database_arn
}

output "database_endpoint" {
  description = "Connection endpoint (host:port) of the primary database"
  value       = module.postgres.database_endpoint
}

output "replica_endpoints" {
  description = "Connection endpoints of the read replicas"
  value       = module.postgres.replica_endpoints
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret with database credentials"
  value       = module.postgres.secret_arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret with database credentials"
  value       = module.postgres.secret_name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = module.postgres.security_group_id
}
