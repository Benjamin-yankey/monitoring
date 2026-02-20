# Quick Start Guide - Observability & Security Stack

## 5-Minute Local Setup

### 1. Start the Stack

```bash
cd /Users/huey/Desktop/Project/monitoring
docker-compose up -d
```

### 2. Verify Services

```bash
docker-compose ps
```

### 3. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | http://localhost:5000 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin |
| AlertManager | http://localhost:9093 | - |
| Node Exporter | http://localhost:9100/metrics | - |

### 4. Generate Test Data

```bash
# Generate requests
for i in {1..50}; do
  curl -s http://localhost:5000/ > /dev/null
  curl -s http://localhost:5000/api/info > /dev/null
done
```

### 5. View Metrics

```bash
# Application metrics
curl http://localhost:5000/metrics

# Prometheus query
curl 'http://localhost:9090/api/v1/query?query=app_requests_total'
```

## AWS Deployment (30 minutes)

### 1. Prerequisites

```bash
# Install Terraform
brew install terraform

# Configure AWS CLI
aws configure

# Set environment variables
export AWS_REGION=eu-central-1
export PROJECT_NAME=cicd-pipeline
export ENVIRONMENT=dev
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve
```

### 3. Get Access Information

```bash
# Display outputs
terraform output

# Example outputs:
# prometheus_url = "http://1.2.3.4:9090"
# grafana_url = "http://1.2.3.5:3000"
# cloudtrail_bucket_name = "cicd-pipeline-dev-cloudtrail-logs-123456789"
```

### 4. Verify Deployment

```bash
# Run verification script
./deploy-observability-stack.sh cicd-pipeline dev eu-central-1
```

## Key Features

### Metrics Collection
- Application metrics at `/metrics` endpoint
- System metrics via Node Exporter
- Prometheus time-series database

### Visualization
- Grafana dashboards
- Real-time metrics display
- Custom dashboard creation

### Alerting
- Prometheus alert rules
- AlertManager routing
- Multiple notification channels

### Logging
- CloudWatch Logs integration
- Docker container logs
- VPC Flow Logs

### Security
- CloudTrail for audit logging
- GuardDuty for threat detection
- S3 encryption and lifecycle policies

### Compliance
- 90-day log retention
- Log file validation
- Multi-region trail
- Encrypted storage

## Common Tasks

### View Application Metrics

```bash
curl http://localhost:5000/metrics
```

### Query Prometheus

```bash
# Error rate
curl 'http://localhost:9090/api/v1/query?query=app_error_rate_percent'

# Requests per second
curl 'http://localhost:9090/api/v1/query?query=rate(app_requests_total[1m])'

# Latency
curl 'http://localhost:9090/api/v1/query?query=avg(http_request_duration_ms)'
```

### Access Grafana

1. Open http://localhost:3000
2. Login: admin/admin
3. Navigate to Dashboards
4. Select "Application Monitoring Dashboard"

### Configure Alerts

Edit `alertmanager.yml`:

```yaml
slack_configs:
  - channel: '#alerts'
    api_url: 'YOUR_SLACK_WEBHOOK_URL'
```

Restart AlertManager:
```bash
docker-compose restart alertmanager
```

### View CloudTrail Logs

```bash
aws logs tail /aws/cloudtrail/cicd-pipeline-dev --follow
```

### Check GuardDuty Findings

```bash
DETECTOR_ID=$(aws guardduty list-detectors --region eu-central-1 --query 'DetectorIds[0]' --output text)
aws guardduty list-findings --detector-id $DETECTOR_ID --region eu-central-1
```

## Troubleshooting

### Services not starting

```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Rebuild containers
docker-compose up -d --build
```

### Prometheus not scraping

```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Verify app is running
curl http://localhost:5000/health
```

### Grafana not showing data

```bash
# Verify datasource
curl http://localhost:3000/api/datasources

# Check Prometheus
curl http://localhost:9090/-/healthy
```

## Cleanup

### Local

```bash
docker-compose down -v
```

### AWS

```bash
cd terraform
terraform destroy -auto-approve
```

## Next Steps

1. **Customize Dashboards**: Create custom Grafana dashboards for your metrics
2. **Configure Notifications**: Set up Slack, email, or webhook alerts
3. **Tune Alert Rules**: Adjust thresholds based on your application
4. **Monitor Costs**: Review CloudWatch and S3 costs
5. **Implement Retention**: Adjust log retention policies as needed

## Documentation

- [Full Observability Stack Guide](./OBSERVABILITY_STACK.md)
- [Testing & Verification Guide](./TESTING_VERIFICATION.md)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AWS CloudTrail](https://docs.aws.amazon.com/cloudtrail/)
- [AWS GuardDuty](https://docs.aws.amazon.com/guardduty/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `docker-compose logs`
3. Verify connectivity: `curl http://localhost:PORT`
4. Check AWS resources: AWS Console
