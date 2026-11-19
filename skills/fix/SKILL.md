---
name: fix
description: 'Applies findings from a Ptah REVIEW.md in auto, plan, or interactive mode, lets the user steer or pull in findings by code, and appends a Fix Summary.'
argument-hint: '[<spec-id>] [codes…] [-a | -p | -i]'
disable-model-invocation: true
---

# /fix

Read review findings and fix them. Record what was changed next to the findings.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

The command takes one source — an optional positional spec identifier (see `../../guides/spec-identifiers.md`) — then optional finding codes and flags.

- If the first positional is shaped like a finding code, or a comma-separated list of them, the spec identifier was omitted and every positional is a finding code. Otherwise the first positional is the spec identifier and every positional after it is a finding code.
- Codes are separated by commas, spaces, or both — `c1,c2`, `c1 c2`, and `c1, c2` are the same. Match codes case-insensitively everywhere, and drop duplicates.
- `-a`, `-p`, `-i` pick the mode for this run: `auto`, `plan`, `interactive`, per **Fix mode** in `../../guides/vocabulary.md`.

Examples:
- `/fix k3f9 C2 -p` — fixes only C2, in plan mode
- `/fix p1,s2` — the spec comes from the branch or this session; fixes only P1 and S2

A positional after the spec identifier that isn't shaped like a code (`P`, `S`, or `C` followed by digits) stops the command:

> "`<arg>` isn't a finding code. Codes look like `P1`, `S2`, `C3`."

More than one of `-a`, `-p`, `-i` stops the command:

> "Conflicting flags: `<flag1>` and `<flag2>`. Pick one."

**Unknown flags** produce an error and stop:

> "Unknown flag `-x`. Supported flags: `-a (auto)`, `-p (plan)`, `-i (interactive)`."

---

## Step 2 — Resolve mode and scope

Determine the effective mode and scope for this run. Precedence is **flag > `commands.fix.mode`**.

### Load Ptah config

Check the config per **Required keys** in `../../guides/config.md`.

### Compute in-scope findings
- In scope: every finding in `REVIEW.md`, defects and judgements alike. When the arguments name codes, only those findings.
- A finding with `Same as: <code>` is fixed together with the finding it names: either one in scope brings in the other. Every count this command shows or logs leaves it out when the finding it names is of the same kind, so each problem counts once.
- Everything else is deferred and listed under **Deferred**

---

## Step 3 — Resolve the spec and read context

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

Read:

- `.ptah/specs/<feature-name>/REVIEW.md` — the findings to fix
- `.ptah/specs/<feature-name>/PLAN.md` — the technical plan
- `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` — what was built

If `REVIEW.md` is empty or missing, stop:

> "No review found for `<spec-id>`. Run `/ptah:review <id>` first."

Check every code from the command arguments against the findings in `REVIEW.md`. A code that isn't there stops the command:

> "`<code>` isn't a finding in `REVIEW.md` for `<id>`. Findings: `<codes>`."

Then find the project's standards per `../../guides/project-standards.md`, reading only the parts that apply to the findings being fixed. Follow them, and cite a standard that shaped a fix on that finding's Fix Summary line.

---

## Step 4 — Apply fixes (mode-specific)

### Applying a finding

Apply a finding's `Fix:` at its own `file:line` and at every location on its `Also at:` line.

A finding with `Same as: <code>` gets no change of its own: the finding it names is fixed once, at the locations of both, with the named finding's `Fix:` line even when the two disagree, since the earlier axis outranks the later.

When a fix removes one failure mode but creates another, flag the trade where the templates below show it. It doesn't stop the run, even in `auto`.

While applying, post at most one short progress line per finding, such as `C1 done, running tests for C2…`, with no explanations.

### Directives by code

In `plan` and `interactive` modes, the user can steer individual findings by code in a free-form reply, several per message — e.g. "C2: use the existing validator instead. ignore S1. P3 is already fixed."

| Directive | Effect |
|---|---|
| A different approach for a code | Replaces the finding's `Fix:` line. Recorded as user-directed. |
| Ignore / skip | Finding moves to **Skipped** — reason: ignored by user, plus any reason given. |
| Already fixed | Finding moves to **Skipped** — reason: already fixed (per user). Not re-verified. |
| Drop instances — e.g. "S5: leave `api/b.ts:40`" | Those locations aren't fixed. The rest of the finding is applied and noted as dropped by user. |

- A code that doesn't exist in the findings being fixed → stop and ask.
- A directive that's ambiguous about what to do → stop and ask.

### `auto` mode
Apply every in-scope fix without asking. Only the rules in Step 5 interrupt it.

### `plan` mode
Before touching any code, present a fix plan:

```
Fix plan — <id>

P1 — <title>
   Change: <one-line summary of intended change>
   Files:  <comma-separated list of files to be modified>

C1 — <title> (+<n> instances)
   Change: <one-line summary> — trades <old failure mode> for <new>
   Files:  <files>

(+<n> instances only when the finding's `Also at:` isn't "none")

Deferred: <out-of-scope codes, or "none">

Mode: plan
Total: <count per kind, e.g. 2 defects, 1 judgement>

Apply all of these? Reply "yes", or steer by code — e.g. "C2: do X instead, skip S1".
```

- **"yes" (or similar)** → apply the plan as shown.
- **Directives** → apply the plan with the directives folded in. A reply made of directives is itself the confirmation; don't re-prompt unless something needs clarifying.
- **A plain decline** → stop and ask what to do differently.

### `interactive` mode
Work through in-scope findings one at a time. For each:

1. State the finding (code, title, `file:line`)
2. Describe the intended change in one or two lines, with the number of `Also at:` instances and any traded failure mode
3. Ask: "Apply this fix? (yes / skip / or tell me a different approach)"
4. Wait for the reply — any directive by code applies, including ones for findings later in the list
5. Apply, briefly note the result

---

## Step 5 — Rules while fixing

In every mode, change only what the findings being fixed document: don't refactor unrelated code or improve what isn't broken.

Each of these is a **Stop and ask** from `RULES.md`, even in `auto`:

- A fix needs a design change
- A fix adds a dependency `PLAN.md` doesn't list
- A project standard conflicts with a finding's `Fix:` line
- A hook blocks a tool call and complying needs a person. Handle every hook per `../../guides/project-hooks.md`

---

## Step 6 — Record the fixes

### 6a. Fix Summary
Append a **Fix Summary** to the findings file `REVIEW.md`.

```markdown
## Fix Summary — <date>

### Mode
<auto | plan | interactive>

### Fixed
- [x] P1 — <title> — <brief note on how it was fixed>
- [x] C1 — <title> — <brief note> (trades <old failure mode> for <new>)
- [x] C2 — <title> — <brief note> (user-directed: <the approach given>)
- [x] S2 — <title> — <brief note> (dropped by user: <file:line>, …)
- [x] C4 — <title> — <brief note> (per <file>:<line>: <the standard>)
- [x] S3 — <title> — fixed with C1

### Skipped
- [ ] S1 — <title> — ignored by user<: reason, if given>
- [ ] P3 — <title> — already fixed (per user)
- [ ] C3 — <title> — blocked by a hook: <the hook's message>
<"None" if every in-scope finding was applied.>

### Deferred
- [ ] P2 — <title> — deferred: not named this run
<"None" if no codes were given.>

### New issues found during fix
<Any new issues discovered while fixing. "None" if clean.>
```

Every finding of the fixed pass appears exactly once — under Fixed, Skipped, or Deferred.

### 6b. Living artifacts and summary

Update `SPEC.md`, `PLAN.md` and `IMPLEMENTATION-SUMMARY.md` per **Artifact ownership** in `RULES.md`.

### 6c. LOGS.md entry

Append `/fix completed` to `.ptah/specs/<feature-name>/LOGS.md` per `../../guides/logs-format.md`, with `Next step:` per **Fix next step** in `../../guides/vocabulary.md`.

---

## Step 7 — Hand off to user

Hand off per `../../guides/result-format.md`.

```
/fix <id> completed
Artifact: `.ptah/specs/<feature-name>/REVIEW.md` (fix summary appended)
Mode: <mode> — fixed: <codes> · skipped: <codes, or "none"> · deferred: <codes, or "none">
New issues found: <"no", or "yes — <note>">
Manual steps:
- <step>
Next: <the entry's Next step:>
```