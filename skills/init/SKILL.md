---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml: fix defaults and the ticket server. Optionally keeps .ptah/ out of git for this developer only.'
disable-model-invocation: true
---

# /init

Configure Ptah for this project.

`RULES.md` is `${CLAUDE_PLUGIN_ROOT}/RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Read the current config

Read `.ptah/ptah.yml`.

- **Missing** → start from an empty config.
- **Present** → start from it.
- **Not valid YAML** → stop:
  > "`.ptah/ptah.yml` isn't valid YAML. Fix it by hand, then re-run `/ptah:init`."

## Step 2 — Ask

For each question, show the current value when set. An empty reply keeps it. When it's unset, an empty reply takes the recommended answer, or `no` for question 3.

1. **Fix mode**
   > "How should `/ptah:fix` apply review findings? A flag overrides this for one run."

   List each value in **Fix mode** in `${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md` with its behavior, and mark `plan` as recommended.

2. **Include minor**
   > "Should `/ptah:fix` also fix minor findings? (yes / no — recommended no)"

3. **Ticket server**
   > "Do you pull tickets from a tracker through an MCP server (e.g. Linear, JIRA, GitHub)? If so, which one? (e.g. `linear` — or `no`)"

   Unless the answer is `no`, find the MCP servers available in this session whose name contains the answer, case-insensitive (e.g. `linear` matches `claude_ai_Linear`):

   - **Exactly one** → `<server>` = its full name. Tell the user which server was found.
   - **More than one** → list them and ask which one to use.
   - **None** → list the available servers and ask which one to use. If there are none, or the user picks none, tell them to install or enable the server and re-run `/ptah:init`, and leave `tickets.server` unset.

4. **Keep `.ptah/` out of git**

   Skip this question if the project isn't a git repository (`git rev-parse --git-dir` fails). `<exclude>` is the path `git rev-parse --git-path info/exclude` prints. It works in worktrees too, where `.git` is a file.

   If `git ls-files .ptah` lists any file, git already tracks `.ptah/`. Its state is `tracked`. Don't ask. Tell the user instead:
   > "git already tracks files in `.ptah/`, so it can't be excluded locally. To stop tracking them, run `git rm -r --cached .ptah` yourself and commit."

   Never run `git rm --cached` for the user. Otherwise, get the current state from `git check-ignore -v .ptah/`:
   - exit `1` → `tracked`
   - exit `0`, and the source in its output (`<source>:<line>:<pattern>`) is `<exclude>` → `excluded locally`
   - exit `0`, any other source → `ignored by <source>`

   Show it as `currently: <state>`, then ask:
   > "Keep `.ptah/` out of git for you only? It's added to `.git/info/exclude`, which is never committed, so teammates aren't affected — but they won't see your specs either. (yes / no)"

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

- Change only `commands.fix.mode`, `commands.fix.include_minor`, and `tickets.server`. Leave every other key as it was.
- Omit `tickets` if there's no ticket server.

## Step 4 — Apply the git choice

Only if question 4 was asked and the answer changes the current state.

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
