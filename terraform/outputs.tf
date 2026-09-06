output "api_base_url" {
  description = "Base URL for the public API load balancer. HTTP is used for this initial demo deployment."
  value       = "http://${aws_lb.api.dns_name}"
}
output "ecr_repository_url" {
  description = "URL of the ECR repository that stores the API container images."
  value       = aws_ecr_repository.api.repository_url
}
output "ecs_cluster_name" {
  description = "Name of the ECS cluster hosting the Task Manager workloads."
  value       = aws_ecs_cluster.main.name
}
output "ecs_api_service_name" {
  description = "Name of the continuously running ECS API service."
  value       = aws_ecs_service.api.name
}
output "database_endpoint" {
  description = "Private RDS PostgreSQL endpoint, including its port. This is not publicly reachable."
  value       = aws_db_instance.main.endpoint
}
output "migration_task_definition_arn" {
  description = "ARN of the one-off ECS task definition used to apply Alembic database migrations."
  value       = aws_ecs_task_definition.migration.arn
}
output "private_subnet_ids" {
  description = "IDs of the private subnets used by ECS Fargate tasks."
  value       = [for subnet in aws_subnet.private : subnet.id]
}
output "ecs_security_group_id" {
  description = "ID of the security group attached to ECS Fargate tasks."
  value       = aws_security_group.ecs.id
}
