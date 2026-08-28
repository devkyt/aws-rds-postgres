# ---------------------------------------------
# IAM Role Assumed By RDS Enhanced Monitoring
# ---------------------------------------------
data "aws_iam_policy_document" "monitoring" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "monitoring" {
  name               = var.use_name_prefix ? null : local.database_identifier
  name_prefix        = var.use_name_prefix ? "${local.database_identifier}-" : null
  assume_role_policy = data.aws_iam_policy_document.monitoring.json

  lifecycle {
    create_before_destroy = true
    enabled               = local.create_monitoring_role
  }
}


# ---------------------------------------------
# Attach The AWS-Managed Enhanced Monitoring Policy
# ---------------------------------------------
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"

  lifecycle {
    enabled = local.create_monitoring_role
  }
}
