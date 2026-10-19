# Ptah workflow rules

Cross-cutting rules the agent applies regardless of which command is running. These apply to **every** Ptah command (`/spec`, `/plan`, `/implement`, `/review`, `/fix`, `/document`).

---

## Always read LOGS.md first

When working on any feature, read `LOGS.md` in the relevant spec folder before doing anything else. It is the single source of truth for current state — what's been done, what was decided, what's next. Never skip it, even when "just looking" at one specific file.

---

## Stop and ask, one question at a time

If anything in the spec or design is ambiguous, contradictory, or underspecified, stop and ask the user a targeted question before proceeding. Ask one question at a time when there are several. Do not guess to keep momentum — guessing accumulates into deviations that surface much later.

This applies before:
- Writing any design (`/plan`)
- Writing any code (`/implement`)
- Applying any fix (`/fix`)

If everything is clear, skip the clarifying step entirely and proceed.

---

## Delegated work

They follow the same contract as the review subagents:

- **The prompt is the folder path, nothing else.** The subagent reads `SPEC.md`, `DESIGN.md`, `LOGS.md`, `refs/`. The dispatcher never summarizes the conversation or explains anything on the user's behalf.

Subagents can't talk to the user, so **Stop and ask** becomes a loop:

1. The subagent hits something it would normally ask about. It stops and returns its questions, each tagged with the change-entry type the answer would be (`decision`, `deviation`, `scope-change`) — result status `needs-input`.
2. The dispatcher logs a `/<command> paused` command entry, then asks the questions one at a time.
3. After each answer, the dispatcher appends a change entry recording it (`Trigger: user-request`, the tagged type, `What:` the answer as a one-line decision).
4. The dispatcher re-dispatches with the same prompt — just the folder path. The subagent finds the answers in `LOGS.md`, where they belong anyway.

Answers go through `LOGS.md` and never through the prompt, so a re-dispatch in a later session — after the main session ended mid-loop — works exactly the same way. And because the pause is a real command entry, `/status` and `/resume` show the spec as paused, with what it's blocked on.

Subagents can't spawn subagents, so these stay dispatched from the main session only.

## Logging discipline

While working on any spec, append **change entries** to the corresponding `LOGS.md` whenever a meaningful event happens mid-session — not just when a command completes.

### When to log

Log automatically, without asking, on these events (the values are defined in [`guides/vocabulary.md`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md))

### When NOT to log

Routine work creates noise — do not log it:
- Reading files, running searches, asking the next clarifying question in a normal flow
- Fixing typos, formatting, or reformatting code
- Restating something already captured in a command's completion entry
- Internal reasoning steps that don't change anything
- reading `LOGS.md`; only log if what it surfaced changed a decision (and then log the decision, not the lookup)

---

## Reports and vocabulary

Every fixed value in Ptah — command statuses, result statuses, spec states, change types and triggers, severities, verdicts, fix modes — is defined once, in [`guides/vocabulary.md`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md). Commands and subagents use those values exactly; a value that isn't on its list is an error, never something to coerce.

Every final report follows [`guides/result-format.md`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md), in markdown:

- **Subagent → dispatcher:** a `===RESULT===` block whose bullets are the `LOGS.md` fields for the entry it produces, then artifact blocks named after their files, then `===END===`. A result that breaks the format is malformed — the dispatcher logs `failed` and never guesses at or patches it.
- **Command → user:** one hand-off shape for every command — status icon and line, artifact path, one to three key facts, and the next command.

`LOGS.md` entries, results, and hand-offs share the same field names, so information moves between them by copying, not translating.

---

## Spec identifiers

Every spec folder created by `/ptah-spec` is named `ptah-<n>-<slug>`, e.g. `ptah-3-user-login`.

- `<n>` — a sequential integer, unique per project
- `<slug>` — a kebab-case version of the feature name given to `/ptah-spec`

### Assigning a number (`/ptah-spec` only)

The next number lives in `.ptah/ptah.yml` under `specs.next_id` — this is a plain config value, not something the agent works out by scanning `.ptah/specs/`.

When `/ptah-spec` creates a new folder:

1. Read `specs.next_id` from `.ptah/ptah.yml`. If the file, or the `specs` section, or the key is missing, treat the next id as `1`.
2. Use that value as `<n>` for the new folder.
3. Immediately after creating the folder, write `specs.next_id: <n + 1>` back to `ptah.yml` — creating the file or the `specs:` section if it didn't exist yet, and leaving any other config (`commands:`, `context_sources:`, etc.) untouched.

The agent never infers the next number from existing folder names. Numbers are never reused, even if a folder is later deleted — the counter only moves forward. If a gap needs reclaiming, that's a manual edit to `specs.next_id`, not something any command does automatically.

### Resolving an identifier (every other command)

Every command that takes a spec argument — `/ptah-design`, `/ptah-implement`, `/ptah-code-review`, `/ptah-fix`, `/ptah-document`, `/ptah-resume` — accepts any of:

- a bare number: `3`
- a number with the prefix: `ptah-3`
- the full folder name: `ptah-3-user-login`

Resolve the argument in this order:

1. If it matches an existing folder name in `.ptah/specs/` exactly, use it.
2. Otherwise, strip a leading `ptah-` if present, take the leading number, and glob `.ptah/specs/ptah-<n>-*`. If exactly one folder matches, use it.
3. Otherwise, treat the argument as a literal legacy folder name — `.ptah/specs/<argument>/` — for specs that predate this convention.
4. If nothing matches any of the above, stop and tell the user no spec was found for `<argument>`, and suggest running `/ptah-status`.

This is a single lookup for one already-existing folder, not a scan across all of them — it's unrelated to how `/ptah-spec` assigns new numbers above.

### Displaying identifiers

Whenever a command refers to a spec in output shown to the user — `/ptah-resume`'s summary header, or a hand-off message suggesting the next command to run — show **only the number**, e.g. "run `/ptah-design 3`". Never surface the slug or full folder name in these contexts.

Two exceptions:
- **`/ptah-status` rows** show the full spec name (`ptah-3-user-login`), since the report is a scannable overview meant to be read, not typed. Its `next:` line still uses the bare number, since that's the part you'd actually run.
- **File paths** the user is meant to open and review (e.g. "Review it at `.ptah/specs/ptah-3-user-login/SPEC.md`") need the real, full path.

---

## Path conventions

Two roots, never mixed.

**Plugin files** ship with Ptah and are read-only. They're addressed through `${CLAUDE_PLUGIN_ROOT}`, which Claude Code expands to the plugin's absolute path in skill and agent content (and the SessionStart hook expands in this file):

| Location | Purpose |
|----------|---------|
| `${CLAUDE_PLUGIN_ROOT}/RULES.md` | This file. Injected into every session by `hooks/session-start.sh` |
| `${CLAUDE_PLUGIN_ROOT}/guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md` |
| `${CLAUDE_PLUGIN_ROOT}/skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `${CLAUDE_PLUGIN_ROOT}/agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See **Delegated work** |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config: `specs.next_id`, `commands.fix`, `context_sources` |
| `.ptah/specs/ptah-<n>-<slug>/` | Per-feature work product (created by `/ptah:spec`). See **Spec identifiers** |
| `.ptah/reviews/<review-name>/` | Per-review work product, separate from the spec pipeline |


---

## Wait for user confirmation

Each command produces an artifact (`SPEC.md`, `DESIGN.md`, `IMPLEMENTATION-SUMMARY.md`, etc.) and hands off to the user. Never auto-advance to the next command in the workflow — always wait for the user to review the artifact and explicitly run the next slash command. Every Ptah skill sets `disable-model-invocation: true`, so none of them can be started by the agent on its own — only by the user typing it.
