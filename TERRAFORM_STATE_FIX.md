# Terraform State Fix Guide

Your Terraform state is out of sync with AWS. Resources exist in AWS but Terraform doesn't know about them.

## Option 1: Import Existing Resources (Recommended)

Import existing AWS resources into Terraform state without deleting them:

```bash
cd terraform/
chmod +x fix-state.sh
./fix-state.sh
```

This script will:
1. Import all existing IAM roles
2. Import the EC2 key pair
3. Import CloudWatch log groups
4. Import CloudTrail trail
5. Update your Terraform state

Then verify and apply:
```bash
terraform plan
terraform apply
```

## Option 2: Manual Import

If you want to import specific resources:

```bash
cd terraform/
terraform init

# Import IAM roles
terraform import module.iam.aws_iam_role.jenkins cicd-pipeline-dev-jenkins-role
terraform import module.monitoring.aws_iam_role.prometheus cicd-pipeline-dev-prometheus-role
terraform import module.monitoring.aws_iam_role.grafana cicd-pipeline-dev-grafana-role
terraform import module.monitoring.aws_iam_role.flow_logs cicd-pipeline-dev-vpc-flow-logs-role

# Import key pair
terraform import module.keypair.aws_key_pair.main cicd-pipeline-dev-keypair

# Import CloudWatch log groups
terraform import module.monitoring.aws_cloudwatch_log_group.jenkins /aws/ec2/cicd-pipeline-dev-jenkins
terraform import module.monitoring.aws_cloudwatch_log_group.app /aws/ec2/cicd-pipeline-dev-app
# ... (see fix-state.sh for complete list)

# Import CloudTrail
terraform import module.monitoring.aws_cloudtrail.main cicd-pipeline-dev-trail
```

## Option 3: Clean Start (Destroys resources)

If you want to start fresh and let Terraform recreate everything:

```bash
cd terraform/

# Remove state file
rm -rf .terraform/

# Destroy existing resources in AWS (optional)
terraform init
terraform destroy

# Re-apply
terraform init
terraform apply
```

**⚠️ Warning**: This will delete all existing AWS resources!

## After Importing

1. **Verify imports**:
   ```bash
   terraform state list
   terraform plan
   ```

2. **Check for conflicts**:
   - If terraform plan shows unexpected changes, review the differences
   - You may need to update `terraform.tfvars` to match existing resource values

3. **Remove unnecessary resources from state** (if needed):
   ```bash
   terraform state rm module.path.aws_resource_type.name
   ```

4. **Apply remaining changes**:
   ```bash
   terraform apply
   ```

## Common Issues

### "Resource already exists in state"
If you try to import a resource that's already in state:
```bash
# Remove from state first
terraform state rm module.path.aws_resource_type.name
# Then import
terraform import module.path.aws_resource_type.name aws_resource_id
```

### Import fails with "InvalidKeyPair.Duplicate"
The EC2 key pair may need special handling. Check AWS console for the key pair name and ensure `terraform.tfvars` has the correct name.

### CloudWatch log group not found
Ensure the log group name matches exactly. Check AWS CloudWatch Logs console for the actual group names.

## State File Location

Your Terraform state is stored in:
```
terraform/.terraform/
terraform/terraform.tfstate (local backend)
```

## Next Steps

After fixing the state:

1. Commit the updated state (if using state management)
2. Update documentation with the resource IDs
3. Configure CI/CD to use proper state backend (S3, Terraform Cloud, etc.)

## References

- [Terraform Import Docs](https://www.terraform.io/cli/commands/import)
- [Terraform State Management](https://www.terraform.io/language/state)
