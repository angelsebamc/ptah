---
name: fix
description: 'Applies findings from a Ptah REVIEW.md in auto, plan, or interactive mode, lets the user steer by finding code, and appends a Fix Summary. Use when the user runs /fix with a spec number.'
argument-hint: '<spec-id> [-a | -p | -i]'
disable-model-invocation: true
---

# /fix

Read review findings and fix all blocker and major issues. Record what was changed next to the findings.

`/fix` works from:

- **A spec** — `/fix <spec-id>` — fixes findings from `.ptah/specs/<feature-name>/REVIEW.md`. This is the feature track.

Every finding carries a code assigned by the reviewer — `B1`, `B2` for blockers, `M1` for major, `N1` for minor, `S1` for suggestions.

`/fix` supports three modes that control how much the agent asks before applying fixes.

## Modes & config

`/fix` has three modes:

| Mode | Flag | Behavior |
|------|------|----------|
| `auto` | `-a` | Apply all in-scope fixes silently. Report at the end. Takes no directives. |
| `plan` | `-p` | Show a one-line-per-finding plan, wait for one reply — "yes" or directives by code — then apply all in one pass. **Default.** |
| `interactive` | `-i` | Ask per finding before applying. Directives by code work at every prompt. |

Mode is resolved with precedence **flag > config > default (`plan`)**.

### Config (`.ptah/ptah.yml`)

```yaml
commands:
  fix:
    mode: plan              # auto | plan | interactive
    include_minor: false    # also fix minor issues by default?
```

Both keys are optional. Missing keys fall back to defaults.

## Step 1 — Parse command arguments

The command takes exactly one source — a positional spec identifier (see **Spec identifiers** in `RULES.md`) plus optional flags.

Examples:
- `/fix 3` — uses mode from `ptah.yml`, or `plan` if no config
- `/fix 3 -a` — applies all fixes silently this run
- `/fix 3 -i` — asks per finding before applying it

**Source errors** stop the command:

- No spec identifier:
  > "`/fix` needs exactly one source: a spec number (`/fix 3`)."

**Mutually-exclusive flag pairs** produce an error and stop:
- `-a`, `-p`, `-i` (pick one)

> "Conflicting flags: `<flag1>` and `<flag2>`. Pick one."

**Unknown flags** produce an error consistent with `/spec`:

> "Unknown flag `-x`. Supported flags: `-a (auto)`, `-p (plan)`, `-i (interactive)`."

---

## Step 2 — Resolve mode and scope

Determine the effective mode and scope for this run. Precedence is **flag > config > default**.

### Load Ptah config

Read `.ptah/ptah.yml`.

- If the file doesn't exist, or `commands.fix` is missing → use defaults (`mode: plan`)
- If `commands.fix.mode` is set, validate it's a fix mode from `${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md`. Anything else → stop:
  > "Invalid `commands.fix.mode` value `<value>` in `ptah.yml`. Must be one of: `auto`, `plan`, `interactive`."

The config file is never modified by `/fix`. Flags only affect the current run.

### Compute in-scope findings
- Always in scope: blocker (`B`) and major (`M`) findings
- Minor (`N`) findings: in scope only when `commands.fix.include_minor` is `true`
- Any minor or suggestion (`S`) the user names by code in a directive: pulled into scope for this run
- Everything else is deferred and listed under **Not in this run**

---

## Step 3 — Resolve the spec and read context

Resolve `<spec-id>` per **Spec identifiers** in `RULES.md`.

Read:

- `.ptah/specs/<feature-name>/REVIEW.md` — the findings to fix
- `.ptah/specs/<feature-name>/PLAN.md` — the technical plan
- `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` — what was built
- `.ptah/specs/<feature-name>/LOGS.md` — session history, to understand current state

If `REVIEW.md` is empty or missing, stop:

> "No review found for `<spec-id>`. Run `/ptah:review <n>` first."

---

## Step 4 — Apply fixes (mode-specific)

### Directives by code

In `plan` and `interactive` modes, the user can steer individual findings by code in a free-form reply, several per message — e.g. "B2: use the existing validator instead. ignore M2. N3 is already fixed."

| Directive | Effect |
|---|---|
| A different approach for a code | Replaces the review's suggested fix for that finding. Recorded as user-directed. |
| Ignore / skip | Finding moves to **Skipped** — reason: ignored by user, plus any reason given. |
| Already fixed | Finding moves to **Skipped** — reason: already fixed (per user). Not re-verified. |
| Code not mentioned | Handled as planned. |

- Match codes case-insensitively — `b2` is `B2`.
- A code that doesn't exist in the findings being fixed → stop and ask. Don't guess which finding was meant.
- A directive that's ambiguous about what to do → stop and ask.

`auto` mode shows no prompt, so it takes no directives.

### `auto` mode
Apply every in-scope fix without asking. Do not narrate each fix as it happens — produce the Fix Summary at the end. The only interruption is the stop-and-ask rule for genuinely ambiguous fixes.

### `plan` mode (default)
Before touching any code, present a fix plan:

```
Fix plan — <n>

B1 — <title>
   Change: <one-line summary of intended change>
   Files:  <comma-separated list of files to be modified>

M1 — <title>
   Change: <one-line summary>
   Files:  <files>

(N findings included only if include_minor is true)

Not in this run: <out-of-scope codes, or "none">

Mode: plan
Total: <X> blockers, <Y> major<, Z minor if included>

Apply all of these? Reply "yes", or steer by code — e.g. "B2: do X instead, skip M1".
```

- **"yes" (or similar)** → apply the plan as shown.
- **Directives** → apply the plan with the directives folded in. A reply made of directives is itself the confirmation; don't re-prompt unless something needs clarifying.
- **A plain decline** → stop and ask what to do differently.

Once confirmed, apply all fixes in one pass without further narration.

### `interactive` mode
Work through in-scope findings one at a time. For each:

1. State the finding (code, title, `file:line`)
2. Describe the intended change in one or two lines
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
- If a fix introduces a new dependency not in the original design, ask first
- Keep fixes minimal and focused — don't improve things that aren't broken

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
- [x] M1 — <title> — <brief note>
- [x] N1 — <title> — <brief note> (only if in scope this run)
- [x] S2 — <title> — <brief note> (named by the user)

### Skipped
- [ ] M2 — <title> — ignored by user<: reason, if given>
- [ ] N3 — <title> — already fixed (per user)
<"None" if every in-scope finding was applied.>

### Deferred
- [ ] N2 — <title> — deferred: not in scope this run
- [ ] S1 — <title> — deferred: suggestion, not auto-fixed

### New issues found during fix
<Any new issues discovered while fixing. "None" if clean.>
```

The Fix Summary is structurally identical across all three modes. Every finding of the fixed pass appears exactly once — under Fixed, Skipped, or Deferred.

### 6b. LOGS.md entry

Append `/fix completed` to `.ptah/specs/<feature-name>/LOGS.md` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`, with `Next step: /ptah:review <n>`.

---

## Step 7 — Hand off to user

Hand off per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`.

```
/fix <n> completed
Artifact: `.ptah/specs/<feature-name>/REVIEW.md` (fix summary appended)
Mode: <mode> — fixed: <codes> · skipped: <codes, or "none"> · deferred: <codes, or "none">
New issues found: <"no", or "yes — <note>">
Next: /ptah:review <n>
```
