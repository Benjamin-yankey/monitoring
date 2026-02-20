#!/bin/bash
set -e

# Fix Terraform state by importing existing AWS resources
# This script imports resources that already exist in AWS but aren't in Terraform state

echo "🔍 Fixing Terraform state..."
echo ""

# Initialize Terraform (if not already done)
terraform init

# Define resource mappings (resource_type.module.name = aws_resource_id)
declare -a imports=(
  "module.iam.aws_iam_role.jenkins=cicd-pipeline-dev-jenkins-role"
  "module.keypair.aws_key_pair.main=cicd-pipeline-dev-keypair"
  "module.monitoring.aws_cloudwatch_log_group.jenkins=/aws/ec2/cicd-pipeline-dev-jenkins"
  "module.monitoring.aws_cloudwatch_log_group.app=/aws/ec2/cicd-pipeline-dev-app"
  "module.monitoring.aws_cloudwatch_log_group.docker_app=/aws/docker/cicd-pipeline-dev-app"
  "module.monitoring.aws_cloudwatch_log_group.prometheus=/aws/docker/cicd-pipeline-dev-prometheus"
  "module.monitoring.aws_cloudwatch_log_group.grafana=/aws/docker/cicd-pipeline-dev-grafana"
  "module.monitoring.aws_cloudwatch_log_group.cloudtrail=/aws/cloudtrail/cicd-pipeline-dev"
  "module.monitoring.aws_cloudwatch_log_group.guardduty_findings=/aws/guardduty/cicd-pipeline-dev"
  "module.monitoring.aws_cloudwatch_log_group.vpc_flow_logs=/aws/vpc/cicd-pipeline-dev"
  "module.monitoring.aws_iam_role.prometheus=cicd-pipeline-dev-prometheus-role"
  "module.monitoring.aws_iam_role.grafana=cicd-pipeline-dev-grafana-role"
  "module.monitoring.aws_iam_role.flow_logs=cicd-pipeline-dev-vpc-flow-logs-role"
  "module.monitoring.aws_cloudtrail.main=cicd-pipeline-dev-trail"
)

# Import each resource
for import_pair in "${imports[@]}"; do
  IFS='=' read -r terraform_addr aws_id <<< "$import_pair"
  echo "📦 Importing: $terraform_addr"
  echo "   AWS Resource: $aws_id"
  
  # Use -no-color to avoid ANSI codes in output
  if terraform import -no-color "$terraform_addr" "$aws_id" 2>&1; then
    echo "   ✅ Success"
  else
    echo "   ⚠️  Skipping (may already exist in state or resource doesn't exist)"
  fi
  echo ""
done

echo "✅ Import complete!"
echo ""
echo "Next steps:"
echo "1. Review the imported state: terraform state list"
echo "2. Verify imports with: terraform plan"
echo "3. If there are conflicts, manually remove from state: terraform state rm <resource>"
echo "4. Update any terraform.tfvars values to match existing resources"
echo "5. Run terraform apply to sync remaining changes"
