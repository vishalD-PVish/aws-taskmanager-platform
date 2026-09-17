# ------------------------------------------------------------------------------
# CloudWatch Logs for Lambda export processing
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda_export_worker" {
  name              = "/aws/lambda/taskmanager-export-worker"
  retention_in_days = 14

  tags = {
    Name      = "taskmanager-export-worker-logs"
    Component = "async-export-worker"
  }
}

resource "aws_cloudwatch_log_group" "lambda_export_dlq_handler" {
  name              = "/aws/lambda/taskmanager-export-dlq-handler"
  retention_in_days = 14

  tags = {
    Name      = "taskmanager-export-dlq-handler-logs"
    Component = "async-export-failure-handling"
  }
}

# ------------------------------------------------------------------------------
# Permit the Lambda service to pull the worker image from ECR
# ------------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "export_worker_lambda_pull" {
  repository = aws_ecr_repository.export_worker.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowLambdaServiceToPullWorkerImage"
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Primary Lambda worker: process export jobs from the primary SQS queue
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "export_worker" {
  function_name = "taskmanager-export-worker"
  description   = "Processes queued task exports and stores CSV files in S3."

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.export_worker.repository_url}:${var.worker_image_tag}"
  role         = aws_iam_role.lambda_export_worker.arn

  architectures = ["x86_64"]
  memory_size   = 512
  timeout       = 60

  reserved_concurrent_executions = 2

  image_config {
    command = ["worker.handler"]
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.lambda_export_worker.id
    ]

    subnet_ids = [
      for subnet in aws_subnet.private : subnet.id
    ]
  }

  environment {
    variables = {
      DB_HOST            = aws_db_instance.main.address
      DB_PORT            = "5432"
      DB_NAME            = "taskmanager"
      DB_SECRET_ARN      = aws_db_instance.main.master_user_secret[0].secret_arn
      EXPORT_BUCKET_NAME = aws_s3_bucket.exports.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_export_worker,
    aws_ecr_repository_policy.export_worker_lambda_pull,
    aws_iam_role_policy_attachment.lambda_export_worker_vpc_access,
    aws_iam_role_policy.lambda_export_worker
  ]

  tags = {
    Name      = "taskmanager-export-worker"
    Component = "async-export-worker"
  }
}

# ------------------------------------------------------------------------------
# DLQ Lambda worker: record terminal export failures in PostgreSQL
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "export_dlq_handler" {
  function_name = "taskmanager-export-dlq-handler"
  description   = "Marks export jobs as failed after SQS retries are exhausted."

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.export_worker.repository_url}:${var.worker_image_tag}"
  role         = aws_iam_role.lambda_export_worker.arn

  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 30

  reserved_concurrent_executions = 1

  image_config {
    command = ["worker.dlq_handler"]
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.lambda_export_worker.id
    ]

    subnet_ids = [
      for subnet in aws_subnet.private : subnet.id
    ]
  }

  environment {
    variables = {
      DB_HOST       = aws_db_instance.main.address
      DB_PORT       = "5432"
      DB_NAME       = "taskmanager"
      DB_SECRET_ARN = aws_db_instance.main.master_user_secret[0].secret_arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_export_dlq_handler,
    aws_ecr_repository_policy.export_worker_lambda_pull,
    aws_iam_role_policy_attachment.lambda_export_worker_vpc_access,
    aws_iam_role_policy.lambda_export_worker
  ]

  tags = {
    Name      = "taskmanager-export-dlq-handler"
    Component = "async-export-failure-handling"
  }
}

# ------------------------------------------------------------------------------
# SQS event-source mappings
# ------------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "export_worker" {
  event_source_arn = aws_sqs_queue.export_jobs.arn
  function_name    = aws_lambda_function.export_worker.arn

  batch_size                         = 1
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 0
}

resource "aws_lambda_event_source_mapping" "export_dlq_handler" {
  event_source_arn = aws_sqs_queue.export_dlq.arn
  function_name    = aws_lambda_function.export_dlq_handler.arn

  batch_size                         = 1
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 0
}
