---
name: implement
description: 'Implements a Ptah spec''s PLAN.md and writes IMPLEMENTATION-SUMMARY.md.'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /implement

Implement a spec's plan, and document what was built in `IMPLEMENTATION-SUMMARY.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/implement` is a thin dispatcher: the implementation happens in the `implementer` subagent's own context. See `../../guides/delegated-work.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

On a sliced spec, `/implement` works on the current slice, per `../../guides/slices.md`. If that slice is finished, stop: "Slice `<n>` of `<id>` is finished. Run `/ptah:plan <id>` to plan the next slice." When it's the last slice, say instead that every slice is finished and `/ptah:review <id>` runs the final review.

If `PLAN.md` in the work folder is empty or missing, stop and tell the user:

> "No plan found for `<spec-id>`. Run `/ptah:plan <id>` first."

---

## Step 2 — Dispatch to the implementer subagent

Invoke the `ptah:implementer` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`, plus the `Slice:` line on a sliced spec:

```
Implement the Ptah spec at .ptah/specs/<feature-name>/
Plugin root: <plugin-root>
Slice: .ptah/specs/<feature-name>/slices/<nn>-<slug>/
```

---

## Step 3 — Handle the result

Handle the result per **Handling the result** in `../../guides/delegated-work.md`, with these additions:

- **`complete`**: the artifact goes to `IMPLEMENTATION-SUMMARY.md` in the work folder. Then read `commands.implement.review` per `../../guides/config.md`, where a missing `.ptah/ptah.yml` means `false`. When it's `true`, invoke the `ptah:review` skill for `<id>` once the `LOGS.md` entry is written, and hand off once, after the review: this command's hand-off, then the review's.
- **`needs-input`**: when an answered question is one of `PLAN.md`'s **Open questions**, remove it per **Artifact ownership** in `RULES.md`.
- **`error` or malformed**: the hand-off adds that code may have changed on disk.