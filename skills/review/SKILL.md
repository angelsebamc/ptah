---
name: review
description: 'Reviews an implemented Ptah spec''s code on three axes (spec, standards, correctness) through three isolated, read-only reviewer subagents in parallel, and writes REVIEW.md with coded defects and judgements and a verdict. Use only when the user asks to review a Ptah spec, or when /ptah:implement runs it because commands.implement.review is true: each run costs three subagents.'
argument-hint: '[<spec-id>]'
---

# /review

Review the implemented code on three axes — spec, standards, correctness — and write `REVIEW.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/review` is a thin dispatcher: the review happens in three isolated `reviewer` subagents, one per axis. See `../../guides/delegated-work.md`. Passing them anything beyond Step 3's prompt defeats the point of isolating them.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` is empty or missing, stop and tell the user:

> "No implementation found for `<spec-id>`. Run `/ptah:implement <id>` first."

This only checks that the implementation happened. The reviewers never see `IMPLEMENTATION-SUMMARY.md`.

---

## Step 2 — Get the base branch

`<base>` is the output of `git symbolic-ref --short refs/remotes/origin/HEAD`. If the command fails, `<base>` is `none`, and the reviewers review uncommitted changes only.

---

## Step 3 — Dispatch the three reviewers

Invoke the `ptah:reviewer` subagent three times in one message, in the foreground, once per axis in **Review axis** in `../../guides/vocabulary.md`. Each prompt must contain **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md`:

```
Review the Ptah spec at .ptah/specs/<feature-name>/
Plugin root: <plugin-root>
Axis: <axis>
Base: <base>
```

---

## Step 4 — Check the results

Check each result against every rule in `../../guides/result-format.md`. A result is also malformed if its `Axis:` isn't the axis it was dispatched with, if it has any status other than `complete` or `error`, or if its codes don't use its axis's letter.

If any result is `error` or malformed, write no `REVIEW.md`. Append `/review failed` per `../../guides/logs-format.md`, with a `Reason:` that names each axis that failed and why, and hand off as failed. If a result was malformed, offer to show the raw response. A review missing an axis would look complete when it isn't.

---

## Step 5 — Write `REVIEW.md`

Write `.ptah/specs/<feature-name>/REVIEW.md`:

````
# REVIEW — <feature-name>

## Summary
<2–3 sentences across the axes: is the code solid, and what's the main concern? Say so when <base> was none.>
- Spec: <d> defects, <j> judgements
- Standards: <d> defects, <j> judgements
- Correctness: <d> defects, <j> judgements

## Spec
<the spec axis's ===FINDINGS=== block>

## Standards
<the standards axis's ===FINDINGS=== block>

## Correctness
<the correctness axis's ===FINDINGS=== block>

## Acceptance criteria check
- [x] <criterion from SPEC.md> — met
- [ ] <criterion from SPEC.md> — <partial | missing> (see <code>)

## Verdict
<`fix-needed` — <n> defects | `approved` — no defects>
````

- **Findings** go in as each axis returned them, never re-ranked across axes. The one change allowed: when two findings on different axes describe the same problem at the same code, keep both and add `Same as: <code>` as the last line of the one on the later axis (spec, then standards, then correctness), naming the earlier one, so `/fix` fixes it once.
- **Acceptance criteria check**: list every acceptance criterion in `SPEC.md`, in order. A criterion named on a spec finding's `Criterion:` line takes that line's status and the finding's code; every other criterion is met. If the number met doesn't match the spec axis's `Acceptance criteria:` field, treat the spec result as malformed and go back to Step 4's failure.
- **Verdict** is per **Review verdict** in `../../guides/vocabulary.md`, from the defects across all three axes. Its `<n>` leaves out a defect whose `Same as:` names another defect. The Summary's per-axis counts still include it.

---

## Step 6 — Log and hand off

Append `/review completed` per `../../guides/logs-format.md`: each axis's counts from its result, `Acceptance criteria:` from the spec axis, the verdict, and `Next step:` per **Review verdict** in `../../guides/vocabulary.md`.

Hand off per `../../guides/result-format.md`.
