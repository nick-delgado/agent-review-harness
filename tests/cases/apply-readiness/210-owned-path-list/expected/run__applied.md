<!-- agent-pr-review:readiness-applied round=1 -->
## Readiness answers applied (round 1)

Only `Decision r1/<ID>: ...` lines count; other replies are not applied. `ALL` accepted the recommendations and edits, but not the assumptions that need an explicit answer.

**Applied:**
- Q-1: accepted the recommendation, (a) Replace UTC with `America/Los_Angeles` (west of UTC, and not the clinic's zone) for every test of the three packages. Each of `packages/contracts`, `packages/tools` and `packages/agent` gets a `vitest.config.ts` that sets `TZ` for its project, so every run uses that zone: `npm test`, `npm test -w`, `npm run mutate` and CI's `npm run test:coverage`. No CI step is added. One run kills D25, P5 and the `clock.ts:148` break, and local runs match CI. Scope: within the issue. Owned paths: + `packages/contracts/tsconfig.json`, `packages/tools/tsconfig.json`, `packages/agent/tsconfig.json` (each `include` lists the new config, so `npm run typecheck` checks it)
- Q-2: accepted the recommendation, (a) Each of the three packages gets one guard test, with the zone set in that package's Vitest config (Q-1 (a) or (b)). The test asserts that `new Intl.DateTimeFormat().resolvedOptions().timeZone` is the chosen zone. The PR's mutate table deletes each config's `TZ` entry, and each deletion is KILLED by that package's guard. Scope: adds 3 small tests. Owned paths: + `packages/contracts/src/zone.test.ts`, `packages/tools/test/zone.test.ts`, `packages/agent/test/zone.test.ts`
- owned path already listed: `packages/contracts/tsconfig.json`
- owned path added: `packages/tools/tsconfig.json`
- owned path added: `packages/agent/tsconfig.json`
- owned path added: `packages/contracts/src/zone.test.ts`
- owned path added: `packages/tools/test/zone.test.ts`
- owned path added: `packages/agent/test/zone.test.ts`

**Not applied:**
- E-1 (Make criterion 1 say which zones count and which tests are covered): its Before text is not in the description any more; not applied
- E-2 (Add the non-goals the owned paths imply): its Before text is not in the description any more; not applied
- E-3 (Add the Verification section the issue form requires): its Before text is not in the description any more; not applied

**Still open** (each needs its own `Decision` line):
- nothing

**To check** (written for an answer you did not choose; correct with a new `Decision` line or a refresh):
- Q-2's edges mentions only Q-1 (c), but (a) was chosen: check whether it still applies
