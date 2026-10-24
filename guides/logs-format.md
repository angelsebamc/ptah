# LOGS.md format

Every command appends an entry to `LOGS.md` when it completes, pauses, or fails, and **change entries** are appended in between as work happens. All entries follow the same strict schema.

This guide defines the schema. The discipline (when to log, when not to) lives in [`RULES.md`](../RULES.md) under "Logging discipline". Every fixed value — statuses, change types, triggers, verdicts — is defined in [`vocabulary.md`](./vocabulary.md).

---

## Required structure

```
## <YYYY-MM-DD HH:MM:SS> — /<command> <status>
- <field>: <value>
- <field>: <value>
- ...
- Next step: <next-command-or-action>
```

## Rules

1. **Heading** — `H2` (`##`), exact format: `<YYYY-MM-DD HH:MM:SS> — /<command> <status>`
   - Date and time use 24-hour local time, e.g. `2026-05-08 14:32:07`
   - Get the timestamp from the shell with `date '+%Y-%m-%d %H:%M:%S'` right before appending. Never write one from memory or copy it from an earlier entry
   - `<status>` is a **command status** from `vocabulary.md`
2. **Body** — unordered list (`-`), one field per line, in the order defined below
3. **One line per value** — no value spans lines, is empty, or has leading or trailing whitespace; lists inside a value are comma-separated
4. **Last field** — must always be `Next step:` for command entries (change entries are exempt — see below)
5. **Separator** — one blank line between entries, no horizontal rules
6. **Order** — newest entries appended to the bottom (chronological), not the top
7. **No prose** — entries are bullets only, no paragraphs

---

### Value shapes

| Field | Shape |
|---|---|
| Counts | digits only, e.g. `3` |
| `Open questions` | a count, or `none` |
| `Acceptance criteria` | `<X> of <Y> met` |
| `Deviations from plan` | `no`, or `yes — see change entries above` |
| `Known issues`, `New issues found` | `no`, or `yes — <note>` |
| `Files touched` | comma-separated paths, or `none` |
| `Source` | a ticket id, or `none` |
| `Mode` | a fix mode from `vocabulary.md` |
| `Verdict` | a verdict from `vocabulary.md` that is valid for the command |
| `Minor fixed` | a count, or `skipped — not in scope` |
| `Suggestions fixed`, `Skipped by user` | a count, or `none` |

---

## `paused` and `failed` — any command

These two have the same fields whichever command wrote them.

### `/<command> paused`
- Blocked on (one line — what needs the user's input)
- Progress (one line — what's finished so far, or `none`)
- Files touched (comma-separated paths, or `none`)
- Next step (`answer the open questions, then re-run /<command>`)

Written by `/plan` and `/implement` when their subagent returns `needs-input`. The user's answers follow as `decision` / `deviation` / `scope-change` change entries, and a re-run picks up from there.

### `/<command> failed`
- Reason (one line)
- Next step (`re-run /<command>`, or what to fix first)

Written when a subagent returns `error` or a malformed result. No artifact is written for a failed run.

---

## `completed` — per-command fields (required, in order)

### `/spec completed`
- Feature
- Source (ticket ID or `none`)
- Key decisions
- Next step

### `/plan completed`
- Approach
- Key decisions
- Open questions (count or `none`)
- Next step

### `/implement completed`
- Summary
- Files created (count)
- Files modified (count)
- Deviations from plan (`yes — see change entries above` or `no`)
- Known issues (`yes — <note>` or `no`)
- Next step

### `/review completed`
- Blockers (count)
- Major (count)
- Minor (count)
- Suggestions (count)
- Acceptance criteria (`X of Y met`)
- Verdict (`fix-needed` or `approved`)
- Next step (`/fix`, or `none — review clean`)

### `/fix completed`
- Mode (`auto`, `plan`, or `interactive`)
- Blockers fixed (count)
- Major issues fixed (count)
- Minor fixed (count, or `skipped — not in scope`)
- Suggestions fixed (count, or `none`)
- Skipped by user (count, or `none` — includes findings marked already fixed)
- New issues found (`yes — <note>` or `no`)
- Next step (`/review`)

---

## Change entries

Between command entries, the agent appends **change entries** whenever a meaningful event happens mid-session: decisions, deviations from the plan, scope changes, blockers, or corrections. They are the canonical record of in-flow events — completion entries reference them rather than restating them.

Heading uses `change during /<command>` instead of `<command> <status>`:

```markdown
## <YYYY-MM-DD HH:MM:SS> — change during /<command>
- Trigger: <user-request | agent-decision>
- Type: <decision | deviation | scope-change | blocker | correction>
- What: <one-line description>
- Why: <reason>
- Impact: <files, decisions, or downstream steps affected; or "none">
```

All five fields are required, in the order shown. `Next step:` is **not** included — change entries record what happened, they don't move the workflow forward.

---

## Example

```markdown
## 2026-04-23 09:14:22 — /spec completed
- Feature: account creation with excluded from net worth toggle
- Source: PROJ-42
- Key decisions: toggle defaults to false
- Next step: /plan

## 2026-04-23 11:47:03 — /plan completed
- Approach: new boolean field on accounts table + UI toggle in form
- Key decisions: reuse existing form component
- Open questions: none
- Next step: /implement

## 2026-04-23 14:22:18 — /implement paused
- Blocked on: whether archived accounts count toward net worth
- Progress: form component and schema change written
- Files touched: src/accounts/AccountForm.tsx, db/schema/0042_archived.sql
- Next step: answer the open questions, then re-run /implement

## 2026-04-23 14:25:40 — change during /implement
- Trigger: user-request
- Type: scope-change
- What: archived accounts are excluded from net worth and hidden by default
- Why: resolves "should archived accounts still count toward net worth?"
- Impact: PLAN.md updated, the schema needs an `archived` column

## 2026-04-23 16:05:33 — /implement completed
- Summary: account creation form with excluded-from-net-worth toggle
- Files created: 3
- Files modified: 4
- Deviations from plan: yes — see change entries above
- Known issues: no
- Next step: /review
```
