# Ptah vocabulary

Every fixed value Ptah uses — in `LOGS.md`, in subagent results, in hand-offs, in `status` — is defined here and only here.

Values are **kebab-case**, lowercase, and exact. A value that isn't on its list is an error, never something to coerce to the nearest match — same "hard failures over silent fallbacks" principle as the rest of Ptah.

---

## Log entries

Values written in `LOGS.md` entries, and the spec state derived from them.

### Command status

The `<status>` in a `LOGS.md` command entry heading: `## <timestamp> — /<command> <status>`.

| Value | Meaning | Written when |
|---|---|---|
| `completed` | The command produced its artifact | The command finishes normally |
| `paused` | The command stopped to wait for the user | A subagent returned `needs-input` (`plan`, `implement`) |
| `failed` | The command stopped without producing its artifact | A subagent returned `error`, or a malformed result |

### Change type

The `Type:` field of a `LOGS.md` change entry.

| Value | Use for |
|---|---|
| `decision` | A choice that affects the work — library, pattern, structure, naming, or a user's answer to a question |
| `deviation` | The implementation diverged from the spec or plan |
| `scope-change` | Something was added to, removed from, or moved out of scope mid-flow |
| `blocker` | Hit something that needs resolving, outside a subagent question loop (those are `paused` command entries) |
| `correction` | The user pointed out something was wrong, and it's being redone |

### Change trigger

The `Trigger:` field of a `LOGS.md` change entry.

| Value | Meaning |
|---|---|
| `user-request` | The user asked for it or answered a question |
| `agent-decision` | The agent decided on its own |

### Spec state

What `status` shows for a spec, derived from its **last command entry** — change entries are ignored for this.

| Value | Last command entry |
|---|---|
| `just-started` | none yet |
| `active` | any `completed`, other than an `approved` review |
| `paused` | any `paused` |
| `failed` | any `failed` |
| `completed` | `review completed` with `Verdict: approved` |

---

## Subagent results

Values in the `===RESULT===` block a subagent returns.

### Result status

The first field of every subagent result. Each maps to exactly one command status, which is what the dispatcher logs.

| Value | Meaning | Logged as |
|---|---|---|
| `complete` | The work is done; artifact block(s) follow | `completed` |
| `needs-input` | The subagent stopped with questions for the user | `paused` |
| `error` | The subagent couldn't do the work at all (e.g. missing input) | `failed` |

### Question tag

The `[<tag>]` on each question a subagent returns with `needs-input`: the change type its answer will be logged as.

| Value | Use for |
|---|---|
| `decision` | The answer is a choice the subagent can't make alone |
| `deviation` | The answer approves or rejects diverging from the spec or plan |
| `scope-change` | The answer adds to, removes from, or moves something out of scope |

---

## Review & fix

Values used by `review` and `fix`.

### Finding severity

| Value | Code | Meaning | `fix` default |
|---|---|---|---|
| `blocker` | `B<n>` | Bug, crash, security risk, data loss | always in scope |
| `major` | `M<n>` | Logic issue, missing edge case, test gap | always in scope |
| `minor` | `N<n>` | Naming, readability, small improvements | in scope only with `include_minor` |
| `suggestion` | `S<n>` | Alternative approach, future consideration | only when named by code |

#### Finding codes

Every finding carries a code: the severity's letter plus a number, e.g. `B1`, `M2`, `S1`. Numbering restarts at 1 for each severity, in the order findings appear in the review. Codes are how `fix` and the user refer to findings — to steer a fix, skip one, or pull in an out-of-scope minor or suggestion.

### Review verdict

| Value | Meaning | Next step |
|---|---|---|
| `fix-needed` | At least one blocker or major finding | `fix` |
| `approved` | No blockers or major findings | none — review clean |

### Fix mode

| Value | Behavior |
|---|---|
| `auto` | Apply all in-scope fixes silently, report at the end |
| `plan` | Show a one-line-per-finding plan, wait for one confirmation, apply in one pass — **default** |
| `interactive` | Ask per finding before applying |