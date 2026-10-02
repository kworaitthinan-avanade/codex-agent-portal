# codex-agent

A mockup of an AI-agent IT operations pipeline, built for AI-driven development.
Tickets are JSON files, Codex Skills move them between folders, and a static
web UI shows the result.

**There is no Python pipeline.** All processing logic lives in `.agents/skills/`
and runs inside Codex. The web layer is display-only HTML/JS/CSS.

## How it works

```
data/01-inbox/
      |
      |  ticket-grouping skill
      v
  GATE 1 - grouping confidence
      |
      +-- >= 0.85 --> auto-assign
      +-- <  0.85 --> 03-approval/pending-grouping/  (human picks 1 of 5)
      |
      v
data/02-grouped/<agent>/
      |
      |  agent-* skill
      v
  GATE 2 - write flag, then action confidence
      |
      +-- all read-only AND conf >= 0.90 --> auto-execute
      +-- any write:true OR conf < 0.90  --> 03-approval/pending-action/
      |
      v
data/06-resolved/   or   04-awaiting-info/   or   05-escalated/
      |
      |  board-refresh skill
      v
web/board.json + web/stats.json  -->  web/*.html
```

**A ticket's folder is its state.** Skills move files, never copy. One ticket
exists in exactly one folder at any time.

## Agents

| Agent | Handles |
|---|---|
| `service-desk` | User inquiries, troubleshooting, usage guidance |
| `request-access` | Requests, approvals, provisioning, access control, SSO |
| `ops-automation` | Monitoring, runbooks, security alerts, automated execution |
| `service-management` | FAQ, reports, progress tracking, incident analysis |
| `finops` | Cloud cost visibility, reduction recommendations, simulation |

## Run

Register the skills with Codex once:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.codex\skills\codex-agent" -Target (Resolve-Path ".\.agents\skills")
```

Verify with `/skills` inside Codex - it should list all 9 skills
(agent-finops, agent-ops-automation, agent-request-access, agent-service-desk,
agent-service-management, approval-gate, board-refresh, ticket-close, ticket-grouping).

If you want to confirm the junction is wired correctly from a plain terminal first:

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\skills\codex-agent" -Recurse -Filter "SKILL.md" | Select-Object Name, Directory
```

This should return 9 `SKILL.md` files, one per skill folder. Then:

```
> run ticket-grouping on data/01-inbox
> run the matching agent skill on data/02-grouped
> run approval-gate
> run board-refresh
```

Or in one prompt:

```
> Process every ticket in data/01-inbox end to end: group them, run the matching
  agent skill, stop at data/03-approval for anything needing me, then refresh the board.
```

Serve the UI:

```powershell
npx serve web
# then http://localhost:3000
```

Do not open via `file://` - `fetch` is blocked by CORS there.

Optional click-to-run bridge:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\web\bridge.ps1
```

## Refresh screen

```powershell
powershell -ExecutionPolicy Bypass -File .\web\refresh-board.ps1
```

`samples/` is immutable and committed. `data/` is working state.

## Pages

| Page | File | Answers |
|---|---|---|
| Overview | `web/index.html` | What is the state of everything right now? |
| Review Queue | `web/review.html` | What needs me? |
| Insights | `web/insights.html` | How well is it working? |

## Docs

| File | Content |
|---|---|
| `docs/00-overview.md` | Problem, goals, scope, non-goals, glossary |
| `docs/01-requirements.md` | Numbered REQ-001 onward, each with acceptance |
| `docs/02-architecture.md` | Folder-as-state model, skills, data flow |
| `docs/03-data-model.md` | Ticket schema, board.json, stats.json |
| `docs/04-business-logic.md` | Gate 1 / Gate 2, thresholds, escalation |
| `docs/05-skills-spec.md` | Per skill: reads / writes / rules |
| `docs/06-ui-spec.md` | The three pages |
| `docs/07-backlog.md` | What to build next, in order |
