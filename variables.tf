variable "database_identifier" {
  description = "Custom identifier for the database. Defaults to {app}-{env}"
  type        = string
  default     = null

  validation {
    condition     = var.database_identifier == null ? true : length(var.database_identifier) > 0
    error_message = "Database identifier cannot be empty if provided."
  }

  validation {
    condition     = var.database_identifier == null ? true : can(regex("^[a-z0-9-]+$", var.database_identifier))
    error_message = "Database identifier must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "app" {
  description = "Application name"
  type        = string

  validation {
    condition     = length(var.app) > 0
    error_message = "Application name cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "env" {
  description = "Target environment"
  type        = string

  validation {
    condition     = length(var.env) > 0
    error_message = "Environment cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.env))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "database_name" {
  description = "Database name"
  type        = string

  validation {
    condition     = length(var.database_name) > 0
    error_message = "Database name cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}


variable "instance_type" {
  description = "Instance type for the primary database (RDS instance class, e.g. db.t3.micro)"
  type        = string

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be in valid RDS format (e.g., db.t3.micro, db.r5.large)."
  }
}


variable "postgres_version" {
  description = "Postgres engine version (e.g. 16.4, 17.2, 18.2)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?$", var.postgres_version))
    error_message = "Postgres version must be in valid format (e.g., 16, 16.4, 18.2)."
  }
}


variable "snapshot_identifier" {
  description = "Snapshot ID to restore the primary database from. Ignored after creation"
  type        = string
  default     = null
}


variable "username" {
  description = "Custom username for the database. If not provided, a random username will be generated"
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.username == null ? true : length(var.username) > 0
    error_message = "Username cannot be empty if provided."
  }

  validation {
    condition     = var.username == null ? true : can(regex("^[a-z][a-z0-9_]*$", var.username))
    error_message = "Username must start with a lowercase letter and contain only lowercase letters, numbers, and underscores."
  }
}


variable "password" {
  description = "Custom password for the database. If not provided, a random password will be generated"
  type        = string
  sensitive   = true
  ephemeral   = true
  default     = null

  validation {
    condition     = var.password == null ? true : length(var.password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}


variable "secret_version" {
  description = "Version number for the database secret. Increment to trigger password rotation"
  type        = number
  default     = 1

  validation {
    condition     = var.secret_version > 0
    error_message = "Secret version must be greater than 0."
  }
}


variable "secret_kms_key_arn" {
  description = "KMS key to encrypt the Secrets Manager secret with database credentials"
  type        = string
  default     = null

  validation {
    condition = (
      var.secret_kms_key_arn == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.secret_kms_key_arn))
    )
    error_message = "KMS key ARN must be in a valid format: arn:aws:kms:region:account-id:key/key-id."
  }
}


variable "secret_tags" {
  description = "Extra tags to attach to the Postgres Secrets Manager secret"
  type        = map(string)
  default     = {}
}


variable "vpc_id" {
  description = "VPC where database will be located"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}


variable "subnet_ids" {
  description = "Subnets used to create a DB subnet group. Ignored when subnet_group_name is set. If empty and no group name is given, AWS uses the default"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-f0-9]{8,}$", id))])
    error_message = "All subnet IDs must be in valid format (subnet-xxxxxxxx)."
  }
}


variable "subnet_group_name" {
  description = "Name of an existing DB subnet group to place the database in. When set, the module uses it as-is and does not create its own subnet group (subnet_ids is ignored)"
  type        = string
  default     = null

  validation {
    condition     = var.subnet_group_name == null ? true : length(var.subnet_group_name) > 0
    error_message = "Subnet group name cannot be empty if provided."
  }
}


variable "multi_az" {
  description = "Whether the primary database is deployed in multi-AZ. Ignored for replicas"
  type        = bool
  default     = false
}


variable "availability_zone" {
  description = "AWS availability zone for the database. Ignored when multi_az is true"
  type        = string
  default     = null

  validation {
    condition     = var.availability_zone == null || can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone))
    error_message = "Availability zone must be null or in valid AWS format (e.g., us-east-1a, eu-west-1b)."
  }
}


variable "port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432

  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "Port must be between 1 and 65535."
  }
}


variable "ca_cert_identifier" {
  description = "RDS CA certificate identifier (e.g. rds-ca-rsa2048-g1). Null uses the AWS default"
  type        = string
  default     = null
}


variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}


variable "ingress" {
  description = "Ingress rules for Postgres security group"
  type = map(object({
    port                      = optional(number)
    protocol                  = optional(string, "tcp")
    description               = optional(string)
    allowed_security_group_id = optional(string)
    cidr_ipv4                 = optional(string)
    cidr_ipv6                 = optional(string)
    prefix_list_id            = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.ingress : length(compact([v.allowed_security_group_id, v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id])) == 1
    ])
    error_message = "Each ingress rule must specify exactly one source: allowed_security_group_id, cidr_ipv4, cidr_ipv6, or prefix_list_id."
  }
}


variable "iam_database_authentication_enabled" {
  description = "Whether to enable IAM database authentication"
  type        = bool
  default     = false
}


variable "storage" {
  description = "Database storage configuration"
  type = object({
    type        = optional(string, "gp3")
    encrypted   = optional(bool, true)
    size_gb     = optional(number, 20)
    max_size_gb = optional(number, null)
    iops        = optional(number, null)
    throughput  = optional(number, null)
  })
  default = {}

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage.type)
    error_message = "Storage type must be one of: [gp2, gp3, io1, io2]"
  }

  validation {
    condition     = var.storage.size_gb >= 20
    error_message = "Storage size must be at least 20 GB."
  }

  validation {
    condition     = var.storage.max_size_gb == null || var.storage.max_size_gb >= var.storage.size_gb
    error_message = "Storage max_size_gb must be greater than or equal to size_gb when set."
  }
}


variable "database_kms_key_arn" {
  description = "KMS key to encrypt the database instance storage. If provided, storage encryption is enabled automatically"
  type        = string
  default     = null

  validation {
    condition = (
      var.database_kms_key_arn == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.database_kms_key_arn))
    )
    error_message = "KMS key ARN must be in a valid format: arn:aws:kms:region:account-id:key/key-id."
  }
}


variable "parameter_group_family" {
  description = "DB parameter group family override (e.g. postgres18). Derived from postgres_version when null"
  type        = string
  default     = null

  validation {
    condition     = var.parameter_group_family == null || can(regex("^postgres[0-9]+$", coalesce(var.parameter_group_family, "postgres0")))
    error_message = "Parameter group family must look like 'postgres17', 'postgres18', etc."
  }
}


variable "primary_parameter_group" {
  description = "Postgres parameter overrides for the primary instance. When null, the AWS default group is used"
  type        = map(string)
  default     = null
}


variable "maintenance" {
  description = "Database maintenance configuration"
  type = object({
    window                     = optional(string, "sat:18:00-sat:19:00")
    auto_minor_version_upgrade = optional(bool, true)
  })
  default = {}

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.maintenance.window))
    error_message = "Maintenance window must be in valid format (e.g., sat:18:00-sat:19:00)."
  }
}


variable "backup" {
  description = "Database backup configuration"
  type = object({
    window                   = optional(string, "22:00-23:00")
    retention                = optional(number, 7)
    copy_tags_to_snapshot    = optional(bool, true)
    delete_automated_backups = optional(bool, true)
    skip_final_snapshot      = optional(bool, false)
    final_snapshot_id        = optional(string, null)
  })
  default = {}

  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup.window))
    error_message = "Backup window must be in valid format (e.g., 22:00-23:00)."
  }

  validation {
    condition     = var.backup.retention >= 0 && var.backup.retention <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}


variable "database_insights_mode" {
  description = "Database Insights mode: 'standard' or 'advanced'. Null leaves it unset"
  type        = string
  default     = null

  validation {
    condition     = var.database_insights_mode == null || contains(["standard", "advanced"], coalesce(var.database_insights_mode, "standard"))
    error_message = "database_insights_mode must be one of: [standard, advanced] or null."
  }
}


variable "performance_insights" {
  description = "Performance Insights configuration. Required if database_insights_mode is 'advanced' (retention_period must be >= 465)"
  type = object({
    enabled          = optional(bool, false)
    kms_key_arn      = optional(string, null)
    retention_period = optional(number, 7)
  })
  default = {}

  validation {
    condition     = contains([7, 731], var.performance_insights.retention_period) || (var.performance_insights.retention_period >= 31 && var.performance_insights.retention_period % 31 == 0)
    error_message = "Performance Insights retention_period must be 7, 731, or a multiple of 31."
  }

  validation {
    condition = (
      var.performance_insights.kms_key_arn == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.performance_insights.kms_key_arn))
    )
    error_message = "Performance Insights KMS key ARN must be a valid KMS key ARN."
  }
}


variable "monitoring_role_arn" {
  description = "Role used for Enhanced Monitoring. When null, a role is created (only if monitoring_interval_sec > 0)"
  type        = string
  default     = null

  validation {
    condition = (
      var.monitoring_role_arn == null ||
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.monitoring_role_arn))
    )
    error_message = "Monitoring role ARN must be in a valid format: arn:aws:iam::account-id:role/role-name."
  }
}


variable "monitoring_interval_sec" {
  description = "Interval in seconds for Enhanced Monitoring metrics. 0 disables it"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval_sec)
    error_message = "monitoring_interval_sec must be one of: [0, 1, 5, 10, 15, 30, 60]."
  }
}


variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (e.g. postgresql, upgrade)"
  type        = list(string)
  default     = ["postgresql"]

  validation {
    condition     = alltrue([for l in var.enabled_cloudwatch_logs_exports : contains(["postgresql", "upgrade"], l)])
    error_message = "Allowed log types for Postgres: postgresql, upgrade."
  }
}


variable "protect_from_deletion" {
  description = "Whether deletion protection is enabled on the primary instance"
  type        = bool
  default     = true
}


variable "replicas" {
  description = "Number of read replicas to create"
  type        = number
  default     = 0

  validation {
    condition     = var.replicas >= 0 && var.replicas <= 15
    error_message = "Replicas must be between 0 and 15."
  }
}


variable "replica_instance_type" {
  description = "Instance class for replicas. Falls back to instance_type when null"
  type        = string
  default     = null

  validation {
    condition     = var.replica_instance_type == null || can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", coalesce(var.replica_instance_type, "db.t3.micro")))
    error_message = "Replica instance type must be in valid RDS format (e.g., db.t3.micro)."
  }
}


variable "replica_parameter_group" {
  description = "Postgres parameter overrides applied on top of primary_parameter_group for replicas. When null, replicas use the primary parameter group"
  type        = map(string)
  default     = null
}


variable "use_name_prefix" {
  description = "Use name_prefix instead of a fixed name for the resources this module creates, so AWS appends a unique suffix"
  type        = bool
  default     = false
}


variable "include_default_tags" {
  description = "Whether to attach the module's default tags to all resources"
  type        = bool
  default     = true
}


variable "tofu_apply_timeouts" {
  description = "Per-operation timeouts applied to the primary and replica databases"
  type = object({
    create = optional(string, "1h")
    delete = optional(string, "1h")
    update = optional(string, "1h")
  })
  default = {}
}


variable "tags" {
  description = "Tags to attach to Postgres database and the related resources"
  type        = map(string)
  default     = {}
}
