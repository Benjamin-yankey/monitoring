variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "jenkins_instance_id" {
  description = "Jenkins instance ID"
  type        = string
}

variable "app_instance_id" {
  description = "App server instance ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Prometheus and Grafana instances"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "app_instance_ip" {
  description = "Private IP of the app instance"
  type        = string
}

variable "prometheus_instance_type" {
  description = "Instance type for Prometheus"
  type        = string
  default     = "t3.micro"
}

variable "grafana_instance_type" {
  description = "Instance type for Grafana"
  type        = string
  default     = "t3.micro"
}

variable "resource_suffix" {
  description = "Random suffix for resource naming"
  type        = string
  default     = ""
}
