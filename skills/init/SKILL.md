---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml.'
disable-model-invocation: true
model: haiku
---

# /init

Configure Ptah's command defaults for this project.

## Step 1 — Read the current config

Read `.ptah/ptah.yml` (relative to the project root, not the plugin folder).

- **Missing** → start from an empty config.
- **Present** → show the user the current `commands.fix` values, if any.
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

## Step 3 — Write the config

Write `.ptah/ptah.yml`, creating `.ptah/` if it doesn't exist:

```yaml
commands:
  fix:
    mode: <auto | plan | interactive>
    include_minor: <true | false>
```

- Change only `commands.fix.mode` and `commands.fix.include_minor`. Anything else — stays exactly as it was.

## Step 4 — Hand off to user

```
/init completed
Artifact: `.ptah/ptah.yml`
fix: mode <mode>, include_minor <true | false>
Next: /ptah:spec name=<feature-name>
```
