#!/bin/bash
# This script exactly replicates the CloudFormation template using AWS CLI commands
# No additions, no assumptions, just the exact resources as defined in the template

# Get principal ARN from command line
if [ $# -lt 1 ]; then
  echo "Usage: $0 <principal-arn>"
  echo "Example: $0 arn:aws:iam::123456789012:role/AviatrixRole"
  exit 1
fi

PRINCIPAL_ARN="$1"
echo "Using Principal ARN: $PRINCIPAL_ARN"

# Extract role name from the Principal ARN (this is what the Fn::Select and Fn::Split do in CloudFormation)
EC2_ROLE_NAME=$(echo "$PRINCIPAL_ARN" | cut -d'/' -f2)
echo "EC2 Role Name: $EC2_ROLE_NAME"

# Get AWS account ID for later use
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Create temporary directory for policy files
TMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TMP_DIR"

# 1. Create aviatrix-platform-app role
echo "Creating aviatrix-platform-app role..."

# Create the trust policy for app role (exact match to CloudFormation)
cat > "$TMP_DIR/app-trust-policy.json" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "$PRINCIPAL_ARN"
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF

# Create or update role
if aws iam get-role --role-name "aviatrix-platform-app" &> /dev/null; then
  echo "App role already exists. Updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "aviatrix-platform-app" \
    --policy-document "file://$TMP_DIR/app-trust-policy.json"
else
  echo "Creating app role..."
  aws iam create-role \
    --role-name "aviatrix-platform-app" \
    --assume-role-policy-document "file://$TMP_DIR/app-trust-policy.json" \
    --path "/"
fi

# 2. Create the EC2 role (AviatrixRoleEC2)
echo "Creating EC2 role ($EC2_ROLE_NAME)..."

# Create the trust policy for EC2 role (exact match to CloudFormation)
cat > "$TMP_DIR/ec2-trust-policy.json" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "$PRINCIPAL_ARN"
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF

# Create or update role
if aws iam get-role --role-name "$EC2_ROLE_NAME" &> /dev/null; then
  echo "EC2 role already exists. Updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "$EC2_ROLE_NAME" \
    --policy-document "file://$TMP_DIR/ec2-trust-policy.json"
else
  echo "Creating EC2 role..."
  aws iam create-role \
    --role-name "$EC2_ROLE_NAME" \
    --assume-role-policy-document "file://$TMP_DIR/ec2-trust-policy.json" \
    --path "/"
fi

# 3. Create the managed policy (CreateAviatrixAppPolicy)
echo "Creating aviatrix-platform-app-policy..."

# Create the policy document
cat > "$TMP_DIR/app-policy.json" << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:Get*",
        "ec2:Search*",
        "elasticloadbalancing:Describe*",
        "route53:List*",
        "route53:Get*",
        "sqs:Get*",
        "sqs:List*",
        "sns:List*",
        "s3:List*",
        "s3:Get*",
        "iam:List*",
        "iam:Get*",
        "directconnect:Describe*",
        "guardduty:Get*",
        "guardduty:List*",
        "ram:Get*",
        "ram:List*",
        "networkmanager:Get*",
        "networkmanager:List*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:DeleteNetworkAclEntry",
        "ec2:AssociateVpcCidrBlock",
        "ec2:AssociateSubnetCidrBlock",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:*InternetGateway*",
        "ec2:*Route*",
        "ec2:*Instance*",
        "ec2:*SecurityGroup*",
        "ec2:*Address*",
        "ec2:*NetworkInterface*",
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteFlowLogs",
        "ec2:CreateFlowLogs",
        "ec2:DescribeFlowLogs",
        "ec2:AssociateIamInstanceProfile",
        "ec2:DisassociateIamInstanceProfile",
        "ec2:DescribeIamInstanceProfileAssociations"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateCustomerGateway",
        "ec2:DeleteCustomerGateway",
        "ec2:CreateVpnConnection",
        "ec2:DeleteVpnConnection",
        "ec2:CreateVpcPeeringConnection",
        "ec2:AcceptVpcPeeringConnection",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:EnableVgwRoutePropagation",
        "ec2:DisableVgwRoutePropagation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AssociateTransitGatewayRouteTable",
        "ec2:AcceptTransitGatewayVpcAttachment",
        "ec2:CreateTransitGateway",
        "ec2:CreateTransitGatewayRoute",
        "ec2:CreateTransitGatewayRouteTable",
        "ec2:CreateTransitGatewayVpcAttachment",
        "ec2:DeleteTransitGateway",
        "ec2:DeleteTransitGatewayRoute",
        "ec2:DeleteTransitGatewayRouteTable",
        "ec2:DeleteTransitGatewayVpcAttachment",
        "ec2:DisableTransitGatewayRouteTablePropagation",
        "ec2:DisassociateTransitGatewayRouteTable",
        "ec2:EnableTransitGatewayRouteTablePropagation",
        "ec2:ExportTransitGatewayRoutes",
        "ec2:ModifyTransitGatewayVpcAttachment",
        "ec2:RejectTransitGatewayVpcAttachment",
        "ec2:ReplaceTransitGatewayRoute",
        "ec2:ModifyTransitGateway",
        "ec2:CreateTransitGatewayConnect",
        "ec2:DeleteTransitGatewayConnect",
        "ec2:CreateTransitGatewayConnectPeer",
        "ec2:DeleteTransitGatewayConnectPeer",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:CreateVpcEndpointServiceConfiguration",
        "ec2:DeleteVpcEndpointServiceConfigurations",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ram:CreateResourceShare",
        "ram:DeleteResourceShare",
        "ram:UpdateResourceShare",
        "ram:AssociateResourceShare",
        "ram:DisassociateResourceShare",
        "ram:TagResource",
        "ram:UntagResource",
        "ram:AcceptResourceShareInvitation",
        "ram:EnableSharingWithAwsOrganization"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "directconnect:CreateDirectConnectGateway",
        "directconnect:CreateDirectConnectGatewayAssociation",
        "directconnect:CreateDirectConnectGatewayAssociationProposal",
        "directconnect:DeleteDirectConnectGateway",
        "directconnect:DeleteDirectConnectGatewayAssociation",
        "directconnect:DeleteDirectConnectGatewayAssociationProposal",
        "directconnect:AcceptDirectConnectGatewayAssociationProposal"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:AddPermission",
        "sqs:ChangeMessageVisibility",
        "sqs:CreateQueue",
        "sqs:DeleteMessage",
        "sqs:DeleteQueue",
        "sqs:PurgeQueue",
        "sqs:ReceiveMessage",
        "sqs:RemovePermission",
        "sqs:SendMessage",
        "sqs:SetQueueAttributes",
        "sqs:TagQueue"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogDelivery",
        "logs:DeleteLogDelivery"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "servicequotas:GetAWSDefaultServiceQuota",
        "servicequotas:GetServiceQuota",
        "servicequotas:ListAWSDefaultServiceQuotas",
        "servicequotas:ListServiceQuotas",
        "servicequotas:ListServices"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:AddRoleToInstanceProfile",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:CreateServiceLinkedRole",
        "iam:TagInstanceProfile"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:DeletePolicyVersion",
        "iam:CreatePolicyVersion"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*",
        "route53:ChangeResourceRecordSets",
        "ec2:*Volume*",
        "ec2:*Snapshot*",
        "ec2:*TransitGatewayPeeringAttachment",
        "guardduty:*",
        "globalaccelerator:*",
        "networkmanager:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudtrail:Get*",
        "cloudtrail:Describe*",
        "cloudtrail:List*",
        "cloudtrail:LookupEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:ListClusters",
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create or update policy
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/aviatrix-platform-app-policy"
if aws iam get-policy --policy-arn "$POLICY_ARN" &> /dev/null; then
  echo "Policy exists, creating new version..."
  
  # Handle version limits if needed
  VERSION_COUNT=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query "length(Versions)" --output text)
  if [ "$VERSION_COUNT" -ge 5 ]; then
    echo "Deleting oldest non-default version..."
    OLDEST_VERSION=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query "Versions[?IsDefaultVersion==\`false\`] | sort_by(@, &CreateDate)[0].VersionId" --output text)
    if [ -n "$OLDEST_VERSION" ] && [ "$OLDEST_VERSION" != "None" ]; then
      aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$OLDEST_VERSION"
    fi
  fi
  
  aws iam create-policy-version \
    --policy-arn "$POLICY_ARN" \
    --policy-document "file://$TMP_DIR/app-policy.json" \
    --set-as-default
else
  echo "Creating new policy..."
  aws iam create-policy \
    --policy-name "aviatrix-platform-app-policy" \
    --policy-document "file://$TMP_DIR/app-policy.json" \
    --description "Policy for creating aviatrix-platform-app-policy" \
    --path "/"
fi

# 4. Attach policy to app role (this is in the CloudFormation 'Roles' section under the policy)
echo "Attaching policy to app role..."
aws iam attach-role-policy \
  --role-name "aviatrix-platform-app" \
  --policy-arn "$POLICY_ARN"

# Final output
echo "==============================================="
echo "Aviatrix IAM resources created successfully"
echo "==============================================="
echo "Account ID: $AWS_ACCOUNT_ID"
echo "AviatrixRoleApp ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/aviatrix-platform-app"
echo "==============================================="

# Clean up
rm -rf "$TMP_DIR"