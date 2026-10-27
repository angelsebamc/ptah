---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml: fix defaults and ticket sources.'
disable-model-invocation: true
model: haiku
---

# /init

Configure Ptah for this project. Every key is documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

## Step 1 — Read the current config

Read `.ptah/ptah.yml` (relative to the project root, not the plugin folder).

- **Missing** → start from an empty config.
- **Present** → show the user the current `commands.fix` and `context_sources` values, if any.
- **Not valid YAML** → stop:
  > "`.ptah/ptah.yml` isn't valid YAML. Fix it by hand, then re-run `/ptah:init`."

  Never overwrite a file you couldn't parse.

## Step 2 — Ask, one question at a time

For each question, show the current value (or the default when unset). An empty reply keeps it.

1. **Fix mode**
   > "How should `/ptah:fix` apply review findings by default?
   > - `auto` — apply all in-scope fixes silently, report at the end
   > - `plan` — show a one-line-per-finding plan, wait for one confirmation (default)
   > - `interactive` — ask per finding"

2. **Include minor**
   > "Should `/ptah:fix` also fix minor findings by default? (yes / no — default no)"

3. **Ticket source**
   > "Do you pull tickets from a tracker through an MCP server (e.g. Linear, JIRA, GitHub)? If so, which source name will you type in `/ptah:spec <source>=<ticket-id>`? (e.g. `linear` — or `no`)"

   On `no`, skip to Step 3. Otherwise `<key>` = the answer, lowercased. Find the MCP servers available in this session whose name contains `<key>`, case-insensitive:

   - **Exactly one** → `<server>` = its full name. Tell the user which server was found.
   - **More than one** → list them and ask which one to use.
   - **None** → list the available servers and ask which one `<key>` should use. If there are none, or the user picks none, tell them to install or enable the server and re-run `/ptah:init`, and leave `context_sources.<key>` unset.

   Then ask whether there's another source, and repeat until the user says no.

## Step 3 — Write the config

Write `.ptah/ptah.yml`, creating `.ptah/` if it doesn't exist:

```yaml
commands:
  fix:
    mode: <auto | plan | interactive>
    include_minor: <true | false>

context_sources:
  <key>: <server>
```

- Change only `commands.fix.mode`, `commands.fix.include_minor`, and the `context_sources` entries the user answered. Anything else — stays exactly as it was.
- Omit `context_sources` if it has no entries.

## Step 4 — Hand off to user

```
/init completed
Artifact: `.ptah/ptah.yml`
fix: mode <mode>, include_minor <true | false>
ticket sources: <key> → <server>, … | none
Next: /ptah:spec name=<feature-name>, or /ptah:spec <key>=<ticket-id>
```
