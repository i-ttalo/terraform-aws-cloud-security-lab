
# ============================================================
# CloudWatch - Alarmes e monitoramento
# ============================================================

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "terraform-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_metric_alarm" "failed_login" {
  alarm_name        = "failed-login-alarm"
  alarm_description = "Detects 5 or more failed login attempts within 5 minutes"

  namespace   = "CloudSecurityLab"
  metric_name = "FailedLoginCount"
  statistic   = "Sum"

  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "failed_login" {
  name           = "failed-login-filter"
  pattern        = "\"SECURITY Failed login\""
  log_group_name = "/cloud-security-lab/ec2"

  metric_transformation {
    name      = "FailedLoginCount"
    namespace = "CloudSecurityLab"
    value     = "1"
  }
}

# ============================================================
# SEC-018 - KMS para CloudTrail no CloudWatch Logs
# ============================================================

resource "aws_kms_key" "cloudtrail_logs" {
  description             = "KMS key for CloudTrail CloudWatch Logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "cloudtrail-cloudwatch-logs-key"
  }
}

locals {
  cloudtrail_log_group_arn = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudtrail/cloud-security-lab"
}

# ============================================================
# Politica KMS
# ============================================================

data "aws_iam_policy_document" "cloudtrail_logs_kms" {
  statement {
    sid    = "EnableAccountKeyManagement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = [local.cloudtrail_log_group_arn]
    }
  }
}

resource "aws_kms_key_policy" "cloudtrail_logs" {
  key_id = aws_kms_key.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs_kms.json
}

# ============================================================
# CloudTrail - CloudWatch Log Group
# ============================================================

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/cloud-security-lab"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail_logs.arn

  depends_on = [
    aws_kms_key_policy.cloudtrail_logs
  ]

  tags = {
    Name        = "cloudtrail-audit-logs"
    Environment = "Security-Lab"
  }
}

# ============================================================
# IAM Role - CloudTrail
# ============================================================

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "cloudtrail-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudTrailAssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = "sts:AssumeRole"

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/cloud-security-lab-trail"
          }
        }
      }
    ]
  })
}

# ============================================================
# IAM Policy - Escrita de logs pelo CloudTrail
# ============================================================

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "cloudtrail-cloudwatch-logs-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudTrailWriteLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${trimsuffix(aws_cloudwatch_log_group.cloudtrail.arn, ":*")}:log-stream:*"
      }
    ]
  })
}

