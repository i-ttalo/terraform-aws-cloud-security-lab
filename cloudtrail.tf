resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "ittalo-cloud-security-cloudtrail-logs-2026"

  tags = {
    Name = "cloud-security-lab-cloudtrail-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail audit logs encryption"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::216103143470:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrailEncryption"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "kms:GenerateDataKey*"
        Resource = "*"

        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:216103143470:trail/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "cloud-security-lab-cloudtrail-key"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "CloudTrailAclCheck"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "CloudTrailWrite"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/216103143470/*"
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                       = "cloud-security-lab-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail_logs.id
  kms_key_id                 = aws_kms_key.cloudtrail.arn
  enable_log_file_validation = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_s3_bucket_server_side_encryption_configuration.cloudtrail_logs
  ]
}
