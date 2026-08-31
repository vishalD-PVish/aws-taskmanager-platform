# ------------------------------------------------------------------------------
# RDS database subnet group
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "taskmanager-db-subnet-group"
  description = "Private database subnets for Task Manager RDS resources"
  subnet_ids  = aws_subnet.database[*].id
  tags = {
    Name      = "taskmanager-db-subnet-group"
    Component = "database"
  }
}
# ------------------------------------------------------------------------------
# RDS PostgreSQL instance
# ------------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier                  = "taskmanager-postgres"
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  max_allocated_storage       = 50
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = "taskmanager"
  username                    = "taskadmin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  publicly_accessible         = false
  multi_az                    = false
  backup_retention_period     = 7
  auto_minor_version_upgrade  = true
  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]
  deletion_protection   = false
  skip_final_snapshot   = true
  copy_tags_to_snapshot = true
  tags = {
    Name      = "taskmanager-postgres"
    Component = "database"
  }
}
