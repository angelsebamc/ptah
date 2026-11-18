---
name: resume
description: 'Orients on one Ptah spec by reading its LOGS.md and showing the last entry and where the work stands.'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /resume

Orient the agent on a spec's current state at the start of a new session.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Locate the spec

`<spec-id>` = `$ARGUMENTS[0]`, if given.

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

---

## Step 2 — Read the session history

Apply the **Always read LOGS.md first** rule from `RULES.md`: read the full `LOGS.md` for the resolved spec folder. If the folder has a `slices/` folder, also read the `LOGS.md` of every slice folder in it, and treat all the logs as one timeline, ordered by timestamp.

If the spec folder's `LOGS.md` is empty or missing, the folder wasn't produced by `/ptah:spec`. Tell the user:

> "Spec `<id>` has no LOGS.md at `.ptah/specs/<folder>/`. Ptah can't resume it."

Then stop.

Otherwise, identify:
- **The last entry** of each log, command or change.
- **The last command entry** (`/<command> completed | paused | failed`) across all the logs, the log it's in, and the change entries after it in that log. These drive `Where you are:`, even when the last entry is a change entry.

### Do not

- Read any artifact, including `SLICE.md`
- Read anything in `refs/`
- Read any source file, including files listed in `IMPLEMENTATION-SUMMARY.md`
- Write or edit any file, including `LOGS.md`

Artifacts, refs and code are loaded by the workflow command that needs them.

---

## Step 3 — Print the summary

On a spec without `slices/`, print exactly two lines, with a blank line between them:

```
Last entry: #<id> <timestamp> <type> — <what>

Where you are: <one-line synthesis>
```

On a spec with `slices/`, print the last entry of each log, the spec folder's first, then each slice by its folder name, and the synthesis:

```
Last entries:
- spec: #<id> <timestamp> <type> — <what>
- <nn>-<slug>: #<id> <timestamp> <type> — <what>

Where you are: <one-line synthesis>
```

`#<id>` and `<timestamp>` are the entry's heading id and timestamp, as written. Leave out `#<id>` for an entry without an id. `<type>` and `<what>` depend on the entry:

| Last entry | `<type>` | `<what>` |
|---|---|---|
| change entry | its `Type:` | its `What:` |
| `completed` command entry | `/<command> completed` | its `Next step:` |
| `paused` command entry | `/<command> paused` | its `Blocked on:` |
| `failed` command entry | `/<command> failed` | its `Reason:` |

### Rules for the synthesis line

Base it on the last command entry's `Next step:`, in one sentence. When that entry is in a slice's log, name the slice. Examples:

- `"Implementation finished. Next step: /ptah:review k3f9."`
- `"Code review done with 2 blockers, 1 major. Next step: /ptah:fix k3f9."`
- `"Spec written. Next step: /ptah:plan k3f9."`
- `"Slice 2 reviewed and approved. Look at the result, then /ptah:accept k3f9 2."`

If the `Next step:` starts with `none`, say nothing is open and name the optional command, if any, per **Next step** in `../../guides/vocabulary.md`. E.g. `"Review clean, nothing open. Optional: /ptah:fix k3f9 N1,N2."`

If the last command entry has `Manual steps:`, name them before the next command, e.g. `"Implementation finished. Restart the local API, then /ptah:review k3f9."`

If the last command entry is `paused`, name what it's blocked on and how to pick it back up. The change entries after it are the user's answers so far. An answer whose `What:` starts with `not-answered-yet:` doesn't count until a later entry answers the same question: name the question and what the user needs to do before re-running. E.g. `"Paused during /ptah:implement, blocked on: <Blocked on: value> — 2 answers logged. Re-run /ptah:implement k3f9 to continue."`

If the last command entry is `failed`, give the reason and the re-run, e.g. `"/ptah:review failed: <Reason: value>. Re-run /ptah:review k3f9."` For a failed `/ptah:implement`, add that code may have changed on disk.