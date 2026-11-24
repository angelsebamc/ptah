---
name: resume
description: 'Orients on one Ptah spec by reading its LOGS.md and showing the last entry and where the work stands.'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /resume

Orient on a spec's current state at the start of a new session, from its `LOGS.md` alone.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/resume` is read-only and reads one file. Leave every artifact, everything in `refs/`, and every source file unread, including the files `IMPLEMENTATION-SUMMARY.md` lists, and write nothing, `LOGS.md` included. The workflow command that needs artifacts, refs or code loads them itself.

## Step 1 — Locate the spec

Resolve `<spec-id>`, the first argument in `$ARGUMENTS` if there is one, per `../../guides/spec-identifiers.md`.

---

## Step 2 — Read the session history

Read the spec folder's full `LOGS.md`, per **Always read LOGS.md first** in `RULES.md`.

If `LOGS.md` is empty or missing, neither `/ptah:spec` nor `/ptah:pull` produced the folder, so stop:

> "Spec `<id>` has no LOGS.md at `.ptah/specs/<folder>/`. Ptah can't resume it."

Otherwise find two things: the **last entry** in the file, command or change, and the **last command entry** (`/<command> completed | paused | failed`) with the change entries after it. The last command entry drives `Where you are:`, even when a change entry comes after it. The step is done when you know both.

---

## Step 3 — Print the summary

Print exactly these two lines, with a blank line between them, and nothing else:

```
Last entry: #<n> <timestamp> <type> — <what>

Where you are: <one-line synthesis>
```

`#<n>` and `<timestamp>` are the last entry's heading id and timestamp, as written; leave out `#<n>` for an entry without an id. `<type>` and `<what>` come from the entry:

| Last entry | `<type>` | `<what>` |
|---|---|---|
| change entry | its `Type:` | its `What:` |
| `completed` command entry | `/<command> completed` | what it produced, such as its `Summary:` or `Verdict:` |
| `paused` command entry | `/<command> paused` | its `Blocked on:` |
| `failed` command entry | `/<command> failed` | its `Reason:` |

The synthesis is one sentence built from the last command entry: what just happened, e.g. "Code review done with 3 defects." What it must also carry depends on that entry:

- `Manual steps:`: name them.
- `paused`: name what it's blocked on, how many answers the change entries after it have logged, and the command to re-run to continue. An answer whose `What:` starts with `not-answered-yet:` doesn't count until a later entry answers the same question; name that question and what the user needs to do before re-running.
- `failed`: give the reason and the command to re-run. For a failed `/ptah:implement`, add that code may have changed on disk.
