---
name: fix
description: 'Applies findings from a Ptah REVIEW.md in auto, plan, or interactive mode, lets the user steer or pull in findings by code, and appends a Fix Summary.'
argument-hint: '[<spec-id>] [codes…] [-a | -p | -i]'
disable-model-invocation: true
---

# /fix

Read review findings and fix all blocker and major issues. Record what was changed next to the findings.

`RULES.md` is `${CLAUDE_PLUGIN_ROOT}/RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/fix` works from:

- **A spec** — `/fix [<spec-id>] [codes…]` — fixes findings from `.ptah/specs/<feature-name>/REVIEW.md`. This is the feature track.

Every finding carries a code assigned by the reviewer — `B1`, `B2` for blockers, `M1` for major, `N1` for minor, `S1` for suggestions.

`/fix` supports three modes that control how much the agent asks before applying fixes.

## Modes & config

`/fix` has three modes:

| Mode | Flag | Behavior |
|------|------|----------|
| `auto` | `-a` | Apply all in-scope fixes without asking. Report at the end. Takes no directives. |
| `plan` | `-p` | Show a one-line-per-finding plan, wait for one reply — "yes" or directives by code — then apply all in one pass. |
| `interactive` | `-i` | Ask per finding before applying. Directives by code work at every prompt. |

Mode is resolved with precedence **flag > config**. The config keys, `commands.fix.mode` and `commands.fix.include_minor`, are documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

## Step 1 — Parse command arguments

The command takes one source — an optional positional spec identifier (see `${CLAUDE_PLUGIN_ROOT}/guides/spec-identifiers.md`) — then optional finding codes and flags.

- If the first positional is shaped like a finding code, or a comma-separated list of them, the spec identifier was omitted and every positional is a finding code. Otherwise the first positional is the spec identifier and every positional after it is a finding code.
- Codes are separated by commas, spaces, or both — `n1,n2`, `n1 n2`, and `n1, n2` are the same. Match them case-insensitively and drop duplicates.
- Codes pull the named minors and suggestions into scope for this run. They add to the default scope, never narrow it.

Examples:
- `/fix k3f9` — uses mode from `ptah.yml`
- `/fix k3f9 -a` — applies all fixes this run without asking
- `/fix k3f9 -i` — asks per finding before applying it
- `/fix k3f9 n1,n2` — also fixes minors N1 and N2 this run
- `/fix k3f9 S1 -p` — also fixes suggestion S1, in plan mode
- `/fix n1,n2` — the spec comes from the branch or this session; also fixes minors N1 and N2

A positional after the spec identifier that isn't shaped like a code (`B`, `M`, `N`, or `S` followed by digits) stops the command:

> "`<arg>` isn't a finding code. Codes look like `B1`, `M2`, `N1`, `S3`."

**Mutually-exclusive flag pairs** produce an error and stop:
- `-a`, `-p`, `-i` (pick one)

> "Conflicting flags: `<flag1>` and `<flag2>`. Pick one."

**Unknown flags** produce an error and stop:

> "Unknown flag `-x`. Supported flags: `-a (auto)`, `-p (plan)`, `-i (interactive)`."

---

## Step 2 — Resolve mode and scope

Determine the effective mode and scope for this run. Precedence is **flag > config**.

### Load Ptah config

Check the config per **Required keys** in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

The config file is never modified by `/fix`. Flags only affect the current run.

### Compute in-scope findings
- Always in scope: blocker (`B`) and major (`M`) findings
- Minor (`N`) findings: in scope only when `commands.fix.include_minor` is `true`
- Any minor or suggestion (`S`) the user names by code — as a command argument or in a directive: pulled into scope for this run.
- Everything else is deferred and listed under **Not in this run**

---

## Step 3 — Resolve the spec and read context

Resolve `<spec-id>` per `${CLAUDE_PLUGIN_ROOT}/guides/spec-identifiers.md`, including when it's omitted.

Read:

- `.ptah/specs/<feature-name>/REVIEW.md` — the findings to fix
- `.ptah/specs/<feature-name>/PLAN.md` — the technical plan
- `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` — what was built
- `.ptah/specs/<feature-name>/LOGS.md` — session history, to understand current state

If `REVIEW.md` is empty or missing, stop:

> "No review found for `<spec-id>`. Run `/ptah:review <id>` first."

Check every code from the command arguments against the findings being fixed. A code that isn't there stops the command — don't guess which finding was meant:

> "`<code>` isn't a finding in `REVIEW.md` for `<id>`. Findings: `<codes>`."

Then find the project's standards per `${CLAUDE_PLUGIN_ROOT}/guides/project-standards.md`, reading only the parts that apply to the findings being fixed. Follow them, and cite a standard that shaped a fix on that finding's Fix Summary line.

---

## Step 4 — Apply fixes (mode-specific)

### Applying a finding

Apply a finding's `Fix:` at its own `file:line` and at every location on its `Also at:` line.

When a fix removes one failure mode but creates another, flag the trade where the templates below show it. It doesn't stop the run, even in `auto`.

While applying, post at most one short progress line per finding, such as `M1 done, running tests for M2…`, with no explanations.

### Directives by code

In `plan` and `interactive` modes, the user can steer individual findings by code in a free-form reply, several per message — e.g. "B2: use the existing validator instead. ignore M2. N3 is already fixed."

| Directive | Effect |
|---|---|
| A different approach for a code | Replaces the finding's `Fix:` line. Recorded as user-directed. |
| Ignore / skip | Finding moves to **Skipped** — reason: ignored by user, plus any reason given. |
| Already fixed | Finding moves to **Skipped** — reason: already fixed (per user). Not re-verified. |
| Drop instances — e.g. "N5: leave `api/b.ts:40`" | Those locations aren't fixed. The rest of the finding is applied and noted as dropped by user. |
| Code not mentioned | Handled as planned. |

- Match codes case-insensitively — `b2` is `B2`.
- A code that doesn't exist in the findings being fixed → stop and ask. Don't guess which finding was meant.
- A directive that's ambiguous about what to do → stop and ask.

`auto` mode shows no prompt, so it takes no directives.

### `auto` mode
Apply every in-scope fix without asking. The only interruption is the stop-and-ask rule for genuinely ambiguous fixes.

### `plan` mode
Before touching any code, present a fix plan:

```
Fix plan — <id>

B1 — <title>
   Change: <one-line summary of intended change>
   Files:  <comma-separated list of files to be modified>

M1 — <title> (+<n> instances)
   Change: <one-line summary> — trades <old failure mode> for <new>
   Files:  <files>

(+<n> instances only when the finding's `Also at:` isn't "none")
(N findings included only if include_minor is true; N and S findings named by code always included)

Not in this run: <out-of-scope codes, or "none">

Mode: plan
Total: <X> blockers, <Y> major<, Z minor if included>

Apply all of these? Reply "yes", or steer by code — e.g. "B2: do X instead, skip M1".
```

- **"yes" (or similar)** → apply the plan as shown.
- **Directives** → apply the plan with the directives folded in. A reply made of directives is itself the confirmation; don't re-prompt unless something needs clarifying.
- **A plain decline** → stop and ask what to do differently.

Once confirmed, apply all fixes in one pass.

### `interactive` mode
Work through in-scope findings one at a time. For each:

1. State the finding (code, title, `file:line`)
2. Describe the intended change in one or two lines, with the number of `Also at:` instances and any traded failure mode
3. Ask: "Apply this fix? (yes / skip / or tell me a different approach)"
4. Wait for the reply — any directive by code applies, including ones for findings later in the list
5. Apply, briefly note the result
6. Move to the next finding

The user can pause the loop or change direction at any point.

---

## Step 5 — Rules while fixing

These apply regardless of mode. Any of them hitting is a **Stop and ask** from `RULES.md`, even in `auto`:

- Fix only what is documented in the findings being fixed — do not refactor unrelated code
- If a fix requires a design change, stop and ask the user before proceeding
- A project standard conflicts with a finding's `Fix:` line
- If a fix introduces a new dependency not in the original design, ask first
- Keep fixes minimal and focused — don't improve things that aren't broken
- A hook blocks a tool call and complying needs a person. Handle every hook per `${CLAUDE_PLUGIN_ROOT}/guides/project-hooks.md`

---

## Step 6 — Record the fixes

### 6a. Fix Summary
Append a **Fix Summary** to the findings file `REVIEW.md`.

```markdown
## Fix Summary — <date>

### Mode
<auto | plan | interactive>

### Fixed
- [x] B1 — <title> — <brief note on how it was fixed>
- [x] B2 — <title> — <brief note> (user-directed: <the approach given>)
- [x] M1 — <title> — <brief note> (trades <old failure mode> for <new>)
- [x] M2 — <title> — <brief note> (dropped by user: <file:line>, …)
- [x] M4 — <title> — <brief note> (per <file>:<line>: <the standard>)
- [x] N1 — <title> — <brief note> (only if in scope this run; "(named by the user)" if pulled in by code)
- [x] S2 — <title> — <brief note> (named by the user)

### Skipped
- [ ] M3 — <title> — ignored by user<: reason, if given>
- [ ] N3 — <title> — already fixed (per user)
- [ ] B3 — <title> — blocked by a hook: <the hook's message>
<"None" if every in-scope finding was applied.>

### Deferred
- [ ] N2 — <title> — deferred: not in scope this run
- [ ] S1 — <title> — deferred: suggestion, not auto-fixed

### New issues found during fix
<Any new issues discovered while fixing. "None" if clean.>
```

The Fix Summary is structurally identical across all three modes. Every finding of the fixed pass appears exactly once — under Fixed, Skipped, or Deferred.

### 6b. Living artifacts and summary

Per **Artifact ownership** in `RULES.md`:

- If a fix changed behavior that `SPEC.md` or `PLAN.md` states, update that file.
- Add each file the fixes touched to `IMPLEMENTATION-SUMMARY.md` under **Changes after implementation**, with `fix <codes>` as the source.

### 6c. LOGS.md entry

Append `/fix completed` to `.ptah/specs/<feature-name>/LOGS.md` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, with `Next step:` per **Fix next step** in `${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md`: `none — no re-review needed; optional: /ptah:review <id>` when the verdict in `REVIEW.md` is `approved` and no new issues were found, `/ptah:review <id>` otherwise.

---

## Step 7 — Hand off to user

Hand off per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`.

```
/fix <id> completed
Artifact: `.ptah/specs/<feature-name>/REVIEW.md` (fix summary appended)
Mode: <mode> — fixed: <codes> · skipped: <codes, or "none"> · deferred: <codes, or "none">
New issues found: <"no", or "yes — <note>">
Manual steps:
- <step>
Next: <the entry's Next step:>
```

The `Manual steps` list appears only when the entry has `Manual steps:`.