# Route 53 호스트 존 생성
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# SSL 인증서 발급 (도메인 및 서브도메인 포함)
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"] # *.everywear.cloud 포함

  lifecycle {
    create_before_destroy = true
  }
}

# 도메인 연결 (api.everywear.cloud -> ALB)
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