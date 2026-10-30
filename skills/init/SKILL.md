---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml: fix defaults and the ticket server.'
disable-model-invocation: true
model: haiku
---

# /init

Configure Ptah for this project. Every key is documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

## Step 1 — Read the current config

Read `.ptah/ptah.yml` (relative to the project root, not the plugin folder).

- **Missing** → start from an empty config.
- **Present** → show the user the current `commands.fix` and `tickets.server` values, if any.
- **Not valid YAML** → stop:
  > "`.ptah/ptah.yml` isn't valid YAML. Fix it by hand, then re-run `/ptah:init`."

  Never overwrite a file you couldn't parse.

## Step 2 — Ask, one question at a time

For each question, show the current value when set. An empty reply keeps it. When it's unset, an empty reply takes the recommended answer.

1. **Fix mode**
   > "How should `/ptah:fix` apply review findings? A flag overrides this for one run.
   > - `auto` — apply all in-scope fixes silently, report at the end
   > - `plan` — show a one-line-per-finding plan, wait for one confirmation (recommended)
   > - `interactive` — ask per finding"

2. **Include minor**
   > "Should `/ptah:fix` also fix minor findings? (yes / no — recommended no)"

3. **Ticket server**
   > "Do you pull tickets from a tracker through an MCP server (e.g. Linear, JIRA, GitHub)? If so, which one? (e.g. `linear` — or `no`)"

   On `no`, leave `tickets.server` out of the config and skip to Step 3. Otherwise find the MCP servers available in this session whose name contains the answer, case-insensitive (e.g. `linear` matches `claude_ai_Linear`):

   - **Exactly one** → `<server>` = its full name. Tell the user which server was found.
   - **More than one** → list them and ask which one to use.
   - **None** → list the available servers and ask which one to use. If there are none, or the user picks none, tell them to install or enable the server and re-run `/ptah:init`, and leave `tickets.server` unset.

## Step 3 — Write the config

Write `.ptah/ptah.yml`, creating `.ptah/` if it doesn't exist:

```yaml
commands:
  fix:
    mode: <auto | plan | interactive>
    include_minor: <true | false>

tickets:
  server: <server>
```

- Change only `commands.fix.mode`, `commands.fix.include_minor`, and `tickets.server`. Anything else — stays exactly as it was.
- Omit `tickets` if there's no ticket server.

## Step 4 — Hand off to user

```
/init completed
Artifact: `.ptah/ptah.yml`
fix: mode <mode>, include_minor <true | false>
ticket server: <server> | none
Next: /ptah:spec, or /ptah:spec <ticket-id>
```
