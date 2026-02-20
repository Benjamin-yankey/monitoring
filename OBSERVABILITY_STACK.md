# Observability and Security Stack

This document describes the complete observability and security implementation for the CI/CD Pipeline application.

## Overview

The observability and security stack includes:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboarding
- **AlertManager**: Alert routing and management
- **Node Exporter**: System metrics collection
- **AWS CloudWatch**: Centralized logging
- **AWS CloudTrail**: Account activity tracking
- **AWS GuardDuty**: Threat detection
- **AWS S3**: Secure log storage with encryption and lifecycle policies

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│  Node.js App (/metrics) → Prometheus → Grafana Dashboards   │
│  Node Exporter → Prometheus → Grafana                       │
├─────────────────────────────────────────────────────────────┤
│                    AWS Services Layer                        │
├─────────────────────────────────────────────────────────────┤
│  CloudWatch Logs ← Docker Logs                              │
│  CloudTrail → S3 (encrypted, lifecycle policies)            │
│  GuardDuty → CloudWatch Events → CloudWatch Logs            │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Application Metrics (/metrics endpoint)

The Node.js application exposes Prometheus metrics at `/metrics`:

- `app_uptime_seconds`: Application uptime
- `app_requests_total`: Total HTTP requests
- `app_errors_total`: Total HTTP errors
- `app_error_rate_percent`: Error rate percentage
- `http_requests_total`: Per-route request counts
- `http_request_duration_ms`: Per-route latency

### 2. Prometheus

**Configuration**: `prometheus.yml`

Scrapes metrics from:
- Application (`/metrics` endpoint)
- Node Exporter (system metrics)
- Prometheus itself

**Alert Rules**: `prometheus-rules.yml`

Configured alerts:
- High error rate (>5%)
- Critical error rate (>10%)
- Application down
- High latency (>1000ms)
- High CPU usage (>80%)
- High memory usage (>85%)
- Low disk space (<10%)
- Node exporter down

### 3. Grafana

**Dashboards**: `grafana/dashboards/app-monitoring.json`

Displays:
- Requests per second
- Average latency (ms)
- Error rate (%)
- Application uptime

**Datasource**: Prometheus

**Access**: http://localhost:3000 (admin/admin)

### 4. AlertManager

**Configuration**: `alertmanager.yml`

Routes alerts by severity:
- Critical alerts
- Warning alerts
- Default alerts

Supports:
- Webhook notifications
- Slack integration (configure webhook URL)
- Email notifications (configure SMTP)

### 5. Node Exporter

Collects system metrics:
- CPU usage
- Memory usage
- Disk usage
- Network I/O
- Process metrics

**Port**: 9100

### 6. AWS CloudWatch Logs

Log groups created:
- `/aws/ec2/{project}-{env}-jenkins`: Jenkins logs
- `/aws/ec2/{project}-{env}-app`: App server logs
- `/aws/docker/{project}-{env}-app`: Docker app logs
- `/aws/docker/{project}-{env}-prometheus`: Prometheus logs
- `/aws/docker/{project}-{env}-grafana`: Grafana logs
- `/aws/cloudtrail/{project}-{env}`: CloudTrail logs
- `/aws/guardduty/{project}-{env}`: GuardDuty findings
- `/aws/vpc/{project}-{env}`: VPC Flow Logs

**Retention**: 90 days

### 7. AWS CloudTrail

**Features**:
- Multi-region trail
- Log file validation enabled
- Tracks all API calls
- Monitors S3 and Lambda data events
- Logs stored in S3 with encryption

**S3 Bucket**:
- Name: `{project}-{env}-cloudtrail-logs-{account-id}`
- Encryption: AES256
- Versioning: Enabled
- Public access: Blocked

**Lifecycle Policy**:
- 30 days: Move to STANDARD_IA
- 90 days: Move to GLACIER
- 365 days: Delete

### 8. AWS GuardDuty

**Features**:
- Threat detection
- S3 logs analysis
- Kubernetes audit logs monitoring
- Findings logged to CloudWatch

**Findings** are automatically captured and logged to CloudWatch Events.

## Deployment

### Local Development (Docker Compose)

```bash
# Start the stack
docker-compose up -d

# Verify deployment
./deploy-observability-stack.sh

# View logs
docker-compose logs -f prometheus
docker-compose logs -f grafana
docker-compose logs -f alertmanager
```

### AWS Deployment (Terraform)

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Get outputs
terraform output
```

**Terraform creates**:
- Prometheus EC2 instance
- Grafana EC2 instance
- CloudTrail with S3 bucket
- GuardDuty detector
- CloudWatch log groups
- IAM roles and policies

## Verification

### 1. Application Metrics

```bash
curl http://localhost:5000/metrics
```

Expected output: Prometheus format metrics

### 2. Prometheus

```bash
# Health check
curl http://localhost:9090/-/healthy

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=app_requests_total'

# View targets
curl http://localhost:9090/api/v1/targets
```

### 3. Grafana

```bash
# Health check
curl http://localhost:3000/api/health

# Access UI
open http://localhost:3000
```

### 4. AlertManager

```bash
# Health check
curl http://localhost:9093/-/healthy

# View alerts
curl http://localhost:9093/api/v1/alerts
```

### 5. CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups --region eu-west-1

# View recent logs
aws logs tail /aws/cloudtrail/cicd-pipeline-dev --follow
```

### 6. CloudTrail

```bash
# Check trail status
aws cloudtrail describe-trails --region eu-west-1

# View recent events
aws cloudtrail lookup-events --region eu-west-1 --max-results 10
```

### 7. GuardDuty

```bash
# List detectors
aws guardduty list-detectors --region eu-west-1

# Get findings
aws guardduty list-findings --detector-id <detector-id> --region eu-west-1
```

## Alert Configuration

### High Error Rate Alert

Triggers when error rate exceeds 5% for 2 minutes:

```yaml
alert: HighErrorRate
expr: (app_errors_total / app_requests_total) * 100 > 5
for: 2m
severity: warning
```

### Critical Error Rate Alert

Triggers when error rate exceeds 10% for 1 minute:

```yaml
alert: HighErrorRateCritical
expr: (app_errors_total / app_requests_total) * 100 > 10
for: 1m
severity: critical
```

### Configuring Notifications

Edit `alertmanager.yml` to configure:

**Slack**:
```yaml
slack_configs:
  - channel: '#alerts'
    api_url: 'YOUR_SLACK_WEBHOOK_URL'
```

**Email**:
```yaml
email_configs:
  - to: 'alerts@example.com'
    from: 'alertmanager@example.com'
    smarthost: 'smtp.example.com:587'
```

**Webhook**:
```yaml
webhook_configs:
  - url: 'http://your-webhook-endpoint'
```

## Monitoring Dashboards

### Application Monitoring Dashboard

Displays:
- Requests per second (RPS)
- Average latency
- Error rate
- Application uptime

**Access**: Grafana → Dashboards → Application Monitoring Dashboard

### Creating Custom Dashboards

1. Access Grafana: http://localhost:3000
2. Click "+" → Dashboard
3. Add panels with Prometheus queries
4. Example queries:
   - `rate(app_requests_total[1m])` - RPS
   - `avg(http_request_duration_ms)` - Latency
   - `app_error_rate_percent` - Error rate

## Security Best Practices

### 1. CloudTrail

- ✓ Multi-region trail enabled
- ✓ Log file validation enabled
- ✓ Data events monitored
- ✓ Logs encrypted in S3
- ✓ S3 bucket versioning enabled
- ✓ Public access blocked

### 2. GuardDuty

- ✓ Threat detection enabled
- ✓ S3 logs analysis enabled
- ✓ Kubernetes audit logs enabled
- ✓ Findings logged to CloudWatch

### 3. CloudWatch Logs

- ✓ 90-day retention
- ✓ Centralized logging
- ✓ VPC Flow Logs enabled
- ✓ Log group encryption

### 4. S3 Bucket

- ✓ AES256 encryption
- ✓ Versioning enabled
- ✓ Public access blocked
- ✓ Lifecycle policies configured
- ✓ Bucket policy restricts access

## Troubleshooting

### Prometheus not scraping metrics

```bash
# Check Prometheus logs
docker-compose logs prometheus

# Verify app is running
curl http://localhost:5000/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

### Grafana not showing data

```bash
# Verify Prometheus datasource
curl http://localhost:9090/-/healthy

# Check Grafana logs
docker-compose logs grafana

# Verify datasource configuration
curl http://localhost:3000/api/datasources
```

### Alerts not firing

```bash
# Check alert rules
curl http://localhost:9090/api/v1/rules

# Verify AlertManager
curl http://localhost:9093/-/healthy

# Check AlertManager logs
docker-compose logs alertmanager
```

### CloudTrail not logging

```bash
# Check trail status
aws cloudtrail describe-trails --region eu-west-1

# Verify S3 bucket
aws s3 ls s3://{bucket-name}

# Check CloudTrail logs
aws cloudtrail lookup-events --region eu-west-1
```

## Cleanup

### Local Cleanup

```bash
# Stop and remove containers
docker-compose down -v

# Run cleanup script
./cleanup-observability-stack.sh
```

### AWS Cleanup

```bash
# Destroy Terraform resources
cd terraform
terraform destroy -auto-approve

# Verify resources are removed
aws cloudtrail describe-trails --region eu-west-1
aws guardduty list-detectors --region eu-west-1
aws logs describe-log-groups --region eu-west-1
```

## Performance Considerations

### Prometheus

- Scrape interval: 15s (default), 10s for app
- Retention: 30 days
- Storage: ~1-2GB per day (depends on cardinality)

### Grafana

- Dashboard refresh: 10s
- Query timeout: 30s
- Memory: ~200MB

### Node Exporter

- Scrape interval: 15s
- Metrics: ~500-1000 per node

### CloudWatch Logs

- Retention: 90 days
- Cost: ~$0.50 per GB ingested

## Cost Optimization

1. **Reduce retention**: Lower CloudWatch log retention from 90 to 30 days
2. **Adjust scrape intervals**: Increase Prometheus scrape interval to 30s
3. **Use lifecycle policies**: Archive old CloudTrail logs to Glacier
4. **Filter logs**: Only log necessary events in CloudTrail
5. **Use spot instances**: For Prometheus/Grafana EC2 instances

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AWS CloudTrail](https://docs.aws.amazon.com/cloudtrail/)
- [AWS GuardDuty](https://docs.aws.amazon.com/guardduty/)
- [AWS CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
