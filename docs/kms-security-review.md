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

## SEC-027 — Final KMS Policy Audit

### Scan baseline
Checkov 3.3.29: 232 passed, 28 failed, 0 skipped.
15 findings affect five KMS policy documents:
CKV_AWS_109, CKV_AWS_111 and CKV_AWS_356.

### S3 KMS key policy
The key policy delegates key management to the AWS account
principal using kms:*.

In a KMS key policy, Resource = "*" refers to the key
to which the policy is attached.

The EC2 application role has only kms:Decrypt permission
on this specific KMS key, according to the reviewed IAM policy.

Risk: identities with sufficiently broad IAM permissions
may obtain administrative control of the key.

Decision: retain the existing delegation pattern for this
laboratory and document the residual administrative risk.
Review IAM administrators before production deployment.

Status: reviewed; Checkov findings remain open.

### Secrets Manager KMS key policy
The key policy delegates management to the AWS account.

The reviewed EC2 role is allowed to call
secretsmanager:GetSecretValue on the database secret
and kms:Decrypt on the corresponding KMS key.

Risk: compromise of the EC2 role may expose database credentials.

Decision: retain resource-scoped application permissions.
Review secret access and rotation before production use.

### CloudTrail SNS KMS key policy
The CloudTrail service principal is allowed to perform
kms:GenerateDataKey* and kms:Decrypt.

The statement includes an aws:SourceAccount restriction.

Risk: administrative IAM delegation remains broad.
The service statement should also be reviewed for
additional source restrictions where supported.

Decision: retain for the laboratory pending integration testing.

### CloudTrail CloudWatch Logs KMS key policy
CloudWatch Logs permissions are restricted to the
regional service principal and the specific Log Group
through the KMS encryption context.

Risk: broad account-level administrative delegation remains.
Operations without the required encryption context
may need separate permission handling.

Decision: retain pending runtime validation.

### VPC Flow Logs KMS key policy
CloudWatch Logs permissions are restricted to the
regional service principal and the Flow Logs Log Group
through the KMS encryption context.

Risk: broad account-level administrative delegation remains.
Runtime compatibility of the encryption context
conditions has not been verified.

Decision: retain pending runtime validation.

## Final assessment
All five flagged KMS policy documents have been reviewed.

The 15 Checkov findings remain open and are not suppressed.

Administrative delegation is retained for the laboratory.
Application-level permissions were reviewed where available,
but this is not a complete audit of account-wide IAM access.

No AWS resources were deployed or tested during this review.

Before production use:
- Audit IAM administrators and effective permissions.
- Validate KMS service integrations.
- Review encryption context and source restrictions.
- Test application access and recovery procedures.
- Reassess residual risks and security requirements.
