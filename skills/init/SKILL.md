---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml: fix defaults and the ticket server. Optionally keeps .ptah/ out of git for this developer only.'
disable-model-invocation: true
---

# /init

Configure Ptah for this project. Every key is documented in `${CLAUDE_PLUGIN_ROOT}/guides/config.md`.

`RULES.md` is `${CLAUDE_PLUGIN_ROOT}/RULES.md`. Read it before Step 1 unless its full text is already in your context.

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
   > - `auto` — apply all in-scope fixes without asking, report at the end
   > - `plan` — show a one-line-per-finding plan, wait for one confirmation (recommended)
   > - `interactive` — ask per finding"

2. **Include minor**
   > "Should `/ptah:fix` also fix minor findings? (yes / no — recommended no)"

3. **Ticket server**
   > "Do you pull tickets from a tracker through an MCP server (e.g. Linear, JIRA, GitHub)? If so, which one? (e.g. `linear` — or `no`)"

   On `no`, leave `tickets.server` out of the config and go to question 4. Otherwise find the MCP servers available in this session whose name contains the answer, case-insensitive (e.g. `linear` matches `claude_ai_Linear`):

   - **Exactly one** → `<server>` = its full name. Tell the user which server was found.
   - **More than one** → list them and ask which one to use.
   - **None** → list the available servers and ask which one to use. If there are none, or the user picks none, tell them to install or enable the server and re-run `/ptah:init`, and leave `tickets.server` unset.

4. **Keep `.ptah/` out of git**

   Skip this question if the project isn't a git repository (`git rev-parse --git-dir` fails). If `git ls-files .ptah` lists any file, git already tracks `.ptah/` and excluding it would do nothing. Its state is `tracked`. Don't ask. Tell the user instead:
   > "git already tracks files in `.ptah/`, so it can't be excluded locally. To stop tracking them, run `git rm -r --cached .ptah` yourself and commit."

   Never run `git rm --cached` for the user. Otherwise, get the current state from `git check-ignore -v .ptah/`:
   - exit `1` → `tracked`
   - exit `0`, and the source in its output (`<source>:<line>:<pattern>`) is the same file `git rev-parse --git-path info/exclude` names → `excluded locally`
   - exit `0`, any other source → `ignored by <source>`

   Show the state as the current value (`currently: <state>`), then ask:
   > "Keep `.ptah/` out of git for you only? It's added to `.git/info/exclude`, which is never committed, so teammates aren't affected — but they won't see your specs either. (yes / no)"

   An empty reply keeps the current state.

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

## Step 4 — Apply the git choice

Only if question 4 was asked and the answer changes the current state. `<exclude>` is the path `git rev-parse --git-path info/exclude` prints. It works in worktrees too, where `.git` is a file. The choice is never stored in `.ptah/ptah.yml`: git holds it.

- **`yes`, state `tracked`** → append the line `.ptah/` to `<exclude>`, creating the file and its folder if missing. Start on a new line if the file doesn't end with one, and don't add the line if it's already there.
- **`no`, state `excluded locally`** → remove the line `.ptah/` from `<exclude>`, and touch no other line. Then run `git check-ignore -v .ptah/` again. If it still exits `0`, tell the user:
  > "`.ptah/` is still ignored by `<pattern>` in `<source>`. Change that rule yourself if you want it tracked."
- **`no`, state `ignored by <source>`** → change nothing. Tell the user:
  > "`.ptah/` is ignored by `<source>`, which `/ptah:init` doesn't edit. Change that rule yourself if you want it tracked."

## Step 5 — Hand off to user

```
/init completed
Artifact: `.ptah/ptah.yml`
fix: mode <mode>, include_minor <true | false>
ticket server: <server> | none
git: .ptah/ excluded locally | ignored by <source> | tracked
Next: /ptah:spec, or /ptah:spec <ticket-id>
```

The `git:` line shows the state after Step 4. Omit it if question 4 was skipped because the project isn't a git repository.
