output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = module.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${module.jenkins.public_ip}:8080"
}

output "app_server_public_ip" {
  description = "Public IP address of application server"
  value       = module.app_server.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.app_server.public_ip}:5000"
}

output "ssh_jenkins" {
  description = "SSH command for Jenkins server"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${module.jenkins.public_ip}"
}

output "ssh_app_server" {
  description = "SSH command for application server"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${module.app_server.public_ip}"
}

output "jenkins_password_secret_name" {
  description = "AWS Secrets Manager secret name for Jenkins admin password"
  value       = module.secrets.secret_name
}

output "jenkins_password_secret_arn" {
  description = "AWS Secrets Manager secret ARN for Jenkins admin password"
  value       = module.secrets.secret_arn
  sensitive   = true
}

# Monitoring Outputs
output "prometheus_public_ip" {
  description = "Public IP address of Prometheus server"
  value       = module.monitoring.prometheus_public_ip
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${module.monitoring.prometheus_public_ip}:9090"
}

output "grafana_public_ip" {
  description = "Public IP address of Grafana server"
  value       = module.monitoring.grafana_public_ip
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${module.monitoring.grafana_public_ip}:3000"
}

output "ssh_prometheus" {
  description = "SSH command for Prometheus server"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${module.monitoring.prometheus_public_ip}"
}

output "ssh_grafana" {
  description = "SSH command for Grafana server"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${module.monitoring.grafana_public_ip}"
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.monitoring.cloudtrail_bucket_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.monitoring.guardduty_detector_id
}

output "guardduty_findings_log_group" {
  description = "GuardDuty findings CloudWatch log group"
  value       = module.monitoring.guardduty_findings_log_group
}