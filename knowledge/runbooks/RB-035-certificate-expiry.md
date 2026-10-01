# RB-035 - Certificate approaching expiry

**Agent:** `ops-automation`
**Match terms:** certificate, expiry, tls, ssl, renewal

## Symptoms

Certificate approaching expiry, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | List certificates expiring within 30 days | `resource_inventory` | false |
| 2 | Identify the owning service for each | `ec2_describe_instances` | false |

## Notes

Renewal is owned by the service team. This runbook produces the notification list.
