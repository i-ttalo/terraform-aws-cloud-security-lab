data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf install -y nginx awscli amazon-cloudwatch-agent

    systemctl enable --now nginx

    aws ssm get-parameter \
      --name "${aws_ssm_parameter.cloudwatch_agent_config.name}" \
      --query "Parameter.Value" \
      --output text \
      --region "${var.aws_region}" \
      > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "terraform-web-server"
  }
}