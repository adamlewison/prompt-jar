---
description: Establishing — or rescuing — a repository's architecture. Audits what's there, decides the right target for this project and stack, documents it as law, enforces it in CI with both a deterministic check and an agent pass, then cleans up the existing mess to match.
---

You are acting as a principal engineer brought in to set the architectural standard for this repository. "Architecture" here means the physical and organisational shape of the code: file structure, directory layout, naming conventions, separation of concerns, layer boundaries, where data access lives versus business logic versus presentation, module public surfaces, file and function size discipline, and import direction. Not runtime architecture, not infrastructure — the shape of the source tree and the rules that keep it coherent.

Your job has four phases. Do them in order. Phases 0–2 do not move a single file.

## Ground rules

- **Verify, never assume.** Determine the framework and its *exact major version* from the lockfile and manifest, then read that version's own documentation before asserting any convention — for JS/TS projects the installed docs (e.g. `node_modules/next/dist/docs/`) beat anything you remember. Framework conventions change between majors, and confidently applying a previous major's layout is worse than giving no advice at all. If the installed package ships no docs, say so and fetch the docs for that pinned version.
- **Consistency outranks personal taste.** Where the codebase already has a dominant convention that sits anywhere within the range of defensible modern practice, adopt it. Only override a convention when you can name the concrete harm it causes.
- **Distance matters.** A world-class architecture the project can actually reach beats a purer one it can't. Weigh migration cost explicitly.
- **Do not flip an advanced project on its head.** The more mature the codebase, the higher the bar for any change that touches a large number of files.
- **Every rule you write must be checkable** — by a script, or by a reviewer in under ten seconds. If you can't state a rule as pass/fail, cut it.

---

## Phase 0 — Audit

Produce a written audit of what exists. No recommendations yet, no changes.

**Inventory**
- Language, framework, and major versions; package manager; monorepo or single package; build tooling; test runner; existing lint/format config and any architectural rules already encoded in it.
- Existing docs that touch conventions: `CLAUDE.md`, `AGENTS.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `docs/`, ADRs, README sections.

**Measure** (report numbers, not impressions)
- Directory tree to a useful depth, with file counts per directory.
- Total files, total LOC, LOC distribution, and the 20 largest files.
- Naming conventions actually in use — count kebab-case vs. camelCase vs. PascalCase filenames, broken down by directory type, and report the split rather than the winner alone.
- Where data access happens: find every import of the DB client / ORM / backend SDK and count distinct call sites. Note how many sit inside UI components or route handlers.
- Where business logic lives, and whether it's reachable without the framework.
- Cross-layer and upward imports, circular dependencies, barrel files, deep relative import chains (`../../../`).
- Server/client boundary markers and how they're distributed.
- Test file placement convention and adherence, split by test kind (unit / integration / e2e). Where the shared test harness lives — factories, mocks, render helpers, DB setup — and whether it's one home or scattered.
- Component organisation: shared vs. feature-owned, colocation, primitive layer.
- Any junk-drawer directories (`utils`, `helpers`, `lib`, `common`) and what's actually in them.

**Judge**
For each dimension: is the codebase **consistent**, **mixed**, or **chaotic**? Name the dominant pattern and its adherence percentage.

**Read the project's maturity**
LOC, contributor count, commit history depth, whether it's shipped. This sets how aggressive the later phases may be. State the reading explicitly — it's the input to every cost judgement that follows.

---

## Phase 1 — Decide the target

First, from scratch: what *is* the state-of-the-art architecture for this exact stack and version, as a senior engineer would lay it out greenfield today? Be specific and opinionated.

Then reconcile that ideal against the audit, deciding each axis below explicitly:

- Top-level layout — `src/` or not, router/entrypoint placement, monorepo package boundaries
- Organisation by feature/domain vs. by technical layer, and where the line sits
- Route/page/entrypoint files: what is allowed to live in them (they should be thin)
- Server/client boundary and how it's expressed
- **Data access layer** — where it lives, and the rule for what is the *only* thing permitted to touch the database
- **Business logic** — where it lives, whether it may import the framework, how it's tested
- Validation and schemas — location, single source of truth, relationship to types
- Components — shared vs. feature-owned, primitive/UI layer, colocation, barrels or no barrels
- Hooks, and the ban on junk-drawer utility directories
- Types — colocated vs. central, generated types, where shared contracts live
- **Naming conventions** — files, directories, components, hooks, types, constants, functions, DB entities, env vars. Give the rule *and* an example for each
- **Tests** — colocated vs. mirrored tree, and the naming rule per kind (unit / integration / e2e), since they often differ in home and runner. Where the shared harness lives (factories, mocks, helpers, fixtures) and how tests import it. Whether test code is exempt from the layer and import rules above — decide it explicitly rather than leaving it to be discovered. Scope here is *placement and naming only*; what to test and how belongs to the testing standard, not this document
- **Size budgets** — file length, function length, component complexity, and what to do when one is exceeded
- Import rules — path aliases, no deep relative imports, permitted import directions between layers
- Side-effect boundaries — env access, config loading, third-party SDK wrapping
- Error handling shape and where errors are translated between layers
- What a module's public surface is and how it's declared

Output a decision table:

| Axis | Current state | Target | Verdict | Rationale | Migration cost |
|---|---|---|---|---|---|

Verdict is one of **keep** / **tighten** / **replace**. Every `replace` needs a named harm in the rationale, not a preference.

**→ CHECKPOINT: present the audit and this table. Get explicit approval before Phase 2.**

---

## Phase 2 — Document it

Write the approved decisions into the repository as `ARCHITECTURE.md` (or directly into `CLAUDE.md` if the ruleset is small), and link it from whichever of `CLAUDE.md` / `AGENTS.md` the repo already uses so every future agent session picks it up.

The document must be **prescriptive, not descriptive** — it is the law, not a tour. It contains:

1. The canonical directory tree, annotated with what belongs in each location.
2. A naming table: entity → rule → example.
3. Layer and dependency rules, stated as permitted import directions.
4. Size budgets, and the prescribed remedy when one is breached.
5. **Decision recipes** — "I'm adding a new ⟨page / API route / DB query / shared component / background job / test / test helper⟩: where does it go?" This is the section that gets used most; make it concrete.
6. Anti-patterns, each with the reason it's banned.
7. Escape hatches: how to legitimately deviate, and how a deviation gets recorded.

Keep it tight. A rule nobody can find is a rule nobody follows.

---

## Phase 3 — Enforce it

Two layers, both required.

**(a) Deterministic check**

Encode everything mechanically checkable. Prefer the project's existing tooling — lint rules for import restrictions and filename casing, `max-lines`, a dependency-graph checker for layer boundaries — and add a small repo-specific script (e.g. `scripts/check-architecture.mjs`) for structural rules the linters can't express.

Test placement and naming are among the cheapest rules to check and the fastest to drift — a test in the wrong tree, or named off-convention, is silently skipped by the runner. Cover them here.

Requirements: exits non-zero on violation; prints `file:line` and the rule broken; runs from a single package script; finishes in seconds.

**Ship it with a baseline.** Record existing known violations in a checked-in baseline file so the check lands green on day one. New violations fail immediately; legacy violations are tracked and the baseline only ever shrinks. This is what makes the standard adoptable without a big-bang refactor.

**(b) Agent pass**

Add a skill at `.claude/skills/house-rules/SKILL.md` that runs the deterministic check and then reviews what a script fundamentally cannot judge:

- whether a name is *good*, not merely correctly cased
- whether a module sits in the right conceptual place
- whether an abstraction is at the right altitude
- drift between the architecture doc and the actual tree
- new patterns that have emerged and should be either adopted into the doc or removed from the code

It outputs a report and, where the fix is unambiguous, a PR.

**CI wiring**: deterministic check on every PR; agent pass on a schedule (weekly is usually right) and on manual dispatch.

---

## Phase 4 — Clean up the mess

Now bring the codebase to the standard. Produce an ordered remediation plan **before touching anything**, batched so each batch is:

- a single concern
- mechanically verifiable
- its own commit (and its own PR where the repo works that way)

Ordering: cheapest and safest first — pure renames and moves, then extraction of misplaced code, then genuine refactors. Front-load the batches that unlock the most baseline shrinkage per unit of risk.

Execution rules, non-negotiable:

- Use `git mv` so history follows the file.
- **Never mix a move with a logic change in the same commit.** A moving commit must be behaviour-preserving, and you should be able to say so with a straight face.
- Update all imports; run typecheck, build, and tests after every batch.
- Shrink the enforcement baseline after each batch — it should never grow.
- If a batch reveals the standard itself is wrong, stop and amend the doc rather than quietly deviating.

**→ CHECKPOINT: present the batch plan and get approval before executing the first move.**

---

## Deliverables

1. The written audit.
2. The decision table.
3. `ARCHITECTURE.md`, linked from `CLAUDE.md` / `AGENTS.md`.
4. The deterministic check, its baseline, and its package script.
5. The `house-rules` skill.
6. The CI workflow.
7. The remediation plan, and the batches themselves once approved.
