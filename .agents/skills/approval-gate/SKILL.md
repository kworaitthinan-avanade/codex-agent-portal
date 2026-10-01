---
name: approval-gate
description: Presents pending grouping and action items to a human and records their decision.
---

# approval-gate

Records a human decision. **This skill has no authority to make one.**

## Reads

- `data/03-approval/pending-grouping/*.json`
- `data/03-approval/pending-action/*.json`

## Writes

- `data/02-grouped/<agent>/` on grouping confirmation
- `data/03-approval/approved/` on action approval
- `data/03-approval/rejected/`
- `data/04-awaiting-info/` on an advisory choice
- `data/05-escalated/`
- `data/runs/<run-id>/decision.json`

## Rules

1. Present items one at a time. **Grouping items first** - they clear in one
   click and should not queue behind plan reviews.
2. For a grouping item, show the AI suggestion highlighted, the alternatives
   with scores, and the matched terms. Offer all five agents plus Escalate.
   On confirmation, move to `data/02-grouped/<chosen>/` and hand straight to
   that agent skill - the human is asked once, not twice (REQ-006).
3. For an action item, present three sections (REQ-016):

   - **Recommended** - the plan as proposed
   - **Alternative** - any narrower plan from `plan_alternatives`
   - **Advisory** - ask requester, request missing info, escalate to L2

4. Show every write step with its target and rollback. Never summarise a write
   step away.
5. Advisory choices execute no tool. Write the comment to the ticket, move to
   `data/04-awaiting-info/`, and record an empty `tool_calls` for the run
   (REQ-017).
6. Rejection moves to `data/05-escalated/` with the reason recorded (REQ-018).
7. Record `approval.by`, `approval.at` and close out
   `metrics.human_wait_seconds`.
8. Never approve on the ticket's behalf, and never infer approval from silence
   or from a high confidence score.


## Universal rules

1. Move ticket files, never copy. One ticket exists in exactly one folder (REQ-020).
2. Append to `history`, never rewrite (REQ-021).
3. Read thresholds from `config.yaml`. Never hardcode a threshold (REQ-041).
4. Write `data/runs/<run-id>/` with `plan.json`, `retrieval.json`,
   `decision.json` and `trace.log` (REQ-022).
5. Never write into `samples/`.
6. Reply in the language of the ticket.
