# 1. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 7

  tags = {
    Environment = "Security-Lab"
  }
}

# 2. IAM Role para o serviço VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCFlowLogs"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Permissões para publicar logs no CloudWatch
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${trimsuffix(aws_cloudwatch_log_group.flow_log_group.arn, ":*")}:*"
      },
      {
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "*"
      }
    ]
  })
}

# 4. Habilitar Flow Logs na VPC
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn         = aws_iam_role.flow_log_role.arn

  depends_on = [
    aws_iam_role_policy.flow_log_policy
  ]

  tags = {
    Name = "cloud-security-lab-vpc-flow-logs"
  }
}
