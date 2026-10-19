---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

## Step 1 — Rules

`RULES.md` is injected at session start. If it isn't in your context, read `${CLAUDE_PLUGIN_ROOT}/RULES.md`.

## Step 2 — Resolve the spec

When the user runs `/plan <spec-id>`, resolve `<spec-id>` to a spec folder per **Spec identifiers** in `RULES.md`. The rest of this file uses `<feature-name>` for that resolved folder, e.g. `ptah-3-user-login`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 3 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only**:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
```

---

## Step 4 — Handle the result

### `Status: needs-input`

The subagent needs the user's input before it can design. Per **Delegated work** in `RULES.md`:

1. Append a `/plan paused` entry to `LOGS.md` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, copying the result's fields verbatim

2. Ask the `### Questions` **one at a time**, in the order returned. Present each in your own words if it reads better, but don't answer, soften, or drop any.

3. After each answer, append a change entry recording it.

4. When every question is answered, go back to Step 2 and re-dispatch with the same prompt.

The `paused` entry already written means `/plan <n>` picks up from the answered questions later, in any session.

### `Status: complete`

Write the `===PLAN.md===` block verbatim to `.ptah/specs/<feature-name>/PLAN.md`, then continue to Step 5.

### `Status: error`, or a malformed result

Write no artifact. Append a `failed` entry.

If the result was malformed, offer to show the raw response.

---

## Step 5 — Append to LOGS.md

On `complete` only: append `/plan completed` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, copying the result's fields and adding `Next step: /ptah:implement <n>`.

---

## Step 6 — Hand off to user

Hand off per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`.
