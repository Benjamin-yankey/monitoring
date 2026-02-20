output "jenkins_log_group" {
  description = "Jenkins CloudWatch log group name"
  value       = aws_cloudwatch_log_group.jenkins.name
}

output "app_log_group" {
  description = "App CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.vpc.id
}

output "prometheus_instance_id" {
  description = "Prometheus EC2 instance ID"
  value       = aws_instance.prometheus.id
}

output "prometheus_public_ip" {
  description = "Prometheus EC2 public IP"
  value       = aws_instance.prometheus.public_ip
}

output "prometheus_private_ip" {
  description = "Prometheus EC2 private IP"
  value       = aws_instance.prometheus.private_ip
}

output "grafana_instance_id" {
  description = "Grafana EC2 instance ID"
  value       = aws_instance.grafana.id
}

output "grafana_public_ip" {
  description = "Grafana EC2 public IP"
  value       = aws_instance.grafana.public_ip
}

output "grafana_private_ip" {
  description = "Grafana EC2 private IP"
  value       = aws_instance.grafana.private_ip
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = local.detector_id
}

output "guardduty_findings_log_group" {
  description = "GuardDuty findings CloudWatch log group"
  value       = aws_cloudwatch_log_group.guardduty_findings.name
}
