---
name: spec
description: 'Starts a new Ptah feature spec: creates the spec folder (<TICKET-ID>-<slug> from a ticket, ptah-<n>-<slug> otherwise) and fills SPEC.md through a one-question-at-a-time conversation, optionally pre-filled from a third party provider ticket via MCP'
argument-hint: 'name=<feature-name> | <source>=<ticket-id>'
disable-model-invocation: true
---

If the spec comes from a ticket (e.g. JIRA, Linear, GitHub), pre-fill parts of it through that source's MCP server. Config keys are documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`

- **Empty, or no `=`** → show the examples below and stop.
- **Otherwise** split on the **first** `=`:
  - `key` = text before the `=`, trimmed
  - `value` = everything after the `=`, trimmed (may contain spaces). If empty, show the examples and stop.
  - If `key` is `name`: plain spec, no ticket. `feature-name` = `value`.
  - Otherwise: `key` is the context source and `value` is the ticket ID.

Examples:
- `/ptah:spec name=user-login`: plain feature, no external ticket
- `/ptah:spec name=user login`: plain feature, no external ticket. If space-separated, turn it into kebab-case
- `/ptah:spec jira=PROJ-1234`: pulls context from JIRA ticket PROJ-1234

Neither the feature name nor the ticket title is used as the folder name directly. Each is kebab-cased into a slug. A ticket spec's folder starts with the ticket id; any other spec's folder is numbered automatically from `ptah.yml`.

---

## Step 2 — Resolve the ticket source and fetch the ticket (if any)

If `key` is a context source:

- `<server>` = `context_sources.<key>` from `.ptah/ptah.yml` if that alias is set, otherwise `key`. A missing `ptah.yml` is fine.
- Find the MCP servers available in this session whose name contains `<server>`, case-insensitive (e.g. `linear` matches `claude_ai_Linear`).
  - **None** → stop, listing the MCP servers that are available:
    > "No MCP server matching `<server>` is available. Available servers: <list>. Install or enable the server, or map `<key>` to one of these under `context_sources` in `.ptah/ptah.yml`."
  - **More than one** → stop, list them, and ask which one to use. Suggest mapping `<key>` to it under `context_sources` so the next run doesn't ask.
  - **Exactly one** → use it. Do not guess or fall back to another server.
- Set `<ticket-id>` = `value`, keeping its casing. If `value` is only digits, set it to `<key>-<value>` instead, e.g. `github-123`. If a folder matching `.ptah/specs/<ticket-id>-*` (case-insensitive) already exists, stop — never create a second folder for the same ticket:
  > "Ticket `<ticket-id>` already has a spec at `.ptah/specs/<folder>/`. Run `/ptah:resume <ticket-id>`."

Otherwise, fetch the ticket with id `value` using that server's MCP tools.

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

## Step 3 — Start the spec conversation

Nothing is written to disk until every question is answered. An interrupted conversation leaves no trace and starts over.

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

## Step 4 — Create the folder structure

`<id>` is the spec's display id per **Spec identifiers** in `RULES.md`.

### 4a. Get the id
- **From a ticket** — `<id>` = `<ticket-id>`. Ticket specs take no number.
- **Without a ticket** — read `specs.next_id` from `.ptah/ptah.yml` in the current project. If the file doesn't exist, or the `specs` section or `next_id` key is missing, treat the next id as `1`. Otherwise, use `specs.next_id` as `<n>`. `<id>` = `<n>`.

### 4b. Build the slug
`<kebab>` is the source text in kebab-case: lowercase, spaces and underscores → `-`, other punctuation removed. The source text is the ticket's title for a ticket spec, and `value` otherwise. If `<kebab>` is longer than 50 characters, cut it at the last `-` before the 50th character.

- **From a ticket** — `slug` = `<ticket-id>-<kebab>`, e.g. `PROJ-45-add-csv-export`
- **Without a ticket** — `slug` = `ptah-<n>-<kebab>`, e.g. `ptah-3-user-login`

### 4c. Create the folder
Create the following structure at `.ptah/specs/<slug>/`:

```
.ptah/specs/<slug>/
  LOGS.md
  SPEC.md
  refs/
```

### 4d. Update the counter
Only for a spec without a ticket. Write `specs.next_id: <n + 1>` back to `.ptah/ptah.yml` in the current project:

- If `ptah.yml` didn't exist yet, create it containing just:
```yaml
specs:
  next_id: <n + 1>
```
- If it existed but had no `specs:` section, add one.
- Leave every other key in `ptah.yml` untouched.

Never infer the next number from existing folder names. Numbers are never reused, even if a folder is deleted — the counter only moves forward.

---

## Step 5 — Write SPEC.md

Write the following to `SPEC.md`.

For a ticket spec, include the `Source:` line linking back to the ticket. Omit it for a spec without a ticket.

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

After writing SPEC.md, append a `/spec completed` entry to `.ptah/specs/<slug>/LOGS.md` per `${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md`

---

## Step 7 — Hand off to user

After writing both files, hand off to the user per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`
