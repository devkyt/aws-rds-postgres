# AWS RDS Postgres

OpenTofu module for RDS Postgres provisioning. You can find how to use it in [example](./example/) folder
and in the [Examples](#examples) section below.

## Table of Contents

- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Basic Database](#basic-database)
  - [Multi-AZ with Read Replicas](#multi-az-with-read-replicas)
  - [Custom Parameter Group](#custom-parameter-group)
  - [Enhanced Monitoring and Performance Insights](#enhanced-monitoring-and-performance-insights)
  - [Bring Your Own Credentials](#bring-your-own-credentials)
  - [Restore from Snapshot](#restore-from-snapshot)
  - [KMS Encryption](#kms-encryption)
  - [IAM Database Authentication](#iam-database-authentication)
- [Notes](#notes)

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11 |
| AWS provider | ~> 6.0  |
| random provider | ~> 3.7 |

The module relies on write-only attributes (`password_wo`, `secret_string_wo`), ephemeral resources, and the `enabled` meta-argument to toggle conditional resources — all of which require OpenTofu >= 1.11.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `app` | Application name | `string` | - | yes |
| `env` | Target environment | `string` | - | yes |
| `database_identifier` | Custom identifier for the database. Defaults to `{app}-{env}` | `string` | `null` | no |
| `database_name` | Initial Postgres database name | `string` | - | yes |
| `instance_type` | RDS instance class for the primary (e.g. `db.t3.micro`) | `string` | - | yes |
| `postgres_version` | Postgres engine version (e.g. `16.4`, `17.2`, `18.2`) | `string` | - | yes |
| `snapshot_identifier` | Snapshot ID to restore the primary from. Ignored after creation | `string` | `null` | no |
| `username` | Custom username. Auto-generated when null | `string` | `null` | no |
| `password` | Custom password. Auto-generated when null | `string` | `null` | no |
| `secret_version` | Bump to trigger password rotation for the auto-generated secret | `number` | `1` | no |
| `secret_kms_key_arn` | KMS key for the Secrets Manager secret | `string` | `null` | no |
| `secret_tags` | Extra tags applied only to the Secrets Manager secret | `map(string)` | `{}` | no |
| `vpc_id` | VPC where the database will be located | `string` | - | yes |
| `subnet_ids` | Subnets used to create a DB subnet group. Ignored when `subnet_group_name` is set. When empty, AWS uses the default | `list(string)` | `[]` | no |
| `subnet_group_name` | Existing DB subnet group to use as-is. When set, the module does not create its own subnet group | `string` | `null` | no |
| `multi_az` | Multi-AZ deployment for the primary | `bool` | `false` | no |
| `availability_zone` | Single-AZ placement (ignored when `multi_az = true`) | `string` | `null` | no |
| `port` | Port the database listens on | `number` | `5432` | no |
| `ca_cert_identifier` | RDS CA bundle (e.g. `rds-ca-rsa2048-g1`). Null uses the AWS default | `string` | `null` | no |
| `publicly_accessible` | Assign a public endpoint | `bool` | `false` | no |
| `ingress` | Map of security group ingress rules. Each rule must specify exactly one source: `allowed_security_group_id`, `cidr_ipv4`, `cidr_ipv6`, or `prefix_list_id` | `map(object)` | `{}` | no |
| `iam_database_authentication_enabled` | Enable IAM database authentication | `bool` | `false` | no |
| `storage` | Storage configuration: `type`, `encrypted`, `size_gb`, `max_size_gb`, `iops`, `throughput` | `object` | `{}` (gp3 / 20 GB / encrypted) | no |
| `database_kms_key_arn` | KMS key for storage encryption. Setting it forces `storage.encrypted = true` | `string` | `null` | no |
| `parameter_group_family` | DB parameter group family (e.g. `postgres18`). Derived from `postgres_version` when null | `string` | `null` | no |
| `primary_parameter_group` | Postgres parameter overrides for the primary. Null uses the AWS default group | `map(string)` | `null` | no |
| `replica_parameter_group` | Replica parameter overrides merged on top of the primary's. Null reuses the primary's group | `map(string)` | `null` | no |
| `maintenance` | Maintenance configuration: `window`, `auto_minor_version_upgrade` | `object` | `{ window = "sat:18:00-sat:19:00", auto_minor_version_upgrade = true }` | no |
| `backup` | Backup configuration: `window`, `retention`, `copy_tags_to_snapshot`, `delete_automated_backups`, `skip_final_snapshot`, `final_snapshot_id` | `object` | 22:00–23:00, 7 days, copy tags on, delete autos on | no |
| `database_insights_mode` | Database Insights mode: `standard` or `advanced` | `string` | `null` | no |
| `performance_insights` | Performance Insights configuration: `enabled`, `kms_key_arn`, `retention_period`. `retention_period` must be 7, 731, or a multiple of 31; advanced Insights requires `>= 465` | `object` | disabled | no |
| `monitoring_interval_sec` | Enhanced Monitoring interval in seconds. `0` disables it. Allowed: `[0, 1, 5, 10, 15, 30, 60]` | `number` | `0` | no |
| `monitoring_role_arn` | Existing IAM role for Enhanced Monitoring. Null creates one (only when interval > 0) | `string` | `null` | no |
| `enabled_cloudwatch_logs_exports` | Log types exported to CloudWatch (`postgresql`, `upgrade`) | `list(string)` | `["postgresql"]` | no |
| `protect_from_deletion` | Deletion protection on the primary instance | `bool` | `true` | no |
| `replicas` | Number of read replicas (0–15) | `number` | `0` | no |
| `replica_instance_type` | Override instance class for replicas. Falls back to `instance_type` | `string` | `null` | no |
| `tofu_apply_timeouts` | Per-operation timeouts for the primary and replica DB instances: `create`, `delete`, `update` | `object` | all `1h` | no |
| `use_name_prefix` | Use name_prefix instead of a fixed name for created resources, so AWS appends a unique suffix | `bool` | `false` | no |
| `include_default_tags` | Attach the module's default tags (App, Environment, ManagedBy, …) | `bool` | `true` | no |
| `tags` | Tags to attach to the database and related resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `database_id` | RDS identifier of the primary Postgres database |
| `database_arn` | ARN of the primary Postgres database |
| `database_endpoint` | Connection endpoint (`host:port`) of the primary |
| `database_address` | Hostname of the primary |
| `database_port` | Port of the primary |
| `database_name` | Name of the initial Postgres database |
| `replica_ids` | RDS identifiers of the read replicas |
| `replica_arns` | ARNs of the read replicas |
| `replica_endpoints` | Connection endpoints of the read replicas |
| `secret_arn` | ARN of the Secrets Manager secret with database credentials |
| `secret_name` | Name of the Secrets Manager secret with database credentials |
| `secret_version_id` | Version ID of the current Secrets Manager secret value |
| `security_group_id` | ID of the database security group |
| `database_connection_url` | Ephemeral `postgres://` connection URL with credentials |

## Examples

### Basic Database

A minimal single-AZ Postgres instance with a security group ingress from an ECS service.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  vpc_id            = "vpc-0123456789abcdef0"
  subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  availability_zone = "eu-central-1b"

  instance_type    = "db.t3.micro"
  postgres_version = "18.2"

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Multi-AZ with Read Replicas

A production-style primary with Multi-AZ failover, two read replicas, and explicit backup window.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "checkout"
  env           = "prod"
  database_name = "app"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]

  instance_type    = "db.r6g.large"
  postgres_version = "18.2"

  multi_az = true

  storage = {
    type        = "gp3"
    size_gb     = 100
    max_size_gb = 500
  }

  replicas              = 2
  replica_instance_type = "db.r6g.large"

  backup = {
    window    = "02:00-03:00"
    retention = 14
  }

  maintenance = {
    window = "sun:04:00-sun:05:00"
  }

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Custom Parameter Group

Overriding Postgres parameters on the primary, with extra overrides for replicas. Parameters listed in `parameters_require_reboot` (e.g. `max_connections`, `shared_preload_libraries`) are applied with `pending-reboot`; the rest apply immediately.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.t3.medium"
  postgres_version = "18.2"

  primary_parameter_group = {
    max_connections          = "200"
    log_min_duration_statement = "500"
    shared_preload_libraries = "pg_stat_statements"
  }

  replicas = 1

  replica_parameter_group = {
    hot_standby_feedback = "on"
  }

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Enhanced Monitoring and Performance Insights

Enabling Enhanced Monitoring (1-second granularity) with a module-managed IAM role and Performance Insights with a 31-day retention.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.r6g.large"
  postgres_version = "18.2"

  monitoring_interval_sec = 1

  performance_insights = {
    enabled          = true
    retention_period = 31
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Bring Your Own Credentials

Providing an explicit username and password instead of letting the module generate them. The credentials are still written to the Secrets Manager secret.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  username = "app_admin"
  password = "super-secret-password" # from a sensitive var, secret store, etc.

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.t3.micro"
  postgres_version = "18.2"

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### Restore from Snapshot

Bootstrapping the primary from an existing RDS snapshot. The `snapshot_identifier` is ignored on subsequent applies so the database is not rebuilt by accident.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  snapshot_identifier = "rds:whatever-experiment-pg-2026-05-01-04-15"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.t3.medium"
  postgres_version = "18.2"

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### KMS Encryption

Encrypting both the database storage and the Secrets Manager secret with customer-managed KMS keys.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.t3.medium"
  postgres_version = "18.2"

  database_kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  secret_kms_key_arn   = "arn:aws:kms:eu-central-1:123456789012:key/abcdef01-2345-6789-abcd-ef0123456789"

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

### IAM Database Authentication

Enabling IAM authentication so application roles can connect using temporary tokens instead of the static password.

```hcl
module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app           = "whatever"
  env           = "experiment"
  database_name = "app"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  instance_type    = "db.t3.medium"
  postgres_version = "18.2"

  iam_database_authentication_enabled = true

  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
  }
}
```

## Notes

- The Secrets Manager secret stores `host`, `port`, `db_name`, `schema`, `username`, `password`, and a ready-to-use `connection_url`.
- Bumping `secret_version` rotates the auto-generated password (only effective when `password` is not set explicitly).
- The Enhanced Monitoring IAM role is created only when `monitoring_interval_sec > 0` and no `monitoring_role_arn` is provided.
- A custom DB subnet group is created only when `subnet_ids` is non-empty; otherwise AWS uses the default VPC subnet group.
- Replicas inherit the primary's parameter group when `replica_parameter_group` is null. Setting it creates a separate group whose parameters are merged from `primary_parameter_group` and `replica_parameter_group`.

## License

Licensed under the Apache License, Version 2.0.

Copyright 2026 Kyrylo Tykhanskyi.
