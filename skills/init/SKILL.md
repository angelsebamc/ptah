---
name: init
description: 'Creates the project''s Ptah config at .ptah/ptah.yml: fix defaults, whether implement runs the review, and the ticket server. Optionally keeps .ptah/ out of git for this developer only.'
disable-model-invocation: true
---

# /init

Configure Ptah for this project.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Read the current config

Read `.ptah/ptah.yml`. If it exists, its values are the starting point; if it's missing, start from an empty config. If it isn't valid YAML, stop:

> "`.ptah/ptah.yml` isn't valid YAML. Fix it by hand, then re-run `/ptah:init`."

## Step 2 — Ask

Ask the four questions below. With each, show the current value when one is set; an empty reply keeps it. When nothing is set, an empty reply takes the recommended answer, or `no` for the ticket server. The step is done when every question that applies has an answer.

1. **Fix mode.** How `/ptah:fix` should apply review findings, noting that a flag overrides it for one run. Offer each value in **Fix mode** in `../../guides/vocabulary.md` with what it does, and recommend `plan`.

2. **Review after implement.** Whether `/ptah:implement` should run `/ptah:review` once the implementation is complete. Say that each review runs three subagents, and recommend `no`.

3. **Ticket server.** Whether the user pulls tickets from a tracker through an MCP server (Linear, JIRA, GitHub…), and if so which. Unless they answer `no`, match the answer case-insensitively against the names of the MCP servers available in this session (`linear` matches `claude_ai_Linear`). One match is `<server>`: tell the user which server you found. Several matches: ask which one. No match: list the available servers and ask. If there are none, or the user picks none, tell them to install or enable the server and re-run `/ptah:init`, and leave `tickets.server` unset.

4. **Keep `.ptah/` out of git.** Skip it if the project isn't a git repository (`git rev-parse --git-dir` fails). `<exclude>` is the path `git rev-parse --git-path info/exclude` prints, which also works in worktrees, where `.git` is a file.

   First find the current state. If `git ls-files .ptah` lists any file, the state is `tracked` and git already tracks `.ptah/`, so it can't be excluded locally: don't ask. Tell the user so, and that to stop tracking it they can run `git rm -r --cached .ptah` themselves and commit. Never run it for them. Otherwise `git check-ignore -v .ptah/` decides the state: exit `1` is `tracked`; exit `0` is `excluded locally` when the source in its output (`<source>:<line>:<pattern>`) is `<exclude>`, and `ignored by <source>` for any other source.

   Show the current state, then ask whether to keep `.ptah/` out of git for this developer only (yes / no). Explain that it goes in `.git/info/exclude`, which is never committed, so teammates aren't affected, but they won't see this developer's specs either.

## Step 3 — Write the config

Write `.ptah/ptah.yml`, creating `.ptah/` if needed:

```yaml
commands:
  implement:
    review: <true | false>
  fix:
    mode: <auto | plan | interactive>

tickets:
  server: <server>
```

Set only `commands.implement.review`, `commands.fix.mode` and `tickets.server`, and leave every other key as it was. Omit `tickets` when there's no ticket server.

## Step 4 — Apply the git choice

Act only if question 4 was asked and the answer changes the current state:

- **`yes` from `tracked`**: append the line `.ptah/` to `<exclude>`, creating the file and its folder if missing, starting on a new line, and skipping it if the line is already there.
- **`no` from `excluded locally`**: remove the line `.ptah/` from `<exclude>`, touching no other line. Run `git check-ignore -v .ptah/` again; if it still exits `0`, tell the user `.ptah/` is still ignored by `<pattern>` in `<source>`, and that they can change that rule themselves if they want it tracked.
- **`no` from `ignored by <source>`**: change nothing. Tell the user `.ptah/` is ignored by `<source>`, which `/ptah:init` doesn't edit, so they can change that rule themselves if they want it tracked.

The step is done when the git state matches the answer, or the user knows which rule they'd have to change.

## Step 5 — Hand off to user

```
/init completed
Artifact: `.ptah/ptah.yml`
implement: review <true | false>
fix: mode <mode>
ticket server: <server> | none
git: .ptah/ excluded locally | ignored by <source> | tracked
```

The `git:` line shows the state after Step 4, and is left out when question 4 was skipped because the project isn't a git repository.
