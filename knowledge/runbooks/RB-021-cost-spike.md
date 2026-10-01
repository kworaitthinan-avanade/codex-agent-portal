# RB-021 - Unexpected cost increase in a subscription

**Agent:** `finops`
**Match terms:** cost, spike, increase, budget, spend, invoice

## Symptoms

Unexpected cost increase in a subscription, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Query cost by service for the affected period | `cost_explorer_query` | false |
| 2 | Retrieve the budget and its alert thresholds | `budget_get` | false |
| 3 | Summarise the top three contributing services with figures | `cost_explorer_query` | false |

## Notes

Present the finding. Do not resize or delete anything from this runbook.
