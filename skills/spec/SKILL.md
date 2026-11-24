---
name: spec
description: 'Starts a new Ptah feature spec: settles it by grilling the developer in rounds of questions (or from a grill earlier in the conversation), looking facts up in the codebase instead of asking, optionally starting from a ticket fetched through the project''s ticket server. Writes SPEC.md in a new spec folder (<TICKET-ID>-<slug> from a ticket, <repo>-<code>-<slug> otherwise), or files the spec as a ticket on the ticket server'
argument-hint: '[<ticket-id> | <ticket-url>]'
disable-model-invocation: true
---

# /spec

Grill the developer until every decision the spec needs is settled, then write `SPEC.md` in a new spec folder, or file the spec as a ticket for someone to pull later. A ticket, when given, is the starting point.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`, trimmed.

- **Empty** → a spec without a ticket.
- **One token shaped like a ticket id**, per **Ticket ids** in `../../guides/spec-identifiers.md` → a ticket spec, with `<ticket-id>` = the token.
- **One URL that gives a ticket id**, per **A ticket id from a URL** in that guide → a ticket spec, with `<ticket-id>` = that id.
- **Anything else** → show the examples below and stop.

`<ticket-id>` keeps the casing it was given in.

Examples:
- `/ptah:spec`: plain feature, no external ticket. The name comes from your answers
- `/ptah:spec PROJ-1234`: pulls context from ticket PROJ-1234 through the project's ticket server
- `/ptah:spec https://some-org.atlassian.net/browse/PROJ-1234`: the same, with the ticket id taken from the URL

---

## Step 2 — Check the config and fetch the ticket

Check the config per **Required keys** in `../../guides/config.md`.

Without a ticket, get `<repo>` now, per `../../guides/spec-identifiers.md`, so a missing git repository stops the command before the grill instead of after it.

With a ticket, fetch it per **Fetching a ticket** in `../../guides/tickets.md`.

Tell the user which ticket you loaded (id and title) and list what it settles: what the feature is, why it matters, and any acceptance criteria or flows it states. Say you'll treat those as decided and ask only about what it leaves open.

---

## Step 3 — Grill the developer

Grill the developer relentlessly on what the feature must do. How to build it belongs to `/ptah:plan`.

### What the spec holds

The grill fills this template. Write one user story per actor and need, and end each acceptance criterion with the id of the story it proves. The `Source:` line is for a ticket spec only.

```markdown
# SPEC — <feature-name>

> **Source:** [<ticket-id>](<ticket-url>) — <ticket-title>

## Problem
<The problem that the user is facing, from the user's perspective>

## Solution
<The solution to the problem, from the user's perspective>

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

### Running the grill

Run the `ptah:grill` skill on the feature, with the spec as the design concept it settles. Its design tree reaches every section of the template plus the existing features, data and APIs the feature touches; its frontier holds error flows back until the main flow is settled, and criteria until the stories are. On a ticket spec, what the ticket settles is decided: ask only about what it leaves open or gets wrong against the code. Decisions the user already confirmed earlier in this conversation are settled the same way. On a spec without a ticket, a grill of this feature earlier in the conversation is the starting point: write the spec from the design concept it settled, and when it left nothing the template needs open, go straight to the summary.

On top of the grill's own done check, every story is proved by at least one acceptance criterion and every criterion proves a story. The summary the user confirms is a summary of the spec.

---

## Step 4 — Choose where the spec goes

**`<feature-name>`** is the ticket's title. Without a ticket, infer it from the Problem and Solution the grill settled, without asking: a short phrase naming what the feature does, e.g. `user login`.

A ticket spec goes to a spec folder, and so does a spec without a ticket when `<server>`, the `tickets.server` in `.ptah/ptah.yml`, is unset or isn't an MCP server available in this session: go on to Step 5. Otherwise ask the developer whether to file the spec on the ticket server or create a spec folder; on a folder, go on to Step 5.

To file it, ask which project the ticket goes to, along with anything else `<server>` needs to create an issue, offering the ones it has. Create the issue with `<server>`'s MCP tools: titled `<feature-name>`, with the confirmed spec as its description, in the Step 3 template without the `# SPEC` heading and `Source:` line, and labeled `ready-to-develop`, creating that label on `<server>` if it doesn't exist. The issue is filed when it exists with that title, description and label. If it can't be created, stop and show the error: "Couldn't create the ticket on `<server>`: <error>."

Hand off per `../../guides/result-format.md`, with the new ticket's id as `<id>`, its URL as the artifact, and `Feature: <feature-name>` and the project among the key facts. There's no `LOGS.md` entry, and the command ends here.

---

## Step 5 — Create the spec folder

Name the folder per `../../guides/spec-identifiers.md`, with `<slug>` from `<feature-name>`: `<ticket-id>-<slug>` for a ticket spec, `<repo>-<code>-<slug>` otherwise.

**`<code>`** (no ticket only) always comes from the shell, never from you. Run, in a POSIX shell:

```sh
LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4
```

or in PowerShell:

```powershell
-join (1..4 | ForEach-Object { 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray() | Get-Random })
```

If a folder in `.ptah/specs/` already starts with `<repo>-<code>-`, run it again.

Create `.ptah/specs/<folder>/` holding `LOGS.md`, `SPEC.md`, and an empty `refs/`.

---

## Step 6 — Write, log, and hand off

Write the spec the user confirmed to `.ptah/specs/<folder>/SPEC.md`, in the template from Step 3.

Append a `/spec completed` entry to `.ptah/specs/<folder>/LOGS.md` per `../../guides/logs-format.md`.

Hand off per `../../guides/result-format.md`, naming the spec by its display id `<id>` per **Displaying an identifier** in `../../guides/spec-identifiers.md`. Without a ticket, include the inferred name among the key facts, e.g. `Feature: user login`.
