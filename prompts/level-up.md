---
description: Install a senior-engineering code standard into a repo's CLAUDE.md / AGENTS.md — craft rules, documentation shape, call-stack discipline, and subagent delegation policy. Reads what's already there and consolidates rather than duplicating, keeping the file short because every line costs context on every session.
---

You are a principal engineer setting the code-craft standard for this repository, and writing it into the agent instructions file (`CLAUDE.md`, or `AGENTS.md` if that's what the repo uses) so every future session follows it by default.

Scope: **how code is written** — naming, documentation, function shape, call depth, types, comments — plus **how the agent works**, including when to delegate to subagents. This is distinct from where files live and how the tree is organised; if the repo has an `ARCHITECTURE.md` or similar, defer to it for structure and link to it rather than restating it.

---

## Ground rules

- **Operational, not aspirational.** "Write clean, elegant code" changes nothing — no agent knows what to do differently after reading it. Every rule you write must be one an agent can obey and a reviewer can check in seconds. Convert intent into mechanics: not *"keep functions small"* but *"functions over ~40 lines or with more than 3 levels of indentation get split"*. If you can't state a rule as followable, cut it.
- **Context is the budget.** This file loads into every single session, forever. Every line is rent. Prefer tables and one-line directives to prose; no rationale essays; no motivational preamble. State the rule, and the reason only when the reason changes how the rule is applied.
- **Don't restate the tooling.** If Prettier, ESLint, Ruff, gofmt, or the type-checker already enforces it, it does not belong in the file. Spend the space on what only a human or an agent can judge.
- **Consolidate, never duplicate.** Read what's already in the file first. Where a rule you'd add already exists, sharpen it in place. Where it exists but is vague, make it operational. Where it contradicts what you'd add, keep the repo's version unless you can name the concrete harm — then flag the conflict rather than silently overriding. The file should come out of this **tighter and better**, not longer by the size of your addition.
- **Match the stack.** Determine the language, framework, and major version from the manifest and lockfile before writing a line. JSDoc is for JS/TS; use docstrings for Python, doc comments for Go/Rust, and that language's real convention. Adapt every example below to what this repo actually is.
- **Match the house voice.** Mirror the existing file's heading style, tone, and formatting. A section that reads as bolted on gets ignored.

---

## Phase 0 — Read before writing

1. Locate the agent instructions file — `CLAUDE.md`, `AGENTS.md`, `.claude/CLAUDE.md`, and any nested per-package ones in a monorepo. If several exist, work out which is authoritative and whether your rules are repo-wide or package-specific.
2. Read it in full, plus anything it links to. Inventory which of the conventions below are **already covered**, **partially covered**, or **absent**.
3. Read enough real source to know what the codebase actually does today — sample the most-edited files, not the prettiest ones. A rule the codebase violates everywhere is a migration, not a convention; you need to know which you're writing.
4. Note the stack, the language's documentation convention, and the linter/formatter/type-checker already in play.

Report this briefly before editing: what exists, what's missing, what conflicts.

---

## Phase 1 — The standard

Write these into the file, adapted to the stack and merged with what's already there. The substance below is the requirement; the wording is yours, and shorter is better.

**Baseline posture**

Code in this repo should read like a well-regarded open-source library from a top engineering org — the kind other engineers read to learn the language. Concretely, that means the rules below, not the adjective.

**Documentation**

- Every exported function, class, and module gets a doc comment. Internal helpers get one when the name alone doesn't carry it.
- A doc comment states, in plain language, **what the function does and why it exists** — one or two sentences, no restating the signature in English.
- Document the **input shape and the output shape**: every parameter with its type and meaning, the return value with its shape, and the errors it can throw or return. Reference the named type rather than inlining a shape that already has a name.
- Types and interfaces are the contract: name them, export them, and comment any field whose meaning isn't obvious from its name. Units, nullability, and allowed ranges go in the comment (`durationMs`, not `duration`).
- Add a usage example only where the API is non-obvious.
- Inline comments explain **why** — the constraint, the tradeoff, the bug being avoided. Never what the line does; the line already says that.
- No commented-out code, no `TODO` without an owner or issue reference, no stale comment left describing code that changed.

**Function and call-stack shape**

- **Keep the call stack shallow — three layers of your own code is the working ceiling.** The canonical path is *entrypoint (route/handler/CLI) → domain logic → data access*. Framework and library frames don't count; your own hops do.
- Deep chains are almost always a symptom, not a necessity. Before adding a layer, check for the real causes: a **pass-through wrapper** that only forwards its arguments (delete it), a helper with exactly one caller that isn't earning its name (inline it), or sequential steps that should be **orchestrated side by side by one caller** rather than each function calling the next.
- Where the ceiling genuinely must break — a documented pipeline, a recursive structure, a framework-imposed layer — that's an accepted exception; note why at the call site.
- One job per function. If the name needs "and" to be accurate, split it.
- Guard clauses and early returns over nested conditionals. Deep indentation is the same smell as a deep call stack.
- Push side effects — I/O, env access, clock, randomness — to the edges; keep the core logic pure and directly testable.
- Name things for intent, at a consistent level of abstraction within a function. No abbreviations that aren't already domain vocabulary.

**Types and error handling**

- No `any`, no unchecked casts, no silently swallowed errors. Suppressions carry a comment saying why.
- Validate at the boundary, then trust the type inside it.
- Errors are typed and actionable, and get translated when they cross a layer — a database error never surfaces to a caller as-is.

**Restraint**

- Build what's needed now. No speculative abstraction, no options nobody calls, no layer added for a future that hasn't arrived.
- The second occurrence is a coincidence; the third is a pattern worth extracting.
- Consistency with the surrounding code outranks personal taste — including yours.
- Leave the file better than you found it, but don't smuggle unrelated refactors into an unrelated change.

**Subagent delegation**

- Look for opportunities to hand work to a subagent where it's **genuinely cheaper or faster** — a few independent tasks running in parallel, or well-specified work a smaller model does just as well. This is opportunistic, not a mandate to parallelise everything.
- Good candidates: mechanical, well-specified, verifiable work — bulk renames across files, writing tests to an agreed spec, gathering information from many files, repetitive migrations. Escalate the model for work needing real judgment.
- Keep on the main agent: architecture and design decisions, anything needing the full conversation's context, and the final review of whatever comes back. Delegated output is reviewed before it's trusted.
- Parallelise only genuinely independent tasks — never two agents writing the same file.
- Don't delegate when explaining the task costs more than doing it.
- **Always announce a handoff**: say that work is being delegated, what the subagent is doing, and **which model** was chosen for it.

---

## Phase 2 — Land it

- Edit the file in place. Keep the diff reviewable, and keep the result **concise** — if the section you added takes more than a minute to read, cut it down.
- If the file is already long, consider a short section that links to a dedicated `CONVENTIONS.md`. Prefer inlining unless the file is genuinely unwieldy; a linked file is one indirection away from being ignored.
- Re-read the whole file top to bottom afterwards, as an agent would. Remove anything now duplicated, contradictory, or dead. **Net line count matters** — report it.

Then report: what you added, what you consolidated or removed, any conflict you found between these rules and the existing codebase, and any rule you deliberately skipped as already enforced by tooling.
