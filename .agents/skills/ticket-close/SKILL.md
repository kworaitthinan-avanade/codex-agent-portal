---
name: ticket-close
description: Executes an approved plan, writes the resolution summary, and closes the ticket.
---

# ticket-close

## Reads

- `data/03-approval/approved/*.json`

## Writes

- `data/06-resolved/`
- `data/05-escalated/` on failure
- `data/runs/<run-id>/trace.log`
- `knowledge/faq/` when a FAQ candidate is warranted

## Rules

1. Execute the approved plan step by step. Log each call to `tool_calls` with
   name, args, result, duration and status.
2. On any step failure: stop immediately, attempt the declared `rollback`, and
   move the ticket to `data/05-escalated/` with reason `execution-failed`.
   Record the rollback outcome - a failed rollback is the most important line in
   the log.
3. Write a human-readable summary to the ticket's work notes, citing the runbook
   filename.
4. Set `state` to `resolved` and `resolved_at`.
5. When the same runbook has now resolved three or more tickets, draft a FAQ
   candidate into `knowledge/faq/` and note it on the ticket. Do not publish it -
   that is a service-management decision.


## Universal rules

1. Move ticket files, never copy. One ticket exists in exactly one folder (REQ-020).
2. Append to `history`, never rewrite (REQ-021).
3. Read thresholds from `config.yaml`. Never hardcode a threshold (REQ-041).
4. Write `data/runs/<run-id>/` with `plan.json`, `retrieval.json`,
   `decision.json` and `trace.log` (REQ-022).
5. Never write into `samples/`.
6. Reply in the language of the ticket.
