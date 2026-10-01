# 05 - Skills specification

Every skill declares **Reads**, **Writes** and **Rules**. That uniform contract
is what makes them composable and independently checkable.

Skills live in `.agents/skills/<name>/SKILL.md`. Register them once:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.codex\skills\codex-agent" -Target ".\.agents\skills"
```

Confirm with `/skills` before building anything on top - a `SKILL.md` in a
folder Codex does not scan will not appear.

## Universal rules

These apply to every skill and are not repeated below.

1. Move ticket files, never copy (REQ-020).
2. Append to `history`, never rewrite (REQ-021).
3. Read thresholds from `config.yaml`, never hardcode (REQ-041).
4. Write `data/runs/<run-id>/` with all four artifacts (REQ-022).
5. Never write into `samples/`.
6. Reply in the language of the ticket.

---

## ticket-grouping

**Reads** `data/01-inbox/*.json`, `config.yaml`, agent keyword sets

**Writes** `data/02-grouped/<agent>/` or `data/03-approval/pending-grouping/`;
`data/runs/<run-id>/`

**Rules**
1. Score the ticket against all five agents. Normalise scores to sum to 1.
2. Record the top score as `confidence.grouping` and the rest as `alternatives` (REQ-003).
3. At or above `thresholds.grouping`, assign and hand off immediately (REQ-004).
4. Below it, move to `pending-grouping` and stop (REQ-005).
5. Never assign two agents. Never leave `agent` null after a successful grouping (REQ-002).

---

## agent-service-desk / agent-request-access / agent-ops-automation / agent-service-management / agent-finops

All five share one contract. Only the runbook subset and tool allow-list differ.

**Reads** `data/02-grouped/<own-agent>/*.json`, `knowledge/runbooks/`, `config.yaml`

**Writes** `data/03-approval/pending-action/`, `data/06-resolved/`,
`data/05-escalated/`, `data/runs/<run-id>/`

**Rules**
1. Retrieve from `knowledge/runbooks/` and write every candidate with its score
   to `retrieval.json`.
2. Cite the winning runbook on the ticket. If none scores above threshold,
   escalate with reason `no-runbook` - never improvise a plan (REQ-010, REQ-011).
3. Build an ordered plan. Every step declares `write: true` or `write: false` (REQ-012).
4. Every write step declares a `rollback` (REQ-019).
5. If any tool is outside this agent's allow-list, escalate with reason
   `tool-not-allowed`.
6. Apply Gate 2 in the documented order: write flag first, confidence second (REQ-014, REQ-015).
7. Where a narrower plan exists, record it under `alternatives` on the plan so
   the reviewer can reduce blast radius without rejecting (REQ-016).
8. Always offer the advisory options: ask requester, request info, escalate.
9. Record `metrics.ai_seconds` and `metrics.tokens`.

### Tool allow-lists

| Agent | Tool | write |
|---|---|---|
| service-desk | `kb_search` | false |
| service-desk | `ticket_comment` | false |
| request-access | `aws_s3_get_bucket_policy` | false |
| request-access | `aws_iam_list_attached` | false |
| request-access | `entra_get_user` | false |
| request-access | `aws_iam_attach_policy` | **true** |
| request-access | `entra_add_group_member` | **true** |
| ops-automation | `cloudwatch_get_alarms` | false |
| ops-automation | `ec2_describe_instances` | false |
| ops-automation | `log_query` | false |
| ops-automation | `ec2_reboot_instance` | **true** |
| ops-automation | `patch_apply` | **true** |
| service-management | `ticket_stats` | false |
| service-management | `faq_draft` | false |
| service-management | `report_generate` | false |
| finops | `cost_explorer_query` | false |
| finops | `budget_get` | false |
| finops | `resource_inventory` | false |
| finops | `resource_resize` | **true** |
| finops | `budget_set` | **true** |

---

## approval-gate

**Reads** `data/03-approval/pending-grouping/`, `data/03-approval/pending-action/`

**Writes** `data/02-grouped/<agent>/`, `data/03-approval/approved/`,
`data/03-approval/rejected/`, `data/04-awaiting-info/`, `data/05-escalated/`,
`data/runs/<run-id>/decision.json`

**Rules**
1. Present pending items one at a time. Grouping items first - they are cheaper
   to clear.
2. For a grouping item, offer all five agents plus Escalate. On confirmation,
   move to `02-grouped/<chosen>/` and hand straight to that agent skill (REQ-006).
3. For an action item, show the recommended plan, any alternatives, and the
   advisory options (REQ-016).
4. Advisory choices execute no tool. Write the comment, move to
   `04-awaiting-info/`, record an empty `tool_calls` for the run (REQ-017).
5. Rejection moves to `05-escalated/` with the reason recorded (REQ-018).
6. Record `approval.by` and `approval.at`, and close out
   `metrics.human_wait_seconds`.
7. Never approve on the ticket's behalf. This skill records a human decision and
   has no authority to make one.

---

## ticket-close

**Reads** `data/03-approval/approved/*.json`

**Writes** `data/06-resolved/`, `data/runs/<run-id>/trace.log`

**Rules**
1. Execute the approved plan step by step, logging each call to `tool_calls`.
2. On any step failure, stop, attempt the declared rollback, and move the ticket
   to `05-escalated/` with reason `execution-failed`.
3. Write a human-readable summary citing the runbook to the ticket's work notes.
4. Propose a FAQ candidate to `knowledge/faq/` when the same runbook has now
   resolved three or more tickets.

---

## board-refresh

**Reads** all of `data/`

**Writes** `web/board.json`, `web/stats.json`

**Rules**
1. Derive every counter from folder contents. Never trust the `state` field over
   the file's location.
2. `counts.needs_you` is both pending folders summed - it is the nav badge.
3. Compute grouping-auto and action-auto rates separately (REQ-034 rationale).
4. Report AI time and human wait as two medians. Never sum them into one figure.
5. Aggregate tokens from each run's `trace.log`, attributed by agent.
6. Write both files atomically so a mid-refresh page load never sees half a board.
