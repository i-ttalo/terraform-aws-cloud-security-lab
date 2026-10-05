resource "aws_ssm_parameter" "environment" {
  name        = "/cloud-security-lab/environment"
  description = "Application environment for Cloud Security Lab"
  type        = "String"
  value       = "production"

  tags = {
    Name = "cloud-security-lab-environment"
  }
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name = "/cloud-security-lab/cloudwatch-agent-config"
  type = "String"

  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/nginx/error.log"
              log_group_name  = aws_cloudwatch_log_group.ec2.name
              log_stream_name = "{instance_id}/nginx-error"
            }
          ]
        }
      }
    }
  })
}