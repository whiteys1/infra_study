# rds.tf
# MySQL RDS (개발용, 퍼블릭, NAT 없음)
# - DB Subnet Group: public subnets 2개 사용
# - DB Instance: publicly_accessible = true

resource "aws_db_subnet_group" "main" {
  name       = "dev-mysql-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = {
    Name = "dev-mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "dev-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true

  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 0
  multi_az                = false

  apply_immediately = true

  tags = {
    Name = "dev-mysql"
  }
}
