## Summary

The PR adds two tools. One major remains: a test claims more than it checks.
It is converging: 4 blocking findings, down from 8.

## Confirmed findings

Allowed scope, established once from `spec/issue-19.json` and the project rules: the issue's owned paths are `packages/tools/src/tools/find_providers*`, `packages/tools/src/tools/check_availability*`, `packages/tools/test/tools/find_providers*`, `packages/tools/test/tools/check_availability*` and `packages/tools/src/registry.ts` (the anchor lines). `CLAUDE.md:100` adds: "If you must touch a shared file (root configs, `packages/contracts`), keep the change minimal and say so in the PR". `.claude/skills/add-agent-tool/SKILL.md:108`, which the issue says to follow, allows a description edit "as a minimal, called-out contracts change". `.claude/skills/task-workflow/SKILL.md:125` puts the journal entry "in the same PR". The PR's own body and description are always in scope. `packages/tools/test/registry.test.ts` is outside the owned paths and is not a contracts file.

### TEST-1: find_providers test says it proves "reads no patient data" but checks only that two patients get the same output

- **Severity:** major
- **Confidence:** medium
- **Category:** hollow-test
- **Location:** `packages/tools/test/tools/find_providers.test.ts:147-151`
- **Evidence:**
  ```ts
  it("rejects a model-supplied patient_id and reads no patient data", async () => {
    expect(errorOf(await run({ patient_id: WALTER })).code).toBe("INVALID_INPUT");
    // The answer doesn't depend on who is asking.
    expect(outputOf(await run({}, WALTER))).toEqual(outputOf(await run({}, MARIA)));
  });
  ```
- **Measured against:** the finding schema's boundary-case table: "A test whose name, or the PR description, claims it covers something the test cannot detect | major (the claim is what makes it major: a reader will trust it)"
- **Why it matters:** The second half of the name promises the handler does not read patient data. The body shows only that Walter and Maria get the same output. A handler that called `ctx.repos.patients.get(ctx.patientId)` or `ctx.repos.appointments.listForPatient(...)` and then ignored the result would still pass. The handler reads no patient data today (`packages/tools/src/tools/find_providers.ts:21-29`), so this is about what the test proves, not a bug. A reader of the cross-patient case will trust the name.
- **Suggested fix:** Back the claim. Spy on `repos.patients.get`, `repos.appointments.get` and `repos.appointments.listForPatient` (all three exist, `packages/tools/src/repos/types.ts:43`, `packages/tools/src/repos/types.ts:147`, `packages/tools/src/repos/types.ts:149`) and assert `not.toHaveBeenCalled()`. This is the `vi.spyOn` / `not.toHaveBeenCalled` pattern at `packages/tools/test/tools/check_availability.test.ts:403-409`. If that is not wanted, drop "and reads no patient data" from the name.
- **Introduced by this PR:** yes
- **Action:** fix now
- **Verification:** confirmed
- **Fixable within the PR's scope:** yes — the fix is in `packages/tools/test/tools/find_providers.test.ts`, which the owned path `packages/tools/test/tools/find_providers*` covers.
- **Checked by verifier:** Read the whole test file and handler. Confirmed the repo method names in `packages/tools/src/repos/types.ts`. Checked that `packages/tools/test/tools/check_availability.test.ts:403-409` uses the spy pattern cited. Checked the diff: the file is new in this PR. Round 1's test reviewer noted the same gap as a remark in its check 3 but did not raise it, so it is not a previous finding.
- **Merged:** none

### SMELL-1: The handler's header summary still says check_availability searches "across the clinic", which the same file now rejects

- **Severity:** minor
- **Confidence:** high
- **Category:** Noise comments (stale / misleading comment)
- **Location:** `packages/tools/src/tools/check_availability.ts:2-3`
  `packages/tools/src/tools/check_availability.ts:10-11`
  `packages/tools/src/tools/check_availability.ts:122-128`
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
- **Measured against:** `packages/tools/src/tools/check_availability.ts:10`: "neither → INVALID_INPUT (decision, PR #70 review): a clinic-wide list mixes specialties the patient". Also `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:45`: "Rule and rationale: header of `packages/tools/src/tools/check_availability.ts`." The journal names this header as the record of the owner's decision (from SPEC-3).
- **Why it matters:** The header's first line says what the tool does, and the journal points readers to this header for the decision. That line still describes the clinic-wide search that commit `d34b6df` removed, and lines 10-11 of the same header contradict it.
- **Suggested fix:** Change line 2 to "open slots by provider or by specialty (one of them is required), within a". Leave lines 10-11 as they are.
- **Introduced by this PR:** yes
- **Action:** fix now
- **Verification:** confirmed
- **Fixable within the PR's scope:** yes — `packages/tools/src/tools/check_availability.ts` is an owned path.
- **Checked by verifier:** Read the handler in full. The only place "across the clinic" appears in the diff is line 125 of the new file hunk, which is line 2 of the file. Checked journal lines 35 and 45. Grepped for any other clinic-wide wording in the handler.
- **Merged:** SPEC-3

### SPEC-1: The model-facing schema still accepts a search with neither `provider_id` nor `specialty`, and the handler now always rejects it

- **Severity:** minor
- **Confidence:** medium
- **Category:** unstated-assumption
- **Location:** `packages/tools/src/tools/check_availability.ts:122-128`
  `packages/contracts/src/tools.ts:119-120`
  `packages/contracts/src/tools.ts:226`
  `packages/contracts/src/__snapshots__/tools.test.ts.snap:85-87`
- **Evidence:**
  ```ts
  // packages/tools/src/tools/check_availability.ts:122-128
  } else {
    return toolFail(
      "INVALID_INPUT",
      "Say which provider or which specialty to search: provider_id or specialty is required.",
      "Ask the patient what kind of visit they need or which provider they want, then call check_availability again with specialty or provider_id.",
    );
  }
  ```
  ```ts
  // packages/contracts/src/tools.ts:119-120
  provider_id: ProviderId.optional().describe("Only this provider (an id from find_providers)."),
  specialty: Specialty.optional().describe("Only providers in this specialty."),
  ```
  ```text
  // packages/contracts/src/__snapshots__/tools.test.ts.snap:85-87
        "required": [
          "date_range",
        ],
  ```
- **Measured against:** `.claude/skills/add-agent-tool/SKILL.md:112`: "**Rules the model must follow:** ... what an error means and what to do." Also the owner's decision at `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:35`: "**A search with neither filter is now an error (SPEC-4).**"
- **Why it matters:** The owner decided the behaviour (reject), but not whether the contract should say so. The JSON schema the model is sent requires only `date_range`, and both filters are marked optional. The description's first sentence, "Find open 30-minute appointment slots by provider or specialty" (`packages/contracts/src/tools.ts:226`), names the two search keys but does not say that one is required. A model that leaves both out learns the rule only from a failed call. The journal accepts that "a weaker model may handle an error worse than an empty list" (`docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:31`). The PR body lists the matching past-date gap as contract change request 2, but not this one. It stays minor because the hint recovers the call and every option is easy to reverse.
- **Suggested fix:** Take no action until the owner decides. If the owner picks (b), add one clause to `TOOLS.check_availability.description` (for example "Give provider_id or specialty.") and update the snapshot, calling it out as a contracts change. Under any option, list the question next to contract change request 2 in the PR body.
- **Introduced by this PR:** yes
- **Action:** needs owner decision
- **Decision needed:** Should the model-facing contract say that `check_availability` needs `provider_id` or `specialty`? (a) Leave the contract as is, rely on "by provider or specialty" plus the error hint, and revisit with evals once #30 lands. No contracts change, and the prompt cache is unchanged. (b) Add a clause to the description now. This is a small, called-out contracts change that invalidates the prompt cache and, per the skill, needs an eval run that cannot happen yet. (c) Encode the rule in the input schema. This is the strongest signal but a larger contracts change, and the JSON Schema conversion may not express "one of two optional fields".
- **Verification:** confirmed, adjusted. The reviewer said the description "says nothing about the rule", but `packages/contracts/src/tools.ts:226` opens with "by provider or specialty", which partly conveys it. The claim is narrowed to the schema, which lists neither field as required, and to the missing explicit "one is required". Confidence is lowered from high to medium. Severity stays minor ("A decision the spec left open, made sensibly and easy to reverse | minor").
- **Fixable within the PR's scope:** yes — the description edit is in `packages/contracts/src/tools.ts`, which `.claude/skills/add-agent-tool/SKILL.md:108` allows "as a minimal, called-out contracts change". The owner already approved one such change in this PR (the slot limit).
- **Checked by verifier:** Read `packages/contracts/src/tools.ts:118-126` and `packages/contracts/src/tools.ts:224-229`, and the snapshot at lines 32-91. Checked the PR body's contract change requests and its "No edits needed" statement. Checked the journal at lines 31 and 35. Grepped for a schema-level refinement on `CheckAvailabilityInput` and found none.
- **Merged:** none

### SPEC-2: Availability results include providers who are not accepting new patients, with nothing in the output that says so. The spec is silent on this.

- **Severity:** minor
- **Confidence:** high
- **Category:** unstated-assumption
- **Location:** `packages/tools/src/tools/check_availability.ts:52-59`
  `packages/tools/src/tools/check_availability.ts:113-121`
- **Evidence:**
  ```ts
  // packages/tools/src/tools/check_availability.ts:52-59
  const toSlotOption = ({ slot, provider }: Candidate): SlotOption => ({
    slot_id: slot.slotId,
    provider_id: slot.providerId,
    provider_name: provider.displayName,
    specialty: slot.specialty,
    start_utc: slot.startUtc,
    start_local: formatClinicDateTime(slot.startUtc),
  });
  ```
  ```ts
  // packages/tools/src/tools/check_availability.ts:114-115
  const list = await ctx.repos.providers.list({ specialty });
  const providers = new Map(list.map((p) => [p.providerId, p]));
  ```
- **Measured against:** `docs/PRD.md:82`: "Understands a provider name, a specialty, date ranges (\"next week\"), and time-of-day preferences. Presents at most 5 options, in the clinic timezone, with provider and weekday. All options come from tool results." Neither the PRD nor issue #19 says whether availability should leave out or flag providers who are not taking new patients. The fixture has one such provider (`packages/tools/fixtures/clinic-default.ts:77`: "Family physician; currently not taking new patients.").
- **Why it matters:** A `family_medicine` search sorts by start time, then `provider_id`, so Dr. Brooks's slots sit alongside Dr. Alvarez's in the 5 options. With the limit now 5 rather than 10, they take a larger share of it. A new patient can be offered those slots, and nothing in the result lets the model notice unless it also called `find_providers`. Scenario `packages/evals/scenarios/book/book-provider-not-accepting.yaml` expects the agent to steer to `prov_alvarez`. Round 1 raised this as SPEC-5 and marked it for the owner, on the grounds that only a contracts change could fix it. This round found a handler-only option (c), inside the owned paths, so it now needs the owner's decision.
- **Suggested fix:** Take no action until the owner decides. Option (a) needs no code. Option (c) is a handler-only change inside the owned paths. Options (b) and (d) are minimal, called-out contracts changes in `packages/contracts/src/tools.ts:44-51` or `packages/contracts/src/tools.ts:226`.
- **Introduced by this PR:** yes
- **Action:** needs owner decision
- **Decision needed:** How should `check_availability` treat providers with `acceptingNewPatients: false`? (a) Return them as now and rely on the system prompt (#16) plus `find_providers`. No change, but the model may offer new patients options they cannot book. (b) Add `accepting_new_patients` to `SlotOption`. The model sees it on every slot, at the cost of a contracts change and an eval run. (c) Leave them out of specialty searches but keep them for an explicit `provider_id` search. Handler-only, but existing patients of that provider lose those slots in specialty results unless the handler also reads the patient's history. (d) Add a sentence to the description telling the model to check `find_providers` first. A contracts wording change and an eval run.
- **Verification:** confirmed
- **Fixable within the PR's scope:** yes — option (c) is in `packages/tools/src/tools/check_availability.ts`, an owned path. Options (b) and (d) are minimal contracts changes that `CLAUDE.md:100` and `.claude/skills/add-agent-tool/SKILL.md:108` allow.
- **Checked by verifier:** Read the fixture provider at `packages/tools/fixtures/clinic-default.ts:70-78`. Confirmed that `SlotOption` (`packages/contracts/src/tools.ts:44-51`) has no acceptance field and that the scenario file exists. Checked the PR body's contract change request 1 and round 1's SPEC-5 with its "for the owner" status in `previous/response.md`.
- **Merged:** none

### TEST-2: The registry test's name still says the production registry is empty, and this PR registers two tools in it

- **Severity:** minor
- **Confidence:** high
- **Category:** hollow-test
- **Location:** `packages/tools/test/registry.test.ts:1-4`
  `packages/tools/test/registry.test.ts:109-116`
- **Evidence:**
  ```ts
  it("is empty for the (still empty) production registry, whose keys are all tool names", () => {
    expect(Object.keys(TOOL_REGISTRY).every((k) => (TOOL_NAMES as readonly string[]).includes(k))).toBe(
      true,
    );
    expect(createToolExecutor(TOOL_REGISTRY, ctx).definitions.length).toBe(
      Object.keys(TOOL_REGISTRY).length,
    );
  });
  ```
- **Measured against:** the finding schema's boundary-case table: "A test whose name, or the PR description, claims it covers something the test cannot detect | major". The severity is capped at minor because the action is `for the owner`.
- **Why it matters:** The PR adds `find_providers` and `check_availability` to `TOOL_REGISTRY` (`packages/tools/src/registry.ts:109-110`), so the test name and the file header (`packages/tools/test/registry.test.ts:3`) now state something false. The body never checked for an empty registry, so the test still passes and the green result is honest. The PR could not fix this: `packages/tools/test/registry.test.ts` is outside issue #19's owned paths, and the PR body lists it under "Deferred / follow-ups".
- **Suggested fix:** When the next tool PR or a small follow-up touches the file, rename the test to something like "has only real tool names as keys, and offers one definition per registered tool", and update the header comment.
- **Introduced by this PR:** worsened
- **Action:** for the owner
- **Verification:** confirmed, adjusted. The reviewer measured this against a line of its own brief, which is outside what the verifier may read. The measure is replaced with the equivalent finding-schema row, which the verifier can check. Severity and action are unchanged.
- **Fixable within the PR's scope:** no — the fix is in `packages/tools/test/registry.test.ts`, which is not among issue #19's owned paths. `CLAUDE.md:100` says "Stay inside them".
- **Checked by verifier:** Read `packages/tools/test/registry.test.ts:1-8` and `packages/tools/test/registry.test.ts:105-118`. Confirmed the file is not in the diff and the registry entries are at `packages/tools/src/registry.ts:108-110`.
- **Merged:** none
- **Related:** STD-1 (the missing issue link for this same deferred item; a different fix, in the PR body).

### STD-1: The PR's deferred follow-ups have no issue links, so the stale registry-test header and the mapper consolidation are tracked nowhere

- **Severity:** nit
- **Confidence:** medium
- **Category:** process
- **Location:** `packages/tools/test/registry.test.ts:1-4`
- **Evidence:**
  ```ts
  /**
   * The executor side of the agent/tools seam, exercised with dummy handlers registered only here
   * (the production TOOL_REGISTRY stays empty until #19–#23 land).
   */
  ```
- **Measured against:** `.github/pull_request_template.md:28-30`: "## Deferred / follow-ups" / "<!-- Anything intentionally left out, with issue links. -->"
- **Why it matters:** The PR body's "Deferred / follow-ups" section lists two items with no issue link: the `ProviderSummary` mapper consolidation and the stale `test/registry.test.ts` header. This PR makes that header false. With no issue behind the header item, nobody owns fixing it once the PR merges. The mapper consolidation is at least noted in the owner's comment on issue #19. `docs/backlog.md` tracks neither.
- **Suggested fix:** In the "Deferred / follow-ups" section, link the issue #19 comment that plans the mapper consolidation, and open a one-line chore issue for the stale registry-test header and name (see TEST-2) and link it.
- **Introduced by this PR:** yes
- **Action:** fix now
- **Verification:** confirmed
- **Fixable within the PR's scope:** yes — the fix is in the PR's own body, which is always in scope.
- **Checked by verifier:** Read the PR template and the PR body's deferred section. Grepped `docs/backlog.md` for consolidation or registry-test follow-ups and found none. Read the issue #19 comment on mapper consolidation.
- **Merged:** none
- **Related:** TEST-2

### SMELL-2: The handler re-sorts results with a hand-written comparator, although the repository contract already returns them in that order

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
- **Measured against:** `packages/tools/src/repos/types.ts:80`: "AP-4. OPEN slots for one provider whose start is in `range`, ascending by start." And `packages/tools/src/repos/types.ts:85-86`: "AP-5. OPEN slots in a specialty on one clinic-local day (`clinicDateOf(startUtc)`), ascending by start, then providerId." The provider path returns one provider's slots already in start order. The specialty path concatenates clinic days walked in ascending order (line 117), each already ordered. `offerable` only filters. The same comparator is already written inline in both repositories.
- **Why it matters:** While both repositories meet their contract, which `packages/tools/test/contract/repositories.contract.ts` checks, the sort cannot change the result. It adds a third hand-written copy of the slot ordering to keep in step. The cost is small. Round 1's SMELL-1 fix said to "keep the one on line 120" (this final sort), and the agent did so in good faith. Removing it now reverses that advice for a reason round 1 did not weigh: the repository contract already guarantees the order.
- **Suggested fix:** Remove `byStartThenProvider` and the `sort` call. Add a one-line comment saying that each repository query returns (start, providerId) order and that days are walked in order, so the concatenation is already sorted.
- **Introduced by this PR:** yes
- **Action:** fix now
- **Verification:** confirmed, adjusted. The suggested fix is rewritten to drop "If the owner prefers to keep the guard, move one shared `compareSlots` into `repos/`". That branch asked for an owner preference, and `repos/` is outside the owned paths. A note is added on round 1's advice about this sort.
- **Fixable within the PR's scope:** yes — the change is in `packages/tools/src/tools/check_availability.ts`, an owned path.
- **Checked by verifier:** Read `packages/tools/src/repos/types.ts:76-89`, `packages/tools/src/repos/in-memory.ts:146-164` and `packages/tools/src/repos/dynamo/repositories.ts:217-238`. Confirmed that each clinic day maps to a contiguous, ascending UTC interval, so concatenating days in order preserves the sort. Checked that no test mocks a slot query with unordered results: the spies at `packages/tools/test/tools/check_availability.test.ts:237-238` wrap the real methods, and the only mock is on `providers.list`. Read round 1's SMELL-1 suggested fix.
- **Merged:** none

### SMELL-3: The test helper hardcodes the visit length instead of using `CLINIC.visitMinutes`

- **Severity:** nit
- **Confidence:** high
- **Category:** Duplication (magic number for an existing constant)
- **Location:** `packages/tools/test/tools/check_availability.test.ts:40-48`
- **Evidence:**
  ```ts
  /** An extra OPEN 30-minute slot for a fixture provider, at any hour (the seed validator allows it). */
  const openSlot = (provider: Provider, startUtc: string): Slot => ({
  ...
    endUtc: toCanonicalUtc(new Date(Date.parse(startUtc) + 30 * 60_000)),
  ```
- **Measured against:** Precedent, not a written rule. `packages/contracts/src/clinic.ts:13` defines `visitMinutes: 30,`. `packages/tools/fixtures/clinic-default.ts:320` (`const visit = CLINIC.visitMinutes;`) and `packages/tools/test/fixtures/clinic-default.test.ts:73` (`CLINIC.visitMinutes * 60_000`) both use the constant.
- **Why it matters:** If the visit length changes, this helper still makes 30-minute slots that the fixture no longer has. The seed does not check slot length (`packages/tools/src/repos/seed.ts:106-113` checks provider, specialty and canonical form only), so nothing would flag the difference. It is test-only, so the risk is small.
- **Suggested fix:** Use `CLINIC.visitMinutes * 60_000`, importing `CLINIC` from `@sched/contracts`, and drop "30-minute" from the doc comment.
- **Introduced by this PR:** yes
- **Action:** fix now
- **Verification:** confirmed
- **Fixable within the PR's scope:** yes — `packages/tools/test/tools/check_availability.test.ts` is an owned path.
- **Checked by verifier:** Opened both precedent lines and `packages/contracts/src/clinic.ts:13`. Read `packages/tools/src/repos/seed.ts:100-113` to see whether the seed validates duration. The reviewer's range 40-47 ends one line short of the helper's closing brace; corrected to 40-48.
- **Merged:** none

## Minor findings table

| ID | Severity | Action | Location | Problem | Suggested fix or decision needed |
|---|---|---|---|---|---|
| SMELL-1 | minor | fix now | `packages/tools/src/tools/check_availability.ts:2-3` | The header's first line still says the tool searches "across the clinic", which the same file now rejects and which the journal names as the record of the decision. | Change line 2 to "open slots by provider or by specialty (one of them is required), within a". |
| SPEC-1 | minor | needs owner decision | `packages/contracts/src/tools.ts:119-120`; `packages/contracts/src/tools.ts:226` | The schema the model is sent requires only `date_range`, and nothing says one of `provider_id` or `specialty` is required, though the handler now rejects a call with neither. | Should the contract say so: (a) no, rely on "by provider or specialty" and the hint, revisit with evals; (b) add a description clause now (contracts change, eval run); or (c) encode it in the input schema (larger contracts change)? |
| SPEC-2 | minor | needs owner decision | `packages/tools/src/tools/check_availability.ts:52-59` | Slots of providers not accepting new patients (Dr. Brooks) are returned with no flag, and the spec is silent. | How to treat them: (a) as now; (b) add `accepting_new_patients` to `SlotOption`; (c) leave them out of specialty searches only (handler-only); or (d) a description sentence to check `find_providers` first? |
| TEST-2 | minor | for the owner | `packages/tools/test/registry.test.ts:109-116` | The registry test's name and file header say the production registry is empty, which this PR makes false, and the file is outside the owned paths. | Rename the test and fix the header in a follow-up that touches the file. |
| STD-1 | nit | fix now | `packages/tools/test/registry.test.ts:1-4` | The PR body's two deferred follow-ups have no issue links, as the PR template asks. | Link the issue #19 comment for the mapper consolidation and open and link a chore issue for the stale registry-test header. |
| SMELL-2 | nit | noticed | `packages/tools/src/tools/check_availability.ts:130` | The final sort repeats an order that the repository contract already guarantees, as a third copy of the comparator. | Remove `byStartThenProvider` and the sort, and add a comment that the repositories and the ordered day walk already give that order. |
| SMELL-3 | nit | fix now | `packages/tools/test/tools/check_availability.test.ts:46` | The test slot helper hardcodes a 30-minute visit instead of `CLINIC.visitMinutes`. | Use `CLINIC.visitMinutes * 60_000` and drop "30-minute" from the doc comment. |

## Rejected findings

| ID | Reviewer's claim | Reason rejected | What was checked |
|---|---|---|---|
| None | | | |

### Merged

| ID | Folded into | Why |
|---|---|---|
| SPEC-3 | SMELL-1 | Same code (`packages/tools/src/tools/check_availability.ts:2`) and the same one-line fix. SPEC-3's measure (the journal names this header as the record of the decision, `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:45`) is kept in SMELL-1. SMELL-1's severity (minor) is kept: a stale comment is a "local maintainability issue". |

## Spot checks

| Reviewer | Check (as the reviewer wrote it) | What you did | Result |
|---|---|---|---|
| Test adequacy | #9 "The specialty path uses AP-5 only (spied), walks days in order, and stops once it has more than the limit. With `< MAX`, test `:303` would fail; with no early exit, test `:236` would fail" | Traced `packages/tools/src/tools/check_availability.ts:117`. With `< MAX`, Oct 6 fills exactly 5 and the loop stops after one call, so `packages/tools/test/tools/check_availability.test.ts:307` (two calls) fails. With no exit, the Oct 6–30 range makes 25 calls, so line 242 (`toHaveBeenCalledTimes(1)`) fails. | holds |
| Test adequacy | #10 "A slot whose provider record is missing is left out rather than failing the search" | Read `packages/tools/test/tools/check_availability.test.ts:270-280`. Without the `provider &&` guard at `packages/tools/src/tools/check_availability.ts:87`, `toSlotOption` reads `displayName` of undefined, the executor returns an error, and `outputOf` throws. | holds |
| Test adequacy | #13 "The literal 5-item lists at `:105` and `:308` would fail if the limit went back to 10" | Counted from the fixture. Lee on Oct 13 after 1:00 PM ET has 6 open slots (2:30 is Maria's, `packages/tools/fixtures/clinic-default.ts:185-192`), so a limit of 10 gives 6 items at line 105. Cardiology Oct 6–7 at 2:00 PM gives 10 at line 308. Both lists would differ. | holds |
| Test adequacy | #4 "Only slots strictly after now are offered. Oct 5 has an open 9:00 lee slot, so `>=` would make the first slot 9:00 and fail the test" | Checked the fixture bookings (`packages/tools/fixtures/clinic-default.ts:183-238`). Lee's only booking is Oct 13 at 2:30 PM, so Oct 5 at 9:00 (13:00Z, equal to `suggestedNow`) is open. `>=` would make line 337's first entry "9:00 AM ET" and line 341's `start_utc` 13:00Z. | holds |
| Spec alignment | R6 "Uses sparse GSI query path when filtering by specialty+day": `packages/tools/src/tools/check_availability.ts:113-121` calls `listOpenBySpecialtyAndDay` day by day and exits early; spied at `packages/tools/test/tools/check_availability.test.ts:236-254` (paths expanded) | Read `packages/tools/src/tools/check_availability.ts:113-121` and `packages/tools/test/tools/check_availability.test.ts:236-254`. The spy wraps the real method and asserts AP-5 was called and AP-4 was not. | holds |
| Spec alignment | R7 "Unit tests against in-memory repos (happy path, not-found, invalid input, cross-patient attempt)", with the per-file line citations | Opened each cited range in both test files. Each test is at the cited lines and is what the row says it is. The find_providers cross-patient test's name overclaims (TEST-1), but the case exists. | holds |
| Spec alignment | #43 PR claim: "38 tests in the two new files, all run through `createToolExecutor`, one per file through the production `TOOL_REGISTRY`" | Counted `it(` blocks while reading: 27 in `packages/tools/test/tools/check_availability.test.ts` and 11 in `packages/tools/test/tools/find_providers.test.ts`. The `TOOL_REGISTRY` tests are at `packages/tools/test/tools/check_availability.test.ts:74` and `packages/tools/test/tools/find_providers.test.ts:54`. | holds |
| Spec alignment | R5 "with slotId, provider, local start (clinic TZ), weekday": the weekday is part of `start_local` via `formatClinicDateTime` (`packages/tools/src/clock.ts:230-235`) (path expanded) | Read `packages/tools/src/clock.ts:230-235`. The string starts with `${weekday}, `. `toSlotOption` fills `slot_id`, `provider_id`, `provider_name` and `start_local`. | holds |
| Standards | #15 "add-agent-tool:104: registry change is import + entry under the #19 anchors; nothing reordered" at `packages/tools/src/registry.ts:34-36`, `packages/tools/src/registry.ts:108-110` (paths expanded) | Read `packages/tools/src/registry.ts:33-38` and `packages/tools/src/registry.ts:104-112`. The diff has two hunks, both +2/-0, under the `#19` anchors. | holds |
| Code smells | #19 "swallowed errors: `packages/tools/src/tools/check_availability.ts:82-89` (drops a slot whose provider is missing) ... The seed invariant at `packages/tools/src/repos/seed.ts:108` makes this unreachable for seeded data" (paths expanded) | Read `packages/tools/src/repos/seed.ts:105-111`. A slot's provider must exist and share its specialty, so `providers.list({ specialty })` always includes it. No try/catch hides a failure. | holds |

## Previous findings

| ID | Before (severity, action) | Agent's response | Status now | Evidence |
|---|---|---|---|---|
| TEST-1 | major, fix now | fixed (`99f1e7a`) | resolved | `packages/tools/test/tools/check_availability.test.ts:74-86` and `packages/tools/test/tools/find_providers.test.ts:54-63` build the executor from `TOOL_REGISTRY` and assert the tool is in `definitions`. Removing either entry fails them. |
| TEST-2 | major, fix now | fixed (`99f1e7a`) | resolved | `packages/tools/test/tools/check_availability.test.ts:199-232` seeds 00:30Z and 04:30Z slots on EST days. A UTC-day range for Sat Nov 7 would return the 00:30Z slot and miss the 04:30Z one, so the `toEqual` fails. The old test is renamed at line 182. |
| STD-2a | minor, fix now | fixed (`555fffe`) | resolved | `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:18-31` records the options and the choice. The README row is at `docs/journal/README.md:22`. |
| SMELL-1 | minor, fix now | fixed (`9496f3a`) | resolved | The per-day sort is gone; one sort remains at `packages/tools/src/tools/check_availability.ts:130`. This round's SMELL-2 questions that remaining sort. |
| SMELL-2 | minor, fix now | fixed (`9496f3a`) | resolved | `providers` is a `const` per branch (`packages/tools/src/tools/check_availability.ts:112`, `packages/tools/src/tools/check_availability.ts:115`). Each slot is paired once in `offerable` (lines 84-90), and `truncated` is computed from the count before the slice (line 131). |
| TEST-3 | minor, fix now | fixed (`99f1e7a`) | resolved | `packages/tools/test/tools/check_availability.test.ts:303-316` (exactly the limit, then the next day: two calls, `truncated: true`) and `packages/tools/test/tools/check_availability.test.ts:318-331` (two-day result). |
| TEST-4 | minor, fix now | fixed (`99f1e7a`) | resolved | `packages/tools/test/tools/check_availability.test.ts:354-363` sets the clock to 01:00Z Oct 6 and asserts Oct 5 is still today. |
| TEST-5 | minor, fix now | fixed (`99f1e7a`) | resolved | `packages/tools/test/tools/check_availability.test.ts:270-280` stubs `providers.list` without `prov_lee` and asserts success with Okafor's slots only. |
| SMELL-3 | nit, fix now | fixed (`9496f3a`) | resolved | `packages/tools/src/tools/find_providers.ts:22-25` and `packages/tools/src/tools/check_availability.ts:114` pass the fields straight to `providers.list`. |
| SMELL-4 | nit, fix now | fixed (`99f1e7a`) | resolved | The happy-path test makes one call and reads it several ways (`packages/tools/test/tools/check_availability.test.ts:91-112`). The clinic-wide test is gone with SPEC-4. |
| SPEC-1 | major, needs owner decision | fixed (decision: 5 slots) | decided | `packages/contracts/src/clinic.ts:19` is `availabilityMaxSlots: 5`, and the snapshot follows at `packages/contracts/src/__snapshots__/tools.test.ts.snap:33`. The code matches the decision. |
| STD-1 | minor, needs owner decision | decision: the rule bans clock reads only | decided | `packages/tools/src/tools/check_availability.ts:42` only parses a stored string, and no argument-less `new Date()` or `Date.now()` is in either handler. The skill text (`.claude/skills/add-agent-tool/SKILL.md:58`) still reads as a blanket ban; the owner routed that rewording outside this PR. |
| STD-2 | minor, needs owner decision | decision: no ADR for tool-level rules | decided | No ADR was added. The rule is in `packages/tools/src/tools/check_availability.ts:17-21` and the journal, as decided. |
| SPEC-2 | minor, needs owner decision | decision: keep the past-date rule | decided | `packages/tools/src/tools/check_availability.ts:73-80` rejects a wholly past range and clamps a partly past one, which matches the decision. |
| SPEC-3 | minor, needs owner decision | decision: keep the error | decided | `packages/tools/src/tools/check_availability.ts:103-109` returns `INVALID_INPUT` for a contradicting `provider_id` and `specialty`. |
| SPEC-4 | minor, needs owner decision | decision: reject a search with neither filter | decided | `packages/tools/src/tools/check_availability.ts:122-128` rejects the call, tested at `packages/tools/test/tools/check_availability.test.ts:402-410`. The header's first line was not updated; that is this round's SMELL-1. |
| SPEC-5 | minor, for the owner | for the owner (no note) | still present | Reported again this round as SPEC-2. A handler-only option inside the owned paths exists, so it now needs the owner's decision rather than being for the owner. `packages/tools/src/tools/check_availability.ts:52-59` still returns slots with no acceptance signal. |

Round 2 (`previous/report.md`) reviewed this same head and reported no findings, so it adds no rows. Many of its table citations point past the end of the cited files (for example it cites line 92 of `packages/contracts/src/clinic.ts`, a 44-line file whose slot limit is at `packages/contracts/src/clinic.ts:19`), so its passes were not relied on here.

## Convergence

| | This round | Previous round |
|---|---|---|
| Findings in changed code (blocking) | 4 | — |
| Noticed in unchanged code (not blocking) | 1 | — |

## Verification summary

| Reviewer | Reported | Confirmed | Adjusted | Merged | Rejected |
|---|---|---|---|---|---|
| Standards | 1 | 1 | 0 | 0 | 0 |
| Code smells | 3 | 2 | 1 | 0 | 0 |
| Spec alignment | 3 | 1 | 1 | 1 | 0 |
| Test adequacy | 2 | 1 | 1 | 0 | 0 |
| **Total** | **9** | **5** | **3** | **1** | **0** |

"Confirmed" counts findings confirmed unchanged; "Adjusted" counts findings confirmed with a change (SMELL-2, SPEC-1, TEST-2). By action: 5 fix now (TEST-1, SMELL-1, STD-1, SMELL-2, SMELL-3), 2 needs owner decision (SPEC-1, SPEC-2), 1 for the owner (TEST-2). Spot checks: 10 done, 10 held. Previous findings: 10 resolved, 6 decided, 1 still present.

## Reviewer tables

### Spec traceability

| Req | Requirement (quoted) | Source | Status | Evidence |
|---|---|---|---|---|
| R1 | "Handler in `packages/tools/src/tools/` validates input with the contracts schema" | issue #19, AC 1 | implemented | Validation happens in the executor with `TOOLS[name].input.safeParse` (`packages/tools/src/registry.ts:202-209`). Both handlers run only through it, and the tests go through `createToolExecutor` (`packages/tools/test/tools/check_availability.test.ts:61-66`, `packages/tools/test/tools/find_providers.test.ts:41-46`). |
| R2 | "uses only injected ToolContext + repos" | issue #19, AC 1 | implemented | `packages/tools/src/tools/check_availability.ts:69`, `packages/tools/src/tools/check_availability.ts:95`, `packages/tools/src/tools/check_availability.ts:111`, `packages/tools/src/tools/check_availability.ts:114`, `packages/tools/src/tools/check_availability.ts:119` and `packages/tools/src/tools/find_providers.ts:22` use only `ctx.clock` and `ctx.repos`. `new Date(startUtc)` at `packages/tools/src/tools/check_availability.ts:42` only parses a stored value, which the owner ruled allowed. |
| R3 | "Supports provider, specialty, date range, and time-of-day filters" | issue #19, AC 2 | implemented | Provider and specialty at `packages/tools/src/tools/check_availability.ts:94-121`; date range at `packages/tools/src/tools/check_availability.ts:73-80`, `packages/tools/src/tools/check_availability.ts:110` and `packages/tools/src/tools/check_availability.ts:117`; time of day at `packages/tools/src/tools/check_availability.ts:40-44`. |
| R4 | "returns ≤ 5 slots" | issue #19, AC 2; `docs/PRD.md:82` "at most 5 options" | implemented | `packages/contracts/src/clinic.ts:19` (`availabilityMaxSlots: 5`), `packages/tools/src/tools/check_availability.ts:131`; tested at `packages/tools/test/tools/check_availability.test.ts:105-112` and `packages/tools/test/tools/check_availability.test.ts:291-301`. |
| R5 | "with slotId, provider, local start (clinic TZ), weekday" | issue #19, AC 2 | implemented | `packages/tools/src/tools/check_availability.ts:52-59`. The weekday is part of `start_local` via `formatClinicDateTime` (`packages/tools/src/clock.ts:230-235`). The contract has no separate weekday field (`packages/contracts/src/tools.ts:44-51`). |
| R6 | "Uses sparse GSI query path when filtering by specialty+day" | issue #19, AC 3; ADR-004 AP-5 | implemented | `packages/tools/src/tools/check_availability.ts:113-121` calls `listOpenBySpecialtyAndDay` day by day and exits early; spied at `packages/tools/test/tools/check_availability.test.ts:236-254`. |
| R7 | "Unit tests against in-memory repos (happy path, not-found, invalid input, cross-patient attempt)" | issue #19, AC 4 | implemented | check_availability: happy `packages/tools/test/tools/check_availability.test.ts:89-113`, not-found `packages/tools/test/tools/check_availability.test.ts:137-141`, invalid `packages/tools/test/tools/check_availability.test.ts:392-396`, cross-patient `packages/tools/test/tools/check_availability.test.ts:398-400` and `packages/tools/test/tools/check_availability.test.ts:412-422`, snapshot unchanged `packages/tools/test/tools/check_availability.test.ts:424-429`. find_providers: happy `packages/tools/test/tools/find_providers.test.ts:80-92`, no match `packages/tools/test/tools/find_providers.test.ts:114-116`, invalid `packages/tools/test/tools/find_providers.test.ts:142-145`, cross-patient `packages/tools/test/tools/find_providers.test.ts:147-151` (name overclaims, TEST-1), snapshot `packages/tools/test/tools/find_providers.test.ts:153-157`. |
| R8 | "Registered in ToolRegistry" | issue #19, AC 5 | implemented | `packages/tools/src/registry.ts:35-36`, `packages/tools/src/registry.ts:109-110` |
| R9 | "tool description reviewed against the skill's guidelines" | issue #19, AC 5 | partial | The descriptions were reviewed and the limit follows the constant (`packages/contracts/src/tools.ts:226`). The description says "by provider or specialty", but neither it nor the schema says that one is required (SPEC-1, needs owner decision). |
| R10 | "At least one L1 eval case added under packages/evals/scenarios/ (or listed for S7-04)" | issue #19, AC 6 | implemented | The PR body lists `l1-find-provider-by-name` and `l1-availability-past-dates` for #33 and references existing L1 files (`packages/evals/scenarios/l1/l1-availability-named-provider-day.yaml`, `packages/evals/scenarios/l1/l1-availability-specialty-next-week.yaml`, `packages/evals/scenarios/l1/l1-availability-after-dst.yaml`). Whether the cases were also commented on #33 cannot be checked here. |
| R11 | "Registration is **two lines**: an import under the import anchor and an entry under this tool's `TOOL_REGISTRY` anchor" (refines the owned path "registry.ts (one-line addition)") | issue #19, comment 1 | implemented | +4 lines for two tools, all under the `#19` anchors: `packages/tools/src/registry.ts:34-36`, `packages/tools/src/registry.ts:108-110` |
| R12 | "The summary mappers (`ProviderSummary` ...) will be duplicated per tool file for now" | issue #19, comment 1 | implemented | `packages/tools/src/tools/find_providers.ts:14-19` |
| R13 | Owned paths: tools/tests for find_providers and check_availability, plus registry.ts | issue #19, "Owned paths" | implemented | Everything outside the owned paths is either the owner-approved contracts change (D1) or journal docs required by the definition of done. |
| R14 | "Understands a provider name" | `docs/PRD.md:82` (FR-030) | implemented | `packages/tools/src/tools/find_providers.ts:22-25` passes `name_query` to the provider repo's name matching; tested at `packages/tools/test/tools/find_providers.test.ts:80-92`. |
| R15 | "in the clinic timezone, with provider and weekday" | `docs/PRD.md:82` (FR-030) | implemented | `packages/tools/src/tools/check_availability.ts:55`, `packages/tools/src/tools/check_availability.ts:58`; DST tests at `packages/tools/test/tools/check_availability.test.ts:161-232`. |
| R16 | "All options come from tool results" | `docs/PRD.md:82` (FR-030) | not verifiable | Model behaviour, graded by evals (#30 has not landed). |
| D1 | "the tool returns at most 5 slots (`LIMITS.availabilityMaxSlots` = 5)" | owner decision (manifest §6) | implemented | `packages/contracts/src/clinic.ts:19`; the snapshot follows at `packages/contracts/src/__snapshots__/tools.test.ts.snap:33`. |
| D2 | "a date range wholly in the past is `INVALID_INPUT` and a partly past one is clamped to now" | owner decision (manifest §6) | implemented | `packages/tools/src/tools/check_availability.ts:73-80`, `packages/tools/src/tools/check_availability.ts:87`; tested at `packages/tools/test/tools/check_availability.test.ts:345-372`. |
| D3 | "a `provider_id` whose specialty contradicts `specialty` is `INVALID_INPUT`" | owner decision (manifest §6) | implemented | `packages/tools/src/tools/check_availability.ts:103-109`; tested at `packages/tools/test/tools/check_availability.test.ts:143-149`. |
| D4 | "a search with neither `provider_id` nor `specialty` is `INVALID_INPUT`" | owner decision (manifest §6) | implemented | `packages/tools/src/tools/check_availability.ts:122-128`; tested at `packages/tools/test/tools/check_availability.test.ts:402-410`. The schema does not state the rule (SPEC-1), and the header's first line contradicts it (SMELL-1). |
| D5 | "tool-level behaviour rules need no ADR" | owner decision (manifest §6) | implemented | No ADR added; the rule is documented in the handler header and the journal. |

Open questions where the spec left the agent to guess:
- Q1: What should a past date range do? Settled by D2.
- Q2: What should a mismatched `provider_id` and `specialty` do? Settled by D3.
- Q3: What should a search with neither filter do? Settled by D4. Whether the contract should say so is still open: SPEC-1.
- Q4: The issue says 5 slots, the contract said 10. Settled by D1.
- Q5: Should availability exclude or flag providers who are not accepting new patients? Open: SPEC-2.
- Q6: How to order slots at the same time? The implementation breaks ties by `provider_id` (`packages/tools/src/tools/check_availability.ts:61-65`), matching the AP-5 repository order. The contract only says "in time order". Easy to reverse; not reported separately.

### Unrequested changes

None. Every changed file maps to a requirement or an owner decision. The two contracts files are D1. The journal entry and index meet the definition-of-done journal requirement (`CLAUDE.md:123`) and record D2 to D4.

### Behaviour coverage

Not produced.
