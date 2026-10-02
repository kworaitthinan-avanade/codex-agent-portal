---
name: board-refresh
description: Scans data/ and regenerates web/board.json and web/stats.json for the UI.
---

# board-refresh

## Reads

- all of `data/`, including `data/runs/*/trace.log`

## Writes

- `web/board.json`
- `web/stats.json`

## Rules

1. **Derive every counter from folder contents.** Never trust a ticket's `state`
   field over the file's actual location - if they disagree, the folder wins and
   the disagreement is logged.
2. `counts` must always include all six keys, even when a folder is empty:
   `unprocessed` (`01-inbox`), `grouped` (all of `02-grouped/<agent>/`),
   `needs_you` (`pending-grouping` plus `pending-action` - the nav badge),
   `awaiting_info` (`04-awaiting-info`), `escalated` (`05-escalated`),
   `resolved_today` (`06-resolved`, created today). A missing key renders as
   "undefined" in the UI - write `0`, never omit the key.
   2a. Copy `thresholds.grouping` and `thresholds.action` from `config.yaml` into a
   top-level `thresholds` object on `board.json`. The Overview page reads this
   directly and fails without it.
3. Compute `grouping_auto` and `action_auto` rates **separately**. They tune two
   independent thresholds and must not be merged into one automation figure.
   - `grouping_auto`: count every ticket that has ever been assigned an agent
     (i.e. has a `confidence.grouping` value, including ones currently sitting
     in `pending-grouping`) as `total`. `count` is those whose state never was
     and is not `pending-grouping`. Never leave this at `0/0` when tickets exist.
   - `action_auto`: count every ticket that has a non-empty `plan` as `total`.
     `count` is those whose `approval_reason` is neither `write-tool` nor
     `low-confidence` (i.e. never routed through `pending-action`). Never leave
     this at `0/0` when plan-bearing tickets exist.
4. Report `ai_median` and `human_wait_median` as two figures. Never sum them
   (REQ-034). Blended, the human queue delay swamps the AI time and the metric
   stops meaning anything.
5. Auto-handled means resolved with no `history` entry whose `actor` is `human`.
6. Aggregate tokens from each run's `trace.log`, attributed to the agent that
   spent them.
7. Write both files atomically - write to a temporary name and rename - so a
   mid-refresh page load never sees half a board.
8. Run this after every state change. The UI has no other data source.

## Universal rules

1. Move ticket files, never copy. One ticket exists in exactly one folder (REQ-020).
2. Append to `history`, never rewrite (REQ-021).
3. Read thresholds from `config.yaml`. Never hardcode a threshold (REQ-041).
4. Write `data/runs/<run-id>/` with `plan.json`, `retrieval.json`,
   `decision.json` and `trace.log` (REQ-022).
5. Never write into `samples/`.
6. Reply in the language of the ticket.
