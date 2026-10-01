# 01 - Requirements

Each requirement has an ID. Reference it in commit messages. The **Accept** line
is the acceptance criterion - there is no separate test plan document.

## Functional - intake and grouping

### REQ-001 - Tickets enter as files
A ticket is a single JSON file placed in `data/01-inbox/`, named after its
ticket number, for example `INC0001.json`.
**Accept:** a file dropped in `01-inbox` is picked up by `ticket-grouping` with no other registration step.

### REQ-002 - Grouping assigns exactly one agent
`ticket-grouping` assigns each ticket to exactly one of the five agents listed
in `config.yaml`.
**Accept:** every grouped ticket has a non-null `agent` matching a configured agent.

### REQ-003 - Grouping produces a confidence score
Grouping records `confidence` between 0 and 1, plus `alternatives` listing the
other candidate agents with their scores.
**Accept:** a grouped ticket has `confidence` and at least one entry in `alternatives`.

### REQ-004 - High-confidence grouping is automatic
If grouping confidence is at or above `thresholds.grouping`, the ticket moves
straight to `data/02-grouped/<agent>/` without asking a human.
**Accept:** a ticket scoring 0.92 appears in `02-grouped` and never in `pending-grouping`.

### REQ-005 - Low-confidence grouping asks a human
If grouping confidence is below `thresholds.grouping`, the ticket moves to
`data/03-approval/pending-grouping/` and the UI offers all five agents plus
Escalate.
**Accept:** a ticket scoring 0.68 appears in `pending-grouping` and the review card shows six buttons.

### REQ-006 - Grouping confirmation continues automatically
After a human confirms a group, the matching agent skill runs without a further
prompt.
**Accept:** confirming a grouping moves the ticket past `02-grouped` in the same run.

## Functional - action

### REQ-010 - An agent must cite a runbook
An agent retrieves from `knowledge/runbooks/` and records the cited filename on
the ticket.
**Accept:** every ticket with a plan has a non-null `runbook`.

### REQ-011 - No runbook means escalate
If no runbook scores above the retrieval threshold, the agent escalates rather
than improvising a plan.
**Accept:** a ticket with no matching runbook appears in `05-escalated` with reason `no-runbook`.

### REQ-012 - Plans declare tool write flags
Every step in a plan carries `write: true` or `write: false`.
**Accept:** no plan step is missing a `write` field.

### REQ-013 - High-confidence read-only plans execute automatically
If action confidence is at or above `thresholds.action` and every step is
read-only, the plan executes without asking.
**Accept:** a read-only plan at 0.95 reaches `06-resolved` with no approval entry in `history`.

### REQ-014 - Write operations always require approval
If a plan contains any step with `write: true`, the ticket moves to
`data/03-approval/pending-action/` regardless of confidence.
**Accept:** confidence 1.0 with one write step does not auto-execute.

### REQ-015 - Low-confidence plans require approval
If action confidence is below `thresholds.action`, the ticket moves to
`pending-action` even when every step is read-only.
**Accept:** a read-only plan at 0.72 appears in `pending-action`.

### REQ-016 - Approval offers alternatives and advisory actions
A pending action card offers the recommended plan, at least one alternative
plan where one exists, and advisory actions that execute nothing.
**Accept:** the expanded card renders three sections: Recommended, Alternative, Advisory.

### REQ-017 - Advisory actions do not execute
Choosing an advisory action writes a comment to the ticket and moves it to
`data/04-awaiting-info/` without calling any tool.
**Accept:** a ticket in `04-awaiting-info` has an empty `tool_calls` record for that run.

### REQ-018 - Rejection escalates
Rejecting a plan moves the ticket to `data/05-escalated/` with the rejection
reason recorded.
**Accept:** a rejected ticket carries `decision.reason` in its run folder.

### REQ-019 - Write steps declare a rollback
Every `write: true` step declares how it is reversed.
**Accept:** no write step is missing `rollback`.

## Functional - state and audit

### REQ-020 - Folder is state
A ticket exists in exactly one folder. Skills move files and never copy them.
**Accept:** searching all of `data/` for a ticket number returns exactly one file.

### REQ-021 - History is append-only
Each skill appends one entry to `history` and never rewrites earlier entries.
**Accept:** the number of `history` entries never decreases across runs.

### REQ-022 - Every run is auditable
Each run writes `data/runs/<run-id>/` containing `plan.json`, `retrieval.json`,
`decision.json` and `trace.log`.
**Accept:** every ticket with a `run_id` has a matching folder with all four files.

### REQ-023 - Runs are reproducible
Re-running the same ticket from `samples/` after changing a threshold produces a
second run folder, leaving the first intact for comparison.
**Accept:** two run folders exist for the same ticket number with different outcomes.

## Functional - UI

### REQ-030 - Three pages
The UI has Overview, Review Queue and Insights, and nothing else.
**Accept:** `web/` contains exactly three HTML pages.

### REQ-031 - Overview shows four counters
Unprocessed, Needs you, Escalated, Resolved today - plus the auto-handled rate.
**Accept:** `index.html` renders five figures above the board.

### REQ-032 - Review Queue separates the two gates
Grouping confirmations and action approvals are shown in separate sections,
grouping first.
**Accept:** `review.html` renders two labelled sections in that order.

### REQ-033 - Approve is gated on review
The Approve button is disabled until the plan block has been scrolled.
**Accept:** the button carries the `disabled` attribute on first render.

### REQ-034 - Insights separates AI time from human wait
Processing time is reported as two distinct figures, never blended.
**Accept:** `insights.html` renders separate AI time and human wait rows.

### REQ-035 - Insights reports token usage
Total tokens, average per ticket, and a breakdown by agent.
**Accept:** `stats.json` contains `tokens.total`, `tokens.per_ticket_avg` and `tokens.by_agent`.

## Non-functional

### REQ-040 - No processing pipeline outside Codex
All ticket processing runs as Codex Skills. No Python or Node pipeline.
**Accept:** the repository contains no executable processing code outside `.agents/skills/`.

### REQ-041 - Single configuration file
All tunable values live in `config.yaml`.
**Accept:** no threshold literal appears in any `SKILL.md`.

### REQ-042 - No frontend build step and no runtime dependencies
The UI is plain HTML, CSS and JavaScript, served statically.
**Accept:** `web/` contains no `package.json` and no bundler output.

### REQ-043 - Paths contain no spaces
No directory or file created by this project uses a space in its name.
**Accept:** a recursive listing shows no path containing a space.

### REQ-044 - No client identifiers
Neither the repository name nor its contents identify a client organisation.
**Accept:** a case-insensitive search for client names returns nothing.

### REQ-045 - Documentation precedes implementation
Behaviour is documented in `docs/` before it is implemented.
**Accept:** every skill rule traces to a REQ ID.
