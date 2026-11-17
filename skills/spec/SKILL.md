---
name: spec
description: 'Starts a new Ptah feature spec: creates the spec folder (<TICKET-ID>-<slug> from a ticket, <repo>-<code>-<slug> otherwise) and fills SPEC.md by grilling the developer in rounds of questions, looking facts up in the codebase instead of asking, optionally starting from a ticket fetched through the project''s ticket server'
argument-hint: '[<ticket-id> | <ticket-url>]'
disable-model-invocation: true
---

# /spec

If the spec comes from a ticket (e.g. JIRA, Linear, GitHub), start from it through the project's ticket server.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`, trimmed.

- **Empty** → a spec without a ticket.
- **A single token shaped like a ticket id** — a letter, then letters or digits, a `-`, then digits, e.g. `PROJ-1234` → a ticket spec. `<ticket-id>` = the argument, keeping its casing.
- **A single URL naming one ticket** — a token starting with `http://` or `https://` whose whole path segments and query-parameter values contain exactly one id shaped like a ticket id (case-insensitive) → a ticket spec. `<ticket-id>` = that id, keeping its casing:
  - `https://some-org.atlassian.net/jira/software/projects/PROJ/boards/12?selectedIssue=PROJ-1234` → `PROJ-1234`
  - `https://linear.app/some-org/issue/PROJ-41/some-title` → `PROJ-41`
- **Anything else** → show the examples below and stop.

Examples:
- `/ptah:spec`: plain feature, no external ticket. The name comes from your answers
- `/ptah:spec PROJ-1234`: pulls context from ticket PROJ-1234 through the project's ticket server
- `/ptah:spec https://some-org.atlassian.net/browse/PROJ-1234`: the same, with the ticket id taken from the URL

---

## Step 2 — Check the config and fetch the ticket (if any)

Check the config per **Required keys** in `../../guides/config.md`.

For a spec without a ticket, get `<repo>` now, per `../../guides/spec-identifiers.md`, so a missing git repository stops the command before the conversation.

For a ticket spec:

- `<server>` = `tickets.server` from `.ptah/ptah.yml`. If it's unset, stop:
  > "No ticket server is set for this project. Run `/ptah:init` to choose one."
- If no MCP server named `<server>` is available in this session, stop, listing the MCP servers that are available:
  > "MCP server `<server>` isn't available. Available servers: <list>. Install or enable it, or run `/ptah:init` to choose another."
- If a folder matching `.ptah/specs/<ticket-id>-*` (case-insensitive) already exists, stop — never create a second folder for the same ticket:
  > "Ticket `<ticket-id>` already has a spec at `.ptah/specs/<folder>/`. Run `/ptah:resume <ticket-id>`."

  A missing `.ptah/specs/` means no match. If the check itself fails, stop and show its error.

Otherwise, fetch the ticket with id `<ticket-id>` using that server's MCP tools.

If the ticket doesn't exist, stop:

> "Ticket `<ticket-id>` wasn't found on `<server>`."

Report back to the user what the ticket settles:

> "Loaded `<ticket-id>`: <ticket title>.
>
> The ticket settles:
> - <each thing it decides: what the feature is, why it matters, any acceptance criteria or flows it states>
>
> I'll treat those as decided and ask about what it leaves open."

---

## Step 3 — Grill the developer

Grill the developer relentlessly on what the feature must do. How to build it belongs to `/ptah:plan`.

### What the spec holds

The grill fills this template. Write one user story per actor and need. End each acceptance criterion with the id of the story it proves. For a ticket spec, include the `Source:` line linking back to the ticket. Omit it for a spec without a ticket.

```markdown
# SPEC — <feature-name>

> **Source:** [<ticket-id>](<ticket-url>) — <ticket-title>

## Description
<the feature in one sentence>

## Problem
<the problem it solves, from the user's perspective>

## User stories
- US1: As a <actor>, I want <need>, so that <benefit>.

## Use cases
<the main flow step by step (what the actor does, what the app does, the end result), then each alternate and error flow with the condition that triggers it>

## Acceptance criteria
- <a testable condition> (US1)

## References
<the files in refs/ and what each shows, or "none">

## Out of scope
<what the feature deliberately leaves out>
```

### Design tree

The open decisions form a **design tree**. Its branches reach every section of the spec, plus the existing features, data and APIs the feature touches; probe each flow for empty states, failures and edge cases. Ask only what changes the spec.

### Facts are yours, decisions are the user's

Look facts up per **Stop and ask** in `RULES.md`: read the files, or dispatch an Explore subagent for a wide search. A running lookup holds back only the questions that depend on it; ask the rest now.

For a ticket spec, what the ticket settles is decided. Ask only about what it leaves open or gets wrong against the code.

### Rounds

Work the tree in rounds. The **frontier** is every decision whose prerequisites are settled (error flows wait on the main flow, criteria on the stories). Ask the whole frontier, then wait for the reply:

```
**1. <short title>**
<the question, with options when there are a few clear ones>
Recommended: <your answer, and why in a few words>
```

Word each question so "yes" accepts the recommendation. Separate rounds with `---`.

Each reply moves the frontier: recompute it and ask the next round.

### Done

The grill is done when the frontier is empty: every branch visited, nothing in the spec silently assumed. Then:

1. Check that every story has at least one acceptance criterion and every criterion proves a story. Ask about any gap as another round.
2. Show the user a summary of the spec, and ask them to confirm or correct it.

---

## Step 4 — Create the folder structure

`<id>` is the spec's display id per `../../guides/spec-identifiers.md`.

### 4a. Get the id
- **From a ticket** — no code; go to 4b.
- **Without a ticket** — generate `<code>` by running, in a POSIX shell:

  ```sh
  LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4
  ```

  or in PowerShell:

  ```powershell
  -join (1..4 | ForEach-Object { 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray() | Get-Random })
  ```

  If any folder in `.ptah/specs/` starts with `<repo>-<code>-`, run it again. Never make up a code or pick one yourself.

### 4b. Name the feature
- **From a ticket** — `<feature-name>` = the ticket's title.
- **Without a ticket** — infer `<feature-name>` from the Description and Problem the grill settled: a short phrase naming what the feature does, e.g. `user login`. Don't ask the user for it.

### 4c. Build the folder name
`<kebab>` is `<feature-name>` in kebab-case, per `../../guides/spec-identifiers.md`. If `<kebab>` is longer than 50 characters, cut it at the last `-` before the 50th character.

- **From a ticket** — `<folder>` = `<ticket-id>-<kebab>`
- **Without a ticket** — `<folder>` = `<repo>-<code>-<kebab>`

### 4d. Create the folder
Create the following structure at `.ptah/specs/<folder>/`:

```
.ptah/specs/<folder>/
  LOGS.md
  SPEC.md
  refs/
```

---

## Step 5 — Write SPEC.md

Write the spec the user confirmed to `SPEC.md`

---

## Step 6 — Append to LOGS.md

Append a `/spec completed` entry to `.ptah/specs/<folder>/LOGS.md` per `../../guides/logs-format.md`.

---

## Step 7 — Hand off to user

Hand off to the user per `../../guides/result-format.md`. For a spec without a ticket, include the inferred name among the key facts, e.g. `Feature: user login`.
