# Ptah workflow rules

Cross-cutting rules the agent applies regardless of which command is running. These apply to **every** Ptah command.

---

## Always read LOGS.md first

When working on any feature, read `LOGS.md` in the relevant spec folder before doing anything else. It is the single source of truth for current state — what's been done, what was decided, what's next. Never skip it, even when "just looking" at one specific file.

---

## Stop and ask, one question at a time

If anything in the spec or plan is ambiguous, contradictory, or underspecified, stop and ask the user a targeted question before proceeding. Ask one question at a time when there are several. Do not guess to keep momentum — guessing accumulates into deviations that surface much later.

This applies before:
- Writing any plan (`/plan`)
- Writing any code (`/implement`)
- Applying any fix (`/fix`)

If everything is clear, skip the clarifying step entirely and proceed.

---

## Wait for the user

Never continue into the next command's work. Hand off and wait for the user to run it.

---

## Delegated work

- **The prompt is the folder path, nothing else.** The subagent reads `SPEC.md`, `PLAN.md`, `LOGS.md`, `refs/`. The dispatcher never summarizes the conversation or explains anything on the user's behalf.

Subagents can't talk to the user, so **Stop and ask** becomes a loop:

1. The subagent hits something it would normally ask about. It stops and returns its questions, each tagged with the change-entry type the answer would be (`decision`, `deviation`, `scope-change`) — result status `needs-input`.
2. The dispatcher logs a `/<command> paused` command entry, then asks the questions one at a time.
3. After each answer, the dispatcher appends a change entry recording it (`Trigger: user-request`, the tagged type, `What:` the answer as a one-line decision).
4. The dispatcher re-dispatches with the same prompt — just the folder path. The subagent finds the answers in `LOGS.md`, where they belong anyway.

Answers go through `LOGS.md` and never through the prompt, so a re-dispatch in a later session — after the main session ended mid-loop — works exactly the same way. And because the pause is a real command entry, `/ptah:resume` shows the spec as paused, with what it's blocked on.

Subagents can't spawn subagents, so they're always dispatched from the main session.

### Handling the result

Dispatching commands (`/plan`, `/implement`, `/review`) handle the subagent's result the same way. First check it against every rule in [`the result format`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md).

- **`complete`** — write the artifact block verbatim to the spec folder, then append `/<command> completed` per [`the logs format`](${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md), copying the result's fields and adding `Next step:`.
- **`needs-input`** — run the loop above: append `/<command> paused` copying the result's fields verbatim, ask the `### Questions` one at a time in the order returned (reword if it reads better, but never answer, soften, or drop one), log each answer, then re-dispatch.
- **`error`, or a malformed result** — write no artifact, append `/<command> failed`, and hand off as failed. If the result was malformed, offer to show the raw response.

Then hand off per the result format.

---

## Logging discipline

While working on any spec, append **change entries** to the corresponding `LOGS.md` whenever a meaningful event happens mid-session — not just when a command completes.

### When to log

Log a change entry, without asking, whenever an event matches a change type in [`vocabulary`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md).

### When NOT to log

Routine work creates noise — do not log it:
- Reading files, running searches, asking the next clarifying question in a normal flow
- Fixing typos, formatting, or reformatting code
- Restating something already captured in a command's completion entry
- Internal reasoning steps that don't change anything
- Reading `LOGS.md`; only log if what it surfaced changed a decision (and then log the decision, not the lookup)

---

## Spec identifiers

Every spec folder created by `/ptah:spec` is named one of two ways:

- **From a ticket** — `<TICKET-ID>-<slug>`, e.g. `PROJ-45-add-csv-export`. The ticket id keeps its original casing; `<slug>` is built from the ticket title. Ticket specs take no number.
- **Without a ticket** — `<repo>-<n>-<slug>`, e.g. `some-web-3-user-login`. `<n>` is a sequential integer from `specs.next_id`, unique per project; `<slug>` is built from the name `/ptah:spec` infers from the spec conversation.

**Kebab-case** means lowercase, spaces and underscores → `-`, other punctuation removed.

`<repo>` is the name of the project's git root folder — the last path segment of `git rev-parse --show-toplevel` — in kebab-case. If the project isn't a git repository, stop:

> "Ptah names specs after the git repository. Run this command inside one."

### Resolving an identifier

Every command that takes a `<spec-id>` accepts a bare number (`3`), a prefixed number (`some-web-3`), a ticket id (`PROJ-45`), or the full folder name. Matching is case-insensitive: `PROJ-45` and `proj-45` are the same spec. Resolve it in this order:

1. If no `<spec-id>` was given, get one per **When the identifier is omitted**.
2. If it matches a folder name in `.ptah/specs/`, use it.
3. Otherwise, if it is a number, glob `.ptah/specs/<repo>-<number>-*`.
4. Otherwise, glob `.ptah/specs/<spec-id>-*`.
5. If exactly one folder matches, use it. If more than one matches, stop, list them, and ask for the full folder name. If none matches, stop: "No spec found for `<spec-id>`."
6. Offer to switch to the spec's branch per **Switching to the spec's branch**. Never skip this step.

Commands refer to the resolved folder as `<feature-name>`.

### When the identifier is omitted

A command that takes a `<spec-id>` and gets none picks the spec in this order, stopping at the first that gives one:

1. **The git branch.** Take the part of `git branch --show-current` after the last `/`. It names a spec when, case-insensitive, it is the spec's id — `<repo>-<n>` for a spec without a ticket, the ticket id for a ticket spec — or starts with that id followed by `-`. E.g. `user/PROJ-45-csv-export` names `PROJ-45-add-csv-export`; `PROJ-4-fix` doesn't. If more than one spec matches, stop, list them, and ask for the full folder name.
2. **This session's last hand-off.** Take the `<id>` from the first line of the most recent Ptah hand-off in this conversation — `/<command> <id> <status>`, e.g. `/review PROJ-45 completed` — and use it as `<spec-id>`.
3. **The user picks.** Ask, listing every spec in `.ptah/specs/` by its display id and the rest of its folder name — specs without a ticket by number first, then ticket specs — and wait for the reply:
   > "Which spec? Reply with its id.
   >
   > These specs are available:
   > - 3 user-login
   > - PROJ-45 add-csv-export"

   Use the reply as `<spec-id>`. If `.ptah/specs/` has no specs, stop: "No specs yet. Run `/ptah:spec` to start one."

Never guess from folder names or `LOGS.md` timestamps.

Before doing anything else, tell the user which spec was picked and why:

> "Using `<id>` from branch `<branch>`." or "Using `<id>` from this session."

### Switching to the spec's branch

Once a spec is resolved — from an id given with the command or any source in **When the identifier is omitted** — skip this if the current branch already names it, by the rule in **The git branch**. Otherwise look for local branches (`git branch --format='%(refname:short)'`) that name the spec, by the same rule:

- **One** → ask: "Spec `<id>` has branch `<branch>`. Switch to it? (yes / no)"
- **More than one** → list them and ask which one to switch to, or none.
- **None**, or the user says no → stay on the current branch.

Before switching, check `git status --porcelain`. If it shows uncommitted changes, don't switch — stop:

> "You have uncommitted changes on `<current-branch>`. Commit or stash them, then run `/ptah:<command> <id>` again."

Otherwise run `git switch <branch>` and go on with the command. Ptah never creates branches.

### Displaying an identifier

In output shown to the user — hand-offs, `Next:` lines, `/ptah:resume`'s header — show only the spec's **display id**, written `<id>`:

- A spec without a ticket — its folder starts with `<repo>-<n>-` — shows only its number, e.g. `/ptah:plan 3`.
- A ticket spec shows its ticket id as written in the folder name — everything up to and including the first run of digits, e.g. `/ptah:plan PROJ-45`.

File paths the user is meant to open are the exception: they use the full folder name.

---

## Reports and vocabulary

Every fixed value in Ptah — command statuses, result statuses, spec states, change types and triggers, severities, verdicts, fix modes — is defined once, in [`vocabulary`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md). Commands and subagents use those values exactly; a value that isn't on its list is an error, never something to coerce.

Every final report follows [`the result format`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md), in markdown.

`LOGS.md` entries, results, and hand-offs share the same field names, so information moves between them by copying, not translating.

---

## Path conventions

Two roots, never mixed.

**Plugin files** ship with Ptah:

| Location | Purpose |
|----------|---------|
| `${CLAUDE_PLUGIN_ROOT}/RULES.md` | This file. Injected into every session by `hooks/session-start.sh` |
| `${CLAUDE_PLUGIN_ROOT}/guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md`, `config.md` |
| `${CLAUDE_PLUGIN_ROOT}/skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `${CLAUDE_PLUGIN_ROOT}/agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See **Delegated work** |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config, created by `/ptah:init`. Every key is documented in [`config`](${CLAUDE_PLUGIN_ROOT}/guides/config.md) |
| `.ptah/specs/<TICKET-ID>-<slug>/`, `.ptah/specs/<repo>-<n>-<slug>/` | Per-feature work product (created by `/ptah:spec`) |