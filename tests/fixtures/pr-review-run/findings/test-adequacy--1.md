# Test adequacy review: PR #70

Nothing was executed. Every "would fail if broken" judgement below comes from reading the tests against the handler, the in-memory repo and the fixture, not from running a mutation.

## 1. Findings

### TEST-101: No test would fail if the two tools were not registered in `TOOL_REGISTRY`

- **Severity:** major
- **Confidence:** high
- **Category:** untested-behaviour
- **Location:** `packages/tools/src/registry.ts:107-110`
  `packages/tools/test/tools/check_availability.test.ts:33`
  `packages/tools/test/tools/find_providers.test.ts:32`
  `packages/tools/test/registry.test.ts:109-116`
- **Evidence:**
  ```ts
  // src/registry.ts
  export const TOOL_REGISTRY: ToolRegistry = {
    // #19 find_providers, check_availability
    find_providers: findProviders,
    check_availability: checkAvailability,
  ```
  ```ts
  // test/tools/check_availability.test.ts: the tests build their own registry
  return createToolExecutor({ check_availability: checkAvailability }, ctx).execute({
  ```
  ```ts
  // test/registry.test.ts: the only test that touches TOOL_REGISTRY is true for any contents
  it("is empty for the (still empty) production registry, whose keys are all tool names", () => {
    expect(Object.keys(TOOL_REGISTRY).every((k) => (TOOL_NAMES as readonly string[]).includes(k))).toBe(
      true,
    );
    expect(createToolExecutor(TOOL_REGISTRY, ctx).definitions.length).toBe(
      Object.keys(TOOL_REGISTRY).length,
    );
  });
  ```
- **Measured against:** `spec/issue-19.json` (acceptance criteria) — "Registered in ToolRegistry; tool description reviewed against the skill's guidelines"; `.claude/skills/add-agent-tool/SKILL.md:104` — "Registration is also what makes the tool visible to the model: an unregistered tool is never offered."
- **Why it matters:** Deleting both registry entries, or pointing `find_providers` at the wrong handler, leaves the whole suite green, and the model is then never offered the tools. The existing registry test passes for an empty registry and for a full one, so the green CI run says nothing about this acceptance criterion.
- **Suggested fix:** In each new test file (inside the owned paths) add one test that runs a call through `createToolExecutor(TOOL_REGISTRY, ctx)` and checks that `definitions` contains the tool name and that a happy-path call returns the expected output. The stale "is empty" test in `registry.test.ts` is outside the owned paths and is already listed as a follow-up in the PR body.
- **Introduced by this PR:** yes (the vacuous registry test is pre-existing; the PR relies on it)

### TEST-102: The "no spill from UTC midnight" test never reaches the code that converts the date range

- **Severity:** major
- **Confidence:** high
- **Category:** hollow-test
- **Location:** `packages/tools/test/tools/check_availability.test.ts:146-163`
  `packages/tools/test/tools/check_availability.test.ts:125-144`
  `packages/tools/src/tools/check_availability.ts:104-105`
- **Evidence:**
  ```ts
  it("keeps an EST day's range to exactly that clinic day (no spill from UTC midnight)", async () => {
    const all = outputOf(await run({ specialty: "physical_therapy", date_range: days("2026-11-02") }));
    ...
    expect(afternoon.slots.every((s) => s.start_local.startsWith("Monday, November 2"))).toBe(true);
  ```
  ```ts
  // the only range conversion in the handler, on the provider_id path
  const utc = clinicDateRangeUtc(firstDay, range.end_date);
  matches = (await ctx.repos.slots.listOpenByProvider(providerId, utc)).filter(wanted);
  ```
- **Measured against:** `.claude/skills/add-agent-tool/SKILL.md:147` — "Hand-rolled offset math, or a range built in UTC instead of `clinicDateRangeUtc`. Test a slot on each side of Nov 1"
- **Why it matters:** The test uses `specialty`, so the handler passes the day string straight to `listOpenBySpecialtyAndDay` and the in-memory repo does the day matching (`src/repos/in-memory.ts:161`); the handler's range conversion is not executed. The DST test on the `provider_id` path (lines 125-144) cannot catch a wrong range either: the fixture only has slots from 8:00 AM to 5:00 PM ET (`fixtures/clinic-default.ts:6`), which is 12:00Z to 22:00Z, so a range built from UTC midnights returns the same slots as the clinic-local one. Replacing `clinicDateRangeUtc(...)` with a UTC-day range would leave all 21 tests green, while the PR body claims the ranges are tested as DST-safe.
- **Suggested fix:** Add a `provider_id` test with seeded slots near clinic midnight, for example 11:30 PM ET on the requested day (next day in UTC, must be returned) and 7:30 PM ET on the day before (requested day in UTC during EST, must not be returned). `find_providers.test.ts:111-115` already shows how to extend the fixture seed. Rename the existing test to say what it checks (an EST day's afternoon slots and their strings).
- **Introduced by this PR:** yes

### TEST-103: The early-exit condition and `truncated` across several days have no test

- **Severity:** minor
- **Confidence:** medium
- **Category:** missing-case
- **Location:** `packages/tools/src/tools/check_availability.ts:111`
  `packages/tools/test/tools/check_availability.test.ts:231-241`
- **Evidence:**
  ```ts
  for (let day = firstDay; day <= range.end_date && matches.length <= MAX; day = addDays(day, 1)) {
  ```
  ```ts
  { specialty: "cardiology", date_range: days("2026-10-06", "2026-10-06") },
  ```
- **Measured against:** `.claude/skills/add-agent-tool/SKILL.md:96` — "truncation at the limit"; `.claude/skills/add-agent-tool/SKILL.md:76` — "respect them and set `truncated` when you cut"
- **Why it matters:** The walk must continue past a day that yields exactly 10 matches to know whether more exist. Every specialty-path test either gets more than 10 on the first day, gets 0, 0, 9 on a range that ends there, or uses a one-day range for the exactly-10 case. Changing `<=` to `<` would stop after exactly 10, report `truncated: false` with more slots on the next day, and no test would fail. No test returns slots drawn from two different days on this path either.
- **Suggested fix:** Reuse the exactly-10 setup (`clock.set("2026-10-06T15:30:00Z")`, cardiology) with `days("2026-10-06", "2026-10-07")` and assert `truncated: true` and two calls to `listOpenBySpecialtyAndDay`. Add one case where the first day gives fewer than 10 and the result spans two days in time order.
- **Introduced by this PR:** yes

### TEST-104: "Today" is never tested at an hour when the UTC date differs from the clinic date

- **Severity:** minor
- **Confidence:** medium
- **Category:** missing-case
- **Location:** `packages/tools/src/tools/check_availability.ts:66-75`
  `packages/tools/test/tools/check_availability.test.ts:244-280`
- **Evidence:**
  ```ts
  const today = clinicDateOf(now);

  if (range.end_date < today) {
  ```
  ```ts
  clock.set("2026-10-13T20:45:00Z"); // Tue Oct 13, 4:45 PM ET: after the last slot starts
  ```
- **Measured against:** `.claude/skills/add-agent-tool/SKILL.md:72` — "Date inputs are clinic-local days; convert with `clinicDateRangeUtc` / `zonedTimeToUtc`, which handle DST (the fixture window crosses Nov 1, 2026). Never do offset math by hand."
- **Why it matters:** The past-date rule (reject, clamp, today allowed) is new behaviour decided in this PR. All clock values in the tests (9:00 AM, 11:30 AM, 4:45 PM ET) fall on the same calendar date in UTC and in ET. If `today` were taken from the UTC date, a request for today made after 8:00 PM ET would be rejected as "in the past", and the tests would still pass.
- **Suggested fix:** Add a case with the clock at about 9:00 PM ET (`clock.set("2026-10-06T01:00:00Z")`, which is Mon Oct 5 in ET): `days("2026-10-05")` must be an empty success, not `INVALID_INPUT`, and a range starting `2026-10-05` must start its day walk on `2026-10-05`.
- **Introduced by this PR:** yes

### TEST-105: The branch that drops a slot whose provider record is missing is never exercised

- **Severity:** minor
- **Confidence:** medium
- **Category:** untested-behaviour
- **Location:** `packages/tools/src/tools/check_availability.ts:78-83`
  `packages/tools/src/tools/check_availability.ts:122-125`
- **Evidence:**
  ```ts
  // Future, in the requested part of the day, and describable. A slot whose provider record is missing
  // can't be named to the patient, so it is left out rather than failing the whole search.
  const wanted = (slot: Slot): boolean =>
    Date.parse(slot.startUtc) > nowMs &&
    matchesTimeOfDay(slot.startUtc, timeOfDay) &&
    providers.has(slot.providerId);
  ```
- **Measured against:** `CLAUDE.md:118` — "Tests are added or updated, and `npm run lint && npm run typecheck && npm test` passes."
- **Why it matters:** In the fixture every slot's provider exists, so removing the `providers.has` check changes no test result. The stated design decision (skip the slot, do not fail the search, and keep `truncated` consistent) is unverified. It may also be unreachable with the in-memory repo if seed validation rejects orphan slots; I did not check `src/repos/seed.ts`.
- **Suggested fix:** If an orphan slot can be seeded, add one test that seeds it and asserts it is absent and the call succeeds. If the seed validator forbids it, say so in the comment or remove the branch.
- **Introduced by this PR:** yes

### Behaviour coverage

| Behaviour | Source | Test | Would fail if broken? |
|---|---|---|---|
| Both tools registered in `TOOL_REGISTRY` | issue #19 AC5, `src/registry.ts:109-110` | none | — (TEST-101) |
| Input validated by contract schema (bad range, enum, date format, empty name) | issue #19 AC1 | `check_availability.test.ts:283`, `find_providers.test.ts:122` | yes (exercises the executor, which is where validation lives) |
| Handler uses only injected context and repos | issue #19 AC1 | all tests run on in-memory repos and a `FrozenClock` | partly: a `new Date()` in the handler would break the frozen-clock cases |
| Model-supplied `patient_id` rejected; same answer for every patient | issue #19 AC4 | `check_availability.test.ts:293,299`, `find_providers.test.ts:127` | yes |
| Nothing written | skill section 3 | `check_availability.test.ts:311`, `find_providers.test.ts:133` | yes |
| find_providers: unfiltered list, stable order | `find_providers.ts:22-28` | `find_providers.test.ts:45` | yes |
| find_providers: name query, exact summary shape | `find_providers.ts:14-24` | `find_providers.test.ts:60,83` | yes |
| find_providers: specialty filter, and combined with name | `find_providers.ts:23-24` | `find_providers.test.ts:74,78` | yes |
| find_providers: no match is an empty success | `find_providers.ts:26` | `find_providers.test.ts:94` | yes |
| find_providers: capped at `LIMITS.providersMaxResults` | `find_providers.ts:27` | `find_providers.test.ts:98` | yes (25 extra providers seeded; without the cap the output schema fails) |
| check_availability by provider: exact slot, time order, booked slot absent | `check_availability.ts:87-105` | `check_availability.test.ts:47,91` | yes |
| Unknown `provider_id` gives `NOT_FOUND` with hint | `check_availability.ts:89-95` | `check_availability.test.ts:101` | yes |
| Provider contradicts specialty gives `INVALID_INPUT` | `check_availability.ts:96-102` | `check_availability.test.ts:107,115` | yes (hint only checked as defined) |
| `time_of_day` split at 12:00 PM ET | `check_availability.ts:41-45` | `check_availability.test.ts:78` | yes |
| Specialty filter uses the sparse specialty+day index, with early exit | issue #19 AC3, `check_availability.ts:107-116` | `check_availability.test.ts:167,187` | yes for the path and for stopping when over the limit |
| Early exit continues at exactly the limit; `truncated` across days | `check_availability.ts:111,127` | `check_availability.test.ts:231` (one-day range only) | no (TEST-103) |
| Clinic-wide search over all specialties | `check_availability.ts:109` | `check_availability.test.ts:201` | yes |
| Empty result is a success with `[]` | skill section 3 | `check_availability.test.ts:222,273` | yes |
| `truncated` false at exactly the limit, true above it | `check_availability.ts:127` | `check_availability.test.ts:231,167` | yes (single day) |
| `start_local` in clinic time with weekday, both sides of DST | issue #19 AC2 | `check_availability.test.ts:125` | yes for the strings and instants |
| Date range converted as clinic-local days (provider path) | `check_availability.ts:104` | `check_availability.test.ts:146` by name only | no (TEST-102) |
| Slots that already started are not offered (strictly after now) | `check_availability.ts:81` | `check_availability.test.ts:245,273` | yes |
| Range starting in the past is clamped to today | `check_availability.ts:75` | `check_availability.test.ts:255` | yes on the specialty path |
| Range ended before today gives `INVALID_INPUT` | `check_availability.ts:68-74` | `check_availability.test.ts:264` | yes |
| "Today" is the clinic date, not the UTC date | `check_availability.ts:66` | none | — (TEST-104) |
| Slot with a missing provider record is skipped | `check_availability.ts:78-83,122-125` | none | — (TEST-105) |
| Returns at most 5 slots | issue #19 AC2, `docs/PRD.md:82` | none; tests assert `LIMITS.availabilityMaxSlots` (10) | — no test for 5. The PR body discloses the conflict between the issue and the contract; this is a spec question, not raised as a test finding |
| L1 eval case added or listed | issue #19 AC6 | none added; listed in PR body | not a unit-test matter |

## 2. Coverage ledger

### Sources read
| Source | Why |
|---|---|
| `skills/review-agent-pr/reviewers/test-adequacy.md`, `references/finding-schema.md`, `manifest.md` | brief, format, inputs |
| `spec/issue-19.json` (body and 2 comments) | acceptance criteria |
| `pr.json` (body) | claimed behaviour and verification |
| `ci.txt` | CI result |
| `packages/tools/src/registry.ts` (full) | changed file, executor behaviour |
| `packages/tools/src/tools/check_availability.ts` (full) | changed file |
| `packages/tools/src/tools/find_providers.ts` (full) | changed file |
| `packages/tools/test/tools/check_availability.test.ts` (full) | new test |
| `packages/tools/test/tools/find_providers.test.ts` (full) | new test |
| `packages/tools/test/registry.test.ts` (test names, lines 105-117) | existing test of `TOOL_REGISTRY` |
| `packages/tools/src/repos/in-memory.ts` (lines 144-165) | what the slot queries do in tests |
| `packages/tools/src/clock.ts` (lines 196-212) | `clinicDateRangeUtc` |
| `packages/tools/fixtures/clinic-default.ts` (header, grep) | slot hours in the fixture |
| `packages/contracts/src/tools.ts` (schemas for the two tools), `clinic.ts` limits | input and output contract |
| `.claude/skills/add-agent-tool/SKILL.md` (sections 1-7) | documented test conventions |
| `CLAUDE.md` (test lines) | definition of done |
| `vitest.config.ts`, `package.json`, `packages/tools/package.json` | runner configuration |

### Checks performed
| # | Check | Scope | Result |
|---|---|---|---|
| 1 | Registration in `TOOL_REGISTRY` has a test that fails if removed | `registry.ts`, all tests importing `TOOL_REGISTRY` | finding TEST-101 |
| 2 | Input validation cases go through the executor and assert `INVALID_INPUT` | both new test files | pass |
| 3 | `patient_id` rejection, same output per patient, snapshot unchanged | both new test files | pass (note: "reads no patient data" in `find_providers.test.ts:127` is checked only as equal output for two patients) |
| 4 | find_providers list, name, specialty, combined, empty, cap | `find_providers.test.ts` | pass |
| 5 | check_availability provider path: output shape, order, booked slot excluded, `NOT_FOUND`, specialty mismatch | `check_availability.test.ts:46-122` | pass |
| 6 | `time_of_day` boundary | `check_availability.test.ts:78` | pass |
| 7 | Sparse index path and early exit asserted on spies, not on return values of mocks | `check_availability.test.ts:167-199` | pass (spies wrap the real repo) |
| 8 | Early exit at exactly the limit, multi-day accumulation | `check_availability.ts:111` | finding TEST-103 |
| 9 | DST and clinic-day range conversion is actually exercised | `check_availability.test.ts:124-164` against handler line 104 and fixture hours | finding TEST-102 |
| 10 | Past-date rules: strict "after now", clamp, reject, clock moves | `check_availability.test.ts:244-280` | pass, with finding TEST-104 for the evening case |
| 11 | Missing-provider skip branch | `check_availability.ts:78-83` | finding TEST-105 |
| 12 | Truncation at and above the limit | `check_availability.test.ts:167,231` | pass for one day |
| 13 | Hollow-test patterns: missing `await`, assertions on mocks, truthy-only, snapshots | both new test files | pass (no snapshots, all calls awaited, `error.hint` `toBeDefined` at line 112 is the only loose assertion) |
| 14 | Weakened verification: modified or deleted test files | `diff.patch` (+617/-0, two new test files, no existing test touched) | not applicable: no test file modified or deleted, no config or threshold change |
| 15 | Tests follow conventions: location, `createToolExecutor`, fixture, `FrozenClock`, fixture patients | skill section 3 (`SKILL.md:80-82`) | pass |
| 16 | CI collects the new files | root `vitest.config.ts` projects `packages/*`, no include override, files named `*.test.ts` beside `test/repos/*.test.ts` | pass |
| 17 | CI test job on the PR head | `ci.txt`, manifest | pass: "Lint, typecheck, test" passed. `ci.txt` holds job status only, so the count of 31 new tests is the PR's claim |

### Searches run
| Query or command | Purpose | Hits |
|---|---|---|
| `grep -n "TOOL_REGISTRY\|describe(\|  it(\|skip" packages/tools/test/registry.test.ts` | find any assertion on the production registry | 1 test (lines 109-116) |
| `grep -rn "skip" packages/tools/test` | skipped tests | 1 pre-existing `describe.skipIf` in `dynamo/dynamo.test.ts`; none in new files |
| `grep -rn "clinicDateRangeUtc" packages/tools/test` | is the range helper tested elsewhere | `clock.test.ts` only (unit test of the helper) |
| `grep -n "listOpenBySpecialtyAndDay\|listOpenByProvider" packages/tools/src/repos/in-memory.ts` | what the repo filters on | 2 |
| `grep -n "availabilityMaxSlots\|providersMaxResults" -r packages/contracts/src` | the limits the tests assert against | 10 and 20 in `clinic.ts` |
| `git diff --stat HEAD~1` | confirm no test file was modified or deleted | 5 files, all additions |

## 3. Not reviewed

- No tests were run and no mutation was applied; "would fail" judgements are by reading.
- `packages/tools/src/repos/seed.ts` was not read, so whether an orphan slot can be seeded (TEST-105) is unknown.
- `packages/tools/test/registry.test.ts` was read only around the `TOOL_REGISTRY` test and its test names, not in full.
- `providerMatchesName` and the providers repo ordering were not read; the find_providers tests were judged on the handler and the asserted outputs.
- `ci.txt` contains job status only, not the test log, so I could not confirm from CI that the two new files were collected or how many tests ran.
- Eval scenarios (`packages/evals/scenarios/`) were not checked; none are added by this PR and evals are not part of CI.
