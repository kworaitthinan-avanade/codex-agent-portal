# RB-022 - Idle or underused resource review

**Agent:** `finops`
**Match terms:** idle, unused, underused, rightsizing, stopped instance

## Symptoms

Idle or underused resource review, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Inventory resources with low utilisation over 30 days | `resource_inventory` | false |
| 2 | Estimate the monthly saving per candidate | `cost_explorer_query` | false |

## Notes

Produce a recommendation only. Resizing is a separate approved change.
