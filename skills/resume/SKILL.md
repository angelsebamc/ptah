---
name: resume
description: 'Orients on one Ptah spec by reading its LOGS.md and reporting the last command, changes since, artifacts produced, and the next step.'
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
- **The last command entry** (`/<command> completed | paused | failed`).
- **All change entries since that last command entry** — decisions, deviations, and corrections from the most recent step
- **Counts** of command entries and change entries in the whole file

---

## Step 3 — Inventory artifacts and refs

Derive which artifacts have been produced from the command entries in `LOGS.md` — not by opening the files:

| Command logged as completed | Artifact produced |
|---|---|
| `/spec` | `SPEC.md` |
| `/plan` | `PLAN.md` |
| `/implement` | `IMPLEMENTATION-SUMMARY.md` |
| `/review` | `REVIEW.md` |
| `/fix` | `REVIEW.md` (fix summary appended) |

List the filenames in the spec folder's `refs/` with `Glob`. Filenames only — do not open them.

### Do not

- Read any artifact
- Read anything in `refs/`
- Read any source file, including files listed in `IMPLEMENTATION-SUMMARY.md`
- Write or edit any file, including `LOGS.md`

---

## Step 4 — Print the summary

Use this exact format — the header shows the spec's **number only**, never the slug or full folder name:

```
Resumed <n>

History: LOGS.md (<count> command entries, <count> change entries)
Artifacts: <comma-separated artifact filenames from Step 3>
Refs: <comma-separated refs/ filenames, or "none">

Last command:
## <heading line, verbatim>
- <fields, verbatim>

Changes since then:
- <HH:MM> <type> — <the entry's "What:" value>

(One line per change entry since the last command. If none: "None.")

Where you are: <one-line synthesis based on the last command's "Next step:" field>
```

### Rules for the synthesis line

The `Where you are:` line is the only piece of original prose in the response. Keep it to one sentence, and reference the next command by number. Examples:

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
