# 02 - Architecture

## The core idea

**A ticket's folder is its state.** There is no database, no status table and no
state machine implementation. Moving a file between directories *is* the state
transition, which makes the whole pipeline inspectable with a file explorer.

```
data/01-inbox/                      new, nobody is working on it
data/02-grouped/<agent>/            assigned, the agent is working
data/03-approval/pending-grouping/  YOU are blocking - which agent?
data/03-approval/pending-action/    YOU are blocking - may it run?
data/03-approval/approved/          approved, ready to close
data/03-approval/rejected/          rejected
data/04-awaiting-info/              waiting on the requester
data/05-escalated/                  needs an L2 engineer
data/06-resolved/                   done
```

## Execution model

Everything runs inside Codex. Each stage is a Skill that reads files from one
folder, writes files to the next, and moves the ticket forward. There is no
Python pipeline and no service process.

```
.agents/skills/
    ticket-grouping         01-inbox        -> 02-grouped | pending-grouping
    agent-service-desk      02-grouped/...  -> 06-resolved | pending-action | 05-escalated
    agent-request-access    same contract
    agent-ops-automation    same contract
    agent-service-management same contract
    agent-finops            same contract
    approval-gate           pending-*       -> approved | rejected | 04-awaiting-info
    ticket-close            approved        -> 06-resolved
    board-refresh           data/           -> web/board.json + web/stats.json
```

Skills are registered by pointing Codex at `.agents/skills`, then verified with
`/skills` before anything is built on top.

## Data flow

```
samples/tickets/            immutable fixtures, committed
        |  copy to reset a demo
        v
data/01-inbox/              INPUT
        |
   ticket-grouping ----------------> GATE 1
        |                                |
        v                                v
data/02-grouped/<agent>/        pending-grouping/
        |                                |
   agent-* skill                   human picks 1 of 5
        |                                |
        v <------------------------------+
   GATE 2
        |
        +--> auto-execute -----> 06-resolved/
        +--> pending-action/ --> approved/ --> ticket-close --> 06-resolved/
        +--> 04-awaiting-info/
        +--> 05-escalated/
        |
        v
data/runs/<run-id>/          plan.json, retrieval.json, decision.json, trace.log
        |
   board-refresh
        |
        v
web/board.json + web/stats.json  ->  web/index.html, review.html, insights.html
```

## Layers

**Skill layer.** Five agent skills plus four pipeline skills. Every skill
declares reads, writes and rules, which makes them composable and independently
testable.

**Knowledge layer.** `knowledge/runbooks/` holds the markdown procedures agents
retrieve and cite. Retrieval is keyword and heading matching, which is
sufficient at this scale and keeps the evidence trail human-readable. A real
deployment would substitute a vector index behind the same skill contract.

**Control layer.** `config.yaml` holds thresholds; the write flag on each tool
holds authority. These are deliberately separate - see Decisions below.

**Presentation layer.** Static HTML reading two generated JSON files. The UI
never processes a ticket; it renders state and, through the optional bridge,
asks Codex to act.

## The bridge

`web/bridge.ps1` is an optional local HTTP listener that lets a button in the
browser trigger `codex exec`. A browser cannot launch a process, so a small
PowerShell listener sits in between.

```
browser            bridge.ps1 :8765          codex
  |--POST {ticket, action}-->|                 |
  |                          |--codex exec---->|
  |                          |                 |--moves files in data/
  |                          |                 |--runs board-refresh
  |                          |<----stdout------|
  |<--{ok, output}-----------|                 |
  |--GET board.json--------->|
```

The bridge is a convenience, not part of the model. The pipeline is fully
operable from the Codex prompt alone.

## Decisions

**D1 - Folder-as-state instead of a status field.** A status field can disagree
with reality; a file location cannot. It also makes the human queue physically
visible: if `pending-action/` is non-empty, a person is the bottleneck.

**D2 - Confidence and write authority are separate.** Confidence governs
*read-only* autonomy. The write flag governs *authority*. Merging them would
mean a sufficiently confident model could grant itself write access, which is
exactly the property the governance model must exclude.

**D3 - Two gates rather than one.** Grouping errors and action errors have
different costs and different review effort. A grouping confirmation is a
one-second click; an action approval needs plan review. Mixing them into one
queue makes the count misleading and trains people to click through both.

**D4 - No processing code.** Writing the pipeline in Python would make this a
Python project that happens to call a model. Writing it as skills makes the
prompt, the rules and the evidence the actual artifacts, which is what the
operating model is about.

**D5 - `samples/` separate from `data/`.** Working state is mutated and partly
gitignored. Fixtures are committed and immutable, so a scenario can be replayed
after a threshold change and the two outcomes compared honestly.
