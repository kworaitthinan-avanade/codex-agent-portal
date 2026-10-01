# 06 - UI specification

Three pages, plain HTML, CSS and JavaScript. No framework, no build step, no
runtime dependencies (REQ-042). Each page fetches a generated JSON file and
renders it.

```
+---------------------------------------------------------------+
|  codex-agent    [Overview]  [Review Queue (4)]  [Insights]     |
+---------------------------------------------------------------+
```

| Page | File | Answers | Data |
|---|---|---|---|
| Overview | `index.html` | What is the state of everything? | `board.json` |
| Review Queue | `review.html` | What needs me? | `board.json` |
| Insights | `insights.html` | How well is it working? | `stats.json` |

Not "Dashboard" - all three are dashboards. The names say what each is *for*.

**The Review Queue badge is the only number in the nav**, because it is the only
page that blocks on a person.

---

## Page 1 - Overview

```
+---------------------------------------------------------------+
|  Overview                        refreshed 17:20   [Refresh]   |
+---------------------------------------------------------------+
|  +--------+  +--------+  +--------+  +--------+                |
|  |   2    |  |   4    |  |   2    |  |   22   |                |
|  | UNPROC |  | NEEDS  |  | ESCAL  |  |RESOLVED|                |
|  |        |  |  YOU   |  |        |  | TODAY  |                |
|  |  grey  |  | AMBER  |  |  red   |  | green  |                |
|  +--------+  +--------+  +--------+  +--------+                |
|                                                                |
|  auto-handled today:  22 of 28   (79%)                         |
+---------------------------------------------------------------+
|  INBOX | GROUPED | NEEDS YOU | AWAITING | ESCALATED | RESOLVED |
|  +----+| +----+  | +----+    | +----+   | +----+    | +----+   |
|  |card|| |card|  | |card|    | |card|   | |card|    | |card|   |
|  +----+| +----+  | +----+    | +----+   | +----+    | +----+   |
+---------------------------------------------------------------+
|  [ Process all inbox tickets ]                                 |
+---------------------------------------------------------------+
```

Four counters plus the auto-handled rate (REQ-031). The board is read-only;
clicking an amber card jumps to the Review Queue.

Each card shows ticket number, short description, agent badge and confidence.

---

## Page 2 - Review Queue

Two sections, grouping first because those clear in one click (REQ-032).

```
+---------------------------------------------------------------+
|  Review Queue                                      4 items     |
+---------------------------------------------------------------+
|  CONFIRM GROUP  (1)                      quick - one click     |
|  +----------------------------------------------------------+ |
|  | INC0014  Cost spike in dev subscription      conf 0.68    | |
|  | matched: cost, subscription, budget                       | |
|  |                                                           | |
|  | [ finops 0.68 ]*  [ ops-automation 0.21 ]                 | |
|  | [ service-desk 0.08 ]  [ request-access 0.02 ]            | |
|  | [ service-management 0.01 ]  [ Escalate ]                 | |
|  |                                                           | |
|  | -> the agent runs automatically after you choose          | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
|  APPROVE ACTION  (3)         review the plan before approving  |
|  +----------------------------------------------------------+ |
|  | INC0001  Cannot access S3 bucket             conf 0.72    | |
|  | request-access . RB-014 . 2 steps, 1 WRITE                | |
|  |                                      [ Review plan > ]    | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
```

Expanded action card:

```
+---------------------------------------------------------------+
| INC0001  Cannot access S3 bucket wora-test-s3                  |
| conf 0.72  [#######...]  threshold 0.90   runbook RB-014 ^     |
+---------------------------------------------------------------+
| RECOMMENDED                                                    |
|   1. aws_s3_get_bucket_policy      READ                        |
|   2. aws_iam_attach_policy         WRITE                       |
|        target   role/CMP001-dev-readonly                        |
|        rollback detach policy S3ListDev                        |
|                                                                |
|   evidence: bucket policy lacks s3:ListBucket for the role     |
|                                                                |
|   [ Approve & run recommended ]*                               |
+---------------------------------------------------------------+
| ALTERNATIVE                                                    |
|   [ Grant read-only instead (narrower scope) ]                 |
|   [ Run diagnostic only, change nothing ]                      |
+---------------------------------------------------------------+
| ADVISORY - executes nothing                                    |
|   [ Ask requester to confirm bucket ]                          |
|   [ Request missing info: role ARN ]                           |
|   [ Escalate to L2 ]                                           |
+---------------------------------------------------------------+
```

### Interaction rules

**Approve is disabled until the plan block has been scrolled** (REQ-033).
Without this the button becomes reflexive and the gate is theatre - which would
demonstrate the opposite of the human-in-the-loop model.

**Write steps carry distinct visual weight.** Amber badge, rollback line always
visible. Read steps stay quiet with a green check. A reviewer should see at a
glance what could break.

**Confidence is a bar with the threshold marked**, not a bare number. How far
below the line it fell is more useful than "0.72" in isolation.

**After any action the board re-fetches and the card animates to its new
column.** That makes folder-as-state visible, which is the thing being
demonstrated.

---

## Page 3 - Insights

```
+---------------------------------------------------------------+
|  Insights              [ Today ] [ 7 days ] [ 30 days ]        |
+---------------------------------------------------------------+
|  AUTOMATION RATE                                               |
|    grouping auto   83%  [##########.......]   25 / 30          |
|    action   auto   80%  [#########........]   24 / 30          |
|    escalated        7%  [#................]    2 / 30          |
+---------------------------------------------------------------+
|  PROCESSING TIME (median)                                      |
|    AI time            0m 42s  |####|                           |
|    human wait        18m 05s  |####################|           |
|    reported separately, never summed                           |
+---------------------------------------------------------------+
|  TOKENS                                                        |
|    total today  184,300        per ticket avg  7,680           |
|      request-access   ########## 62,100                        |
|      service-desk     ######     41,200                        |
|      finops           ####       33,400                        |
|      ops-automation   ###        28,900                        |
|      service-mgmt     ##         18,700                        |
+---------------------------------------------------------------+
|  RESOLVED BY DAY                                               |
|    Mon ########    12                                          |
|    Tue ##########  15                                          |
|    Wed ######       9                                          |
+---------------------------------------------------------------+
```

Bars are styled `div` widths - no chart library, no build step.

**AI time and human wait stay as separate rows** (REQ-034). Blended, the human
queue delay swamps the AI time and the metric stops meaning anything. Split,
the chart shows immediately that the bottleneck is the approval queue - which
is the honest finding a human-in-the-loop system should surface, not hide.

The two auto rates are reported separately so each threshold can be tuned
independently on its own evidence.

---

## Colour system

```css
--auto:     #2d6a2d;   /* green  - AI handled it, no human needed */
--pending:  #cc6600;   /* amber  - YOU are the bottleneck */
--write:    #b85450;   /* red    - mutating operation */
--escalate: #8b3a3a;
--idle:     #6b6b6b;   /* grey   - not started */
```

**Only one colour means "act now."** If amber appears anywhere, a human is
blocking. That discipline is what keeps the dashboard readable at a glance.
