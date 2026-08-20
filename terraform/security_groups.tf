# ------------------------------------------------------------------------------
# Application Load Balancer security group
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "taskmanager-alb-sg"
  description = "Controls inbound traffic to the public Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Do not keep AWS's default allow-all outbound rule.
  # Specific ingress and egress rules will be declared separately.
  egress = []

  tags = {
    Name = "taskmanager-alb-sg"
    Tier = "public"
  }
}

# ------------------------------------------------------------------------------
# ALB inbound rule: public HTTP
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id

  description = "Allow public HTTP traffic to the Application Load Balancer"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# ------------------------------------------------------------------------------
# ECS task security group
# ------------------------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "taskmanager-ecs-sg"
  description = "Controls traffic to private ECS Fargate application tasks"
  vpc_id      = aws_vpc.main.id

  # Do not keep AWS's default allow-all outbound rule.
  # Specific ingress and egress rules will be declared separately.
  egress = []

  tags = {
    Name = "taskmanager-ecs-sg"
    Tier = "private"
  }
}

# ------------------------------------------------------------------------------
# ECS inbound rule: only the ALB can reach the application
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "ecs_app_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id

  description = "Allow the ALB to reach ECS application tasks"
  from_port   = var.app_port
  to_port     = var.app_port
  ip_protocol = "tcp"
}

# ------------------------------------------------------------------------------
# RDS PostgreSQL security group
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "taskmanager-rds-sg"
  description = "Controls traffic to the private PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  # The database does not need to initiate outbound connections.
  # Specific ingress rules will be declared separately.
  egress = []

  tags = {
    Name = "taskmanager-rds-sg"
    Tier = "database"
  }
}

# ------------------------------------------------------------------------------
# RDS inbound rule: only ECS tasks can connect to PostgreSQL
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_postgres_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id

  description = "Allow ECS application tasks to connect to PostgreSQL"
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

# ------------------------------------------------------------------------------
# ALB outbound rule: forward requests only to ECS application tasks
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id

  description = "Allow the ALB to forward requests to ECS application tasks"
  from_port   = var.app_port
  to_port     = var.app_port
  ip_protocol = "tcp"
}

# ------------------------------------------------------------------------------
# ECS outbound rule: connect only to PostgreSQL
# ------------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds_postgres" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.rds.id

  description = "Allow ECS application tasks to connect to PostgreSQL"
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}
