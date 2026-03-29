# outputs_sqs.tf

# output "sqs_crawling_request_url" {
#   description = "SQS Crawling Request Queue URL"
#   value       = aws_sqs_queue.crawling_request.url
# }

# output "sqs_crawling_request_arn" {
#   description = "SQS Crawling Request Queue ARN"
#   value       = aws_sqs_queue.crawling_request.arn
# }

# output "sqs_crawling_dlq_url" {
#   description = "SQS Crawling DLQ URL"
#   value       = aws_sqs_queue.crawling_dlq.url
# }

# output "sqs_crawling_dlq_arn" {
#   description = "SQS Crawling DLQ ARN"
#   value       = aws_sqs_queue.crawling_dlq.arn
# }

output "sqs_fitting_request_url" {
  description = "SQS Fitting Request Queue URL"
  value       = aws_sqs_queue.fitting_request.url
}

output "sqs_fitting_request_arn" {
  description = "SQS Fitting Request Queue ARN"
  value       = aws_sqs_queue.fitting_request.arn
}

output "sqs_fitting_dlq_url" {
  description = "SQS Fitting DLQ URL"
  value       = aws_sqs_queue.fitting_dlq.url
}

output "sqs_fitting_dlq_arn" {
  description = "SQS Fitting DLQ ARN"
  value       = aws_sqs_queue.fitting_dlq.arn
}