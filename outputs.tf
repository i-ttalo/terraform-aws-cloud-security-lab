output "private_subnet_id" {
  description = "id of the private subnet"
  value       = aws_subnet.private-subnet.id
}
