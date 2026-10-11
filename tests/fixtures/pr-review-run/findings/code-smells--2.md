# Code-smells review: PR #70 @ d34b6df

## 1. Findings

### SMELL-201: The handler's header summary still says check_availability searches "across the clinic", which the same file now rejects

- **Severity:** minor
- **Confidence:** high
- **Category:** Noise comments (stale / misleading comment)
- **Location:** `packages/tools/src/tools/check_availability.ts:2-3`
  `packages/tools/src/tools/check_availability.ts:10-11`
  `packages/tools/src/tools/check_availability.ts:122-127`
- **Evidence:**
  ```ts
   * check_availability (FR-030): open slots by provider, by specialty, or across the clinic, within a
   * clinic-local date range, optionally mornings or afternoons only.
  ...
   * - neither → INVALID_INPUT (decision, PR #70 review): a clinic-wide list mixes specialties the patient
   *   didn't ask for, so the hint sends the model back to ask what kind of visit or which provider.
  ...
    } else {
      return toolFail(
        "INVALID_INPUT",
        "Say which provider or which specialty to search: provider_id or specialty is required.",
  ```
- **Measured against:** `packages/tools/src/tools/check_availability.ts:10` — "neither → INVALID_INPUT (decision, PR #70 review): a clinic-wide list mixes specialties the patient". The brief's dispensables family covers comments that no longer describe the code. Commit `d34b6df` changed the "neither" branch into an error but left the file's opening sentence as it was.
- **Why it matters:** The first line of the header says what the tool does. A future editor or the author of a sibling tool reads that line first, and it now describes a clinic-wide search that no longer exists. Lines 10-11 in the same header contradict it. The owner made a deliberate decision on this behaviour, and this line misstates it.
- **Suggested fix:** Change line 2 to "open slots by provider or by specialty (one of them is required), within a". Leave lines 10-11 as they are.
- **Introduced by this PR:** yes
- **Action:** fix now

### SMELL-202: The handler re-sorts results with a hand-written comparator, although the repository contract already returns them in that order

- **Severity:** nit
- **Confidence:** medium
- **Category:** Defence against impossible states / Duplication
- **Location:** `packages/tools/src/tools/check_availability.ts:61-65`
  `packages/tools/src/tools/check_availability.ts:130`
  `packages/tools/src/repos/in-memory.ts:162`
  `packages/tools/src/repos/dynamo/repositories.ts:233-237`
- **Evidence:**
  ```ts
  const byStartThenProvider = ({ slot: a }: Candidate, { slot: b }: Candidate): number => {
    const d = Date.parse(a.startUtc) - Date.parse(b.startUtc);
    if (d !== 0) return d;
    return a.providerId < b.providerId ? -1 : a.providerId > b.providerId ? 1 : 0;
  };
  ...
    candidates.sort(byStartThenProvider);
  ```
- **Measured against:** `packages/tools/src/repos/types.ts:80` — "AP-4. OPEN slots for one provider whose start is in `range`, ascending by start." and `packages/tools/src/repos/types.ts:85-86` — "AP-5. OPEN slots in a specialty on one clinic-local day (`clinicDateOf(startUtc)`), ascending by start, then providerId." The provider path gets one provider's slots, already in start order. The specialty path concatenates whole clinic days, walked in ascending order (line 117), and each day is already ordered by start and then providerId. `offerable` only filters, so it keeps that order. The concatenation is therefore already in `byStartThenProvider` order. The same comparator is written inline in `in-memory.ts:162` and `dynamo/repositories.ts:233-237`, and this is a third copy.
- **Why it matters:** The sort cannot change the result while both repositories meet their contract, which `test/contract/repositories.contract.ts` checks. What the sort adds is a third hand-written copy of the slot ordering, which must be kept in step with the repositories if that ordering ever changes. The cost is small, so this is a nit.
- **Suggested fix:** Remove `byStartThenProvider` and the `sort` call. Add a one-line comment saying that the repositories return each query in (start, providerId) order and that days are walked in order. If the owner prefers to keep the guard, move one shared `compareSlots` into `repos/` next to `compareProviders` (`repos/provider-match.ts:31`), and have both repositories and this handler use it.
- **Introduced by this PR:** yes
- **Action:** fix now

### SMELL-203: The test helper hardcodes the visit length instead of using `CLINIC.visitMinutes`

- **Severity:** nit
- **Confidence:** high
- **Category:** Duplication (magic number for an existing constant)
- **Location:** `packages/tools/test/tools/check_availability.test.ts:40-47`
- **Evidence:**
  ```ts
  /** An extra OPEN 30-minute slot for a fixture provider, at any hour (the seed validator allows it). */
  const openSlot = (provider: Provider, startUtc: string): Slot => ({
  ...
    endUtc: toCanonicalUtc(new Date(Date.parse(startUtc) + 30 * 60_000)),
  ```
- **Measured against:** Precedent, not a written rule. `packages/contracts/src/clinic.ts:13` defines `visitMinutes: 30,`. `packages/tools/fixtures/clinic-default.ts:320` (`const visit = CLINIC.visitMinutes;`) and `packages/tools/test/fixtures/clinic-default.test.ts:73` (`CLINIC.visitMinutes * 60_000`) both use the constant rather than a literal.
- **Why it matters:** If the visit length changes, this helper keeps making 30-minute slots that the fixture no longer has. It is a test-only helper, so the risk is small.
- **Suggested fix:** Use `CLINIC.visitMinutes * 60_000`, importing `CLINIC` from `@sched/contracts`. Drop "30-minute" from the doc comment, or keep it in step with the constant.
- **Introduced by this PR:** yes
- **Action:** fix now

## 2. Coverage ledger

### Sources read
| Source | Why |
|---|---|
| `packages/tools/src/tools/check_availability.ts` (full file) | changed file |
| `packages/tools/src/tools/find_providers.ts` (full file) | changed file |
| `packages/tools/src/registry.ts` (full file) | changed file; also shows the norm for helpers such as `toolOk` and `toolFail` and for function length (`createToolExecutor`, lines 159-238) |
| `packages/tools/test/tools/check_availability.test.ts` (full file) | changed file |
| `packages/tools/test/tools/find_providers.test.ts` (full file) | changed file |
| `diff.patch` (contracts `clinic.ts`, snapshot, journal, journal README hunks) | changed files, one line each or docs |
| `packages/tools/src/clock.ts` (full file) | shared helpers the handler should reuse (`clinicDateOf`, `clinicDateRangeUtc`, `addDays`, `toZonedParts`, `formatClinicDateTime`) |
| `packages/tools/src/repos/types.ts` (full file) | the repository ordering contract; the convention on throws and typed results |
| `packages/tools/src/repos/provider-match.ts` (full file) | the existing comparator (`compareProviders`) and name matching |
| `packages/tools/src/repos/in-memory.ts:70-180` | existing `byStart` / `byKey` comparators; the AP-4 and AP-5 implementations |
| `packages/tools/src/repos/dynamo/repositories.ts:160-280` | the Dynamo AP-3, AP-4 and AP-5 implementations and their ordering |
| `packages/tools/src/repos/seed.ts` (full file) | whether a slot with a missing provider is already impossible (the check at line 108) |
| `packages/tools/fixtures/index.ts`, `packages/tools/fixtures/clinic-default.ts:300-360` | whether a slot-builder helper already exists for tests |
| `packages/contracts/src/tools.ts:100-130` (plus grep hits at lines 36-60, 166-226) | the input and output contracts; `SlotOption` and `ProviderSummary` |
| `.claude/skills/add-agent-tool/SKILL.md` | the norm for handler shape, test scaffolding and per-file mappers |
| `CLAUDE.md` | architecture rules |
| `spec/issue-19.json` | owned paths; the comment that sanctions per-tool summary mappers |
| `manifest.md` | the owner's decisions and the machine-enforced rules |

### Checks performed
| # | Check | Scope | Result |
|---|---|---|---|
| 1 | Duplication: `toSlotOption` against any existing Slot→SlotOption mapper | `check_availability.ts:52-59` vs the whole repo | pass (no other mapper exists) |
| 2 | Duplication: `toProviderSummary` against existing mappers | `find_providers.ts:14-19` | pass. The only other copy is the skill's worked example. Issue #19's comment says "The summary mappers (`ProviderSummary` for #19/#20 ...) will be duplicated per tool file for now." |
| 3 | Duplication: `matchesTimeOfDay` / `NOON` against existing time-of-day helpers in `clock.ts` and elsewhere | `check_availability.ts:35-44` | pass. It reuses `toZonedParts`, and nothing else splits by time of day. |
| 4 | Duplication: date conversion and day walking reuse `clock.ts` rather than offset math | `check_availability.ts:71, 79, 110, 117` | pass (`clinicDateOf`, `clinicDateRangeUtc`, `addDays`, `formatClinicDateTime`) |
| 5 | Duplication: the slot comparator against existing comparators | `check_availability.ts:61-65` | finding SMELL-202 |
| 6 | Duplication inside the PR: the same block pasted across the two handlers or test files | both handlers and both tests | pass. The `outputOf`/`errorOf`/`run` scaffolding repeats the skill's per-file test pattern. |
| 7 | Duplication: the test slot builder against existing fixture or scenario helpers | `check_availability.test.ts:40-47` | pass (nothing exported builds a slot). The magic number is reported as finding SMELL-203. |
| 8 | Bloaters: handler length compared with neighbours | `check_availability.ts:67-132` (66 lines) vs `createToolExecutor` (80 lines) and in-memory repo methods | pass |
| 9 | Bloaters: long parameter lists, data clumps, primitive obsession | both handlers | pass. It uses the contracts types (`Slot`, `Provider`, `ProviderId`, `ToolInput`). `startUtc: string` matches the repo's convention. |
| 10 | Change preventers: shotgun surgery, parallel hierarchies | `registry.ts`, `clinic.ts`, snapshot | pass. The registry change is two lines under the #19 anchors, as the skill requires. The limit change is one constant, and the description and snapshot follow it by interpolation. |
| 11 | Change preventers: divergent change | `registry.ts`, `clinic.ts` | pass |
| 12 | Couplers: feature envy, intimacy, message chains, layer direction | both handlers | pass. They use only `ctx.clock` and `ctx.repos`, plus the exported `clock.ts` and `registry.ts` helpers. The `tools/*` → `registry` import cycle is the pattern the skill prescribes (value imports are used only inside functions at call time). |
| 13 | Dispensables: dead code, unused imports or params | both handlers | pass. Every import is used, and there are no unused parameters. |
| 14 | Dispensables: speculative generality | `check_availability.ts` (`offerable` taking a providers map, `Candidate`) | pass. `offerable` is shared by both paths, and on the provider path it takes a single-entry map. |
| 15 | Dispensables: noise, stale or narrating comments | header of `check_availability.ts`, inline comments | finding SMELL-201. "(decision, PR #70 review)" and "(decision)" at lines 10 and 17 are rationale pointers, not edit narration, so they pass. |
| 16 | Dispensables: commented-out code, debug output, TODO/FIXME | both handlers and both tests | pass (grep found none) |
| 17 | OO abusers: switch on a type code | `check_availability.ts:98-128` (the provider / specialty / neither branches) | pass. There are three query paths that differ in shape, and no lookup-table precedent exists. |
| 18 | Agent patterns: placeholder or stub behaviour | both handlers | pass. Both paths query the real repos, and the owner decided the "neither" branch is an error. |
| 19 | Agent patterns: swallowed errors | `check_availability.ts:82-89` (drops a slot whose provider is missing) | pass. The seed invariant at `seed.ts:108` makes this unreachable for seeded data, and the skill's worked example sets the norm: "a dangling reference degrades to `null` instead of failing the whole call". Nothing is caught and hidden. |
| 20 | Agent patterns: defence against impossible states | `check_availability.ts:130` (re-sort); `:84-86` (provider lookup on the provider path) | finding SMELL-202 (re-sort). The provider-path lookup is covered in row 14. |
| 21 | Agent patterns: unrequested compatibility shims or flags | whole diff | pass |
| 22 | Agent patterns: unrelated churn | `registry.ts`, `clinic.ts`, snapshot, journal README | pass. Every hunk serves the task or the owner's slot-limit decision. |
| 23 | Agent patterns: weakened types (`any`, `as`, `!`, suppressions) | both handlers and both tests | pass (grep found none) |
| 24 | All families | `docs/journal/*` | not applicable (prose docs, no code) |

### Searches run
| Query or command | Purpose | Hits |
|---|---|---|
| `grep -rn "SlotOption" apps packages services scripts spikes` (excluding tests) | existing equivalent of `toSlotOption` | 8 (contracts schema and examples, plus the new file; no mapper) |
| `grep -rn "ProviderSummary" ...` (excluding tests) | existing equivalent of `toProviderSummary` | 9 (contracts schema and examples, plus the new file; no mapper) |
| `grep -rn "start_local" ...` (excluding tests) | another place that builds slot options | 16 (contracts, clock doc, spike fixture; no builder) |
| `grep -rn "provider_name" ...` / `"accepting_new_patients"` | the same, for field mapping | 7 / 4 (no other mapper) |
| `grep -rn "NOON" ...` | an existing noon constant | 2 (both in the new file) |
| `grep -rn "morning" ...` / `"afternoon"` | an existing time-of-day filter | 6 / 9 (contracts and the new file only) |
| `grep -rn "hour < 12\|hour >= 12\|< 12\b" ...` | the same, by logic fragment | 0 |
| `grep -rn "providerId < \|localeCompare\|byStart\|compareSlots\|\.sort(" ...` | an existing slot comparator | 24 (inline comparators in `in-memory.ts:162`, `dynamo/repositories.ts:233-237`; `compareProviders`; no exported slot comparator) |
| `grep -rn "addDays(" ...` | day-walk helper reuse | 8 |
| `grep -rn "Date.parse(.*startUtc" ...` | hand-rolled instant comparison elsewhere | 6 |
| `grep -rn "clinicDateOf(" ...` | clinic-day helper reuse | 5 |
| `grep -rn "time_of_day\|timeOfDay\|TimeOfDay" ...` | an existing `TimeOfDay` type or helper | 11 (contracts schema and the new file) |
| `grep -rn "makeSlotId(" packages` | an existing test slot builder | 7 (fixture internals, seed, contracts tests; nothing exported for tests) |
| `grep -rn "30 \* 60_000\|visitMinutes" packages` | the visit-length constant against literals | 6 |
| `grep -rn "const outputOf\|const errorOf" packages` | test scaffolding duplicated in shared test utils | 4 (only the two new test files; the skill's pattern is per file) |
| `grep -rn "createInMemoryRepositories({" packages` | shared test setup helper | 11 (every test builds its own; no shared helper) |
| `grep -rn "export function .*[Ss]lot\|export const .*[Ss]lot" packages` | exported slot helpers | 10 (Dynamo item mappers, contracts ids and schemas; nothing reusable for tests) |
| `grep -nE " as \|!\.\|any\b\|eslint-disable\|ts-ignore\|TODO\|FIXME\|console\." <changed ts files>` | weakened types, debug output, placeholders | 7 (all false positives in prose or `"any"` enum) |
| `grep -rn "across the clinic\|clinic-wide" packages docs/adr docs/PRD.md` | stale description of the removed clinic-wide path | 2 (`check_availability.ts:2`, `:10`) |

## 3. Not reviewed

- `packages/tools/src/repos/in-memory.ts` and `packages/tools/src/repos/dynamo/repositories.ts`: read only in the ranges listed above (unchanged files, read for precedent).
- `docs/journal/*`: prose. The smell families do not apply to it, and the standards reviewer owns the journal convention.
- Correctness of the handler logic (date clamping, truncation) and whether the tests are adequate: outside this brief, except where a smell touched them.
