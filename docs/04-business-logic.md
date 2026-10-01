# 04 - Business logic

Two gates. Gate 1 decides *who* handles the ticket. Gate 2 decides *whether the
plan may run*. Thresholds come from `config.yaml` and are never hardcoded.

## Full pipeline

```
data/01-inbox/
      |
      |  ticket-grouping
      v
 score the ticket against the five agents
      |
      +-- grouping conf >= 0.85 --> assign silently
      |                                   |
      +-- grouping conf <  0.85 --> GATE 1: pending-grouping/
                                          |
                                    human picks one of:
                                    [service-desk] [request-access]
                                    [ops-automation] [service-mgmt]
                                    [finops] [Escalate]
                                          |
                                    AI CONTINUES AUTOMATICALLY
                                          |
      +-----------------------------------+
      v
data/02-grouped/<agent>/
      |
      |  agent-* skill: retrieve runbook, build plan, score action confidence
      v
 no runbook match? --> 05-escalated/ (reason: no-runbook)
      |
      v
 GATE 2
      |
      +-- any step write:true ------------------> pending-action/
      +-- all read-only AND action conf >= 0.90 -> execute
      +-- all read-only AND action conf <  0.90 -> pending-action/
      |
      v
 pending-action/ offers three kinds of choice:
      |
      +-- RECOMMENDED  run the proposed plan      --> approved/ --> 06-resolved/
      +-- ALTERNATIVE  run a different listed plan --> approved/ --> 06-resolved/
      +-- ADVISORY     execute nothing:
      |                  ask requester             --> 04-awaiting-info/
      |                  request missing info      --> 04-awaiting-info/
      |                  escalate                  --> 05-escalated/
      +-- REJECT                                   --> 05-escalated/
      |
      v
data/06-resolved/  --> board-refresh --> web/board.json + web/stats.json
```

## Gate 1 - grouping

| Condition | Outcome |
|---|---|
| `confidence >= thresholds.grouping` | Assign to `02-grouped/<agent>/`, continue |
| `confidence <  thresholds.grouping` | Move to `pending-grouping/`, ask a human |

There are only two paths. There is no third "escalate automatically" branch at
Gate 1 - if the AI is unsure, a person decides, and Escalate is one of the six
buttons they can press. Removing the automatic escalate keeps every unroutable
ticket visible rather than silently parked.

**After confirmation the agent runs immediately** (REQ-006). The human is asked
once, not twice. A grouping confirmation is a one-second click, and the design
depends on it staying that cheap.

The card pre-highlights the AI's suggestion and shows the alternatives with
their scores, so confirming the obvious case is a single click and overriding is
also a single click.

## Gate 2 - action

Evaluated in this order. The first matching rule wins.

| # | Condition | Outcome |
|---|---|---|
| 1 | No runbook matched | Escalate, reason `no-runbook` |
| 2 | A tool is not in the agent's allow-list | Escalate, reason `tool-not-allowed` |
| 3 | Any step has `write: true` | `pending-action/`, reason `write-tool` |
| 4 | Action confidence < `thresholds.action` | `pending-action/`, reason `low-confidence` |
| 5 | Otherwise | Execute automatically |

**Rule 3 precedes rule 4 deliberately.** A write operation asks at any
confidence, including 1.0. Confidence governs read-only autonomy; the write flag
governs authority. If confidence could unlock write access, a sufficiently
confident model would be able to grant itself permissions - the exact property
the governance model exists to exclude.

## The three kinds of choice at Gate 2

**Recommended** - the plan as proposed. One click, pre-highlighted.

**Alternative** - a different plan the agent also considered, usually narrower.
Offering "grant read-only instead" or "diagnostic only" lets a reviewer reduce
blast radius without rejecting outright and losing the work.

**Advisory** - executes nothing. This covers the common real case where the
agent's reasoning is sound but the *ticket* is ambiguous: the right move is to
go back to the requester, not to run anything. Without this option a reviewer
must either approve something they are unsure of or reject work that was
actually correct.

## Escalation paths

Every route writes the same `decision.json` shape, so escalation rate is one
countable metric across all five agents.

| Trigger | Stage | Reason code |
|---|---|---|
| Human presses Escalate at Gate 1 | Gate 1 | `grouping-unclear` |
| No runbook above retrieval threshold | Agent | `no-runbook` |
| Tool not in the agent allow-list | Agent | `tool-not-allowed` |
| Human rejects the plan | Gate 2 | `rejected` |
| Human chooses advisory Escalate | Gate 2 | `needs-engineer` |
| Execution fails or output fails validation | Execute | `execution-failed` |
| Requester disputes the resolution | Closure | `reopened` |

## Thresholds

```yaml
thresholds:
  grouping: 0.85
  action:   0.90
always_ask_on_write: true
```

Tune the two numbers independently and read the effect on the Insights page,
where grouping-auto and action-auto rates are reported separately for exactly
this reason. That pair of numbers is the evidence for expanding autonomy: raise
automation only where the measured error rate supports it.

## Metrics definitions

| Metric | Definition |
|---|---|
| **Auto-handled** | Resolved with no `history` entry where `actor` is `human` |
| **Grouping auto rate** | Tickets never entering `pending-grouping` / all grouped |
| **Action auto rate** | Tickets never entering `pending-action` / all with a plan |
| **AI time** | Sum of `metrics.ai_seconds` for the run |
| **Human wait** | Time between entering a pending folder and the human decision |
| **Tokens** | Sum from `trace.log`, attributed to the agent that spent them |
