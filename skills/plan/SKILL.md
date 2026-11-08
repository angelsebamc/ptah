---
name: plan
description: 'Writes the implementation plan in PLAN.md for a Ptah spec by dispatching the architect subagent'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /plan

Write the technical plan for a spec in `PLAN.md`.

`RULES.md` is `${CLAUDE_PLUGIN_ROOT}/RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/plan` is a thin dispatcher: the planning happens in the `architect` subagent's own context. See `${CLAUDE_PLUGIN_ROOT}/guides/delegated-work.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `${CLAUDE_PLUGIN_ROOT}/guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop and tell the user:

> "No spec found for `<spec-id>`."

---

## Step 2 — Dispatch to the architect subagent

Invoke the `ptah:architect` subagent. Its prompt must contain **only**:

```
Plan the Ptah spec at .ptah/specs/<feature-name>/
```

---

## Step 3 — Handle the result

Per **Handling the result** in `${CLAUDE_PLUGIN_ROOT}/guides/delegated-work.md`:

- **`complete`** — write the `===PLAN.md===` block to `.ptah/specs/<feature-name>/PLAN.md`. `Next step: /ptah:implement <id>`.
  - If `Open questions` isn't `none`, after logging `/plan completed`, ask PLAN.md's **Open questions** one at a time in order. After each answer, update `PLAN.md` to match: rework the sections the chosen option affects, and remove the question from **Open questions** (write `none` once it's empty). Then append a change entry whose `Impact:` names the `PLAN.md` sections updated.
  - If the user defers a question, leave it in **Open questions**, log nothing for it, and move on.
  - If `Concerns` isn't `none`, the hand-off adds a `Concerns` list, one item per line of PLAN.md's **Concerns**, copied verbatim.
- **`needs-input`** — a re-dispatch picks up from the answered questions, in this session or a later one.
- **`error` / malformed** — as in the rule.