# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the taskmanager VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to deploy into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnets: ALB, NAT GW, bastion (if ever needed)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets: ECS Fargate tasks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnets: RDS PostgreSQL, ElastiCache Redis"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "app_port" {
  description = "Port exposed by the application container inside ECS"
  type        = number
  default     = 8080
}

# ------------------------------------------------------------------------------
# ECS app setup - making our variables!
# ------------------------------------------------------------------------------

variable "ecs_task_cpu" {
  description = "Fargate CPU units for each awesome API task"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory in MiB for each task (because memory rocks!)"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Number of API tasks to keep juggling"
  type        = number
  default     = 2
}

variable "container_image_tag" {
  description = "The ECR image version our task will reference"
  type        = string
  default     = "0.5.0"
}


