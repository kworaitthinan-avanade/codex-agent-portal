# 00 - Overview

## Problem

IT operations capacity grows in direct proportion to headcount. Repetitive
inquiries, standard access requests, routine monitoring responses and recurring
cost questions consume engineer time that should go to exceptions and
improvement work.

## Goal

Demonstrate an operating model in which AI agents handle repetitive work,
initial investigation, classification and recommended actions, while engineers
retain control over exceptions, approvals, escalations and quality.

Operational capacity should become less directly dependent on staff numbers,
and automation should expand gradually rather than granting AI broad autonomy
on day one.

## What this mockup demonstrates

1. A ticket arrives as a file and is classified into one of five agent groups.
2. Confidence decides whether classification happens automatically or asks a human.
3. An agent retrieves a runbook, builds an execution plan and scores its confidence.
4. Confidence and the write flag together decide whether the plan runs or asks.
5. A human confirms, chooses an alternative, requests more information, or escalates.
6. Every step produces an auditable artifact.
7. A dashboard reports automation rate, processing time and token usage.

## Scope

- Five agent groups: service-desk, request-access, ops-automation,
  service-management, finops.
- Two human-in-the-loop gates: grouping and action.
- File-based ticket lifecycle with folder-as-state.
- Static web UI with three pages.
- Run artifacts sufficient to audit any decision after the fact.

## Non-goals

- No real ServiceNow connection. Tickets are JSON fixtures.
- No real AWS or Azure mutations. Tools are simulated and logged.
- No authentication, multi-user support or role-based access in the UI.
- No production deployment, scaling or high availability.
- No Python processing pipeline. Logic lives in Codex Skills.
- Not a chatbot. The subject of this project is the operational process.

## Glossary

| Term | Meaning |
|---|---|
| **Agent** | One of five skill-backed specialisations that process a ticket |
| **Gate 1** | Grouping confirmation - which agent should handle this ticket |
| **Gate 2** | Action confirmation - may this plan execute |
| **HITL** | Human in the loop. A point where a person decides |
| **Write tool** | A tool that mutates a real system. Always requires approval |
| **Read tool** | A tool that only observes. Eligible for automatic execution |
| **Plan** | An ordered list of tool calls an agent proposes for a ticket |
| **Runbook** | A markdown procedure in `knowledge/runbooks/` an agent may cite |
| **Run** | One execution of a skill against one ticket, with its artifacts |
| **Advisory action** | An outcome that executes nothing and asks the requester instead |
| **Folder-as-state** | The design rule that a ticket's location defines its state |
| **Auto-handled** | A ticket resolved without any human decision |
