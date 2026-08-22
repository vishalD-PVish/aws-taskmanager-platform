# ------------------------------------------------------------------------------
# Amazon Elastic Container Registry repository
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "api" {
  name                 = "taskmanager-api"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name      = "taskmanager-api"
    Component = "container-registry"
  }
}
# ------------------------------------------------------------------------------
# ECR lifecycle policy
# ------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
