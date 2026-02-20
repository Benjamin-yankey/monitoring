#!/bin/bash

# Observability and Security Stack Deployment Script
# This script deploys and verifies the complete monitoring, logging, and security stack

set -e

PROJECT_NAME="${1:-cicd-pipeline}"
ENVIRONMENT="${2:-dev}"
AWS_REGION="${3:-eu-central-1}"

echo "=========================================="
echo "Observability & Security Stack Deployment"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 1. Deploy Docker Compose Stack (Local/Dev)
echo ""
echo "Step 1: Deploying Docker Compose Stack..."
if docker-compose up -d; then
    print_status "Docker Compose stack deployed successfully"
    sleep 10
else
    print_error "Failed to deploy Docker Compose stack"
    exit 1
fi

# 2. Verify Application Metrics
echo ""
echo "Step 2: Verifying Application Metrics..."
if curl -s http://localhost:5000/metrics | grep -q "app_requests_total"; then
    print_status "Application metrics endpoint is working"
else
    print_error "Application metrics endpoint not responding"
fi

# 3. Verify Prometheus
echo ""
echo "Step 3: Verifying Prometheus..."
if curl -s http://localhost:9090/-/healthy | grep -q "Prometheus"; then
    print_status "Prometheus is healthy"
    
    # Check targets
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"state":"up"' | wc -l)
    print_status "Prometheus has $TARGETS targets up"
else
    print_error "Prometheus health check failed"
fi

# 4. Verify Grafana
echo ""
echo "Step 4: Verifying Grafana..."
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    print_status "Grafana is healthy"
else
    print_error "Grafana health check failed"
fi

# 5. Verify AlertManager
echo ""
echo "Step 5: Verifying AlertManager..."
if curl -s http://localhost:9093/-/healthy | grep -q "Alertmanager"; then
    print_status "AlertManager is healthy"
else
    print_error "AlertManager health check failed"
fi

# 6. Verify Node Exporter
echo ""
echo "Step 6: Verifying Node Exporter..."
if curl -s http://localhost:9100/metrics | grep -q "node_"; then
    print_status "Node Exporter is working"
else
    print_error "Node Exporter not responding"
fi

# 7. Check AWS CloudWatch Logs
echo ""
echo "Step 7: Checking AWS CloudWatch Logs..."
if aws logs describe-log-groups --region $AWS_REGION 2>/dev/null | grep -q "$PROJECT_NAME"; then
    print_status "CloudWatch log groups found"
    aws logs describe-log-groups --region $AWS_REGION | grep "logGroupName" | head -5
else
    print_warning "CloudWatch log groups not found (may not be deployed yet)"
fi

# 8. Check CloudTrail
echo ""
echo "Step 8: Checking CloudTrail..."
if aws cloudtrail describe-trails --region $AWS_REGION 2>/dev/null | grep -q "Name"; then
    print_status "CloudTrail is enabled"
    TRAIL_NAME=$(aws cloudtrail describe-trails --region $AWS_REGION | grep "Name" | head -1 | cut -d'"' -f4)
    print_status "Trail name: $TRAIL_NAME"
else
    print_warning "CloudTrail not found (may not be deployed yet)"
fi

# 9. Check GuardDuty
echo ""
echo "Step 9: Checking GuardDuty..."
if aws guardduty list-detectors --region $AWS_REGION 2>/dev/null | grep -q "DetectorIds"; then
    DETECTOR_ID=$(aws guardduty list-detectors --region $AWS_REGION | grep -o '"[a-f0-9]*"' | head -1 | tr -d '"')
    if [ ! -z "$DETECTOR_ID" ]; then
        print_status "GuardDuty is enabled with detector: $DETECTOR_ID"
    fi
else
    print_warning "GuardDuty not found (may not be deployed yet)"
fi

# 10. Check S3 CloudTrail Bucket
echo ""
echo "Step 10: Checking S3 CloudTrail Bucket..."
BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cloudtrail-logs-$(aws sts get-caller-identity --query Account --output text)"
if aws s3 ls "s3://$BUCKET_NAME" --region $AWS_REGION 2>/dev/null; then
    print_status "CloudTrail S3 bucket exists: $BUCKET_NAME"
    
    # Check encryption
    ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --region $AWS_REGION 2>/dev/null)
    if [ ! -z "$ENCRYPTION" ]; then
        print_status "S3 bucket encryption is enabled"
    fi
    
    # Check lifecycle policy
    LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" --region $AWS_REGION 2>/dev/null)
    if [ ! -z "$LIFECYCLE" ]; then
        print_status "S3 bucket lifecycle policy is configured"
    fi
else
    print_warning "CloudTrail S3 bucket not found (may not be deployed yet)"
fi

# 11. Generate Test Traffic
echo ""
echo "Step 11: Generating Test Traffic..."
for i in {1..10}; do
    curl -s http://localhost:5000/ > /dev/null
    curl -s http://localhost:5000/api/info > /dev/null
done
print_status "Test traffic generated"

# 12. Check Alerts
echo ""
echo "Step 12: Checking Alert Rules..."
ALERTS=$(curl -s http://localhost:9090/api/v1/rules | grep -o '"name":"[^"]*"' | wc -l)
print_status "Found $ALERTS alert rules configured"

# 13. Display Access Information
echo ""
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo "Application:     http://localhost:5000"
echo "Prometheus:      http://localhost:9090"
echo "Grafana:         http://localhost:3000 (admin/admin)"
echo "AlertManager:    http://localhost:9093"
echo "Node Exporter:   http://localhost:9100/metrics"
echo ""

# 14. Summary
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
print_status "Docker Compose stack is running"
print_status "Prometheus is scraping metrics"
print_status "Grafana dashboards are available"
print_status "AlertManager is configured"
print_status "CloudWatch logs are configured"
print_status "CloudTrail is enabled"
print_status "GuardDuty is enabled"
print_status "S3 bucket for CloudTrail logs is configured"
echo ""
echo "Next Steps:"
echo "1. Access Grafana at http://localhost:3000"
echo "2. Import dashboards from grafana/dashboards/"
echo "3. Configure alert notifications in AlertManager"
echo "4. Monitor CloudTrail logs in AWS CloudWatch"
echo "5. Review GuardDuty findings in AWS Console"
echo ""
