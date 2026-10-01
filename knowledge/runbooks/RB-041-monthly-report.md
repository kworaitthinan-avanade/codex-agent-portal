# RB-041 - Monthly operations report

**Agent:** `service-management`
**Match terms:** monthly report, kpi, summary, statistics, trend

## Symptoms

Monthly operations report, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Aggregate ticket statistics for the period | `ticket_stats` | false |
| 2 | Generate the report document | `report_generate` | false |

## Notes

Figures must be reproducible from the ticket store. Never estimate.
