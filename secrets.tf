resource "aws_kms_key" "secrets" {
  description             = "KMS key for Cloud Security Lab secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "cloud-security-lab-secrets-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/cloud-security-lab-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "database" {
  name        = "cloud-security-lab/database"
  description = "Database credentials for Cloud Security Lab"
  kms_key_id  = aws_kms_key.secrets.arn
}

resource "aws_iam_role_policy" "ec2_secrets_read" {
  name = "terraform-ec2-secrets-read"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.database.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}

data "aws_iam_policy_document" "secrets_kms" {
  statement {
    sid    = "EnableAccountKeyManagement"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key_policy" "secrets" {
  key_id = aws_kms_key.secrets.id
  policy = data.aws_iam_policy_document.secrets_kms.json
}