# outputs.tf
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

output "s3_bucket_name" {
  value = aws_s3_bucket.app.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.app.arn
}

output "ecr_crawler_repository_url" {
  value = aws_ecr_repository.crawler.repository_url
}

output "service_discovery_namespace" {
  value = aws_service_discovery_private_dns_namespace.main.name
}

output "crawler_service_url" {
  value = "http://crawler.everywear.local:8001"
}
