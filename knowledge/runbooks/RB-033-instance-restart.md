# RB-033 - Unresponsive instance restart

**Agent:** `ops-automation`
**Match terms:** unresponsive, hung, restart, reboot, not responding

## Symptoms

Unresponsive instance restart, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the instance is unreachable from two checks | `ec2_describe_instances` | false |
| 2 | Confirm no maintenance window conflict | `cloudwatch_get_alarms` | false |
| 3 | Reboot the instance | `ec2_reboot_instance` | true |

## Notes

Highest blast radius in this project. Rollback is not possible after a reboot; the mitigation is the pre-checks.
