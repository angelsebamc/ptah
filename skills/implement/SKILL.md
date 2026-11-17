---
name: implement
description: 'Implements a Ptah spec''s PLAN.md by dispatching the implementer subagent, relaying its blocking questions and writing IMPLEMENTATION-SUMMARY.md.'
argument-hint: '[<spec-id>] [<slice>]'
disable-model-invocation: true
---

# /implement

Implement a spec's plan, or one slice's, and document what was built in `IMPLEMENTATION-SUMMARY.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/implement` is a thin dispatcher: the implementation happens in the `implementer` subagent's own context. See `../../guides/delegated-work.md`.

## Step 1 — Resolve the spec and the slice

Take the slice number, if any, per **Slice number argument** in `../../guides/slices.md`. Resolve `<spec-id>` per `../../guides/spec-identifiers.md`. If the spec has `SLICES.md`, pick the slice per **Picking the slice** in `../../guides/slices.md`. The work folder is per **Work folder** there.

If `PLAN.md` in the work folder is empty or missing, stop and tell the user:

> "No plan found for `<id>`. Run `/ptah:plan <id>` first."

---

## Step 2 — Dispatch to the implementer subagent

Invoke the `ptah:implementer` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`, and the `Slice:` line only on a slice:

```
Implement the Ptah spec at .ptah/specs/<feature-name>/
Slice: .ptah/specs/<feature-name>/slices/<nn>-<slug>/
Plugin root: <plugin-root>
```

---

## Step 3 — Handle the result

Per **Handling the result** in `../../guides/delegated-work.md`:

- **`complete`** — write the `===IMPLEMENTATION-SUMMARY.md===` block to `IMPLEMENTATION-SUMMARY.md` in the work folder. `Next step: /ptah:review <id>`.
- **`needs-input`** — if an answered question is one of `PLAN.md`'s **Open questions**, remove it per **Artifact ownership** in `RULES.md`.
- **`error` / malformed** — when handing off, add that code may have changed on disk.
