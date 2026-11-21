# Result and hand-off format

Every Ptah command ends with a final report, and every report has one of two readers:

- **A dispatching command** reads a subagent's **result** and turns it into files and a `LOGS.md` entry.
- **The user** reads a command's **hand-off**.

Every fixed value comes from [`vocabulary.md`](./vocabulary.md).

---

## Subagent result

The subagent's final message:

````
===RESULT===
- Status: <complete | needs-input | error>
- <Field>: <value>
- ...

### Questions
- [<change-type>] <question> — <why it matters>
===<ARTIFACT>.md===
<raw markdown, verbatim>
===END===
````

### Rules

1. **The final message is the result.** Another command reads it, not a person, so it opens on `===RESULT===` and closes on `===END===`. Leave out anything a project rule asks you to add to a response, such as a footer listing the rules you followed.
2. **`Status:` is always the first bullet.**
3. **The fields after it are the `LOGS.md` fields for the entry that status produces** — `completed`, `paused`, or `failed` (see the mapping in `vocabulary.md` and the per-command fields below). Same names, same order, values copied verbatim. The one exception is the `reviewer`'s `complete` fields, which cover one axis: `/review` combines the three results into one entry.
4. **One line per value.** No value spans lines. Lists inside a value are comma-separated.
5. **Fixed values are exact** — each written as `vocabulary.md` spells it.
6. **`###` sections appear only when they apply** — never written empty. `### Questions` appears only with `needs-input`.
7. **Artifact blocks are named after the file they become** (`===PLAN.md===`) and appear only with `complete`. Their content is raw markdown, written verbatim. The exceptions are the `reviewer`'s `===FINDINGS===`, which becomes its axis's section of `REVIEW.md`, and `===CRITERIA===`, which becomes its **Acceptance criteria check**.

### Malformed results

The dispatcher reads the result from `===RESULT===` to the first `===END===` and ignores anything before or after it. A result is malformed when that content is wrong: `Status:` missing, a required field missing, a value outside its vocabulary, a missing artifact block on `complete`, a question without a valid **question tag**, or no `===END===`, which means the result was cut off. `Status:` written after another bullet doesn't make it malformed.

The dispatcher never guesses or patches a malformed result. It treats it exactly like `Status: error`: logs a `failed` entry with `Reason: malformed result — <what was wrong>`, writes no artifact.

### Per-command fields

| Subagent | `complete` fields | `needs-input` fields | Artifact block |
|---|---|---|---|
| `architect` | Approach, Key decisions, Open questions, Concerns | Blocked on, Progress, Files touched | `===PLAN.md===` |
| `implementer` | Summary, Files created, Files modified, Deviations from plan, Known issues | Blocked on, Progress, Files touched | `===IMPLEMENTATION-SUMMARY.md===` |
| `reviewer` | Axis, Defects, Judgements | — | `===FINDINGS===`, plus `===CRITERIA===` on the `spec` axis |

`error` always carries exactly one field: `Reason: <one line>`.

Field formats are defined in [`logs-format.md`](./logs-format.md) under each command. The `reviewer`'s `Axis` is a review axis from `vocabulary.md`, and its `Defects` and `Judgements` are counts.

### Example

````
===RESULT===
- Status: needs-input
- Blocked on: whether archived accounts count toward net worth
- Progress: form component and schema change written
- Files touched: src/accounts/AccountForm.tsx, db/schema/0042_archived.sql

### Questions
- [decision] Should archived accounts still count toward net worth? — the design hides them from the list but doesn't say whether the total excludes them.
===END===
````

---

## Hand-off

Every command's final message to the user:

```
/<command> <id> <status>
Artifact: `<path to the artifact the user should review>`
<one to three lines of key facts>
Next: <what the user needs to do>
```

`Next:` is a recommendation, written only when the user has something to do before carrying on: answer the questions a pause is waiting on, fix what made a run fail, or check or decide something the result raised. Leave the line out otherwise. It never just names the command that usually follows, such as `/ptah:review` after `/ptah:implement`.

A command's skill may name a list for its hand-off. It goes after the key facts and before `Next:`, one line per item:

```
<Label>:
- <item>
```

A `/review` with no Ptah spec has no `<id>`: its first line is `/review branch <branch> <status>`.

When the command's `completed` entry has `Manual steps:`, the hand-off lists them in the same form under `Manual steps`, last before `Next:`.