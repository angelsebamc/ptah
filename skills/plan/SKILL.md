---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

## Step 1 - Read the `rules` in [`RULES.md`](../../ptah/RULES.md)

## Step 2 — Resolve the spec

When the user runs `/plan <spec-id>`, resolve `<spec-id>` to a spec folder as `specs/<spec-id>-<feature-name-or-ticket>`.

If `specs/<spec-id>-<feature-name-or-ticket>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 3 — Dispatch to the architect subagent

Invoke the `architect` subagent. Its prompt must contain **only**:

```
Plan the Ptah spec at `specs/<spec-id>-<feature-name-or-ticket>`
```

---

## Step 4 — Handle the result

### `Status: needs-input`

The subagent needs the user's input before it can design. Per **Delegated work** in `RULES.md`:

1. Append a `paused` entry to `LOGS.md`, copying the result's fields verbatim

2. Ask the `### Questions` **one at a time**, in the order returned. Present each in your own words if it reads better, but don't answer, soften, or drop any.

3. After each answer, append a change entry recording it.

4. When every question is answered, go back to Step 2 and re-dispatch with the same prompt.

The `paused` entry already written means `/plan <n>` picks up from the answered questions later, in any session.

### `Status: complete`

Write the `===PLAN.md===` block verbatim to `../../specs/<feature-name>/PLAN.md`, then continue to Step 4.

### `Status: error`, or a malformed result

Write no artifact. Append a `failed` entry.

If the result was malformed, offer to show the raw response.

---

## Step 5 — Append to LOGS.md

---

## Step 6 — Hand off to user
