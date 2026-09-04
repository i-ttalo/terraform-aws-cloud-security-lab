variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "sa-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block used by the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR block used by the private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "admin_cidr" {
  description = "CIDR allowed to access the EC2 via SSH"
  type        = string
}