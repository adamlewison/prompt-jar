---
description: Set and enforce a repository's testing strategy — a deliberately small suite where every test earns its place. Audits what's there, fixes the rule for what does and does not get a test, picks one runner and one way to write each tier, documents it with reference tests to copy, enforces it with lint rules plus a guard script and CI, then prunes the tests that aren't paying rent.
---

You are a principal engineer setting the testing standard for this repository, and wiring it in so every future session — yours or another agent's — writes tests the same way without being asked.

The goal is a **small, trusted suite**, not a large one: fast, deterministic, and made almost entirely of tests that would catch a real bug. Test count is a cost, not a score.

Scope: what gets tested and what deliberately doesn't, how each kind of test is written, the runner and lint setup, and the enforcement that holds the line across sessions. Where test files live and what they're named defers to the repo's `ARCHITECTURE.md` if it has one.

---

## The principle everything derives from

> **Spend tests on risk: blast radius × how quietly it can break.**

- **Blast radius** — what a failure costs. Money, auth and permissions, data loss or corruption, the primary thing users come here to do, a contract other modules or services depend on.
- **Quietly** — loud failures don't need tests. A type error, a failed build, a page that white-screens on first load all announce themselves. Silent failures are what tests are for: an off-by-one in prorated billing, a permission check that returns the wrong boolean for one role, a timezone bug, a retry that double-charges.

Both high → test it. Either one low → don't. Every rule below is that sentence made concrete.

One corollary, stated up front because it is the single biggest source of worthless tests: **coverage is a diagnostic, never a target.** No coverage percentage may ever gate a build. Read coverage on a critical module to find a gap you didn't know about; never write a test to move the number.

---

## The four tiers

| Tier | What it is | How many |
|---|---|---|
| **0 — free** | Type checker, linter, formatter | Everything they can prove. Never test what the compiler already guarantees. |
| **1 — scenario** | Drives the real, running app the way a user does, front to back | One per critical journey. Countable on one hand. |
| **2 — boundary** | Enters a module, route, or component through its **public surface** with its real collaborators; fakes only the true system edges | **The bulk of the suite.** |
| **3 — unit** | A pure function exercised directly, table-driven | Only where the logic is dense. |

The weight sits at tier 2, not tier 3 — this is the "testing trophy" shape rather than the classic pyramid. The reason is worth internalising: most code in a real application *wires other code together*, and a unit test of wiring asserts only that the wiring is what it is. It passes happily while the feature is broken. A boundary test fails when the feature is broken, which is the only thing a test is for.

**Tier 3 is for dense logic**, meaning a function whose input space genuinely branches: parsing, dates and timezones, money and rounding, permission matrices, sorting or ranking, state machines, retry and backoff. Once the harness exists an extra case costs nothing, so cover the edges properly — empty, one, many, boundary, negative, overflow, malformed.

---

## When a test gets written

Exactly four triggers. If a change matches none of them, it ships with no new test, and that is the correct outcome.

1. **A bug was fixed.** Non-negotiable, and the only trigger that isn't a judgment call. Write it *first*, watch it fail, then fix the code. This is the highest-value test in any suite: proof the failure mode was real and a guarantee it can't come back.
2. **Critical path.** Money, authentication, authorisation, anything that destroys or migrates data, the primary user journey. Tier 1 or 2.
3. **Dense logic.** As defined above. Tier 3, table-driven.
4. **A published contract.** A schema, API response shape, or event payload that something outside this module depends on. Test the shape at the boundary.

## When a test does not get written

Delete these on sight; each one costs maintenance and returns nothing.

- Getters, setters, constructors, constants, config objects, pass-through wrappers.
- Assertions that only restate what the type system already proves.
- Any test that mocks your own module and then asserts the mock was called. That asserts your code is what it is, and it will keep passing after you break the behaviour.
- Snapshots by default. At most one for a genuinely complex, genuinely stable output, reviewed like code. A snapshot of every component is a suite that fails on every legitimate change and gets `-u`'d without reading — a rubber stamp with a runtime cost.
- Framework behaviour: that the router routes, that the ORM saves, that the validation library validates.
- Anything added to raise coverage.
- The same behaviour covered at two tiers. Pick the outermost tier that fails informatively and delete the other.

**Default budget for a normal feature: 0–1 scenario, 1–3 boundary, unit tests only if there is dense logic.** When a change's test diff is larger than its source diff, that's allowed but it must be justified in a sentence.

---

## How every test is written

**Fakes stop at the system edge.**

- Fake only what you don't own or can't control: outbound network and third-party HTTP, payment/email/SMS providers, the clock, randomness, and anything that costs money per call.
- **Never mock your own modules.** If a test is only writable by mocking internal code, that is a design finding, not a testing problem — the side effects need pushing out of that logic, not a mock injected into it. Fix the code and the test becomes easy.
- Prefer one fake at the boundary over mocks scattered inside: an HTTP interceptor (MSW or equivalent) for network, a real throwaway or in-memory database rather than a mocked client, an injected clock, a seeded RNG.

**Determinism, non-negotiable.**

- No `sleep`, no arbitrary waits. Wait on a condition, or use fake timers.
- No test may depend on today's date, the machine's timezone, or unseeded randomness.
- No shared mutable state and no ordering dependence. Every test creates its own data and passes both alone and in parallel.
- A flaky test is a broken test: fix it or delete it within a day. **Never** add a retry. Retries trade one real signal for permanent noise.

**Quality bar for each test.**

- The name states the behaviour and the condition — `refuses a refund larger than the original charge`, not `test refund 2`.
- One reason to fail. Arrange, act, assert.
- No branching or conditional assertions in a test body. Table-driven cases, yes; `if` inside a test, no.
- Assert on observable behaviour: the return value, the persisted state, what the user sees, the request that went out. Never on private internals or on how many times your own functions were called.
- **Before keeping a test, break the code on purpose and confirm it fails.** Ten seconds, and it's the only thing that distinguishes a test from a false guarantee. (Hand-rolled mutation testing; a test that passes against broken code is worse than no test at all.)

**Tooling.**

- **One runner.** If the repo has two, consolidate. Vitest for anything Vite-based or modern TS, Jest where it's already established and working, otherwise the language default (pytest, `go test`, `cargo test`). Don't migrate a working runner on taste alone.
- Components through the user-facing API: Testing Library with `user-event`, queried by role and accessible label the way a user finds things. No shallow rendering, no asserting on props or internal state, no test IDs sprinkled everywhere as the default query.
- Scenario tests: Playwright or the ecosystem equivalent, against a really running app.
- Test data: factory functions with sensible defaults and per-test overrides. Not large shared fixture files — those become a second, undocumented schema that every test silently depends on.
- **Lint the tests.** Turn on the runner's lint plugin (`eslint-plugin-jest` / `eslint-plugin-vitest`, or `flake8`/`ruff` equivalents): no focused tests, no disabled tests, no conditional `expect`, every test contains an assertion, no duplicate titles. Mechanical hygiene belongs to the linter, never to a reviewer.
- **Speed is a feature.** The default `test` script must run in seconds with no manual setup. A suite nobody runs is a record of the past. Slower work — scenario tests, containers — goes behind its own script and runs in CI.

---

## Phase 0 — Audit

Numbers, not impressions. No changes yet.

- Runner(s) and version, config files, existing lint/type setup, CI test wiring, what the `test` script actually does and how long it takes from cold.
- Test count, test LOC, source LOC, and the test-to-source ratio. Per directory as well as overall.
- Tier mix: how many tests are effectively scenario / boundary / unit, and where the weight sits.
- Rot inventory: focused (`.only`) and skipped tests, snapshot count, retry configuration, coverage thresholds, tests containing `sleep` or fixed waits, tests depending on the real clock.
- Mock inventory: every place an internal module is mocked. Count them — this is usually the largest single source of tests that can't fail.
- The inverse, and the most important part: list the repo's **critical paths** (money, auth, data loss, primary journey) and mark which are untested.
- Any git history signal you can get cheaply: files with the most bug-fix commits. That list is where tests are worth the most.

Report it as: what's covered that shouldn't be, what's uncovered that must be, and the state of the plumbing.

---

## Phase 1 — Decide

Produce the decision table:

| Axis | Current state | Target | Verdict | Rationale |
|---|---|---|---|---|

Cover at minimum: runner, tier mix and target ratio, mocking boundary, test data approach, component testing approach, scenario test scope, determinism gaps, lint rules to enable, coverage policy, CI shape, and the specific critical paths that need a test written.

Verdicts are **keep** / **tighten** / **replace**. Every `replace` names the concrete harm, not a preference. Consistency with what the repo already does wins ties.

**→ CHECKPOINT: present the audit and this table. Get explicit approval before writing anything.**

---

## Phase 2 — Document it, and leave something to copy

Two artefacts, and the second is what actually produces consistency between sessions.

**(a) The rules.** A compact `TESTING.md`, linked from whichever of `CLAUDE.md` / `AGENTS.md` the repo uses. In `CLAUDE.md` itself put only the short version, because that file is rent paid on every session: the risk principle, the four triggers, the never-write list, the mocking boundary, the no-coverage-target rule, and a link. Under ten lines. Everything else lives in `TESTING.md`.

**(b) Reference tests.** Designate — or write — one exemplary test per tier that's actually in use, and link them by path from `TESTING.md`. `CLAUDE.md` instructs: *new tests match the shape of these files.* A canonical example to copy is far more effective at producing consistency than any amount of prose, for agents and humans alike. Along with them, land the shared harness those examples use — the factories, the render helper, the test-database setup — so there is exactly one way to do each common thing.

Then write the decision recipe, because it's the section that gets used most: *"I changed ⟨a bug / a route / a pure function / a component / a schema⟩ — do I write a test, and at which tier?"* Concrete, with the answer sometimes being no.

---

## Phase 3 — Enforce it

Three layers.

**(a) Lint.** Enable the test-lint rules from Phase 1. Free, instant, no human in the loop.

**(b) Guard script** (e.g. `scripts/check-tests.mjs`), run from one package script, finishing in seconds, exiting non-zero with `file:line` and the rule broken. It checks what lint can't:

- No focused tests; no skipped test without an issue reference.
- No mocking of internal modules — relative paths and the repo's own path aliases.
- No coverage threshold configured as a gate.
- No `sleep` or bare timeout waits in test files.
- No retry configuration in the runner or CI.
- Prints test count and test-to-source ratio on every run, so suite growth is visible rather than discovered a year later.

**Ship it with a baseline** of the violations that exist today, so it lands green. New violations fail immediately; the baseline only ever shrinks.

**(c) Agent pass** — a skill at `.claude/skills/test-review/SKILL.md` that runs the guard script and then judges what no script can:

- Does each test assert behaviour, or implementation?
- Would it fail if the feature broke? (Where it's cheap, actually try.)
- Is it at the right tier, or duplicating a test one tier out?
- Are the critical paths from the audit still covered as the code moves?
- **Which tests should now be deleted.** Say this explicitly in the skill — nothing else in a codebase ever proposes removing a test, so a suite only grows unless something is charged with pruning it.

Wire CI: types, lint, guard script, and the fast suite on every PR; scenario tests on PR if they're quick, otherwise on merge; the agent pass weekly and on manual dispatch.

---

## Phase 4 — Prune, then fill

In that order. The suite should come out of this **smaller and more trusted**.

1. Classify every existing test: **keep** / **rewrite at the right tier** / **delete**. Present the delete list first, each with a one-line reason and the behaviour that stops being covered. Deleting a test is a normal, healthy act — a test that cannot fail is a liability, and one that fails for the wrong reasons is worse.
2. Fix the determinism and mocking violations in the tests that survive. Where an internal mock can't be removed without changing the code, say so — that's a design finding worth reporting, and it belongs in the report whether or not it gets fixed now.
3. Then write the missing tests for the critical paths, ranked by blast radius × silence. Highest first, and stop when the remaining candidates stop clearing the bar. Not every gap gets filled.
4. Shrink the baseline after each batch. One concern per commit.

**→ CHECKPOINT: present the prune list and the gap list, in priority order, before executing.**

---

## Deliverables

1. The audit, with numbers.
2. The decision table.
3. `TESTING.md`, plus the short section in `CLAUDE.md` / `AGENTS.md` linking it.
4. The reference test per tier, and the shared test harness they use.
5. Lint rules, the guard script, its baseline, and the package script.
6. The `test-review` skill and the CI wiring.
7. The prune and fill batches, once approved.

Finally, report the before/after numbers: test count, test-to-source ratio, suite runtime, internal mocks removed, critical paths newly covered. If test count went up a lot, justify it or cut further.
