# LOGS.md format

Every command appends an entry to `LOGS.md` when it completes, pauses, or fails, and **change entries** are appended in between as work happens. This guide defines the schema every entry follows. When to log lives in [`RULES.md`](../RULES.md) under "Logging discipline", and every fixed value in [`vocabulary.md`](./vocabulary.md).

---

## Required structure

```
## #<n> — <YYYY-MM-DD HH:MM:SS> — /<command> <status>
- <field>: <value>
- <field>: <value>
- ...
```

## Rules

1. **Heading** — `H2` (`##`), exact format: `#<n> — <YYYY-MM-DD HH:MM:SS> — /<command> <status>`
   - `#<n>` is the entry's id: the number of `## ` headings in `LOGS.md` plus 1. Never write one from memory or work it out from earlier entries. Get it from the shell, with `<log>` the spec's `LOGS.md` path:

     ```
     # POSIX
     echo $(( $(cat <log> 2>/dev/null | grep -c '^## ') + 1 ))

     # PowerShell
     if (Test-Path <log>) { @(Select-String -Path <log> -Pattern '^## ').Count + 1 } else { 1 }
     ```

   - The timestamp is 24-hour local time, e.g. `2026-05-08 14:32:07`, taken from the shell: `date '+%Y-%m-%d %H:%M:%S'` (POSIX) or `Get-Date -Format 'yyyy-MM-dd HH:mm:ss'` (PowerShell). Never write one from memory or copy it from an earlier entry
   - Get the id and the timestamp right before appending, in the same step
   - `<status>` is a **command status** from `vocabulary.md`
   - An entry written before ids has no `#<n>`; refer to it by its timestamp
2. **Body** — unordered list (`-`), one field per line, in the order defined below
3. **One line per value** — no value spans lines, is empty, or has leading or trailing whitespace; lists inside a value are comma-separated
4. **Separator** — one blank line between entries, no horizontal rules
5. **Order** — newest entries appended to the bottom (chronological), not the top
6. **Append-only** — past entries are never edited, reordered, or deleted, even when a later step makes one look wrong. To revert or restore something an earlier entry recorded, append a `correction` change entry
7. **No prose** — entries are bullets only, no paragraphs
8. **Slice** — on a sliced spec, per [`slices.md`](./slices.md), an entry that belongs to a slice has `Slice: <n>` as its first field, before the fields defined below. The entries that belong to no slice leave it out: `/spec`, `/slice`, the final review, its fixes, and changes made once the feature is finished

---

### Value shapes

| Field | Shape |
|---|---|
| Counts | digits only, e.g. `3` |
| `Open questions`, `Concerns` | a count, or `none` |
| `Acceptance criteria` | `<X> of <Y> met` |
| `Spec`, `Standards`, `Correctness` | `<d> defects, <j> judgements`, counts of that axis's findings |
| `Deviations from plan` | `no`, or `yes — see change entries above` |
| `Known issues`, `New issues found` | `no`, or `yes — <note>` |
| `Files touched` | comma-separated paths, or `none` |
| `Source` | a ticket id, or `none` |
| `Mode` | a fix mode from `vocabulary.md` |
| `Verdict` | a verdict from `vocabulary.md` that is valid for the command |
| `Skipped by user`, `Deferred` | a count, or `none` |
| `Manual steps` | comma-separated, each item one action the user takes before continuing, such as restarting a local service or renaming a file before handing it on |
| `Slice` | a slice number, digits only |
| `Done` | comma-separated slice numbers, or `none` |
| `Base commit` | the full commit id from `git rev-parse HEAD` |

---

## `paused` and `failed` — any command

These two have the same fields whichever command wrote them.

### `/<command> paused`
- Blocked on (one line — what needs the user's input)
- Progress (one line — what's finished so far, or `none`)
- Files touched

Written by `/plan` and `/implement` when their subagent returns `needs-input`. The user's answers follow as `decision` / `deviation` / `scope-change` change entries, and a re-run picks up from there. An answer the user can't give yet starts its `What:` with the `not-answered-yet:` marker.

### `/<command> failed`
- Reason (one line)

Written when a subagent returns `error` or a malformed result. No artifact is written for a failed run. For `/review`, the Reason names each axis that failed.

---

## `completed` — per-command fields (required, in order)

Each value takes its shape from **Value shapes** above. Any `completed` entry may add `Manual steps:` as its last field. Leave it out when there are none.

### `/spec completed`
- Feature
- Source
- Key decisions

### `/pull completed`
- Feature
- Source

### `/slice completed`
- Slices (count)
- Done (the slices committed code already delivers, as agreed in the approval list)

### `/plan completed`
- Approach
- Key decisions
- Open questions
- Concerns
- Base commit (a slice's first `/plan completed` only)

### `/implement completed`
- Summary
- Files created (count)
- Files modified (count)
- Deviations from plan
- Known issues

### `/review completed`
- Spec
- Standards
- Correctness
- Acceptance criteria
- Verdict

### `/fix completed`
- Mode
- Defects fixed (count)
- Judgements fixed (count)
- Skipped by user (includes findings marked already fixed)
- Deferred (findings left out by the codes given)
- New issues found

---

## Change entries

Between command entries, the agent appends a **change entry** for each mid-session event that matches a change type in `vocabulary.md`. Change entries are the canonical record of those events; completion entries reference them rather than restating them.

Heading uses `change` instead of `/<command> <status>`:

```markdown
## #<n> — <YYYY-MM-DD HH:MM:SS> — change
- Trigger: <user-request | agent-decision>
- Type: <decision | deviation | scope-change | blocker | correction>
- What: <one-line description>
- Why: <reason>
- Impact: <files, decisions, or downstream steps affected; or "none">
- Corrects: <#<n> | <timestamp> | none>
```

All fields are required, in the order shown, after any `Slice:`, except `Corrects:`, which every `correction` has and no other type does: the id of the entry it corrects (its timestamp for an entry written before ids), or `none` when it corrects something done rather than something logged. The correction restates whatever in the corrected entry still holds.

---

## Example

```markdown
## #1 — 2026-04-23 09:14:22 — /spec completed
- Feature: account creation with excluded from net worth toggle
- Source: PROJ-42
- Key decisions: toggle defaults to false

## #2 — 2026-04-23 11:47:03 — /plan completed
- Approach: new boolean field on accounts table + UI toggle in form
- Key decisions: reuse existing form component
- Open questions: none
- Concerns: none

## #3 — 2026-04-23 14:22:18 — /implement paused
- Blocked on: whether archived accounts count toward net worth
- Progress: form component and schema change written
- Files touched: src/accounts/AccountForm.tsx, db/schema/0042_archived.sql

## #4 — 2026-04-23 14:25:40 — change
- Trigger: user-request
- Type: scope-change
- What: archived accounts are excluded from net worth and hidden by default
- Why: resolves "should archived accounts still count toward net worth?"
- Impact: PLAN.md updated, the schema needs an `archived` column

## #5 — 2026-04-23 16:05:33 — /implement completed
- Summary: account creation form with excluded-from-net-worth toggle
- Files created: 3
- Files modified: 4
- Deviations from plan: yes — see change entries above
- Known issues: no

## #6 — 2026-04-23 16:40:12 — change
- Trigger: user-request
- Type: correction
- What: archived accounts stay visible in the account list and are only excluded from net worth
- Why: the user wants to see archived accounts; hiding them was never intended
- Impact: src/accounts/AccountList.tsx, PLAN.md (archived accounts visible), IMPLEMENTATION-SUMMARY.md under Changes after implementation
- Corrects: #4
```