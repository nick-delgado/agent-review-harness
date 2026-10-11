# Spec-alignment review: PR #70 (head `d34b6df`)

## 1. Findings

### SPEC-1: The model-facing contract still presents a search with neither `provider_id` nor `specialty` as valid, but the handler now always rejects it

- **Severity:** minor
- **Confidence:** high
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
  // packages/contracts/src/__snapshots__/tools.test.ts.snap:85-87 (the definition the model is sent)
        "required": [
          "date_range",
        ],
  ```
- **Measured against:** `.claude/skills/add-agent-tool/SKILL.md:112` — "**Rules the model must follow:** ... what an error means and what to do." Also the owner's decision, recorded at `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:35` — "**A search with neither filter is now an error (SPEC-4).**"
- **Why it matters:** The owner decided the behaviour (reject), but not whether the contract should say so. The decision now lives only in the handler. The JSON schema the model is sent requires only `date_range`, and the description says nothing about the rule. A model can learn it only by making a failing call, which costs a round trip. The PR's own journal entry notes that "a weaker model may handle an error worse than an empty list". The PR description says the description was reviewed against section 5 and needs "No edits", and its contract change requests list the same kind of gap for past dates (request 2) but not this one. This is minor because the handler's hint recovers the call and the choice is easy to reverse.
- **Suggested fix:** Take no action until the owner decides. If the owner picks (b), add one clause to `TOOLS.check_availability.description` in `packages/contracts/src/tools.ts:226` (for example "Give provider_id or specialty.") and update the snapshot. Either way, list it next to contract change request 2 in the PR body so both rules are settled together once #30 can measure them.
- **Introduced by this PR:** yes
- **Action:** needs owner decision
- **Decision needed:** Should the model-facing contract state that `check_availability` needs `provider_id` or `specialty`? Options: (a) leave the contract as is and rely on the error hint, then revisit with the L1/L2 evals once #30 lands (no contracts change, the prompt cache is unchanged, and models may waste a call); (b) add a clause to the description now (a small cross-stream contracts change that invalidates the prompt cache and, per the skill, needs an eval run that can't happen yet); (c) encode the rule in the input schema itself (the strongest signal to the model, but a larger contracts change, and the JSON Schema converter may not express "one of two optional fields").

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
- **Measured against:** `docs/PRD.md:82` — "Understands a provider name, a specialty, date ranges (\"next week\"), and time-of-day preferences. Presents at most 5 options, in the clinic timezone, with provider and weekday. All options come from tool results." Neither the PRD nor issue #19 says whether availability should exclude or flag providers who aren't taking new patients. The fixture has one (`packages/tools/fixtures/clinic-default.ts:77` — "Family physician; currently not taking new patients.").
- **Why it matters:** A `family_medicine` search sorts by start time, then `provider_id`, so Dr. Brooks's slots sit alongside Dr. Alvarez's in the 5 options. Now that the limit is 5 rather than 10, they take a larger share of it. A new patient can be offered those slots, and nothing in the result lets the model notice unless it separately called `find_providers`. Scenario `packages/evals/scenarios/book/book-provider-not-accepting.yaml` expects the agent to steer to `prov_alvarez`. The PR description raises this itself (contract change request 1) but leaves it undecided, so the assumption ships as-is.
- **Suggested fix:** Take no action until the owner decides. Option (a) below needs no code. Option (c) is a handler-only change inside the owned paths. Option (b) goes through `SlotOption` in `packages/contracts/src/tools.ts:44-51`.
- **Introduced by this PR:** yes
- **Action:** needs owner decision
- **Decision needed:** How should `check_availability` treat providers with `acceptingNewPatients: false`? Options: (a) return them as now and rely on the system prompt (#16) plus `find_providers` (no change, and the model may offer unbookable options to new patients); (b) add `accepting_new_patients` to `SlotOption` (a cross-stream contracts change and an eval run, but the model sees it with every slot); (c) leave them out of specialty searches but keep them for an explicit `provider_id` search (handler-only, but existing patients of that provider lose them from specialty results unless the handler also reads the patient's history); (d) add a sentence to the description telling the model to check `find_providers` first (a contracts wording change and an eval run).

### SPEC-3: The handler's header comment still says the tool searches "across the clinic", which contradicts the owner's decision recorded a few lines below

- **Severity:** nit
- **Confidence:** high
- **Category:** deviation
- **Location:** `packages/tools/src/tools/check_availability.ts:2-3`
  `packages/tools/src/tools/check_availability.ts:10-11`
- **Evidence:**
  ```ts
   * check_availability (FR-030): open slots by provider, by specialty, or across the clinic, within a
   * clinic-local date range, optionally mornings or afternoons only.
  ...
   * - neither → INVALID_INPUT (decision, PR #70 review): a clinic-wide list mixes specialties the patient
   *   didn't ask for, so the hint sends the model back to ask what kind of visit or which provider.
  ```
- **Measured against:** `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md:45` — "Rule and rationale: header of `packages/tools/src/tools/check_availability.ts`." The journal points readers to this header as the record of the decision. The decision itself is at line 35 of the journal: "**A search with neither filter is now an error (SPEC-4).**"
- **Why it matters:** The header is the documented home of these rules, and its first line still describes the clinic-wide search that commit `d34b6df` removed.
- **Suggested fix:** Drop "or across the clinic" from line 2, for example "open slots by provider or by specialty, within a clinic-local date range, ...".
- **Introduced by this PR:** yes
- **Action:** fix now

### Spec traceability

| Req | Requirement (quoted) | Source | Status | Evidence |
|---|---|---|---|---|
| R1 | "Handler in `packages/tools/src/tools/` validates input with the contracts schema" | issue #19, AC 1 | implemented | Validation happens in the executor with `TOOLS[name].input.safeParse` (`packages/tools/src/registry.ts:202-209`); both handlers run only through it and the tests go through `createToolExecutor` (`packages/tools/test/tools/check_availability.test.ts:61-66`, `packages/tools/test/tools/find_providers.test.ts:41-46`) |
| R2 | "uses only injected ToolContext + repos" | issue #19, AC 1 | implemented | `packages/tools/src/tools/check_availability.ts:69,95,111,114,119` and `packages/tools/src/tools/find_providers.ts:22` use only `ctx.clock` and `ctx.repos`. `new Date(startUtc)` at `check_availability.ts:42` only parses a stored value, which the owner ruled allowed |
| R3 | "Supports provider, specialty, date range, and time-of-day filters" | issue #19, AC 2 | implemented | `check_availability.ts:94-121` (provider and specialty), `:73-80` and `:110,117` (date range), `:40-44` (time of day) |
| R4 | "returns ≤ 5 slots" | issue #19, AC 2; `docs/PRD.md:82` "at most 5 options" | implemented | `packages/contracts/src/clinic.ts:19` (`availabilityMaxSlots: 5`), `check_availability.ts:131`; tested at `check_availability.test.ts:105-112,291-301` |
| R5 | "with slotId, provider, local start (clinic TZ), weekday" | issue #19, AC 2 | implemented | `check_availability.ts:52-59`. The weekday is part of `start_local` via `formatClinicDateTime` (`packages/tools/src/clock.ts:230-235`). The contract has no separate weekday field (`packages/contracts/src/tools.ts:44-51`) |
| R6 | "Uses sparse GSI query path when filtering by specialty+day" | issue #19, AC 3; ADR-004 AP-5 | implemented | `check_availability.ts:113-121` calls `listOpenBySpecialtyAndDay` day by day and exits early; spied at `check_availability.test.ts:236-254` |
| R7 | "Unit tests against in-memory repos (happy path, not-found, invalid input, cross-patient attempt)" | issue #19, AC 4 | implemented | check_availability: happy `test.ts:89-113`, not-found `:137-141`, invalid `:392-396`, cross-patient `:398-400,412-422`, snapshot unchanged `:424-429`. find_providers: happy `find_providers.test.ts:80-92`, no match `:114-116`, invalid `:142-145`, cross-patient `:147-151`, snapshot `:153-157` |
| R8 | "Registered in ToolRegistry" | issue #19, AC 5 | implemented | `packages/tools/src/registry.ts:35-36,109-110` |
| R9 | "tool description reviewed against the skill's guidelines" | issue #19, AC 5 | partial | The descriptions were reviewed and the limit follows the constant (`packages/contracts/src/tools.ts:226`). The new neither-filter rule isn't reflected (SPEC-1) |
| R10 | "At least one L1 eval case added under packages/evals/scenarios/ (or listed for S7-04)" | issue #19, AC 6 | implemented | The PR body lists `l1-find-provider-by-name` and `l1-availability-past-dates` for #33 and references existing L1 files (`packages/evals/scenarios/l1/l1-availability-named-provider-day.yaml`, `l1-availability-specialty-next-week.yaml`, `l1-availability-after-dst.yaml`). Whether it was also commented on #33 can't be checked here |
| R11 | "Registration is **two lines**: an import under the import anchor and an entry under this tool's `TOOL_REGISTRY` anchor" (refines the owned path "registry.ts (one-line addition)") | issue #19, comment 1 | implemented | +4 lines for two tools, all under the `#19` anchors: `registry.ts:34-36,108-110` |
| R12 | "The summary mappers (`ProviderSummary` ...) will be duplicated per tool file for now" | issue #19, comment 1 | implemented | `packages/tools/src/tools/find_providers.ts:14-19` |
| R13 | Owned paths: tools/tests for find_providers and check_availability, plus registry.ts | issue #19, "Owned paths" | implemented | Everything outside the owned paths is either the owner-approved contracts change (D1) or journal docs required by the definition of done |
| R14 | "Understands a provider name" | `docs/PRD.md:82` (FR-030) | implemented | `find_providers.ts:22-25` passes `name_query` to `providerMatchesName`; tested at `find_providers.test.ts:80-92` |
| R15 | "in the clinic timezone, with provider and weekday" | `docs/PRD.md:82` (FR-030) | implemented | `check_availability.ts:55,58`; DST tests at `check_availability.test.ts:161-232` |
| R16 | "All options come from tool results" | `docs/PRD.md:82` (FR-030) | not verifiable | This is model behaviour, graded by evals (#30 hasn't landed) |
| D1 | "the tool returns at most 5 slots (`LIMITS.availabilityMaxSlots` = 5)" | owner decision (manifest §6) | implemented | `packages/contracts/src/clinic.ts:19`; the snapshot follows at `packages/contracts/src/__snapshots__/tools.test.ts.snap:33` |
| D2 | "a date range wholly in the past is `INVALID_INPUT` and a partly past one is clamped to now" | owner decision (manifest §6) | implemented | `check_availability.ts:73-80,87`; tested at `check_availability.test.ts:345-372` |
| D3 | "a `provider_id` whose specialty contradicts `specialty` is `INVALID_INPUT`" | owner decision (manifest §6) | implemented | `check_availability.ts:103-109`; tested at `check_availability.test.ts:143-149` |
| D4 | "a search with neither `provider_id` nor `specialty` is `INVALID_INPUT`" | owner decision (manifest §6) | implemented | `check_availability.ts:122-128`; tested at `check_availability.test.ts:402-410`. The contract doesn't state the rule (SPEC-1) |
| D5 | "tool-level behaviour rules need no ADR" | owner decision (manifest §6) | implemented | No ADR added; the rule is documented in the handler header and the journal |

Open questions where the spec left the agent to guess:
- Q1: What should a past date range do? Settled by D2.
- Q2: What should a mismatched `provider_id` and `specialty` do? Settled by D3.
- Q3: What should a search with neither filter do? Settled by D4. Whether the contract should say so is still open: SPEC-1.
- Q4: The issue says 5 slots, the contract said 10. Settled by D1.
- Q5: Should availability exclude or flag providers who aren't accepting new patients? Open: SPEC-2.
- Q6: How to order slots at the same time? The implementation breaks ties by `provider_id` (`check_availability.ts:61-65`). The contract only says "in time order". The choice is easy to reverse and matters only through Q5, so it isn't reported separately.

### Unrequested changes

None. Every changed file maps to a requirement or an owner decision. The two contracts files are D1. The journal entry and index are the definition-of-done journal requirement (`CLAUDE.md:123`), and they record D2 to D4.

## 2. Coverage ledger

### Sources read
| Source | Why |
|---|---|
| `skills/review-agent-pr/reviewers/spec-alignment.md` | brief |
| `skills/review-agent-pr/references/finding-schema.md` | output format |
| `RUN_DIR/manifest.md` | review inputs, owner decisions (§6) |
| `RUN_DIR/pr.json` (body, six commit messages, file list) | PR description claims |
| `RUN_DIR/spec/issue-19.json` (body and both comments) | task spec |
| `RUN_DIR/ci.txt` | CI status |
| `RUN_DIR/diff.patch` (hunk headers and contracts hunks) | what changed |
| `packages/tools/src/tools/check_availability.ts` (full) | changed file |
| `packages/tools/src/tools/find_providers.ts` (full) | changed file |
| `packages/tools/src/registry.ts` (full) | changed file |
| `packages/tools/test/tools/check_availability.test.ts` (full) | changed file |
| `packages/tools/test/tools/find_providers.test.ts` (full) | changed file |
| `packages/contracts/src/clinic.ts` (full) | changed file |
| `packages/contracts/src/__snapshots__/tools.test.ts.snap` (check_availability entry, lines 30-90) | changed file |
| `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md` (full) | changed file |
| `docs/journal/README.md` | changed file |
| `packages/contracts/src/tools.ts` (lines 1-235) | the contract the handlers implement |
| `packages/tools/src/repos/types.ts` (lines 40-95) | AP-3/4/5 repo interfaces |
| `packages/tools/src/clock.ts` (lines 195-245) | `clinicDateRangeUtc`, `formatClinicDateTime` |
| `packages/tools/fixtures/clinic-default.ts` (providers) | not-accepting provider (SPEC-2) |
| `docs/PRD.md` (full) | FR-030, goals, traceability |
| `docs/architecture.md` (full) | direction |
| `docs/backlog.md` (full) | direction, dependants (#33, #36) |
| `docs/adr/README.md`, `0001`, `0004`, `0009` (full) | ADRs cited by the issue |
| `docs/adr/0002`, `0005`, `0007`, `0008`, `0010` (grep for tool, availability and eval content) | direction |
| `CLAUDE.md` (full) | architecture rules, definition of done, contracts rule |
| `.claude/skills/add-agent-tool/SKILL.md` (full) | the issue says to follow it |
| `packages/evals/scenarios/` (listing), `l1/l1-availability-*.yaml`, `availability/availability-weekend-after-hours.yaml`, `clarify/clarify-next-friday.yaml`, `clarify/clarify-vague-request.yaml`, `book/book-multi-constraint.yaml`, `book/book-provider-not-accepting.yaml`, `reschedule/reschedule-earlier-any-dermatologist.yaml` (part), `l1/l1-hedged-reply-is-not-yes.yaml`, `l1/l1-escalate-after-two-failures.yaml`, `l1/l1-reschedule-after-yes.yaml` (context sections) | check that the new rules (5 slots, a filter required) don't contradict committed scenarios; check the PR's scenario references |

### Checks performed
| # | Check | Scope | Result |
|---|---|---|---|
| 1 | R1: input validated with the contracts schema | `registry.ts`, both handlers, tests | pass |
| 2 | R2: only ToolContext and repos used; no clock read outside `ctx.clock` | both handlers | pass |
| 3 | R3: provider, specialty, date-range and time-of-day filters present | `check_availability.ts` | pass |
| 4 | R4: at most 5 slots, with `truncated` | `clinic.ts`, handler, tests | pass |
| 5 | R5: slot id, provider, clinic-local start, weekday in the output | `toSlotOption`, `formatClinicDateTime` | pass |
| 6 | R6: specialty path uses AP-5 `listOpenBySpecialtyAndDay` | handler, spy test | pass |
| 7 | R7: happy, not-found, invalid and cross-patient tests in both files | both test files | pass |
| 8 | R8: registered in `TOOL_REGISTRY` | `registry.ts` | pass |
| 9 | R9: description reviewed against skill §5, including the new rules | `tools.ts:226`, snapshot, skill §5 | finding SPEC-1 |
| 10 | R10: L1 cases listed or referenced; referenced files exist | PR body, `packages/evals/scenarios/l1/` | pass |
| 11 | R11: registration only under the `#19` anchors, two lines per tool | `registry.ts`, diff | pass |
| 12 | R12: `ProviderSummary` mapper duplicated as the issue comment directs | `find_providers.ts` | pass |
| 13 | R13: changes outside the owned paths are only the owner-approved contracts change and docs | diff file list | pass |
| 14 | R14 to R16: FR-030 clauses | PRD, handlers | pass (R16 not verifiable) |
| 15 | D1 to D5: owner decisions from the manifest implemented as stated | handler, contracts, tests | pass (D4 contract text: SPEC-1) |
| 16 | Scope: `docs/journal/2026-09-30-...md` | diff | pass (DoD journal) |
| 17 | Scope: `docs/journal/README.md` | diff | pass (journal index) |
| 18 | Scope: `packages/contracts/src/__snapshots__/tools.test.ts.snap` | diff | pass (D1) |
| 19 | Scope: `packages/contracts/src/clinic.ts` | diff | pass (D1) |
| 20 | Scope: `packages/tools/src/registry.ts` | diff | pass (R8/R11) |
| 21 | Scope: `packages/tools/src/tools/check_availability.ts` | diff | pass (R1 to R6, D2 to D4); header wording: SPEC-3 |
| 22 | Scope: `packages/tools/src/tools/find_providers.ts` | diff | pass (R1, R14) |
| 23 | Scope: `packages/tools/test/tools/check_availability.test.ts` | diff | pass (R7) |
| 24 | Scope: `packages/tools/test/tools/find_providers.test.ts` | diff | pass (R7) |
| 25 | Direction: `docs/PRD.md` (FR-030 at most 5, G3 measured quality) | PRD | pass |
| 26 | Direction: `docs/architecture.md` (ToolRegistry in ChatFn, ToolContext from JWT) | architecture | pass |
| 27 | Direction: ADR-001 (identity injection, tool errors as `is_error`, stable cached tool prefix) | handlers, contracts | pass (the tool-definition byte change was owner-approved) |
| 28 | Direction: ADR-004 (AP-3/AP-4/AP-5 access paths, UTC storage, clinic-local presentation) | handlers, repo interfaces | pass |
| 29 | Direction: ADR-009 (no invented facts, identity from JWT, neither-filter rationale cites no-medical-advice) | handlers, journal | pass |
| 30 | Direction: ADR-008 (L1 cases, smoke evals on tool changes) | PR body | pass (runner doesn't exist yet; disclosed) |
| 31 | Direction: ADR-002, 005, 007, 010 | grep | not applicable (nothing in this PR touches them) |
| 32 | Direction: `docs/backlog.md` (#33 owns scenarios, #36 depends on #19, consolidation follow-up) | backlog, PR body | pass |
| 33 | Direction: `CLAUDE.md` (contracts change called out, owned paths, DoD) | PR body, diff | pass |
| 34 | Direction: committed eval scenarios don't expect a neither-filter call or more than 5 slots | `packages/evals/scenarios/**` | pass |
| 35 | PR claim: "stopping as soon as it has more than the slot limit" | `check_availability.ts:117` | pass |
| 36 | PR claim: "It needs a `provider_id` or a `specialty`" | `check_availability.ts:122-128` | pass |
| 37 | PR claim: find_providers name variants, stable order, capped at 20, empty list on no match | `find_providers.ts`, tests `:65-116,118-140` | pass |
| 38 | PR claim: unknown id gives NOT_FOUND with a find_providers hint; mismatch gives INVALID_INPUT with a hint | handler `:96-109`, tests `:137-149` | pass |
| 39 | PR claim: DST 12:00Z / 13:00Z and clinic-midnight bounds tested | tests `:161-232` | pass |
| 40 | PR claim: morning `< 12:00`, afternoon `>= 12:00` ET | handler `:40-44`, test `:115-125` | pass |
| 41 | PR claim: sorted by start then `provider_id`; at most 5; exactly 5 gives `truncated: false` (tested) | handler `:61-65,130-131`, test `:291-301` | pass |
| 42 | PR claim: past-date rules (strictly after now, clamp, INVALID_INPUT with clinic time, empty success today) | handler `:73-87`, tests `:334-380` | pass |
| 43 | PR claim: "38 tests in the two new files, all run through `createToolExecutor`, one per file through the production `TOOL_REGISTRY`" | `grep -c "^\s*it("`: 27 + 11; `:74`, `:54` | pass |
| 44 | PR claim: coverage list (range over 31 days, bad enum, bad date format, empty name, `patient_id`, identical answers, snapshot unchanged, spied index path, weekend-empty, moving clock) | both test files | pass |
| 45 | PR claim: "659 passed, 61 skipped" | CI | not verifiable (tests not run by rule; CI shows pass) |
| 46 | PR claim: registry.ts has two imports and two entries under the `#19` anchors, "Nothing else changed" | diff (+4 -0) | pass |
| 47 | PR claim: limit changed 10 to 5; schema `.max()` and description follow; "Nothing else uses the constant" | `grep -rn availabilityMaxSlots` | pass |
| 48 | PR claim: descriptions reviewed against skill §5, "No edits needed" | `tools.ts:226`, skill §5 | finding SPEC-1 (reported there as an open question rather than a separate overclaim, because "No edits needed" is a judgement the owner's SPEC-4 decision didn't settle) |
| 49 | PR claim: journal entry added; "ADR: none needed"; "PRD: unchanged" | diff | pass |
| 50 | PR claim: the listed existing L1 and L2/L3 scenarios exist | `packages/evals/scenarios/` listing | pass (all 12 exist) |
| 51 | PR claim: eval smoke suite not run because `npm run evals` doesn't exist (#30) | `CLAUDE.md:58` | pass (disclosed) |

### Searches run
| Query or command | Purpose | Hits |
|---|---|---|
| `grep -rn "availabilityMaxSlots" --exclude-dir=node_modules .` | check the limit change doesn't break other consumers; check "Nothing else uses the constant" | 11 (contracts, handler, tests, skill, journal) |
| `grep -rn "10 slots\|up to 10\|≤ 10\|<= 10\|max 10\|ten slots"` | stale references to the old limit | 1 (`spikes/s1-bedrock-tool-latency/fixture.ts:90`, a throwaway spike) |
| `grep -c "^\s*it(" packages/tools/test/tools/*.ts` | verify the "38 tests" claim | 27 + 11 |
| `grep -rn "check_availability" packages/evals/scenarios` | scenarios that depend on check_availability arguments or result size | ~30 |
| `grep -rn "check_availability\|find_providers" packages/agent/src services apps` | prompt or handler assumptions about a clinic-wide search | 0 |
| `grep -n "FR-030" docs/PRD.md` | locate the requirement | 2 |
| `grep -rn "acceptingNewPatients\|accepting_new_patients\|new patient" docs CLAUDE.md packages/tools/fixtures` | any spec rule for not-accepting providers (SPEC-2) | 3 (fixture only) |
| `grep -n -i "tool\|slot\|availability\|L1\|smoke" docs/adr/0002 0005 0007 0008 0010` | direction relevance of the remaining ADRs | ~45 |

## 3. Not reviewed

- `RUN_DIR/previous/`: not read, by rule. The owner's decisions were taken from manifest §6.
- ADRs 0003 and 0006 were not read. They cover IaC layout and voice, which nothing in this PR touches.
- ADRs 0002, 0005, 0007, 0008 and 0010 were scanned with grep rather than read in full.
- Whether the L1 cases were also commented on issue #33, as the skill asks: GitHub issue #33 isn't in the inputs.
- R16 ("All options come from tool results") and the effect of SPEC-1/SPEC-2 on model behaviour: these need the eval harness (#30), which doesn't exist yet.
- The test pass counts in the PR body: tests are not run by rule; CI reports pass.
