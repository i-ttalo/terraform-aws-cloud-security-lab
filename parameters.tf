resource "aws_ssm_parameter" "environment" {
  name        = "/cloud-security-lab/environment"
  description = "Application environment for Cloud Security Lab"
  type        = "String"
  value       = "production"

  tags = {
    Name = "cloud-security-lab-environment"
  }
}

resource "aws_iam_role_policy" "ec2_parameter_read" {
  name = "terraform-ec2-parameter-read"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = aws_ssm_parameter.environment.arn
      }
    ]
  })
}