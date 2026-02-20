#!/bin/bash

# Observability and Security Stack Cleanup Script
# This script removes all monitoring, logging, and security resources

set -e

PROJECT_NAME="${1:-cicd-pipeline}"
ENVIRONMENT="${2:-dev}"
AWS_REGION="${3:-eu-central-1}"

echo "=========================================="
echo "Observability & Security Stack Cleanup"
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

# Confirmation
echo "This will remove:"
echo "  - Docker Compose containers and volumes"
echo "  - Prometheus and Grafana EC2 instances"
echo "  - CloudTrail and GuardDuty configurations"
echo "  - CloudWatch log groups"
echo "  - S3 bucket with CloudTrail logs"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

# 1. Stop and remove Docker Compose stack
echo ""
echo "Step 1: Stopping Docker Compose stack..."
if docker-compose down -v 2>/dev/null; then
    print_status "Docker Compose stack stopped and removed"
else
    print_warning "Docker Compose stack not running or already removed"
fi

# 2. Disable CloudTrail
echo ""
echo "Step 2: Disabling CloudTrail..."
TRAIL_NAME="${PROJECT_NAME}-${ENVIRONMENT}-trail"
if aws cloudtrail stop-logging --trail-name "$TRAIL_NAME" --region $AWS_REGION 2>/dev/null; then
    print_status "CloudTrail stopped"
else
    print_warning "CloudTrail not found or already stopped"
fi

# 3. Delete CloudTrail
if aws cloudtrail delete-trail --trail-name "$TRAIL_NAME" --region $AWS_REGION 2>/dev/null; then
    print_status "CloudTrail deleted"
else
    print_warning "CloudTrail deletion failed or already deleted"
fi

# 4. Disable GuardDuty
echo ""
echo "Step 3: Disabling GuardDuty..."
DETECTOR_ID=$(aws guardduty list-detectors --region $AWS_REGION --query 'DetectorIds[0]' --output text 2>/dev/null)
if [ ! -z "$DETECTOR_ID" ] && [ "$DETECTOR_ID" != "None" ]; then
    if aws guardduty delete-detector --detector-id "$DETECTOR_ID" --region $AWS_REGION 2>/dev/null; then
        print_status "GuardDuty detector deleted"
    else
        print_warning "GuardDuty deletion failed"
    fi
else
    print_warning "GuardDuty detector not found"
fi

# 5. Delete CloudWatch Log Groups
echo ""
echo "Step 4: Deleting CloudWatch Log Groups..."
LOG_GROUPS=$(aws logs describe-log-groups --region $AWS_REGION --query "logGroups[?contains(logGroupName, '$PROJECT_NAME')].logGroupName" --output text)
for LOG_GROUP in $LOG_GROUPS; do
    if aws logs delete-log-group --log-group-name "$LOG_GROUP" --region $AWS_REGION 2>/dev/null; then
        print_status "Deleted log group: $LOG_GROUP"
    fi
done

# 6. Empty and delete S3 CloudTrail bucket
echo ""
echo "Step 5: Deleting S3 CloudTrail bucket..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cloudtrail-logs-${ACCOUNT_ID}"

if aws s3 ls "s3://$BUCKET_NAME" --region $AWS_REGION 2>/dev/null; then
    # Empty bucket
    if aws s3 rm "s3://$BUCKET_NAME" --recursive --region $AWS_REGION 2>/dev/null; then
        print_status "S3 bucket emptied"
    fi
    
    # Delete bucket
    if aws s3 rb "s3://$BUCKET_NAME" --region $AWS_REGION 2>/dev/null; then
        print_status "S3 bucket deleted: $BUCKET_NAME"
    else
        print_warning "S3 bucket deletion failed"
    fi
else
    print_warning "S3 bucket not found: $BUCKET_NAME"
fi

# 7. Terminate Prometheus and Grafana instances (via Terraform)
echo ""
echo "Step 6: Terminating monitoring instances..."
echo "Note: Use 'terraform destroy' to remove Prometheus and Grafana EC2 instances"
print_warning "Run: cd terraform && terraform destroy -auto-approve"

# 8. Summary
echo ""
echo "=========================================="
echo "Cleanup Summary"
echo "=========================================="
print_status "Docker Compose stack removed"
print_status "CloudTrail disabled and deleted"
print_status "GuardDuty detector deleted"
print_status "CloudWatch log groups deleted"
print_status "S3 CloudTrail bucket deleted"
echo ""
echo "Remaining cleanup:"
echo "  - Run 'terraform destroy' to remove EC2 instances"
echo "  - Verify all resources are removed in AWS Console"
echo ""
