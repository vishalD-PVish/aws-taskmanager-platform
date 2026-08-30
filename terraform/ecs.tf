# ------------------------------------------------------------------------------
# CloudWatch Logs
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/taskmanager-api"
  retention_in_days = 14
  tags = {
    Name      = "taskmanager-api-logs"
    Component = "observability"
  }
}
# ------------------------------------------------------------------------------
# ECS cluster
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "taskmanager-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name      = "taskmanager-cluster"
    Component = "compute"
  }
}
# ------------------------------------------------------------------------------
# ECS Fargate task definition
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "api" {
  family                   = "taskmanager-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api.repository_url}:${var.container_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])
  tags = {
    Name      = "taskmanager-api"
    Component = "ecs-task-definition"
  }
}
# ------------------------------------------------------------------------------
# ECS Fargate service
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "api" {
  name                               = "taskmanager-api-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.api.arn
  desired_count                      = var.api_desired_count
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.app_port
  }
  propagate_tags = "SERVICE"
  depends_on = [
    aws_lb_listener.http
  ]
  tags = {
    Name      = "taskmanager-api-service"
    Component = "ecs-service"
  }
}
