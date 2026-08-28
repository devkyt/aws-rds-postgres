locals {
  app    = "whatever"
  env    = "experiment"
  region = "eu-central-1"

  tags = {
    Name        = local.app
    Environment = local.env
    Region      = local.region
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-experiments-state"
    region = "eu-central-1"
    key    = "whatever/terraform.tfstate"
  }
}


provider "aws" {
  region = local.region
}


module "postgres" {
  source = "git@github.com:devkyt/aws-rds-postgres.git?ref=main&depth=1"

  app = local.app
  env = local.env

  # Optional: override database identifier (defaults to {app}-{env})
  # database_identifier = "my-custom-db"

  database_name = "app"

  # Optional: provide your own credentials (auto-generated if omitted)
  # username = "admin_user"
  # password = "super-secret-password"

  vpc_id            = "vpc-0123456789abcdef0"
  subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  availability_zone = "eu-central-1b"

  instance_type    = "db.t3.micro"
  postgres_version = "18.2"

  # Increment to trigger password rotation
  secret_version = 1

  storage = {
    type      = "gp3"
    encrypted = true
    size_gb   = 20
  }

  # Ingress rules for security group
  ingress = {
    "ecs" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
    # "office-vpn" = {
    #   port      = 5432
    #   cidr_ipv4 = "10.0.0.0/16"
    # }
  }

  maintenance = {
    window                     = "mon:03:00-mon:04:00"
    auto_minor_version_upgrade = true
  }

  backup = {
    window    = "04:00-05:00"
    retention = 7
  }

  # Optional: KMS encryption for the database instance storage
  # database_kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Optional: KMS encryption for the Secrets Manager secret
  # secret_kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Optional: use existing monitoring role instead of creating one
  # monitoring_role_arn = "arn:aws:iam::123456789012:role/rds-monitoring-role"

  tags = local.tags
}
