---
name: plan
description: 'Writes the implementation plan for a Ptah spec, or for its current slice, in PLAN.md.'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /plan

Write the technical plan for a spec in `PLAN.md`, or on a sliced spec, for its current slice.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/plan` is a thin dispatcher: the planning happens in the `architect` subagent's own context. See `../../guides/delegated-work.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 2 — Pick the slice (sliced spec only)

On a sliced spec, per `../../guides/slices.md`, `/plan` plans the current slice, and moves on when it's finished: the slice to plan is then the lowest-numbered slice that isn't finished. If every slice is finished, stop:

> "Every slice of `<id>` is finished. Run `/ptah:review <id>` for the final review."

When that slice has no `Base commit:` yet, it starts here, from a commit. If `git status --porcelain` shows anything outside `.ptah/`, stop:

> "You have uncommitted work outside `.ptah/`. Commit the finished slice, or discard the work, then run `/ptah:plan <id>` again."

Otherwise its `<base-commit>` is the output of `git rev-parse HEAD`.

---

## Step 3 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`, plus the `Slice:` line on a sliced spec:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
Plugin root: <plugin-root>
Slice: .ptah/specs/<feature-name>/slices/<nn>-<slug>/
```

---

## Step 4 — Handle the result

Handle the result per **Handling the result** in `../../guides/delegated-work.md`. On `complete`, the artifact goes to `PLAN.md` in the work folder, and on a slice's first `/plan completed` the entry adds `Base commit: <base-commit>`.

When `Open questions` isn't `none`, ask PLAN.md's **Open questions** in order once `/plan completed` is logged, and update `PLAN.md` to match each answer per **Artifact ownership** in `RULES.md`. A question the user defers stays in **Open questions**, with nothing logged for it. When `Concerns` isn't `none`, the hand-off adds a `Concerns` list with PLAN.md's **Concerns** copied verbatim.
