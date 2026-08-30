# ------------------------------------------------------------------------------
# Networking outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID for the taskmanager platform"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB placement)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ECS placement)"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs (RDS, ElastiCache)"
  value       = aws_subnet.database[*].id
}
# ---------------------------------------------------------------------------
# Application Load Balancer outputs
# ---------------------------------------------------------------------------
output "api_alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.api.dns_name
}
output "api_url" {
  description = "HTTP URL for the Task Manager API"
  value       = "http://${aws_lb.api.dns_name}"
}
