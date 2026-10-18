---
name: review
description: 'Reviews an implemented Ptah spec against its SPEC.md and PLAN.md through the isolated, read-only reviewer subagent, and writes CODE-REVIEW.md with coded findings (B/M/N/S) and a verdict. Documentation only. Use when the user runs /review with a spec number.'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

# /review

Review the implemented code against the plan and spec.

`/review` is a thin dispatcher: it resolves the spec, hands the actual review off to the `reviewer` subagent, and writes what comes back.

## Step 1 — Resolve the spec

When the user runs `/review <spec-id>`, resolve `<spec-id>` to a spec folder per **Spec identifiers** in `RULES.md`. The rest of this file uses `<feature-name>` to mean that resolved folder.

If `specs/<feature-name>/IMPLEMENTATION.md` is empty or missing, stop and tell the user:

> "No implementation found for `<spec-id>`. Run `/implement <spec-id>` first."

---

## Step 2 — Delegate to the reviewer subagent

Invoke the `reviewer` subagent. Its prompt must contain **only**:

```
Review the Ptah spec at .claude/specs/<feature-name>/
```

Nothing else. Do not add context from this conversation, summarize what happened during `/implement`, or explain any deviations or decisions on the implementer's behalf — the subagent reads `SPEC.md`, `PLAN.md`, `IMPLEMENTATION.md`, and `LOGS.md` itself. Passing it anything beyond the folder path defeats the point of isolating it.

---

## Step 3 — Handle the result

Read the subagent's result per `guides/result-format.md`. Check it against every rule there before acting on it — a result that breaks any rule is **malformed** and handled like `error`, never guessed at or patched up.

- **`Status: complete`** — write the `===CODE-REVIEW.md===` block verbatim to `specs/<feature-name>/REVIEW.md`, then continue to Step 4.
- **`Status: error`, or a malformed result** — write no artifact. Append a `failed` entry, then skip to Step 5 and hand off as failed. If the result was malformed, offer to show the raw response.

---

## Step 4 — Append to LOGS.md

Append the completion entry, copying the result's fields verbatim and adding `Next step:` from the verdict:

```markdown
## <YYYY-MM-DD HH:MM:SS> — /review completed
- Blockers: <from result>
- Major: <from result>
- Minor: <from result>
- Suggestions: <from result>
- Acceptance criteria: <from result>
- Verdict: <from result>
- Next step: <see routing rule below>
```

**`Next step:` routing rule** — from the verdict, per `guides/vocabulary.md`:

| Verdict | `Next step:` |
|---|---|
| `fix-needed` | `/fix` |
| `ready-to-document` | `/document` |

---

## Step 5 — Hand off to user

Use the hand-off format in `guides/result-format.md`
