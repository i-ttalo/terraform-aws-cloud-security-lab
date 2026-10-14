# KMS Security Review — SEC-012

## Scope
Review of KMS key policies and Checkov findings:
CKV_AWS_109, CKV_AWS_111 and CKV_AWS_356.

## Findings
Checkov reports potential excessive permissions in the
CloudWatch Logs KMS policy document.

## Security controls
- Account-level key management delegation through IAM.
- CloudWatch Logs service principal scoped to the AWS Region.
- Encryption Context restricted to the VPC Flow Logs log group.
- No wildcard principal in the reviewed policy.

## Risk assessment
The administrative KMS statement uses kms:* and Resource = "*".
This is a standard KMS key policy pattern for enabling IAM
delegation, but it requires appropriately restricted IAM policies.

The CloudWatch Logs statement is restricted by Encryption Context,
reducing the scope of permitted key usage.

## Decision
Retain the existing policy pending IAM permission review.
Document the Checkov findings rather than suppressing them
without justification.

## Validation
Terraform configuration validated successfully.
Checkov findings remain open for documented review.
