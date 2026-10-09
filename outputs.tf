output "vpc_id" {
  description = "id of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_id" {
  description = "id of the private subnet"
  value       = aws_subnet.private-subnet.id
}


