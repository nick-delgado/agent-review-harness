## Goal
Run the date tests in a zone that catches clock bugs.

## Owned paths
- `packages/contracts/tsconfig.json`
- `vitest.config.ts`
- `packages/tools/tsconfig.json`
- `packages/agent/tsconfig.json` (each `include` lists the new config, so `npm run typecheck` checks it)
- `packages/contracts/src/zone.test.ts`
- `packages/tools/test/zone.test.ts`
- `packages/agent/test/zone.test.ts`

## Notes
Nothing else.

## Decisions and clarifications

Settled before work started, in answer to readiness reviews: the owner's answers, and the assumptions the owner let stand. Coding agents and PR reviewers treat these as part of the spec.

- **r1/Q-1** (settled against `66971d5`): Which time zone do these tests run in, and does it replace UTC for them or run beside it? → (a) Replace UTC with `America/Los_Angeles` (west of UTC, and not the clinic's zone) for every test of the three packages. Each of `packages/contracts`, `packages/tools` and `packages/agent` gets a `vitest.config.ts` that sets `TZ` for its project, so every run uses that zone: `npm test`, `npm test -w`, `npm run mutate` and CI's `npm run test:coverage`. No CI step is added. One run kills D25, P5 and the `clock.ts:148` break, and local runs match CI. Scope: within the issue. Owned paths: + `packages/contracts/tsconfig.json`, `packages/tools/tsconfig.json`, `packages/agent/tsconfig.json` (each `include` lists the new config, so `npm run typecheck` checks it) (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/210#issuecomment-6060229351))
  - edges: Boundary zones: a zone east of UTC never qualifies. D25 and P5 read a UTC-midnight `Date` (`dates.ts:91`, `system.v1.ts:156`), and in Tokyo `new Date("2026-10-05T00:00:00Z").getDay()` is 1, the same as in UTC; in New York and Los Angeles it is 0. Scope: the list of covered tests is complete as given, namely all tests of the three projects, not only the three files; `services/api`, `packages/evals`, `apps/web` and `scripts` keep the machine zone (E-2). Evidence under (a) and (b): the criterion-2 table runs `npx vitest run <the three test files>` with no `TZ=` prefix, and under (a) it also has a KILLED row for deleting `timeZone: CLINIC.timezone,` at `clock.ts:148`. Evidence under (c): the table uses the step's exact command and `TZ`. Coincidences under (a): Los Angeles and New York share the calendar day at some instants, so a day-level clinic-zone fallback can pass at those instants; hour-level output always differs by 3 hours. Concurrency: none, since this is a config value and CI steps run in sequence.
  - not chosen: (b) Replace UTC with `America/New_York` (the clinic's zone) for every test of the three packages, with the same per-package `vitest.config.ts` mechanism as (a). This kills D25 and P5, as PR #208's table shows, but the `clock.ts:148` break, and any other fallback to the machine zone where the clinic's should be used, then passes. Scope: within the issue. Owned paths: + `packages/contracts/tsconfig.json`, `packages/tools/tsconfig.json`, `packages/agent/tsconfig.json`
  - not chosen: (c) Keep UTC and add a second run, in CI only. `npm run test:coverage` stays as it is, and one new step in the `Lint, typecheck, test` job runs the three packages' tests again with `TZ: America/New_York`. CI catches both kinds of break. Local `npm test` and `npm run mutate` keep the machine's zone, so an agent sees D25-type breaks locally only by adding a `TZ=` prefix by hand. The `@sched/tools` DynamoDB suite runs twice inside the job's 10-minute limit (`ci.yml:30`). `CLAUDE.md:122` and the `ci.yml` header change together (sync region `ci-checks`, `scripts/sync-regions.test.ts:1-7`). Scope: within the issue. Owned paths: + `.github/workflows/ci.yml` (the header comment, lines 1-11)
- **r1/Q-2** (settled against `66971d5`): Does a guard test fail when the zone setting is removed? → (a) Each of the three packages gets one guard test, with the zone set in that package's Vitest config (Q-1 (a) or (b)). The test asserts that `new Intl.DateTimeFormat().resolvedOptions().timeZone` is the chosen zone. The PR's mutate table deletes each config's `TZ` entry, and each deletion is KILLED by that package's guard. Scope: adds 3 small tests. Owned paths: + `packages/contracts/src/zone.test.ts`, `packages/tools/test/zone.test.ts`, `packages/agent/test/zone.test.ts` (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/210#issuecomment-6060229351))
  - edges: Under Q-1 (c), option (a) can't work: the guard would fail the UTC `npm run test:coverage` run, so only (b) fits. The list of guards is complete at one per package; a single shared guard wouldn't fail when only one package's setting is removed. Contracts' guard must sit under `src/`, because `packages/contracts/tsconfig.json` includes only `src`; the tools and agent paths are suggestions. Evidence: the mutate rows each name the package's guard test in `expect`.
  - not chosen: (b) No guard test. The criterion-2 rows for D25 and P5 are the evidence for the setting. The PR records that no test fails when the setting alone is removed, and this decision is the recorded exception to the definition of done. Scope: within the issue.
- **r1, assumed** (as of `66971d5`):
  - A-1: **(verify first)** When the zone is set in Vitest config (Q-1 (a) or (b)), the agent sets it as `test.env: { TZ: "<zone>" }` in each new `packages/<p>/vitest.config.ts`. These files are required by Q-1. It doesn't set it in the root `vitest.config.ts`: Vitest 5.0.2 resolves directory projects with `configFile: false` (`node_modules/vitest/dist/chunks/index.C-uw7tH9.js:12580-12588`), so root `test` options don't reach them. It doesn't use a top-level `process.env.TZ = ...` in a config either, because configs load in Vitest's main process and that assignment would reach every project. Each config also sets `test.name: "@sched/<dir>"`, which is a suggestion: nothing depends on project names. Before building on any of this, the agent confirms the setting reaches the test workers: with no `TZ=` prefix, D25 is KILLED. (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/210#issuecomment-6060229351))
  - A-2: The agent shows criterion 2 with a local `npm run mutate -- <edits> --markdown -- <command>` table in the PR body, and doesn't push a mutated commit to CI. D25 and P5 are copied verbatim from PR #208's table: D25 `.getUTCDay()` → `.getDay()`; P5 `    timeZone: "UTC",⏎    weekday: "long",` → `    weekday: "long",`. The `<command>` is what CI runs for those tests (see Q-1's Edges).
  - A-3: The agent expects no test to need fixing or pinning: a search found no local-zone read in any test, and the only one in source is `system.v1.ts:159`, which is pinned to UTC. If a test does fail under the zone, the agent rewrites that test so it doesn't depend on the zone. It changes no source file. If the failure shows a real bug in `dates.ts`, `clock.ts` or `system.v1.ts`, the agent reports it on #210 and asks rather than fixing it here (E-2). (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/210#issuecomment-6060229351))
  - A-4: Under Q-1 (a) or (b), no CI step is added, so criterion 4 doesn't apply and the agent adds no `CLAUDE.md` line. A comment at the top of each new config says why the zone is set (D25, P5, #210). Under Q-1 (c), the agent edits both copies of the `ci-checks` region rather than using a `Sync-checked` trailer. (makes stale: Under Q-1 (c) only:; `CLAUDE.md:122`; `.github/workflows/ci.yml:2-10`)
  - A-5: The agent writes a new journal entry with its row in `docs/journal/README.md`. It doesn't edit the dated lines in `docs/journal/2026-10-07-one-copy-of-the-clinic-calendar.md` ("CI runs in UTC, so CI alone would not catch either regression"; "#210 tracks running the date tests in CI").


## Readiness notes

Pointers from readiness reviews. They are not owner decisions: follow them, or say in the PR why not.

- **r1, reuse** (as of `66971d5`): 
  - D25 and P5: copy them verbatim from PR #208's body (Seen failing table, rows D25 and P5). They aren't in the repo.
  - The mutate run: import nothing, and call `npm run mutate` (`scripts/mutate.ts`) as a CLI with `--only` and `--markdown`.
  - The zone string: hard-code it in each config. Don't import `CLINIC.timezone` from `@sched/contracts`, because under Q-1 (a) the zone is deliberately not the clinic's.

