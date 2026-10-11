<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

**Issue:** #210 [M2] Run the date tests under a non-UTC time zone in CI, so local-zone bugs fail a check · **Read at:** 2026-10-08T12:38Z · **Default branch:** `main` @ `66971d5`

The issue asks for the date tests of `@sched/contracts`, `@sched/tools` and `@sched/agent` to run in CI under a zone other than UTC, so that D25 and P5 from PR #208, which survive in UTC, fail a check. Two things need settling first. The first is which zone to use and whether it replaces UTC for these tests or runs beside it. The issue's example, the clinic's own zone, kills D25 and P5 but stops catching a different break that today's UTC run does catch. The second is whether a guard test keeps the setting from being dropped later: the definition of done asks for one, and the owned paths don't allow it.

Round: 1 · Questions: 2 · Assumptions: 5 · Suggested edits: 3 · Spec commit: 66971d59062897515dfe3689a49718f75181a2a6 · Harness version: 2026.10.08.1

**Check these first:** A-1, A-3

**To answer:** reply on this issue with one line per item, in the form shown under each
(`Decision r1/<ID>: <answer>`): an option's letter or your own words for a question,
"accept" or "reject" for an edit, "ok" or your correction for an assumption. To take every
recommendation and edit at once, `Decision r1/ALL: accept`; it does not cover the
assumptions under "Check these first" or those marked "(verify first)" or "(would have
asked)", which each need their own line. Only `Decision` lines are applied, never other
replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: Which time zone do these tests run in, and does it replace UTC for them or run beside it?

- **Why it matters:** The issue's example, `America/New_York`, is the clinic's zone (`packages/contracts/src/clinic.ts:7`). Once the process zone equals the clinic zone, a break where code falls back to the machine's zone instead of `CLINIC.timezone` can no longer be seen. Example: deleting `timeZone: CLINIC.timezone,` from `displayFormatter` (`packages/tools/src/clock.ts:148`). Under UTC that formats 14:00Z as "2:00 PM" and fails `clock.test.ts:145-152`, which expects "10:00 AM ET". Under New York it formats "10:00 AM" and passes. Swapping UTC for New York therefore trades one blind spot for another. A zone east of UTC fixes nothing: D25 and P5 survive there. If this choice is wrong, the PR's config and evidence get redone.
- **Source:** the issue, criterion 1: "run in CI under a non-UTC zone (for example `TZ=America/New_York`, set in the affected Vitest projects' config or as an extra CI step) ... Which mechanism is open". Goal: "Make the date-sensitive tests run in a non-UTC zone in CI too". The issue is silent on the clinic-zone blind spot and on whether "too" means "as well as UTC".
- **Options:**
  - (a) Replace UTC with `America/Los_Angeles` (west of UTC, and not the clinic's zone) for every test of the three packages. Each of `packages/contracts`, `packages/tools` and `packages/agent` gets a `vitest.config.ts` that sets `TZ` for its project, so every run uses that zone: `npm test`, `npm test -w`, `npm run mutate` and CI's `npm run test:coverage`. No CI step is added. One run kills D25, P5 and the `clock.ts:148` break, and local runs match CI. Scope: within the issue. Owned paths: + `packages/contracts/tsconfig.json`, `packages/tools/tsconfig.json`, `packages/agent/tsconfig.json` (each `include` lists the new config, so `npm run typecheck` checks it)
  - (b) Replace UTC with `America/New_York` (the clinic's zone) for every test of the three packages, with the same per-package `vitest.config.ts` mechanism as (a). This kills D25 and P5, as PR #208's table shows, but the `clock.ts:148` break, and any other fallback to the machine zone where the clinic's should be used, then passes. Scope: within the issue. Owned paths: + `packages/contracts/tsconfig.json`, `packages/tools/tsconfig.json`, `packages/agent/tsconfig.json`
  - (c) Keep UTC and add a second run, in CI only. `npm run test:coverage` stays as it is, and one new step in the `Lint, typecheck, test` job runs the three packages' tests again with `TZ: America/New_York`. CI catches both kinds of break. Local `npm test` and `npm run mutate` keep the machine's zone, so an agent sees D25-type breaks locally only by adding a `TZ=` prefix by hand. The `@sched/tools` DynamoDB suite runs twice inside the job's 10-minute limit (`ci.yml:30`). `CLAUDE.md:122` and the `ci.yml` header change together (sync region `ci-checks`, `scripts/sync-regions.test.ts:1-7`). Scope: within the issue. Owned paths: + `.github/workflows/ci.yml` (the header comment, lines 1-11)
- **Edges:** Boundary zones: a zone east of UTC never qualifies. D25 and P5 read a UTC-midnight `Date` (`dates.ts:91`, `system.v1.ts:156`), and in Tokyo `new Date("2026-10-05T00:00:00Z").getDay()` is 1, the same as in UTC; in New York and Los Angeles it is 0. Scope: the list of covered tests is complete as given, namely all tests of the three projects, not only the three files; `services/api`, `packages/evals`, `apps/web` and `scripts` keep the machine zone (E-2). Evidence under (a) and (b): the criterion-2 table runs `npx vitest run <the three test files>` with no `TZ=` prefix, and under (a) it also has a KILLED row for deleting `timeZone: CLINIC.timezone,` at `clock.ts:148`. Evidence under (c): the table uses the step's exact command and `TZ`. Coincidences under (a): Los Angeles and New York share the calendar day at some instants, so a day-level clinic-zone fallback can pass at those instants; hour-level output always differs by 3 hours. Concurrency: none, since this is a config value and CI steps run in sequence.
- **Recommendation:** (a). One run catches D25, P5 and the clinic-zone fallback. It adds no CI time, and local mutate runs match CI without a prefix. In #114, r1/A-3 had the agent add that prefix by hand. In UTC, `clock.test.ts:145-152` kills the `clock.ts:148` break today. Under (b) that check is lost.
- **Reply:** `Decision r1/Q-1: (a)`

#### Q-2: Does a guard test fail when the zone setting is removed?

- **Why it matters:** The only code this issue writes is the setting. While the date code is correct, deleting the setting fails no test, so a later edit could drop it silently and the issue's goal would regress unseen. `scripts/pr-evidence.ts:7-8` won't ask for evidence, because config files aren't source files there.
- **Source:** CLAUDE.md, "Definition of done": "break each thing the code you wrote does with `npm run mutate` ... If none does, add one." The issue's owned paths: "Tests under those packages, only to fix or pin a UTC-only test". The two conflict.
- **Options:**
  - (a) Each of the three packages gets one guard test, with the zone set in that package's Vitest config (Q-1 (a) or (b)). The test asserts that `new Intl.DateTimeFormat().resolvedOptions().timeZone` is the chosen zone. The PR's mutate table deletes each config's `TZ` entry, and each deletion is KILLED by that package's guard. Scope: adds 3 small tests. Owned paths: + `packages/contracts/src/zone.test.ts`, `packages/tools/test/zone.test.ts`, `packages/agent/test/zone.test.ts`
  - (b) No guard test. The criterion-2 rows for D25 and P5 are the evidence for the setting. The PR records that no test fails when the setting alone is removed, and this decision is the recorded exception to the definition of done. Scope: within the issue.
- **Edges:** Under Q-1 (c), option (a) can't work: the guard would fail the UTC `npm run test:coverage` run, so only (b) fits. The list of guards is complete at one per package; a single shared guard wouldn't fail when only one package's setting is removed. Contracts' guard must sit under `src/`, because `packages/contracts/tsconfig.json` includes only `src`; the tools and agent paths are suggestions. Evidence: the mutate rows each name the package's guard test in `expect`.
- **Recommendation:** (a). The definition of done asks for exactly this, it costs three short files, and without it the setting is the one line of the PR that nothing protects.
- **Reply:** `Decision r1/Q-2: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | **(verify first)** When the zone is set in Vitest config (Q-1 (a) or (b)), the agent sets it as `test.env: { TZ: "<zone>" }` in each new `packages/<p>/vitest.config.ts`. These files are required by Q-1. It doesn't set it in the root `vitest.config.ts`: Vitest 5.0.2 resolves directory projects with `configFile: false` (`node_modules/vitest/dist/chunks/index.C-uw7tH9.js:12580-12588`), so root `test` options don't reach them. It doesn't use a top-level `process.env.TZ = ...` in a config either, because configs load in Vitest's main process and that assignment would reach every project. Each config also sets `test.name: "@sched/<dir>"`, which is a suggestion: nothing depends on project names. Before building on any of this, the agent confirms the setting reaches the test workers: with no `TZ=` prefix, D25 is KILLED. | Code scout's reading of the Vitest 5.0.2 dist; `vitest.config.ts:19`; no package has a Vitest config today. Not run. | nothing (`vitest.config.ts:3-4` stays true) | `Decision r1/A-1: <your correction>` |
| A-2 | The agent shows criterion 2 with a local `npm run mutate -- <edits> --markdown -- <command>` table in the PR body, and doesn't push a mutated commit to CI. D25 and P5 are copied verbatim from PR #208's table: D25 `.getUTCDay()` → `.getDay()`; P5 `    timeZone: "UTC",⏎    weekday: "long",` → `    weekday: "long",`. The `<command>` is what CI runs for those tests (see Q-1's Edges). | The criterion's parenthetical: "(shown with `npm run mutate` under the same setting, in the PR body)"; PR #208 body, Seen failing rows D25 and P5 | nothing | `Decision r1/A-2: <your correction>` |
| A-3 | The agent expects no test to need fixing or pinning: a search found no local-zone read in any test, and the only one in source is `system.v1.ts:159`, which is pinned to UTC. If a test does fail under the zone, the agent rewrites that test so it doesn't depend on the zone. It changes no source file. If the failure shows a real bug in `dates.ts`, `clock.ts` or `system.v1.ts`, the agent reports it on #210 and asks rather than fixing it here (E-2). | Code scout's searches (local-zone `Date` getters, `toLocale*`, zone-less date-times, `Intl.DateTimeFormat` without `timeZone`); owned paths: "Tests under those packages, only to fix or pin a UTC-only test" | nothing | `Decision r1/A-3: <your correction>` |
| A-4 | Under Q-1 (a) or (b), no CI step is added, so criterion 4 doesn't apply and the agent adds no `CLAUDE.md` line. A comment at the top of each new config says why the zone is set (D25, P5, #210). Under Q-1 (c), the agent edits both copies of the `ci-checks` region rather than using a `Sync-checked` trailer. | Criterion 4: "names the setting if it adds a CI step"; `scripts/sync-regions.test.ts:1-7` | Under Q-1 (c) only:<br>`CLAUDE.md:122`<br>`.github/workflows/ci.yml:2-10` | `Decision r1/A-4: <your correction>` |
| A-5 | The agent writes a new journal entry with its row in `docs/journal/README.md`. It doesn't edit the dated lines in `docs/journal/2026-10-07-one-copy-of-the-clinic-calendar.md` ("CI runs in UTC, so CI alone would not catch either regression"; "#210 tracks running the date tests in CI"). | `.claude/skills/dev-journal/SKILL.md:24`: "Don't rewrite history" | nothing (`docs/journal/2026-10-07-one-copy-of-the-clinic-calendar.md:24`, `:35` stay as dated history) | `Decision r1/A-5: <your correction>` |

### Suggested edits to the issue

#### E-1: Make criterion 1 say which zones count and which tests are covered

Before:
```text
- [ ] The tests of `packages/contracts/src/dates.ts`, `packages/tools/src/clock.ts` and `packages/agent/src/prompts/system.v1.ts` run in CI under a non-UTC zone (for example `TZ=America/New_York`, set in the affected Vitest projects' config or as an extra CI step), and still pass. Which mechanism is open; the PR says which and why.
```
After:
```text
- [ ] When CI's `Lint, typecheck, test` job runs, the tests of the `@sched/contracts`, `@sched/tools` and `@sched/agent` projects (which include the tests of `packages/contracts/src/dates.ts`, `packages/tools/src/clock.ts` and `packages/agent/src/prompts/system.v1.ts`) run under a time zone west of UTC, chosen and set as decided in r1/Q-1, and pass. A zone east of UTC does not count: it reads a UTC-midnight date as the same calendar day, so D25 and P5 survive there. The PR says which mechanism and why.
```
- **Reply:** `Decision r1/E-1: accept` (or `reject`)

#### E-2: Add the non-goals the owned paths imply

Before:
```text
## Dependencies
```
After:
```text
## Non-goals
- Changing the date code (`dates.ts`, `clock.ts`, `system.v1.ts`). A real bug a non-UTC run exposes is reported on this issue, not fixed here.
- Running other packages' tests (`services/api`, `packages/evals`, `apps/web`, `scripts`) under the new zone.
- A matrix of several zones.
- Teaching `scripts/mutate.ts` or `scripts/pr-evidence.ts` about time zones.

## Dependencies
```
- **Reply:** `Decision r1/E-2: accept` (or `reject`)

#### E-3: Add the Verification section the issue form requires

Before:
```text
## References
```
After:
```text
## Verification
- The agent: `npm run lint && npm run typecheck && npm test`, `npm run test:coverage`, `npm run coverage:changed`.
- The agent: the criterion-2 `npm run mutate -- … --markdown` table, run locally with the same command and zone CI uses, in the PR body.
- CI: `Lint, typecheck, test` green on the PR.

## References
```
- **Reply:** `Decision r1/E-3: accept` (or `reject`)

### Reuse, dependencies and risks

- **Reuse:**
  - D25 and P5: copy them verbatim from PR #208's body (Seen failing table, rows D25 and P5). They aren't in the repo.
  - The mutate run: import nothing, and call `npm run mutate` (`scripts/mutate.ts`) as a CLI with `--only` and `--markdown`.
  - The zone string: hard-code it in each config. Don't import `CLINIC.timezone` from `@sched/contracts`, because under Q-1 (a) the zone is deliberately not the clinic's.
- **Dependencies:** #114 is closed, and PR #208 merged on 2026-10-07 (`d15b92c`), so `dates.ts` is on `main`. Unblocked; the issue's "Blocked by #114" is now history.
- **Overlaps:** no open PRs.
- **Size:** small, one PR: three configs of about 10 lines (or one CI step), possibly three tsconfig `include` entries and three guard tests, plus a journal entry and its row. Under 150 changed lines, so no split.
- **Sibling issues:**
  - #212 edits `system.v1.ts` ("Offering times") and `system.v1.test.ts`. Those tests will run under the zone chosen here, and there's no line conflict with `long()`.
  - #34 edits the `CLAUDE.md` CI section (the same `ci-checks` region). That's a merge-order concern only under Q-1 (c).
  - #137 adds `scripts/*.test.ts`, which is unaffected unless the zone is set for the whole suite (excluded by E-2).
  - None of them has a readiness comment or a "Decisions and clarifications" section.

**Relied on:** `CLAUDE.md` "Definition of done"; `CLAUDE.md` "How work flows" (owned paths, the CI bullet and `ci-checks` sync region); #114 "Decisions and clarifications" (r1/A-3, r1/Q-3); PR #208 "Verification" (Seen failing, rows D25 and P5) and "Deferred / follow-ups"; `.github/ISSUE_TEMPLATE/task.yml` "Verification"; `.claude/skills/dev-journal/SKILL.md` ("Don't rewrite history")

<details>
<summary>What was checked</summary>

**Requirements**

- R-1, the Goal ("date-sensitive tests ... in CI too"): testable once Q-1 settles the zone and what "too" means.
- R-2, criterion 1: testable as rewritten by E-1. As written, "a non-UTC zone" admits zones east of UTC, where criterion 2 can't hold.
- R-3, "the PR says which and why": testable from the PR body.
- R-4, criterion 2: testable through the mutate table (A-2). The literal "a check in CI's job fails" isn't observable without pushing mutated commits, so the parenthetical defines the evidence.
- R-5, criterion 3: testable once the scope is fixed. A-3 says how.
- R-6, criterion 4: conditional on a CI step (A-4).
- R-7, criterion 5: testable as written.
- R-8, the deferred comment (TEST-1): covered by R-2 and R-4. Its line references (`dates.ts:89-92`, `system.v1.ts:158-161`, `dates.test.ts:16-21`) match `66971d5`.

**Checked against the code at `66971d5`**

- `vitest.config.ts:19` is `projects: ["packages/*", "services/*", "apps/*", "scripts"]`, and there's no per-package Vitest config. `find` lists only the root `vitest.config.ts` and `apps/web/vite.config.ts`.
- `ci.yml` sets no `TZ`. The job env at `:38-39` is only `DYNAMODB_ENDPOINT`, and `timeout-minutes: 10` is at `:30`. The code scout cited `:41-42` and `:32` for these, which are off by a few lines.
- `dates.ts:91` is `.getUTCDay()`. `system.v1.ts:159-160` is `toLocaleDateString` with `timeZone: "UTC"`. `clock.ts:147-148` is `displayFormatter` with `timeZone: CLINIC.timezone`. `clock.test.ts:145-152` expects "10:00 AM ET" for 14:00Z.
- Package tsconfig includes: contracts `["src"]`, tools `["src", "fixtures", "test"]`, agent `["src", "test"]`. Each package typechecks with `tsc --noEmit -p .`, and the root `tsconfig.json` includes only the root `vitest.config.ts`. ESLint isn't type-aware (`tseslint.configs.strict`), so a config outside every tsconfig still lints. That is why Q-1 (a) and (b) add the tsconfig paths.
- `scripts/pr-evidence.ts:7-8, 32-35`: source globs exclude tests and `test/` directories, so neither configs nor guard tests need a mutate row.
- `node_modules/vitest` is 5.0.2. In `dist/chunks/index.C-uw7tH9.js:12580-12588`, directory projects resolve with `configFile: false`, which confirms that root `test` options don't reach them.
- PR #208's body (`spec/background/issue-208.md:32-43, 71, 85`):
  - Under `TZ=UTC`, D25 and P5 SURVIVED.
  - Under `TZ=America/New_York`, D25 was KILLED by `dates.test.ts > ... addDays and weekdayOf do calendar arithmetic` and by ten `system.v1.test.ts` tests, and P5 by ten `system.v1.test.ts` tests.

**Commands run (read-only)**

- Zone arithmetic, `TZ=<zone> node -e ...` on Node v26.9.0, the local machine. The repo pins Node 24, so treat the exact behaviour as unconfirmed on 24:
  - `new Date("2026-10-05T00:00:00Z").getDay()`: UTC 1, America/New_York 0, America/Los_Angeles 0, Asia/Tokyo 1.
  - The same date's `toLocaleDateString` without `timeZone`: "Monday, October 5" in UTC and Tokyo, "Sunday, October 4" in New York and Los Angeles.
  - A formatter without `timeZone`, applied to 2026-10-15T14:00Z: 2:00 PM in UTC, 10:00 AM in New York, 7:00 AM in Los Angeles. This confirms the Q-1 claims.
  - Setting `process.env.TZ` at runtime in the main thread took effect.
- `git log --since=2026-10-07T14:13:12Z` over `dates.ts`, `clock.ts`, `system.v1.ts`, their tests, `vitest.config.ts` and `ci.yml` found only `98b7310`, part of PR #208, from before its merge. No stale references.

**Dropped or changed from the analysts' material**

- The east-of-UTC claim (OB-2(c)) is now checked by the run above.
- OB-4 (mechanism) is folded into Q-1's options, since the mechanism and the zone choice are coupled.
- OB-6 (how to pin) is folded into A-3, because no test is expected to need it.
- C-2 (missing Verification section) became E-3.
- "Blocked by #114" is left as is: it's history, not wrong.

**Not checked**

- Whether `test.env.TZ` takes effect in Vitest's forks workers on Node 24 before the test modules load (A-1, verify first).
- Whether any test in the three projects fails under the new zone. That needs a test run, which this review doesn't do.
- How Vitest names a config-file project when `test.name` is unset.

</details>

