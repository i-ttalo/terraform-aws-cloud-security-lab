resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/cloud-security-lab/ec2"
  retention_in_days = 14
}

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

resource "aws_cloudwatch_log_metric_filter" "nginx_errors" {
  name           = "nginx-errors-filter"
  pattern        = "\"[error]\""
  log_group_name = aws_cloudwatch_log_group.ec2.name

  metric_transformation {
    name      = "NginxErrorCount"
    namespace = "CloudSecurityLab"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "nginx_errors" {
  alarm_name        = "nginx-error-alarm"
  alarm_description = "Detects 5 or more Nginx error logs within 5 minutes"

  namespace   = "CloudSecurityLab"
  metric_name = "NginxErrorCount"
  statistic   = "Sum"

  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"
}