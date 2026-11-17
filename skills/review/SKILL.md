---
name: review
description: 'Reviews an implemented Ptah spec against its SPEC.md, its PLAN.md, and the project''s own standards through the isolated, read-only reviewer subagent, and writes REVIEW.md with coded findings (B/M/N/S) and a verdict.'
argument-hint: '[<spec-id>] [<slice>]'
disable-model-invocation: true
---

# /review

Review the implemented code against the plan, the spec, and the project's own standards.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/review` is a thin dispatcher: the review happens in the isolated `reviewer` subagent's own context. See `../../guides/delegated-work.md`. Passing it anything beyond Step 2's prompt defeats the point of isolating it.

## Step 1 — Resolve the spec and the slice

Take the slice number, if any, per **Slice number argument** in `../../guides/slices.md`. Resolve `<spec-id>` per `../../guides/spec-identifiers.md`. If the spec has `SLICES.md`, pick the slice per **Picking the slice** in `../../guides/slices.md`: a slice review, or the final review once every slice is accepted. The work folder is per **Work folder** there.

Unless this is the final review, if `IMPLEMENTATION-SUMMARY.md` in the work folder is empty or missing, stop and tell the user:

> "No implementation found for `<id>`. Run `/ptah:implement <id>` first."

---

## Step 2 — Dispatch to the reviewer subagent

Invoke the `ptah:reviewer` subagent. Its prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`, and the `Slice:` line only on a slice:

```
Review the Ptah spec at .ptah/specs/<feature-name>/
Slice: .ptah/specs/<feature-name>/slices/<nn>-<slug>/
Plugin root: <plugin-root>
```

---

## Step 3 — Handle the result

Per **Handling the result** in `../../guides/delegated-work.md`.

- **`complete`** — write the `===REVIEW.md===` block to `REVIEW.md` in the work folder. Take `Next step:` per **Review verdict** in `../../guides/vocabulary.md`.
