resource "aws_sqs_queue" "export_dlq" {
  name                      = "taskmanager-export-jobs-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
  tags = {
    Name      = "taskmanager-export-jobs-dlq"
    Component = "async-export-failure-handling"
  }
}
resource "aws_sqs_queue" "export_jobs" {
  name                       = "taskmanager-export-jobs"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.export_dlq.arn
    maxReceiveCount     = 3
  })
  tags = {
    Name      = "taskmanager-export-jobs"
    Component = "async-export-processing"
  }
}
resource "aws_sqs_queue_redrive_allow_policy" "export_dlq" {
  queue_url = aws_sqs_queue.export_dlq.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns = [
      aws_sqs_queue.export_jobs.arn
    ]
  })
}
