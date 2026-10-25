---
name: implement
description: 'Implements a Ptah spec''s PLAN.md by dispatching the implementer subagent, relaying its blocking questions and writing IMPLEMENTATION-SUMMARY.md.'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

# /implement

Implement a spec's plan, and document what was built in `IMPLEMENTATION-SUMMARY.md`.

`/implement` is a thin dispatcher: the implementation — reading the plan, writing the code — happens in the `implementer` subagent's own context. This session only relays questions, writes `IMPLEMENTATION-SUMMARY.md`, and logs. See **Delegated work** in `RULES.md`.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per **Spec identifiers** in `RULES.md`.

If `.ptah/specs/<feature-name>/PLAN.md` is empty or missing, stop and tell the user:

> "No plan found for `<spec-id>`. Run `/ptah:plan <n>` first."

---

## Step 2 — Dispatch to the implementer subagent

Invoke the `ptah:implementer` subagent. Its prompt must contain **only**:

```
Implement the Ptah spec at .ptah/specs/<feature-name>/
```

---

## Step 3 — Handle the result

Per **Handling the result** in `RULES.md`:

- **`complete`** — write the `===IMPLEMENTATION-SUMMARY.md===` block to `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md`. `Next step: /ptah:review <n>`.
- **`needs-input`** — work the subagent already finished is on disk. If an answer changes the plan itself, update `PLAN.md` to match before re-dispatching, and say so in the change entry's `Impact:`.
- **`error` / malformed** — as in the rule. When handing off, add that code may have changed on disk.