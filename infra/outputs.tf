# outputs.tf
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

# outputs.tf에 추가(이미 outputs.tf가 있다면 아래만 추가)
output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "rds_port" {
  value = aws_db_instance.mysql.port
}

output "rds_db_name" {
  value = aws_db_instance.mysql.db_name
}
