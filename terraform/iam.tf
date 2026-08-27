# --------------------------------------------------------------
# ECS task execution role
# --------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "taskmanager-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name      = "taskmanager-ecs-task-execution-role"
    Component = "ecs"
  }
}
# ---------------------------------------------------------------------------
# Permissions that ECS needs to start up and monitor containers
# ---------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# ------------------------------------------------------------------------------
# ECS application task role - the VIP pass for the app
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = "taskmanager-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name      = "taskmanager-ecs-task-role"
    Component = "application"
  }
}
