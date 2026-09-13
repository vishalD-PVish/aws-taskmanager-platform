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
# ------------------------------------------------------------------------------
# Giving our app just the right access: read the RDS credentials
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_execution_read_rds_secret" {
  name = "taskmanager-read-rds-secret"
  role = aws_iam_role.ecs_task_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_db_instance.main.master_user_secret[0].secret_arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Lambda export worker execution role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_export_worker" {
  name = "taskmanager-lambda-export-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name      = "taskmanager-lambda-export-worker-role"
    Component = "async-export-worker"
  }
}
# ------------------------------------------------------------------------------
# Lambda VPC networking and CloudWatch Logs permissions
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_export_worker_vpc_access" {
  role       = aws_iam_role.lambda_export_worker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
# ------------------------------------------------------------------------------
# Lambda worker application permissions
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_export_worker" {
  name = "taskmanager-lambda-export-worker-policy"
  role = aws_iam_role.lambda_export_worker.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConsumeExportQueueMessages"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = [
          aws_sqs_queue.export_jobs.arn,
          aws_sqs_queue.export_dlq.arn
        ]
      },
      {
        Sid    = "WriteExportFiles"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.exports.arn}/*"
      },
      {
        Sid    = "ReadRdsManagedCredentials"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_db_instance.main.master_user_secret[0].secret_arn
      }
    ]
  })
}
