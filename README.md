# 🍯 prompt jar

A jar of reusable prompts I reach into when working with Claude Code across my repos — standard procedures, checklists, and instructions I don't want to retype every time.

## How it's organized

Prompts live in [`prompts/`](./prompts), one file per prompt. Each file is plain Markdown: a short description up top, then the prompt text itself, ready to paste (or pipe) into Claude Code.

See [`prompts/TEMPLATE.md`](./prompts/TEMPLATE.md) for the format.

## Usage

Grab a prompt from the jar and hand it to Claude Code, e.g.:

```
cat prompts/some-prompt.md | claude
```

or just copy-paste the contents into a session.
