---
name: implement
description: 'Implements a Ptah spec''s PLAN.md by dispatching the implementer subagent, relaying its blocking questions and writing IMPLEMENTATION-SUMMARY.md.'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

# /implement

Implement a spec's plan, and document what was built in `IMPLEMENTATION-SUMMARY.md`.

`/implement` is a thin dispatcher: the implementation — reading the plan, writing the code — happens in the `implementer` subagent's own context. This session only relays questions, writes `IMPLEMENTATION-SUMMARY.md`, and logs. See **Delegated work**.

## Step 1 — Rules

`RULES.md` is injected at session start. If it isn't in your context, read `${CLAUDE_PLUGIN_ROOT}/RULES.md`.

## Step 2 — Resolve the spec

When the user runs `implement <spec-id>`, resolve `<spec-id>` to a spec folder per **Spec identifiers** in `RULES.md` — it may be a bare number, `<n>`, or a full folder name. The rest of this file uses `<feature-name>` to mean that resolved folder.

If `.ptah/specs/<feature-name>/PLAN.md` is empty or missing, stop and tell the user:

> "No plan found for `<spec-id>`. Run `/plan <spec-id>` first."

---

## Step 3 — Dispatch to the implementer subagent

Invoke the `ptah:implementer` subagent. Its prompt must contain **only**:

```
Implement the Ptah spec at .ptah/specs/<feature-name>/
```

Nothing else — no summary of this conversation, no answers to earlier questions (those are in `LOGS.md`), no progress notes (the subagent finds them in `LOGS.md` and on disk). The subagent reads everything itself.

---

## Step 4 — Handle the result

Read the subagent's result. Check it against every rule there before acting on it — a result that breaks any rule is **malformed** and handled like `error`, never guessed at or patched up.

### `Status: needs-input`

The subagent stopped partway and needs the user's input. Work it already finished is on disk. Per **Delegated work** in rules:

1. Append a `/implement paused` entry to `LOGS.md` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, copying the result's fields verbatim.
   This entry is what lets the next dispatch pick up where this one stopped — including in a later session.
2. Ask the `### Questions` **one at a time**, in the order returned. Present each in your own words if it reads better, but don't answer, soften, or drop any.
3. After each answer, append a change entry recording it
   If an answer changes the plan itself, update `PLAN.md` to match before re-dispatching, and say so in `Impact:`.
4. When every question is answered, go back to Step 2 and re-dispatch with the same prompt.

Hand off as paused. The `paused` entry already written means `/implement <n>` picks up later, in any session.

### `Status: complete`

Write the `===IMPLEMENTATION-SUMMARY.md===` block verbatim to `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md`.

### `Status: error`, or a malformed result

Write no artifact. Append a `failed` entry.

---

## Step 5 — Append to LOGS.md

On `complete` only: append `/implement completed` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, copying the result's fields and adding `Next step: /ptah:review <n>`.

---

## Step 6 — Hand off to user

Hand off per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`.
