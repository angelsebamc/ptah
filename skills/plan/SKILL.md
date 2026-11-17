---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '[<spec-id>] [<slice>]'
disable-model-invocation: true
---

# /plan

Write the technical plan for a spec, or for one of its slices, in `PLAN.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/plan` is a thin dispatcher: the planning happens in the `architect` subagent's own context. See `../../guides/delegated-work.md`.

## Step 1 — Resolve the spec and the slice

Take the slice number, if any, per **Slice number argument** in `../../guides/slices.md`. Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

If the spec has `SLICES.md`, pick the slice per **Picking the slice** in `../../guides/slices.md`. If the slice has no folder yet, create it per **Slice folder** there. The work folder is per **Work folder** there.

---

## Step 2 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`, and the `Slice:` line only on a slice:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
Slice: .ptah/specs/<feature-name>/slices/<nn>-<slug>/
Plugin root: <plugin-root>
```

---

## Step 3 — Handle the result

Per **Handling the result** in `../../guides/delegated-work.md`:

- **`complete`** — write the `===PLAN.md===` block to `PLAN.md` in the work folder. `Next step: /ptah:implement <id>`.
  - If `Open questions` isn't `none`, after logging `/plan completed`, ask PLAN.md's **Open questions** in order. Then update `PLAN.md` to match each answer, per **Artifact ownership** in `RULES.md`.
  - If the user defers a question, leave it in **Open questions**, log nothing for it, and move on.
  - If `Concerns` isn't `none`, the hand-off adds a `Concerns` list of PLAN.md's **Concerns**, copied verbatim.
