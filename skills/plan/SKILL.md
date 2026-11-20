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

Handle the result per **Handling the result** in `../../guides/delegated-work.md`. On `complete`, the artifact goes to `.ptah/specs/<feature-name>/PLAN.md` and `Next step:` is `/ptah:implement <id>`.

When `Open questions` isn't `none`, ask PLAN.md's **Open questions** in order once `/plan completed` is logged, and update `PLAN.md` to match each answer per **Artifact ownership** in `RULES.md`. A question the user defers stays in **Open questions**, with nothing logged for it. When `Concerns` isn't `none`, the hand-off adds a `Concerns` list with PLAN.md's **Concerns** copied verbatim.