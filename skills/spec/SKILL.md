---
name: spec
description: 'Starts a new Ptah feature spec: creates the numbered spec folder (ptah-<n>-<slug>) and fills SPEC.md through a one-question-at-a-time conversation, optionally pre-filled from a third party provider ticket via MCP'
argument-hint: 'name=<feature-name> | <source>=<ticket-id>'
disable-model-invocation: true
---

If the current project has a Ptah config at `.ptah/ptah.yml` (relative to the project root, not the plugin folder) with external context sources configured (e.g. JIRA, Linear, GitHub), pre-fill parts of the spec from a linked ticket.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`

- **Empty** → show the examples below and stop.
- **No `=`** → the argument is a spec identifier: continue an unfinished spec (Step 3).
- **Otherwise** split on the **first** `=`:
  - `key` = text before the `=`, trimmed
  - `value` = everything after the `=`, trimmed (may contain spaces). If empty, show the examples and stop.
  - If `key` is `name`: plain spec, no ticket. `feature-name` = `value`.
  - Otherwise: `key` is the context source and `value` is the ticket ID.

Examples:
- `/ptah:spec name=user-login`: plain feature, no external ticket
- `/ptah:spec name=user login`: plain feature, no external ticket. If space-separated, turn it into kebab-case
- `/ptah:spec jira=PROJ-1234`: pulls context from JIRA ticket PROJ-1234
- `/ptah:spec 7`: continues spec 7, whose SPEC.md was never written

The feature name is **not** used as the folder name directly. It's kebab-cased into a slug, and the folder itself is numbered automatically from `ptah.yml`

---

## Step 2 — Load Ptah config and fetch external context (if any)

If `key` is a context source:

- If `.ptah/ptah.yml` does not exist in the current project, tell the user:
  > "No Ptah config found. Add `context_sources` to `.ptah/ptah.yml` to use tickets, or run `/ptah:spec name=<feature-name>` instead."
  Then stop.
- If `key` is not listed under `context_sources`, tell the user which sources are configured and stop.
- This plugin does not bundle MCP servers for ticket sources. If the source is configured but its MCP tools are not available in this session, tell the user to install or enable that MCP server and stop. Do not guess or fall back.

Otherwise, fetch the ticket with id `value` using that source's MCP tools.

DO NOT silently fall back if the ticket does not exist. Inform the user that the ticket does not exist and stop.

Report back to the user what was pulled in:

> "Loaded `value` ticket:
>
> The following spec fields will be pre-filled from the ticket:
> - Description ← ticket summary
> - Problem ← ticket description
> - Acceptance criteria ← ticket acceptance criteria
>
> I'll show each one during the spec conversation so you can confirm or edit."

---

## Step 3 — Create the folder structure

If Step 1 got a spec identifier:

1. Resolve it per **Spec identifiers** in `RULES.md`. If nothing matches, stop:
    > "No spec found for `<spec-id>`."
2. If that folder's `SPEC.md` exists and isn't empty, stop:
    > "Spec `<n>` already has a SPEC.md. Run `/ptah:resume <n>`."
3. Otherwise use that folder as `<slug>` and skip `new-spec` — no new folder, no change to `specs.next_id`. Tell the user:
    > "Continuing spec **`<n>`** at `.ptah/specs/<slug>/`."

Then go to Step 4. Ticket context isn't re-fetched, so ask every question normally.

Otherwise, run `new-spec <value>` (per **Ptah script** in `RULES.md`). It prints `<n> <slug>` after:

- taking `<n>` from `specs.next_id` in `.ptah/ptah.yml` (`1` if unset) and moving the counter to `<n + 1>`, leaving every other key untouched
- building `<slug>` as `ptah-<n>-<kebab>`, where `<kebab>` is `value` in kebab-case
- creating `.ptah/specs/<slug>/` with `LOGS.md`, `SPEC.md`, `PLAN.md`, `IMPLEMENTATION-SUMMARY.md`, `REVIEW.md`, and `refs/`

Numbers come only from the counter, never from existing folder names, and are never reused.

Confirm to the user that the folder was created, showing both the number and the full folder name:

> "Created spec **`<n>`** at `.ptah/specs/<slug>/`"

---

## Step 4 — Start the spec conversation

Tell the user:

> "Let's build out the spec together — I'll ask you a few questions to define a solid use case before moving to design."

Then guide the user through the following sections **one at a time**. Wait for their answer before asking the next question.

### If external context was loaded (Step 2):
For any question whose answer is pre-filled from the ticket, present the pre-filled value and ask for confirmation:

> "From the ticket: _<mapped value>_.
>
> Keep as-is, or rewrite?"

Accept edits. Don't force the user to retype something that's already good.

For sections without a mapping, ask normally.

### Questions to ask (in order):

1. **Description**
   > "In one sentence — what is this feature?"

2. **Problem**
   > "What problem does this solve for the user?"

3. **Use case**
   > "Walk me through the user flow step by step. What does the user do, what does the app do, what's the end result?"

4. **Acceptance criteria**
   > "How do we know this feature is done? List the conditions that must be true for it to be considered complete."

5. **References**
   > "Are there any screenshots, mockups, or other files I should put in `/refs`? If so, describe them or share them now."

6. **Out of scope**
   > "Is something explicitly NOT part of this feature?"

---

## Step 5 — Write SPEC.md

After all questions are answered, write the following to `SPEC.md`.

If external context was loaded and `backlink_header: true` is set in `ptah.yml`, include the source header at the top:

```markdown
# SPEC — <feature-name>

> **Source:** [<ticket-id>](<ticket-url>) — <ticket-title>

## Description
<one-line description>

## Problem
<why this feature matters>

## Use case
<step-by-step user flow>

## Acceptance criteria
- <criterion 1>
- <criterion 2>
- ...

## References
<list of files in /refs, or "none">

## Out of scope
- <item 1>
- <item 2>
- ...
```

---

## Step 6 — Append to LOGS.md

After writing SPEC.md, log `/spec completed` with `log command <n> spec completed`, with the fields from `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md` and `Next step: /ptah:plan <n>`.

---

## Step 7 — Hand off to user

After writing both files, hand off to the user per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`
