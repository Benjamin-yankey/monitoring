# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-jenkins"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins-logs"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-app"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-app-logs"
  }
}

resource "aws_cloudwatch_log_group" "docker_app" {
  name              = "/aws/docker/${var.project_name}-${var.environment}-app"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-docker-app-logs"
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/aws/docker/${var.project_name}-${var.environment}-prometheus"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-prometheus-logs"
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/aws/docker/${var.project_name}-${var.environment}-grafana"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-grafana-logs"
  }
}

# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket              = "${var.project_name}-${var.environment}-cloudtrail-logs-${random_id.bucket_suffix.hex}"
  force_destroy       = true
  object_lock_enabled = false

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.cloudtrail_logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  depends_on = [aws_s3_bucket.cloudtrail_logs]
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.cloudtrail_logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  depends_on = [aws_s3_bucket.cloudtrail_logs]
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.cloudtrail_logs,
    aws_s3_bucket_public_access_block.cloudtrail_logs
  ]
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_logs]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail"
  }
}

# CloudTrail Logs to CloudWatch
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  }
}

# GuardDuty
data "aws_guardduty_detector" "existing" {
}

# Only create detector if none exists (existing ones are not managed by this module)
resource "aws_guardduty_detector" "main" {
  count  = length(data.aws_guardduty_detector.existing.id) > 0 ? 0 : 1
  enable = true

  tags = {
    Name = "${var.project_name}-${var.environment}-guardduty"
  }
}

locals {
  detector_id = length(data.aws_guardduty_detector.existing.id) > 0 ? data.aws_guardduty_detector.existing.id : aws_guardduty_detector.main[0].id
  has_detector = length(data.aws_guardduty_detector.existing.id) > 0 || length(aws_guardduty_detector.main) > 0
}

# Only manage features if we created the detector or it's already enabled
resource "aws_guardduty_detector_feature" "s3_logs" {
  count       = local.has_detector && length(data.aws_guardduty_detector.existing.id) == 0 ? 1 : 0
  detector_id = local.detector_id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "kubernetes" {
  count       = local.has_detector && length(data.aws_guardduty_detector.existing.id) == 0 ? 1 : 0
  detector_id = local.detector_id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}

# CloudWatch Alarms for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_findings_log" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindingsLog"
  arn       = aws_cloudwatch_log_group.guardduty_findings.arn
}

resource "aws_cloudwatch_log_group" "guardduty_findings" {
  name              = "/aws/guardduty/${var.project_name}-${var.environment}"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-guardduty-findings"
  }
}

# Prometheus EC2 Instance
resource "aws_instance" "prometheus" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.prometheus_instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.prometheus.id]
  iam_instance_profile   = aws_iam_instance_profile.prometheus.name

  user_data = base64encode(templatefile("${path.module}/prometheus-setup.sh", {
    app_instance_ip = var.app_instance_ip
  }))

  monitoring = true

  tags = {
    Name = "${var.project_name}-${var.environment}-prometheus"
  }

  depends_on = [aws_security_group.prometheus]
}

# Grafana EC2 Instance
resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.grafana_instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  iam_instance_profile   = aws_iam_instance_profile.grafana.name

  user_data = base64encode(file("${path.module}/grafana-setup.sh"))

  monitoring = true

  tags = {
    Name = "${var.project_name}-${var.environment}-grafana"
  }

  depends_on = [aws_security_group.grafana]
}

# Security Groups
resource "aws_security_group" "prometheus" {
  name        = "${var.project_name}-${var.environment}-prometheus-sg"
  description = "Security group for Prometheus"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-prometheus-sg"
  }
}

resource "aws_security_group" "grafana" {
  name        = "${var.project_name}-${var.environment}-grafana-sg"
  description = "Security group for Grafana"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-grafana-sg"
  }
}

# IAM Roles and Policies
resource "aws_iam_role" "prometheus" {
  name = "${var.project_name}-${var.environment}-prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "${var.project_name}-${var.environment}-prometheus-profile"
  role = aws_iam_role.prometheus.name
}

resource "aws_iam_role_policy" "prometheus" {
  name = "${var.project_name}-${var.environment}-prometheus-policy"
  role = aws_iam_role.prometheus.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.prometheus.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "grafana" {
  name = "${var.project_name}-${var.environment}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "grafana" {
  name = "${var.project_name}-${var.environment}-grafana-profile"
  role = aws_iam_role.grafana.name
}

resource "aws_iam_role_policy" "grafana" {
  name = "${var.project_name}-${var.environment}-grafana-policy"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.grafana.arn}:*"
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_cloudwatch_metric_alarm" "jenkins_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-jenkins-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.jenkins_instance_id
  }

  alarm_description = "Alert when Jenkins CPU exceeds 80%"
}

resource "aws_cloudwatch_metric_alarm" "app_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.app_instance_id
  }

  alarm_description = "Alert when App server CPU exceeds 80%"
}

resource "aws_flow_log" "vpc" {
  vpc_id          = var.vpc_id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}"
  retention_in_days = 90

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = [
        aws_cloudwatch_log_group.vpc_flow_logs.arn,
        "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      ]
    }]
  })
}
