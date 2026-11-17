---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /plan

Write the technical plan for a spec in `PLAN.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/plan` is a thin dispatcher: the planning happens in the `architect` subagent's own context. See `../../guides/delegated-work.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 2 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
Plugin root: <plugin-root>
```

---

## Step 3 — Handle the result

Per **Handling the result** in `../../guides/delegated-work.md`:

- **`complete`** — write the `===PLAN.md===` block to `.ptah/specs/<feature-name>/PLAN.md`. `Next step: /ptah:implement <id>`.
  - If `Open questions` isn't `none`, after logging `/plan completed`, ask PLAN.md's **Open questions** in order. Then update `PLAN.md` to match each answer, per **Artifact ownership** in `RULES.md`.
  - If the user defers a question, leave it in **Open questions**, log nothing for it, and move on.
  - If `Concerns` isn't `none`, the hand-off adds a `Concerns` list of PLAN.md's **Concerns**, copied verbatim.