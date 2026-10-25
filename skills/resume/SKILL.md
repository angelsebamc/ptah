---
name: resume
description: 'Orients on one Ptah spec by reading its LOGS.md and showing the last entry and where the work stands.'
argument-hint: '<spec-id>'
disable-model-invocation: true
---

Orient the agent on a spec's current state at the start of a new session. Run this before continuing any in-flight work.

## Step 1 — Locate the spec

`<spec-id>` = `$ARGUMENTS[0]`

When the user runs `/ptah:resume <spec-id>`, resolve `<spec-id>` per **Spec identifiers** in `RULES.md`.

---

## Step 2 — Read the session history

Apply the **Always read LOGS.md first** rule from `RULES.md`: read the full `LOGS.md` for the resolved spec folder.

If `LOGS.md` is empty or missing, the spec conversation was never finished. Tell the user:

> "Spec `<n>` was started but its SPEC.md was never written. Next step: `/ptah:spec <n>` to continue it."

Then stop.

Otherwise, identify:
- **The last entry** in the file, command or change.
- **The last command entry** (`/<command> completed | paused | failed`) and the change entries after it. The `Where you are:` line is built from these, even when the last entry is a change entry.

### Do not

- Read any artifact
- Read anything in `refs/`
- Read any source file, including files listed in `IMPLEMENTATION-SUMMARY.md`
- Write or edit any file, including `LOGS.md`

---

## Step 3 — Print the summary

Print exactly two lines, with a blank line between them:

```
Last entry: <HH:MM> <type> — <what>

Where you are: <one-line synthesis>
```

`<HH:MM>` is the time from the last entry's heading. `<type>` and `<what>` depend on the entry:

| Last entry | `<type>` | `<what>` |
|---|---|---|
| change entry | its `Type:` | its `What:` |
| `completed` command entry | `/<command> completed` | its `Next step:` |
| `paused` command entry | `/<command> paused` | its `Blocked on:` |
| `failed` command entry | `/<command> failed` | its `Reason:` |

Show nothing else from `LOGS.md` — no other entries, counts, artifacts, or refs.

### Rules for the synthesis line

The `Where you are:` line is the only piece of original prose in the response. Base it on the last command entry's `Next step:`. Keep it to one sentence, and reference the next command by number. Examples:

- `"Implementation finished. Next step: /ptah:review 7."`
- `"Code review done with 2 blockers, 1 major. Next step: /ptah:fix 7."`
- `"Spec written. Next step: /ptah:plan 7."`

If the last command entry is `paused`, name what it's blocked on and how to pick it back up. The change entries after it are the user's answers so far. E.g. `"Paused during /ptah:implement, blocked on: <Blocked on: value> — 2 answers logged. Re-run /ptah:implement 7 to continue."`

If the last command entry is `failed`, give the reason and the re-run, e.g. `"/ptah:review failed: <Reason: value>. Re-run /ptah:review 7."` For a failed `/ptah:implement`, add that code may have changed on disk.

Command statuses and spec states are defined in `${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md`.

---

## What `/resume` is and isn't

**It is:** an orientation command. It reads `LOGS.md` and reports where the work stands, so you and the agent agree on the next step before running it.

**It isn't:** a context preloader. Artifacts, refs, and code are loaded by the workflow command that needs them, when it runs. Isn't a workflow command.

---

Use `/resume` when:
- Starting a new session and continuing work from a previous one
- Switching between two in-flight specs (run `/ptah:resume <other-n>` to swap)
- Briefing a fresh agent (or a teammate) on the current state of a feature