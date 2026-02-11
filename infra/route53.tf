# infra/route53.tf

# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "EveryWear domain managed by Terraform"

  tags = {
    Name        = "everywear-hosted-zone"
    Environment = var.environment
    Project     = "everywear"
  }
}

# ACM 인증서
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "everywear-certificate"
    Environment = var.environment
    Project     = "everywear"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ACM DNS 검증 레코드
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# ACM 검증 완료 대기
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# API 서브도메인 A 레코드
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.api_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# 출력
output "route53_name_servers" {
  description = "Route 53 Name Servers for domain registration"
  value       = aws_route53_zone.main.name_servers
}

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

output "acm_certificate_status" {
  description = "ACM Certificate validation status"
  value       = aws_acm_certificate.cert.status
}