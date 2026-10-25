---
name: review
description: 'Reviews an implemented Ptah spec against its SPEC.md and PLAN.md through the isolated, read-only reviewer subagent, and writes REVIEW.md with coded findings (B/M/N/S) and a verdict. Documentation only. Use when the user runs /review with a spec number.'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

# /review

Review the implemented code against the plan and spec.

`/review` is a thin dispatcher: the review happens in the isolated `reviewer` subagent's own context. See **Delegated work** in `RULES.md`. Passing it anything beyond the folder path defeats the point of isolating it.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per **Spec identifiers** in `RULES.md`.

If `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` is empty or missing, stop and tell the user:

> "No implementation found for `<spec-id>`. Run `/ptah:implement <n>` first."

---

## Step 2 — Dispatch to the reviewer subagent

Invoke the `ptah:reviewer` subagent. Its prompt must contain **only**:

```
Review the Ptah spec at .ptah/specs/<feature-name>/
```

---

## Step 3 — Handle the result

Per **Handling the result** in `RULES.md`. The reviewer never returns `needs-input`.

- **`complete`** — write the `===REVIEW.md===` block to `.ptah/specs/<feature-name>/REVIEW.md`. Take `Next step:` from the verdict:

  | Verdict | `Next step:` |
  |---|---|
  | `fix-needed` | `/ptah:fix <n>` |
  | `approved` | `none — review clean` |

- **`error` / malformed** — as in the rule.