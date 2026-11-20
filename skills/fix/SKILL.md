---
name: fix
description: 'Applies findings from a Ptah REVIEW.md in auto, plan, or interactive mode, lets the user steer or pull in findings by code, and appends a Fix Summary.'
argument-hint: '[<spec-id>] [codes…] [-a | -p | -i]'
disable-model-invocation: true
---

# /fix

Fix the findings in a spec's `REVIEW.md` and record what changed next to them.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

The arguments are an optional spec identifier (see `../../guides/spec-identifiers.md`), then optional finding codes, then an optional mode flag. A finding code is `P`, `S`, or `C` followed by digits. If the first positional is shaped like a code, or a comma-separated list of codes, the spec identifier was omitted and every positional is a code; otherwise the first positional is the spec identifier and the rest are codes. Commas, spaces, or both separate codes. Match codes case-insensitively everywhere, and drop duplicates.

`-a`, `-p`, `-i` pick this run's mode: `auto`, `plan`, `interactive`, per **Fix mode** in `../../guides/vocabulary.md`.

Examples:
- `/fix k3f9 C2 -p` — fixes only C2, in plan mode
- `/fix p1,s2` — the spec comes from the branch or this session; fixes only P1 and S2

Stop on any of these, with its message:

- A positional after the spec identifier that isn't shaped like a code: "`<arg>` isn't a finding code. Codes look like `P1`, `S2`, `C3`."
- More than one mode flag: "Conflicting flags: `<flag1>` and `<flag2>`. Pick one."
- Any other flag: "Unknown flag `-x`. Supported flags: `-a (auto)`, `-p (plan)`, `-i (interactive)`."

---

## Step 2 — Resolve the spec, mode and scope

Check the config per **Required keys** in `../../guides/config.md`, then resolve `<spec-id>` per `../../guides/spec-identifiers.md`. The mode is the flag if Step 1 found one, otherwise `commands.fix.mode`.

Read `REVIEW.md`, `PLAN.md` and `IMPLEMENTATION-SUMMARY.md` in `.ptah/specs/<feature-name>/`. If `REVIEW.md` is empty or missing, stop: "No review found for `<spec-id>`. Run `/ptah:review <id>` first." If a code from the arguments isn't a finding in `REVIEW.md`, stop: "`<code>` isn't a finding in `REVIEW.md` for `<id>`. Findings: `<codes>`."

The **scope** is every finding in `REVIEW.md`, defects and judgements alike, or only the named codes when the arguments name any. A finding with `Same as: <code>` travels with the finding it names: either one in scope brings in the other. Every finding outside the scope is **deferred**. In every count this command shows or logs, leave out a `Same as:` finding when the finding it names is of the same kind, so each problem counts once.

Find the project's standards per `../../guides/project-standards.md`, reading only the parts that apply to the findings in scope. Follow them while fixing.

The step is done when the mode is set and every finding in `REVIEW.md` is either in scope or deferred.

---

## Step 3 — Apply the fixes

### Applying a finding

Apply a finding's `Fix:` at its own `file:line` and at every location on its `Also at:` line. A `Same as:` finding gets no change of its own: the finding it names is fixed once, at the locations of both, using the named finding's `Fix:` even when the two disagree, since the earlier axis outranks the later.

Stay surgical: change only what the findings in scope document, with no refactoring of unrelated code and no improving what isn't broken. A fix that removes one failure mode but creates another is a trade: say so in the plan, the interactive prompt and the Fix Summary, and keep going, even in `auto`. While applying, post at most one short progress line per finding, such as `C1 done, running tests for C2…`, with no explanations.

Each of these is a **Stop and ask** from `RULES.md`, in every mode including `auto`:

- A fix needs a design change.
- A fix adds a dependency `PLAN.md` doesn't list.
- A project standard conflicts with a finding's `Fix:` line.

### Directives by code

In `plan` and `interactive`, the user can steer findings by code in a free-form reply, several per message, e.g. "C2: use the existing validator instead. ignore S1. P3 is already fixed."

| Directive | Effect |
|---|---|
| A different approach for a code | Replaces the finding's `Fix:` line. Recorded as user-directed. |
| Ignore / skip | Finding moves to **Skipped**: ignored by user, plus any reason given. |
| Already fixed | Finding moves to **Skipped**: already fixed (per user). Not re-verified. |
| Drop instances, e.g. "S5: leave `api/b.ts:40`" | Those locations aren't fixed. The rest of the finding is applied and noted as dropped by user. |

A directive for a code that isn't in scope, or one that's ambiguous about what to do, is a stop and ask.

### By mode

**`auto`**: apply every finding in scope without asking. Only the stop-and-ask cases above interrupt it.

**`plan`**: before touching any code, show a fix plan headed with the spec id. For each finding in scope, give its code and title, a one-line summary of the intended change (with any trade), and the files it will modify; when its `Also at:` isn't `none`, add the number of extra instances. Then list the deferred codes (or none), the mode, and the total per kind (e.g. 2 defects, 1 judgement), and ask whether to apply it all, inviting a "yes" or steering by code. A "yes" applies the plan as shown. A reply of directives applies the plan with them folded in: it is itself the confirmation, so re-ask only if something needs clarifying. A plain decline is a stop and ask about what to do differently.

**`interactive`**: work through the findings in scope one at a time. For each, state its code, title and `file:line`, describe the intended change in a line or two with its number of `Also at:` instances and any trade, and ask whether to apply it, skip it, or take a different approach. Wait for the reply; any directive by code applies, including ones for findings later in the list. Apply, and note the result briefly.

The step is done when every finding in scope is fixed or skipped.

---

## Step 4 — Record the fixes

Append a Fix Summary to `REVIEW.md`, in this format:

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
<"None" if every in-scope finding was applied.>

### Deferred
- [ ] P2 — <title> — deferred: not named this run
<"None" if no codes were given.>

### New issues found during fix
<Any new issues discovered while fixing. "None" if clean.>
```

Cite a standard on the line of each fix it shaped. Every finding in `REVIEW.md` appears exactly once, under Fixed, Skipped, or Deferred.

Update `SPEC.md`, `PLAN.md` and `IMPLEMENTATION-SUMMARY.md` per **Artifact ownership** in `RULES.md`.

Append `/fix completed` to `.ptah/specs/<feature-name>/LOGS.md` per `../../guides/logs-format.md`, with `Next step:` per **Fix next step** in `../../guides/vocabulary.md`.

---

## Step 5 — Hand off

Hand off per `../../guides/result-format.md`, with `.ptah/specs/<feature-name>/REVIEW.md` (fix summary appended) as the artifact. The key facts are the mode, the fixed, skipped and deferred codes (`none` where empty), and whether new issues were found, with a note if so. List the entry's manual steps, and end on its `Next step:`.
