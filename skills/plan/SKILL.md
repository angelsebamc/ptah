---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

# /plan

Write the technical plan for a spec in `PLAN.md`.

`/plan` is a thin dispatcher: the planning happens in the `architect` subagent's own context. See **Delegated work** in `RULES.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per **Spec identifiers** in `RULES.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 2 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only**:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
```

---

## Step 3 — Handle the result

Per **Handling the result** in `RULES.md`:

- **`complete`** — write the `===PLAN.md===` block to `.ptah/specs/<feature-name>/PLAN.md`. `Next step: /ptah:implement <id>`.
- **`needs-input`** — a re-dispatch picks up from the answered questions, in this session or a later one.
- **`error` / malformed** — as in the rule.