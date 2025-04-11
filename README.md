# Aviatrix AWS Onboarding Script 

## Overview

This script (`aviatrix-exact-cloudformation.sh`) provides a direct command-line implementation of the Aviatrix CloudFormation template for onboarding AWS accounts to the Aviatrix PaaS. It creates the necessary IAM roles and policies that allow Aviatrix to access and manage resources in the target AWS account.

## Purpose

The script creates identical IAM resources to those defined in the Aviatrix CloudFormation template, but uses the AWS CLI instead of CloudFormation. This allows for:

1. Command-line deployment without requiring CloudFormation
2. Integration into automation workflows
3. Ease of deployment in environments where CloudFormation is not preferred
4. Idempotent execution (can be run multiple times safely)

## Required ARN

**Important**: You must use the following ARN to successfully onboard accounts to Aviatrix AWS PaaS:

```
arn:aws:iam::343218225342:role/aviatrix-role-ec2-f-58a636c8abfb48c393b92305bb2e3e05
```

This is the Aviatrix Controller role that will assume the roles created in your account.

## IAM Resources Created

The script creates the following IAM resources:

### 1. aviatrix-platform-app Role

**Purpose**: Main role for Aviatrix to access your AWS account
**Trust Relationship**: Trusts the Aviatrix Controller role to assume this role
**Resource Properties**:
- RoleName: `aviatrix-platform-app`
- Path: `/`

### 2. EC2 Role (AviatrixRole or as specified in the ARN)

**Purpose**: Role for EC2 resources launched by Aviatrix
**Trust Relationship**: Trusts the Aviatrix Controller role to assume this role
**Resource Properties**:
- RoleName: Extracted from the Principal ARN (e.g., `AviatrixRole`)
- Path: `/`

### 3. aviatrix-platform-app-policy

**Purpose**: Policy defining permissions for Aviatrix to manage AWS resources
**Attached To**: The `aviatrix-platform-app` role
**Permissions**: Includes permissions for:
- EC2 resources (VPCs, subnets, security groups, instances, etc.)
- Transit Gateways
- Route tables
- Load Balancers
- S3 buckets
- IAM roles and policies
- CloudWatch
- Direct Connect
- RAM (Resource Access Manager)
- And various other AWS services

## Usage

```bash
./aviatrix-exact-cloudformation.sh <principal-arn>
```

Example:
```bash
./aviatrix-exact-cloudformation.sh arn:aws:iam::343218225342:role/aviatrix-role-ec2-f-58a636c8abfb48c393b92305bb2e3e05
```

## Requirements

1. AWS CLI installed and configured
2. Appropriate AWS credentials with permissions to create IAM roles and policies
3. Bash shell environment

## Important Notes for Operators

1. **IAM Permissions**: The user executing this script must have permissions to create and manage IAM roles and policies.

2. **Policy Versions**: The script handles the AWS limit of 5 policy versions by deleting the oldest non-default version if necessary.

3. **Error Handling**: If roles or policies already exist, the script will attempt to update them rather than failing.

4. **Trust Relationship**: The trust relationship is set up exactly as in the CloudFormation template, allowing the Aviatrix Controller role to assume the created roles.

5. **Account Preparation**: Before running this script, ensure the AWS account has been prepared for Aviatrix integration according to Aviatrix documentation.

6. **Regional Considerations**: The IAM resources created are global, not region-specific.

7. **MFA Considerations**: If the AWS account enforces MFA, ensure appropriate authentication is performed before running the script.

8. **CloudFormation Equivalent**: This script creates the exact same resources as the Aviatrix CloudFormation template, so it can be used as a direct replacement.

9. **Troubleshooting**: If you encounter the "Failed to assume role to app role aviatrix-platform-app" error, ensure the Principal ARN is correct and that the EC2 role has appropriate permissions.

## Permission Details

The policy created includes significant permissions for AWS resource management. Key permission categories:

- **Read-only permissions**: EC2:Describe*, EC2:Get*, IAM:List*, IAM:Get*, etc.
- **VPC permissions**: Create, modify, and delete VPCs, subnets, route tables, etc.
- **Security permissions**: Manage security groups, network ACLs, etc.
- **Networking permissions**: Internet gateways, NAT gateways, transit gateways, VPC endpoints, etc.
- **Management permissions**: IAM role management, instance profile management, etc.

Review the policy document in the script for the comprehensive list of permissions granted.

## Idempotence

The script is designed to be idempotent:
- It checks if resources exist before creating them
- It updates existing resources rather than failing on duplicates
- It handles policy version limits appropriately

You can run the script multiple times without causing errors or duplicate resources.

## Support

For issues with the script or onboarding process, contact Aviatrix support with the following information:
- Your AWS Account ID
- The ARN used for the Principal
- Any error messages encountered during script execution
