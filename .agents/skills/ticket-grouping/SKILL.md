---
name: ticket-grouping
description: Classifies tickets in data/01-inbox into one of five agent groups, or asks a human when confidence is low.
---

# ticket-grouping

Gate 1. Decides **who** handles the ticket.

## Reads

- `data/01-inbox/*.json`
- `config.yaml` (`thresholds.grouping`, `agents`)

## Writes

- `data/02-grouped/<agent>/` when confident
- `data/03-approval/pending-grouping/` when not
- `data/runs/<run-id>/`

## Rules

1. Score the ticket against all five agents using the signal sets below.
   Normalise the scores so they sum to 1.
2. Record the top score as `confidence.grouping`, the rest as `alternatives`,
   sorted descending (REQ-003).
3. Record which terms matched, as `match_reason`. The reviewer needs to see why.
4. If `confidence.grouping >= thresholds.grouping`: set `agent`, set `state` to
   `grouped`, move to `data/02-grouped/<agent>/`, then hand off to that agent
   skill in the same run (REQ-004, REQ-006).
5. Otherwise: set `state` to `pending-grouping`, move to
   `data/03-approval/pending-grouping/`, and stop (REQ-005).
6. Never assign two agents. Never leave `agent` null after a successful
   grouping (REQ-002).
7. Do not escalate automatically at this gate. If the AI is unsure a human
   decides, and Escalate is one of the six buttons they may press.

## Signals

| Agent | Signals |
|---|---|
| `service-desk` | password, login, cannot open, how do I, error message, not working, slow, install, printer, VPN client |
| `request-access` | access, permission, denied, provision, create account, SSO, role, group membership, subscription, environment creation |
| `ops-automation` | alert, alarm, monitoring, CPU, memory, disk, patch, vulnerability, CVE, restart, backup, certificate expiry |
| `service-management` | report, FAQ, KPI, progress, monthly, analysis, trend, documentation, knowledge article |
| `finops` | cost, budget, spend, invoice, billing, rightsizing, reserved instance, savings plan, idle resource |

Japanese equivalents count the same: アクセス, 権限, 費用, 障害, 監視, 申請.


## Universal rules

1. Move ticket files, never copy. One ticket exists in exactly one folder (REQ-020).
2. Append to `history`, never rewrite (REQ-021).
3. Read thresholds from `config.yaml`. Never hardcode a threshold (REQ-041).
4. Write `data/runs/<run-id>/` with `plan.json`, `retrieval.json`,
   `decision.json` and `trace.log` (REQ-022).
5. Never write into `samples/`.
6. Reply in the language of the ticket.
