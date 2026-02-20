# Observability Stack Testing and Verification Guide

This guide provides step-by-step instructions to verify all components of the observability and security stack.

## Prerequisites

- Docker and Docker Compose installed
- AWS CLI configured with appropriate credentials
- curl or Postman for API testing
- Access to AWS Console

## Local Testing (Docker Compose)

### 1. Start the Stack

```bash
# Navigate to project directory
cd /Users/huey/Desktop/Project/monitoring

# Start all services
docker-compose up -d

# Verify containers are running
docker-compose ps
```

Expected output:
```
NAME                COMMAND                  SERVICE             STATUS
alertmanager        "/bin/alertmanager ..."  alertmanager        Up
app                 "npm start"              app                 Up
grafana             "/run.sh"                grafana             Up
node-exporter       "/bin/node_exporter"     node-exporter       Up
prometheus          "/bin/prometheus ..."    prometheus          Up
```

### 2. Test Application Metrics Endpoint

```bash
# Test /metrics endpoint
curl -s http://localhost:5000/metrics | head -20

# Expected output:
# # HELP app_uptime_seconds Application uptime in seconds
# # TYPE app_uptime_seconds gauge
# app_uptime_seconds 45.123
# ...
```

### 3. Generate Test Traffic

```bash
# Generate requests to create metrics
for i in {1..50}; do
  curl -s http://localhost:5000/ > /dev/null
  curl -s http://localhost:5000/api/info > /dev/null
  sleep 0.1
done

# Verify metrics updated
curl -s http://localhost:5000/metrics | grep app_requests_total
```

### 4. Test Prometheus

```bash
# Health check
curl -s http://localhost:9090/-/healthy

# Query app requests
curl -s 'http://localhost:9090/api/v1/query?query=app_requests_total' | jq .

# Query error rate
curl -s 'http://localhost:9090/api/v1/query?query=app_error_rate_percent' | jq .

# List all targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, state: .health}'

# Expected targets:
# - app (up)
# - node-exporter (up)
# - prometheus (up)
# - alertmanager (up)
```

### 5. Test Grafana

```bash
# Health check
curl -s http://localhost:3000/api/health | jq .

# List datasources
curl -s http://localhost:3000/api/datasources | jq '.[] | {name: .name, type: .type}'

# Access UI
open http://localhost:3000
# Login: admin / admin
```

**Grafana Verification Steps**:
1. Login with admin/admin
2. Navigate to Dashboards
3. Open "Application Monitoring Dashboard"
4. Verify panels show data:
   - Requests Per Second
   - Average Latency
   - Error Rate
   - Application Uptime

### 6. Test AlertManager

```bash
# Health check
curl -s http://localhost:9093/-/healthy

# List alerts
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | {labels: .labels, state: .state}'

# List alert groups
curl -s http://localhost:9093/api/v1/alerts/groups | jq .
```

### 7. Test Node Exporter

```bash
# Get metrics
curl -s http://localhost:9100/metrics | head -20

# Check specific metrics
curl -s http://localhost:9100/metrics | grep node_cpu_seconds_total | head -5
curl -s http://localhost:9100/metrics | grep node_memory_MemTotal_bytes
curl -s http://localhost:9100/metrics | grep node_filesystem_size_bytes
```

### 8. Trigger Test Alerts

```bash
# Generate high error rate (simulate errors)
for i in {1..100}; do
  curl -s http://localhost:5000/nonexistent 2>/dev/null || true
done

# Wait for Prometheus evaluation (15-30 seconds)
sleep 30

# Check if alert fired
curl -s http://localhost:9090/api/v1/alerts | jq '.data[] | select(.labels.alertname=="HighErrorRate")'

# Check AlertManager
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | select(.labels.alertname=="HighErrorRate")'
```

### 9. Test Prometheus Rules

```bash
# List all rules
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | {name: .name, rules: (.rules | length)}'

# Check specific rule
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name=="app_alerts") | .rules[] | {alert: .alert, expr: .expr}'
```

### 10. View Container Logs

```bash
# Application logs
docker-compose logs app | tail -20

# Prometheus logs
docker-compose logs prometheus | tail -20

# Grafana logs
docker-compose logs grafana | tail -20

# AlertManager logs
docker-compose logs alertmanager | tail -20

# Node Exporter logs
docker-compose logs node-exporter | tail -20
```

## AWS Testing (Terraform Deployment)

### 1. Verify Terraform Deployment

```bash
cd terraform

# Check deployment status
terraform show

# Get outputs
terraform output

# Expected outputs:
# - prometheus_public_ip
# - grafana_public_ip
# - cloudtrail_bucket_name
# - guardduty_detector_id
```

### 2. Test Prometheus EC2 Instance

```bash
# Get Prometheus IP
PROMETHEUS_IP=$(terraform output -raw prometheus_public_ip)

# SSH to instance
ssh -i /path/to/key.pem ec2-user@$PROMETHEUS_IP

# Check Prometheus service
sudo systemctl status prometheus

# Check Node Exporter service
sudo systemctl status node-exporter

# View Prometheus config
cat /etc/prometheus/prometheus.yml

# Exit SSH
exit
```

### 3. Test Grafana EC2 Instance

```bash
# Get Grafana IP
GRAFANA_IP=$(terraform output -raw grafana_public_ip)

# SSH to instance
ssh -i /path/to/key.pem ec2-user@$GRAFANA_IP

# Check Docker containers
docker ps

# Check Grafana logs
docker logs grafana

# Exit SSH
exit
```

### 4. Verify CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups --region eu-west-1 | jq '.logGroups[] | {name: .logGroupName, retention: .retentionInDays}'

# View recent logs
aws logs tail /aws/cloudtrail/cicd-pipeline-dev --follow --since 1h

# Get log stream names
aws logs describe-log-streams --log-group-name /aws/cloudtrail/cicd-pipeline-dev --region eu-west-1
```

### 5. Verify CloudTrail

```bash
# Check trail status
aws cloudtrail describe-trails --region eu-west-1 | jq '.trailList[] | {Name: .Name, IsMultiRegionTrail: .IsMultiRegionTrail, LogFileValidationEnabled: .LogFileValidationEnabled}'

# Get trail status
aws cloudtrail get-trail-status --name cicd-pipeline-dev-trail --region eu-west-1

# View recent events
aws cloudtrail lookup-events --region eu-west-1 --max-results 10 | jq '.Events[] | {EventName: .EventName, EventTime: .EventTime, Username: .Username}'

# Check S3 bucket
BUCKET=$(terraform output -raw cloudtrail_bucket_name)
aws s3 ls s3://$BUCKET --recursive | head -10

# Check bucket encryption
aws s3api get-bucket-encryption --bucket $BUCKET --region eu-west-1

# Check bucket lifecycle
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET --region eu-west-1
```

### 6. Verify GuardDuty

```bash
# List detectors
aws guardduty list-detectors --region eu-west-1

# Get detector details
DETECTOR_ID=$(aws guardduty list-detectors --region eu-west-1 --query 'DetectorIds[0]' --output text)
aws guardduty get-detector --detector-id $DETECTOR_ID --region eu-west-1

# List findings
aws guardduty list-findings --detector-id $DETECTOR_ID --region eu-west-1 --finding-criteria '{"Criterion":{"severity":{"Gte":4}}}' | jq '.FindingIds | length'

# Get finding details
FINDING_ID=$(aws guardduty list-findings --detector-id $DETECTOR_ID --region eu-west-1 --query 'FindingIds[0]' --output text)
if [ ! -z "$FINDING_ID" ]; then
  aws guardduty get-findings --detector-id $DETECTOR_ID --finding-ids $FINDING_ID --region eu-west-1 | jq '.Findings[0]'
fi
```

### 7. Verify IAM Roles and Policies

```bash
# List IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `cicd-pipeline`)]' | jq '.[] | {RoleName: .RoleName, CreateDate: .CreateDate}'

# Check Prometheus role policies
aws iam list-role-policies --role-name cicd-pipeline-dev-prometheus-role

# Check Grafana role policies
aws iam list-role-policies --role-name cicd-pipeline-dev-grafana-role
```

## Performance Testing

### 1. Load Testing

```bash
# Install Apache Bench (if not installed)
# macOS: brew install httpd
# Linux: sudo apt-get install apache2-utils

# Run load test
ab -n 1000 -c 10 http://localhost:5000/

# Monitor metrics during load test
watch -n 1 'curl -s http://localhost:5000/metrics | grep app_'
```

### 2. Monitor Resource Usage

```bash
# Docker stats
docker stats --no-stream

# Prometheus storage usage
du -sh /var/lib/docker/volumes/monitoring_prometheus_data/_data

# Grafana storage usage
du -sh /var/lib/docker/volumes/monitoring_grafana_data/_data
```

## Security Testing

### 1. Verify Encryption

```bash
# Check S3 bucket encryption
aws s3api get-bucket-encryption --bucket $BUCKET --region eu-west-1 | jq '.Rules[0].ApplyServerSideEncryptionByDefault'

# Check S3 bucket versioning
aws s3api get-bucket-versioning --bucket $BUCKET --region eu-west-1
```

### 2. Verify Access Controls

```bash
# Check S3 public access block
aws s3api get-public-access-block --bucket $BUCKET --region eu-west-1

# Check bucket policy
aws s3api get-bucket-policy --bucket $BUCKET --region eu-west-1 | jq '.Policy | fromjson'
```

### 3. Verify CloudTrail Validation

```bash
# Check log file validation
aws cloudtrail describe-trails --region eu-west-1 | jq '.trailList[0].LogFileValidationEnabled'

# Validate CloudTrail logs
aws cloudtrail validate-logs --trail-name cicd-pipeline-dev-trail --region eu-west-1
```

## Troubleshooting

### Issue: Prometheus not scraping metrics

**Solution**:
```bash
# Check Prometheus logs
docker-compose logs prometheus | grep -i error

# Verify app is running
curl http://localhost:5000/health

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="down")'

# Restart Prometheus
docker-compose restart prometheus
```

### Issue: Grafana not showing data

**Solution**:
```bash
# Check Grafana logs
docker-compose logs grafana | grep -i error

# Verify Prometheus datasource
curl http://localhost:3000/api/datasources | jq '.[] | select(.name=="Prometheus")'

# Test Prometheus connection
curl http://localhost:9090/-/healthy

# Restart Grafana
docker-compose restart grafana
```

### Issue: Alerts not firing

**Solution**:
```bash
# Check alert rules
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | {alert: .alert, state: .state}'

# Check AlertManager
curl http://localhost:9093/-/healthy

# View AlertManager logs
docker-compose logs alertmanager | grep -i error

# Restart AlertManager
docker-compose restart alertmanager
```

### Issue: CloudTrail not logging

**Solution**:
```bash
# Check trail status
aws cloudtrail get-trail-status --name cicd-pipeline-dev-trail --region eu-west-1

# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket $BUCKET --region eu-west-1

# Start trail if stopped
aws cloudtrail start-logging --trail-name cicd-pipeline-dev-trail --region eu-west-1
```

## Cleanup

### Local Cleanup

```bash
# Stop and remove containers
docker-compose down -v

# Remove volumes
docker volume rm monitoring_prometheus_data monitoring_grafana_data monitoring_alertmanager_data
```

### AWS Cleanup

```bash
# Destroy Terraform resources
cd terraform
terraform destroy -auto-approve

# Verify cleanup
aws cloudtrail describe-trails --region eu-west-1
aws guardduty list-detectors --region eu-west-1
aws logs describe-log-groups --region eu-west-1
```

## Success Criteria

✓ Application metrics endpoint responds at /metrics
✓ Prometheus scrapes all targets successfully
✓ Grafana displays dashboard with real-time data
✓ AlertManager receives and routes alerts
✓ Node Exporter collects system metrics
✓ CloudWatch logs receive container logs
✓ CloudTrail logs account activity to S3
✓ GuardDuty detects threats
✓ S3 bucket has encryption and lifecycle policies
✓ All services are highly available and resilient
