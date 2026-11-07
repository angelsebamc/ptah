# Project standards

Find the target project's standards: every file in it that documents how code should be written or how the product should behave — docs, and the instructions the project gives any coding agent (`CLAUDE.md`, `AGENTS.md`, rules, skills). Read the parts relevant to the feature, and cite a standard as `<file>:<line>`. Invoke a skill that applies; read it as a file when it can't be invoked, and follow it only as far as your own job allows.

The project's hook config is a standard too: `.claude/settings.json`, `.claude/settings.local.json`, the hooks of the plugins the project enables, and `hooks` in the frontmatter of the project's skills and agents. When a hook's matcher covers a tool call the feature needs, read its script to learn what it blocks.
