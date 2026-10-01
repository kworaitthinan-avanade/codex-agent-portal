# 07 - Backlog

Build in this order. Each item names the requirements it satisfies. Point Codex
at one item at a time.

## M1 - Skeleton

| # | Item | REQ |
|---|---|---|
| 1 | Create the `data/` folder tree with `.gitkeep` files | REQ-020 |
| 2 | Write `config.yaml` with both thresholds | REQ-041 |
| 3 | Register `.agents/skills` with Codex, verify with `/skills` | - |
| 4 | Copy `samples/tickets/*.json` into `data/01-inbox/` | REQ-001 |

## M2 - Grouping

| # | Item | REQ |
|---|---|---|
| 5 | Implement `ticket-grouping` scoring and normalisation | REQ-002, REQ-003 |
| 6 | Auto-assign path above threshold | REQ-004 |
| 7 | Pending path below threshold with alternatives | REQ-005 |
| 8 | Hand-off so confirmation continues automatically | REQ-006 |

## M3 - One agent end to end

Start with `request-access`. Its workflow is ticket-shaped and it has both read
and write tools, so it exercises every branch of Gate 2.

| # | Item | REQ |
|---|---|---|
| 9 | Runbook retrieval writing `retrieval.json` | REQ-010 |
| 10 | Escalate when no runbook matches | REQ-011 |
| 11 | Plan construction with write flags and rollbacks | REQ-012, REQ-019 |
| 12 | Gate 2 in documented order - write flag before confidence | REQ-014, REQ-015 |
| 13 | Auto-execute path for read-only high-confidence plans | REQ-013 |
| 14 | Run artifacts: plan, retrieval, decision, trace | REQ-022 |

## M4 - Approval

| # | Item | REQ |
|---|---|---|
| 15 | `approval-gate` for grouping items | REQ-005 |
| 16 | `approval-gate` for action items with all three choice kinds | REQ-016 |
| 17 | Advisory outcomes to `04-awaiting-info` executing nothing | REQ-017 |
| 18 | Rejection to `05-escalated` with reason | REQ-018 |
| 19 | `ticket-close` with rollback on failure | REQ-020 |

## M5 - The other four agents

| # | Item | REQ |
|---|---|---|
| 20 | `agent-service-desk` | REQ-010..019 |
| 21 | `agent-ops-automation` | REQ-010..019 |
| 22 | `agent-finops` | REQ-010..019 |
| 23 | `agent-service-management` | REQ-010..019 |

## M6 - UI

| # | Item | REQ |
|---|---|---|
| 24 | `board-refresh` writing `board.json` | REQ-022 |
| 25 | Overview page with four counters and the board | REQ-030, REQ-031 |
| 26 | Review Queue with two sections | REQ-032 |
| 27 | Expanded action card, Approve gated on scroll | REQ-033 |
| 28 | `stats.json` with split times and token totals | REQ-034, REQ-035 |
| 29 | Insights page | REQ-034, REQ-035 |

## M7 - Polish

| # | Item | REQ |
|---|---|---|
| 30 | `bridge.ps1` click-to-run | - |
| 31 | FAQ candidate generation after three uses of a runbook | - |
| 32 | Threshold-change replay comparison from `samples/` | REQ-023 |

## Deliberately not in scope

Real ServiceNow integration, real cloud mutations, authentication, multi-user
approval routing, vector search. Each would be a substitution behind an existing
skill contract rather than a change to the model - which is the point of keeping
the contracts narrow.
