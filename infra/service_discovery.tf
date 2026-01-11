# service_discovery.tf
# AWS Cloud Map을 사용한 Service Discovery

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "everywear.local"
  description = "Private DNS namespace for ECS services"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "everywear-service-discovery"
  }
}

# Backend 서비스용 Service Discovery
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "backend-service-discovery"
  }
}

# Crawler 서비스용 Service Discovery
resource "aws_service_discovery_service" "crawler" {
  name = "crawler"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "crawler-service-discovery"
  }
}