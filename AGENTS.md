# AGENTS.md - standing rules for Codex in this repository

## Source of truth

`docs/` defines this system. Code and skills implement `docs/`, never the reverse.

1. Read the relevant `docs/` file before changing anything.
2. Undocumented behaviour is not allowed. If a change is not covered by a
   requirement, update `docs/01-requirements.md` in the same change.
3. Every requirement has an ID (`REQ-NNN`). Reference it in commit messages:
   `feat(approval-gate): enforce write approval (REQ-014)`
4. Record non-obvious design choices in `docs/02-architecture.md` under Decisions.

## Hard rules

1. **Skills move ticket files, never copy.** One ticket exists in exactly one
   folder. The folder is the state.
2. **Any tool with `write: true` always requires human approval**, regardless of
   confidence score. Confidence governs read-only autonomy. The write flag
   governs authority. These are separate concerns and must not be merged.
3. **Never invent a runbook.** If no runbook in `knowledge/runbooks/` matches,
   escalate to `data/05-escalated/`.
4. **Never overwrite `history`.** Always append.
5. **Every run writes a folder** under `data/runs/<run-id>/` containing
   `plan.json`, `retrieval.json`, `decision.json` and `trace.log`.
6. **Do not add a Python pipeline.** Processing happens in skills, inside Codex.
   Small helper scripts for the web layer only are acceptable.
7. `samples/` is immutable. Never write into it.

## Thresholds

Read from `config.yaml`. Never hardcode a threshold in a skill.

## Language

Documentation and code comments in English. Ticket content may be Japanese or
English; agents must reply in the language of the ticket.
