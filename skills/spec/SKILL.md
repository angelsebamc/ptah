---
name: spec
description: 'Starts a new Ptah feature spec: creates the spec folder (<TICKET-ID>-<slug> from a ticket, <repo>-<n>-<slug> otherwise) and fills SPEC.md through a one-question-at-a-time conversation, optionally pre-filled from a ticket through the project''s ticket server'
argument-hint: '[<ticket-id>]'
disable-model-invocation: true
---

# /spec

If the spec comes from a ticket (e.g. JIRA, Linear, GitHub), pre-fill parts of it through the project's ticket server. Config keys are documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`, trimmed.

- **Empty** → a spec without a ticket. Its name is inferred from the spec conversation in Step 4.
- **A single token shaped like a ticket id** — a letter, then letters or digits, a `-`, then digits, e.g. `PROJ-1234` → a ticket spec. `<ticket-id>` = the argument, keeping its casing.
- **Anything else** → show the examples below and stop.

Examples:
- `/ptah:spec`: plain feature, no external ticket. The name comes from your answers
- `/ptah:spec PROJ-1234`: pulls context from ticket PROJ-1234 through the project's ticket server

Neither the inferred name nor the ticket title is used as the folder name directly. Each is kebab-cased into a slug. A ticket spec's folder starts with the ticket id; any other spec's folder starts with the repository name and is numbered automatically from `ptah.yml`.

---

## Step 2 — Check the config and fetch the ticket (if any)

Check the config per **Required keys** in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

For a spec without a ticket, get `<repo>` now, per **Spec identifiers** in `RULES.md`, so a missing git repository stops the command before the conversation.

For a ticket spec:

- `<server>` = `tickets.server` from `.ptah/ptah.yml`. If it's unset, stop:
  > "No ticket server is set for this project. Run `/ptah:init` to choose one."
- If no MCP server named `<server>` is available in this session, stop, listing the MCP servers that are available:
  > "MCP server `<server>` isn't available. Available servers: <list>. Install or enable it, or run `/ptah:init` to choose another."

  Do not guess or fall back to another server.
- If a folder matching `.ptah/specs/<ticket-id>-*` (case-insensitive) already exists, stop — never create a second folder for the same ticket:
  > "Ticket `<ticket-id>` already has a spec at `.ptah/specs/<folder>/`. Run `/ptah:resume <ticket-id>`."

Otherwise, fetch the ticket with id `<ticket-id>` using that server's MCP tools.

DO NOT silently fall back if the ticket does not exist. Inform the user that the ticket does not exist and stop.

Report back to the user what was pulled in:

> "Loaded `<ticket-id>` ticket:
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
- **Without a ticket** — read `specs.next_id` from `.ptah/ptah.yml` in the current project. If the `specs` section or `next_id` key is missing, treat the next id as `1`. Otherwise, use `specs.next_id` as `<n>`. `<id>` = `<n>`.

### 4b. Name the feature
- **From a ticket** — `<feature-name>` = the ticket's title.
- **Without a ticket** — infer `<feature-name>` from the Description and Problem answers: a short phrase naming what the feature does, e.g. `user login`. Don't ask the user for it.

### 4c. Build the slug
`<kebab>` is `<feature-name>` in kebab-case, per **Spec identifiers** in `RULES.md`. If `<kebab>` is longer than 50 characters, cut it at the last `-` before the 50th character.

- **From a ticket** — `slug` = `<ticket-id>-<kebab>`, e.g. `PROJ-45-add-csv-export`
- **Without a ticket** — `slug` = `<repo>-<n>-<kebab>`, e.g. `some-web-3-user-login`

### 4d. Create the folder
Create the following structure at `.ptah/specs/<slug>/`:

```
.ptah/specs/<slug>/
  LOGS.md
  SPEC.md
  refs/
```

### 4e. Update the counter
Only for a spec without a ticket. Write `specs.next_id: <n + 1>` back to `.ptah/ptah.yml` in the current project:

- If it has no `specs:` section, add one.
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

After writing both files, hand off to the user per `${CLAUDE_PLUGIN_ROOT}/guides/result-format.md`. For a spec without a ticket, include the inferred name among the key facts, e.g. `Feature: user login`.
