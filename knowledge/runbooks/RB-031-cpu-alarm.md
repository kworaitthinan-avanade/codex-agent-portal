# RB-031 - Sustained high CPU alarm

**Agent:** `ops-automation`
**Match terms:** cpu, alarm, high utilisation, performance, cloudwatch

## Symptoms

Sustained high CPU alarm, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Retrieve the firing alarm and its history | `cloudwatch_get_alarms` | false |
| 2 | Describe the affected instance | `ec2_describe_instances` | false |
| 3 | Query application logs for the alarm window | `log_query` | false |

## Notes

Diagnose first. A restart is a separate decision requiring approval.
