# RB-014 - S3 bucket access denied

**Agent:** `request-access`
**Match terms:** s3, bucket, access denied, listbucket, permission

## Symptoms

S3 bucket access denied, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Read the current bucket policy | `aws_s3_get_bucket_policy` | false |
| 2 | List policies attached to the caller's role | `aws_iam_list_attached` | false |
| 3 | Attach the least-privilege list policy | `aws_iam_attach_policy` | true |

## Notes

Prefer read-only grants. Step 3 is a write and always requires approval. Rollback: detach the attached policy.
