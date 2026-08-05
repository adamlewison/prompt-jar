# 🍯 prompt jar

A jar of reusable prompts I reach into when working with Claude Code across my repos — standard procedures, checklists, and instructions I don't want to retype every time.

## How it's organized

Prompts live in [`prompts/`](./prompts), one file per prompt. Each file is a Claude Code [custom slash command](https://docs.claude.com/en/docs/claude-code/slash-commands#custom-slash-commands): a `description` frontmatter field, then the prompt text itself. The filename (minus `.md`) is the command name.

See [`prompts/TEMPLATE.md`](./prompts/TEMPLATE.md) for the format.

## What's in the jar

| Prompt | Use for |
|---|---|
| [🏠 house-rules](./prompts/house-rules.md) | Auditing, defining, enforcing and remediating a repo's architecture — file structure, naming, layer boundaries, size discipline |

## Install

```
curl -fsSL https://raw.githubusercontent.com/adamlewison/prompt-jar/main/install.sh | bash
```

This symlinks every prompt into `~/.claude/commands/`, so each one becomes a slash command — `/house-rules`, etc. — available in **any** project's Claude Code session, not just this repo. It's idempotent, so re-run it any time to pick up new or updated prompts.

Already have a local clone? Run `./install.sh` from the repo root instead — same effect, no re-cloning.

## Usage

Once installed, just invoke a prompt by name in any Claude Code session:

```
/house-rules
```

You can still grab a prompt manually without installing, e.g.:

```
cat prompts/some-prompt.md | claude
```

or just copy-paste the contents into a session.

## Adding a new prompt

Copy [`prompts/TEMPLATE.md`](./prompts/TEMPLATE.md) to `prompts/<name>.md`, fill in the `description` and prompt body, and add a row to the table above. Re-run `install.sh` (or the curl one-liner) to pick it up as `/<name>`.
