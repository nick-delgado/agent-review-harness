## Cause analysis

Every cause below is an inference from the PR and the repository; the agent's prompt and transcript were not available. Inventory read in full: `CLAUDE.md`, `.claude/skills/add-agent-tool/SKILL.md`, `.claude/skills/task-workflow/SKILL.md` (+ `evals/evals.json`), `.claude/skills/dev-journal/SKILL.md` (+ `evals/evals.json`), `.claude/skills/sam-deploy/SKILL.md`, `.claude/agents/task-worker.md`, `.github/ISSUE_TEMPLATE/task.yml`, `.github/pull_request_template.md`, plus `.github/workflows/ci.yml`, `vitest.config.ts` and `eslint.config.js` for guardrails.

### SPEC-1: check_availability returns up to 10 slots; the acceptance criterion says at most 5
- **Primary cause:** conflicting-instructions
- **Contributing:** ambiguous-instruction, spec-gap
- **Confidence:** high
- **Evidence:**
  - The two sources, both in the agent's path. Issue #19 (`spec/issue-19.json`, acceptance criteria): "returns ≤ 5 slots with slotId, provider, local start (clinic TZ), weekday". The skill the issue tells the agent to follow, `.claude/skills/add-agent-tool/SKILL.md:76`: "The limits (`LIMITS.availabilityMaxSlots`, and so on) are in contracts; respect them and set `truncated` when you cut." `packages/contracts/src/clinic.ts:19`: `availabilityMaxSlots: 10`; `packages/contracts/src/tools.ts:226` tells the model "Returns up to ${LIMITS.availabilityMaxSlots} slots".
  - Where the 5 comes from: `docs/PRD.md:82` (FR-030) "Presents at most 5 options". That is a rule about what the agent says; the issue restated it as what the tool returns. The contract (commit `0ba7570`, #4, 2026-09-28) and the skill (`791e2bb`, #11, 2026-09-29) both chose 10 without the issue being updated.
  - The rule for conflicts does not cover this one. `.claude/skills/task-workflow/SKILL.md:72`: "If the issue conflicts with an ADR, stop and ask. Don't silently pick one." It names ADRs only; this conflict is issue against contract and skill. `:77` ("comment on the issue and ask the user") is limited to "files outside your paths". The subagent definition pushes the other way: `.claude/agents/task-worker.md:23-25` "don't re-derive what the issue and ADRs already decide ... If you're blocked, report what you tried rather than thrashing", and a task-worker has no stated way to ask mid-run.
  - Nowhere to record it: `.github/pull_request_template.md` has no section for an unmet acceptance criterion, so the agent filed it as item 3 of "Contract change requests (not made here)" and still wrote `Closes #19`.
  - Searches: `grep -rn -i "stop and ask\|ask the user\|comment on the issue\|conflict" CLAUDE.md .claude .github` (only `task-workflow:72` and `:77` apply); `grep -rn "availabilityMaxSlots\|at most 5\|≤ 5" packages docs .claude` (no source reconciles 5 and 10).
- **Counterfactual:** had the conflict rule covered the contract and skill and said what to do when nobody can be asked (take the reading that satisfies both, here a slice to 5, and leave the criterion unticked), a competent agent would plausibly have capped at 5 or stopped; had the issue cited the constant instead of a number there would have been no conflict.
- **Could a test or check have caught it?** partly — no mechanical check can compare issue prose with a constant. A handler test written from the acceptance criterion (`expect(slots.length).toBeLessThanOrEqual(5)`) would have failed, but the agent writes those tests and wrote them from the constant (`check_availability.test.ts:95`). The reliable fix is at the spec: cite the constant in the issue.

### TEST-1: No test would fail if the two tools were not registered in `TOOL_REGISTRY`
- **Primary cause:** misleading-precedent
- **Contributing:** missing-instruction, missing-guardrail
- **Confidence:** high
- **Evidence:**
  - The copied precedent. The skill's worked example test (`.claude/skills/add-agent-tool/SKILL.md:198-287`) builds a one-tool registry (`:234` `createToolExecutor({ get_patient_profile: getPatientProfile }, ctx)`), then shows registration at `:289-304` with no test for it, and ends "verified ... the test (6 passing)" (`:308`). The PR's tests reproduce its scaffolding line for line (`outputOf`, `errorOf`, `run`; `check_availability.test.ts:15-38` against `SKILL.md:217-239`).
  - The instruction is silent. Section 3 prescribes the one-tool registry (`SKILL.md:80`: "Run through `createToolExecutor({ tool_name: handler }, ctx)`"); the minimum-cases table (`:86-92`) and the definition of done (`:132-133`) have no registration case, although `:104` says "an unregistered tool is never offered." Search: `grep -rn "TOOL_REGISTRY" CLAUDE.md .claude .github` finds no sentence asking for a test.
  - The existing guard is vacuous and outside the owned paths. `packages/tools/test/registry.test.ts:109-116` ("is empty for the (still empty) production registry") is true for any registry contents. The agent saw the file was stale and left it: PR body, "Not touched (outside owned paths)".
  - The type cannot help: `packages/tools/src/registry.ts:87` makes every key optional.
- **Counterfactual:** had the worked example contained one assertion against `TOOL_REGISTRY`, or the cases table a "Registered" row, the agent, which copied the rest of the example, would plausibly have copied that too.
- **Could a test or check have caught it?** yes — a unit test in each tool's own test file: `expect(TOOL_REGISTRY.check_availability).toBe(checkAvailability)` and the tool name in `createToolExecutor(TOOL_REGISTRY, ctx).definitions`. It fails when the registry line is deleted, and it stays inside each issue's owned paths so parallel PRs do not collide.

### TEST-2: The "no spill from UTC midnight" test never reaches the code that converts the date range
- **Primary cause:** undiscoverable-context
- **Contributing:** ambiguous-instruction, missing-guardrail
- **Confidence:** medium
- **Evidence:**
  - The practice that would have exposed it exists, but only in the journal. `docs/journal/2026-09-29-watch-the-double-booking-test-fail.md:15`: "A test that can't fail against this implementation says nothing about it." and `:19`: "**Break it on purpose.**" No auto-loaded file or skill carries it: `grep -rn -i "would fail\|watch.*fail\|break it\|mutation" CLAUDE.md .claude .github` returns nothing, and `CLAUDE.md:13` mentions `docs/journal/` only as story material.
  - The skill defines the DST test as an output-format check. `SKILL.md:96`: "the DST boundary (a slot on Nov 2 shows EST)". The range problem appears only in the debugging table (`:147`: "a range built in UTC instead of `clinicDateRangeUtc`. Test a slot on each side of Nov 1"), and "a slot on each side of Nov 1" is exactly what `check_availability.test.ts:125-144` does; it cannot detect a UTC-built range.
  - The fixture cannot distinguish the two ranges: `packages/tools/fixtures/clinic-default.ts:6` has slots only "Mon–Fri 8:00 AM–5:00 PM", and the skill says to use the fixture (`SKILL.md:82`) without saying that a midnight-edge slot must be seeded.
  - No guardrail: `vitest.config.ts` has no coverage or mutation settings; `ci.yml:38-41` runs lint, typecheck and test only.
  - The over-claim in the PR body ("an EST day never spills across UTC midnight") is the agent's own; no instruction asked it to check a claim against a failing run, which is the same gap.
- **Counterfactual:** had the skill told the agent to replace `clinicDateRangeUtc(...)` with a UTC-day range and watch the test go red, it would have stayed green and the agent would have had to seed a near-midnight slot or rename the test.
- **Could a test or check have caught it?** yes — a `provider_id` test with seeded slots at 11:30 PM ET on the requested day and 7:30 PM ET the day before; mechanically, mutation testing over `src/tools/*.ts` reports the surviving mutant.

### Pattern: undiscoverable-context (TEST-2, TEST-3, TEST-4, TEST-5; TEST-1 related)
- **Primary cause:** undiscoverable-context
- **Contributing:** missing-guardrail
- **Confidence:** medium
- **Evidence:** Each finding is a one-line change to the handler that leaves all 31 tests green: `<=` to `<` at `check_availability.ts:111` (TEST-3), `clinicDateOf(now)` to the UTC date at `:66` (TEST-4), dropping `providers.has` at `:83` (TEST-5), a UTC-day range at `:104` (TEST-2), deleting `registry.ts:109-110` (TEST-1). The agent tested every case the skill lists (`SKILL.md:86-96`) and stopped there; the three minors are all in behaviour the agent added itself (day walk, past-date rule, missing-provider guard), which the list could not name in advance. The one practice that generalises, breaking the code to see the test fail, is recorded at `docs/journal/2026-09-29-watch-the-double-booking-test-fail.md:15-19` and referenced from no instruction file or skill (search above). `CLAUDE.md:118` asks only that "Tests are added or updated". Against `agent-lapse`: no in-path instruction asks for more than the listed cases, and all of them are present.
- **Counterfactual:** a "watch it fail once" step in skill section 3, with the definition-of-done box to match, would have surfaced all five with the agent's own tools.
- **Could a test or check have caught it?** yes — mutation testing on `packages/tools/src/tools/*.ts` flags TEST-2 to TEST-5; branch coverage alone flags only TEST-5. Alternatives considered: a CI coverage threshold (cheap, catches one of five) and a fixed longer edge list in the skill (catches these five, not the next tool's).

### Pattern: spec-gap (SPEC-2, SPEC-3, SPEC-4, SPEC-5; SPEC-1 related)
- **Primary cause:** spec-gap
- **Contributing:** missing-instruction
- **Confidence:** high
- **Evidence:**
  - The spec's one sentence on behaviour: "Supports provider, specialty, date range, and time-of-day filters; returns ≤ 5 slots with slotId, provider, local start (clinic TZ), weekday" (issue #19). Silent on past dates, on `provider_id` with a different `specialty`, on neither filter, and on providers not accepting new patients. `docs/PRD.md:82` is equally silent.
  - The contract leaves all of it open: `packages/contracts/src/tools.ts:91-105` (`DateRange` accepts past dates), `:119-120` (both filters `.optional()`, no refinement), `:169-173` (`SlotOption` has no accepting flag).
  - The skill invites the handler to decide: `SKILL.md:62` "Tool-level rules that need \"now\" ... belong in the handler", and its edge list (`:96`) has none of these cases.
  - Nothing says what to do when the spec is silent. `task-workflow:72` covers an ADR conflict, `:77` files outside owned paths; `task-worker.md:23` says "don't re-derive what the issue and ADRs already decide". `task.yml:17` asks for "Checkable statements" without prompting for edge behaviour. Search: `grep -rn -i "assum\|silent\|ambiguous\|unclear\|guess\|open question" CLAUDE.md .claude .github` finds nothing on point.
  - The agent did disclose what it recognised as a decision (PR heading "Past dates (decision ...)", change requests 1 and 2), but SPEC-3 and SPEC-4 are listed as plain behaviour, and the change requests live only in the PR body.
- **Counterfactual:** had the issue stated the four behaviours, the agent would have implemented them as written; had the workflow required a "Decisions for the owner" list and an issue comment, the guesses would have reached the owner as questions instead of being found in review.
- **Could a test or check have caught it?** partly — not the guessing itself. For SPEC-4 a contract refinement ("one of provider_id or specialty is required") would make the choice explicit and machine-checked; the rest needs the spec or the owner.

### Notes on the remaining minors
- **STD-1:** the rule's wording and its stated purpose differ (`SKILL.md:58` "`new Date()`" against `clock.ts:2-3`), `toZonedParts` takes only a `Date` (`clock.ts:105`), and `repos/dynamo/repositories.ts:125` already has `new Date(ms)`. The agent's reading (zero-argument only) is not strained.
- **STD-2:** five thresholds for one obligation: `CLAUDE.md:122` "any new or reversed decision", `:123` "surprising, hard, or story-worthy", `task-workflow/SKILL.md:120` "you made or reversed a decision", `add-agent-tool/SKILL.md:138` "if something surprised you", `dev-journal/SKILL.md:21` "A significant technical choice", PR template `:25` "if story-worthy". The agent applied the loosest.
- **SMELL-2:** the guard echoes the worked example (`SKILL.md:183`, `:196`: "a dangling reference degrades to `null` instead of failing the whole call"; handler `:78-79`: "left out rather than failing the whole search"). That explains the guard, not the duplicated check.

## Cause summary

| Finding | Severity | Failure class | Primary cause | Confidence | Evidence |
|---|---|---|---|---|---|
| TEST-1 | major | test-cannot-fail | misleading-precedent | high | The "worked example" at `x.md:3` |
| SMELL-1 | minor | stale-restatement | missing-instruction | low | header line |

## Patterns

| Cause | Findings | What they have in common |
|---|---|---|
| undiscoverable-context | TEST-2, TEST-3, TEST-4, TEST-5 (TEST-1 related) | Each is a one-line break of the handler that no test notices; the "watch it fail" practice exists only in a journal entry. |
| spec-gap | SPEC-2, SPEC-3, SPEC-4, SPEC-5 (SPEC-1 related) | The issue gives one sentence of behaviour, and no instruction says what to do with a decision it leaves open. |
| conflicting-instructions | SPEC-1, STD-2 | Two in-path sources disagree, and the only "stop and ask" rule covers ADR conflicts. |

## Proposals

### P1: Make "watch each test fail once" part of the tool recipe
- **Type:** skill-edit
- **Addresses:** TEST-1, TEST-2, TEST-3, TEST-4, TEST-5 (cause: undiscoverable-context)
- **Confidence:** medium
- **Target:** `.claude/skills/add-agent-tool/SKILL.md`
- **Change:**
  ```diff
  @@ section 3, after the "Cover, at minimum" table
  +**Watch each test fail once.** For every behaviour a test names, make the one-line change to the handler that breaks it (a UTC-day range instead of `clinicDateRangeUtc`, `<` for `<=`, a guard removed), run the test, then restore. If it stays green, the test doesn't reach that code: fix it, or rename it to what it checks. Test names and the PR's "Tested" list may claim only what went red. Why: `docs/journal/2026-09-29-watch-the-double-booking-test-fail.md`.
  @@ line 96
  -the DST boundary (a slot on Nov 2 shows EST); truncation at the limit;
  +the DST boundary (a slot on Nov 2 shows EST); the clinic-day boundary (fixture slots are 8 AM–5 PM ET, which a UTC-day range also returns: seed one at 11:30 PM ET, and set the clock after 8 PM ET for "today"); truncation at the limit, on one day and across two;
  @@ line 132
  -- [ ] Tests via `createToolExecutor`: happy, not-found, invalid input, cross-patient (with snapshot unchanged), tool-specific edges
  +- [ ] Tests via `createToolExecutor`: happy, not-found, invalid input, cross-patient (with snapshot unchanged), tool-specific edges; each seen to fail once
  ```
- **Expected effect:** The agents on #20–#23 find tests that cannot fail before the reviewer does, using a practice the project already trusts.
- **Cost and risk:** About five lines in a skill loaded for every tool task, and more test runs per task; it relies on the agent doing it honestly.

### P2: Say what to do with conflicts and open decisions, and give them a place in the PR
- **Type:** skill-edit
- **Addresses:** SPEC-1, SPEC-2, SPEC-3, SPEC-4, SPEC-5 (cause: conflicting-instructions, spec-gap)
- **Confidence:** medium
- **Target:** `.claude/skills/task-workflow/SKILL.md` and `.github/pull_request_template.md`
- **Change:**
  ```diff
  @@ task-workflow/SKILL.md:72
  -3. **The ADRs and PRD requirements the issue cites.** If the issue conflicts with an ADR, stop and ask. Don't silently pick one.
  +3. **The ADRs and PRD requirements the issue cites.** If the issue conflicts with an ADR, the PRD, `packages/contracts` or a skill, stop and ask. Don't silently pick one. If you can't ask (you're a task-worker), take the reading that satisfies both when one exists, leave that acceptance criterion unticked, and comment the conflict on the issue.
  +4. **What the issue doesn't say.** When you choose a behaviour the model or patient can see and the issue, PRD and contract are silent (an error instead of an empty result, a default search, a silent clamp), list it under "Decisions for the owner" in the PR with the options you rejected, and comment it on the issue. A contract change request goes in a new issue, not only the PR body.
  @@ pull_request_template.md, after "Shared-file or contract changes"
  +## Decisions for the owner
  +
  +<!-- Acceptance criteria not met as written, and behaviours you chose where the issue was silent. "None" is a fine answer. -->
  ```
- **Expected effect:** A 5-against-10 conflict becomes a capped handler plus an unticked criterion, and guesses arrive as a list the owner can answer in one pass.
- **Cost and risk:** Three lines of workflow and one template section; agents may over-report trivial choices, so the wording limits it to behaviour the model or patient can see.

### P3: Run mutation testing on the tool handlers
- **Type:** new-lint-or-ci-check
- **Addresses:** TEST-2, TEST-3, TEST-4, TEST-5 (cause: missing-guardrail, contributing)
- **Confidence:** low (configuration not run here; check the Vitest-projects setup works with the runner)
- **Target:** `packages/tools/stryker.config.json` (new) and `packages/tools/package.json`
- **Change:**
  ```diff
  +{ "testRunner": "vitest", "mutate": ["src/tools/*.ts"], "reporters": ["clear-text"], "thresholds": { "high": 90, "low": 80, "break": 80 } }
  @@ package.json "scripts"
  +    "test:mutation": "stryker run",
  ```
  with `@stryker-mutator/core` and `@stryker-mutator/vitest-runner` as devDependencies, and the command added to the skill's definition of done once it is stable; keep it out of the required CI check at first.
- **Expected effect:** Surviving mutants name the exact lines whose tests cannot fail, which turns P1 from a habit into a report.
- **Cost and risk:** Two dev dependencies and minutes per run; equivalent mutants produce false alarms, so the threshold should start as advice.

### P4: Add a registration case to the tool tests and the worked example
- **Type:** new-test
- **Addresses:** TEST-1 (cause: misleading-precedent)
- **Confidence:** high
- **Target:** `.claude/skills/add-agent-tool/SKILL.md` (cases table at `:91` and the worked example test at `:281`); the same `it` in the two new test files of this PR
- **Change:**
  ```diff
   | Cross-patient | An extra `patient_id` is rejected; another patient's IDs read as `NOT_FOUND`; and **nothing changed** (`repos.snapshot()` before/after) |
  +| Registered | `TOOL_REGISTRY.<tool_name>` is this handler, and `createToolExecutor(TOOL_REGISTRY, ctx).definitions` lists the tool |
  @@ worked example test
  +  it("is registered in the production registry", () => {
  +    expect(TOOL_REGISTRY.get_patient_profile).toBe(getPatientProfile);
  +  });
  ```
  Also delete the "is empty for the (still empty) production registry" test at `packages/tools/test/registry.test.ts:109-116` in a follow-up, since it passes for any contents.
- **Expected effect:** Deleting a registry line fails a test in the tool's own file, inside the issue's owned paths, so parallel tool PRs do not conflict.
- **Cost and risk:** One table row and three example lines; negligible.

### P5: Cite contract constants and edge behaviour in task issues
- **Type:** spec-practice
- **Addresses:** SPEC-1, SPEC-2, SPEC-3, SPEC-4 (cause: conflicting-instructions, spec-gap)
- **Confidence:** medium
- **Target:** `.github/ISSUE_TEMPLATE/task.yml`
- **Change:**
  ```diff
  -      description: Checkable statements. Each one should be verifiable by a command, test, or observation.
  +      description: Checkable statements. Each one should be verifiable by a command, test, or observation. Cite a limit by its contracts constant (`LIMITS.availabilityMaxSlots`), not a number. Say what happens for empty, past, conflicting and missing inputs, or write "agent decides; list in the PR".
  ```
  For #19 itself: decide 5 or 10 on the issue (FR-030's "Presents at most 5 options" is about what the agent says, not what the tool returns), and amend #20–#23 the same way before they are built.
- **Expected effect:** The number in an issue cannot drift from the contract, and the author of the issue chooses edge behaviour or hands it over explicitly.
- **Cost and risk:** Slightly longer issues; helps only issues written after the change unless #20–#23 are amended by hand.

### P6: Use one threshold for journal entries and ADRs
- **Type:** doc-edit
- **Addresses:** STD-2 (cause: conflicting-instructions, shared with SPEC-1)
- **Confidence:** medium
- **Target:** `.claude/skills/task-workflow/SKILL.md:120` and `CLAUDE.md:122`
- **Change:**
  ```diff
  -  - you made or reversed a decision;
  +  - you made or reversed a decision that another issue will have to follow (a code comment is not a record);
  @@ CLAUDE.md:122
  -  - An ADR for any new or reversed decision.
  +  - An ADR for any new or reversed significant technical decision (the `dev-journal` skill says which).
  ```
- **Expected effect:** The past-date rule, which #21 and #22 must follow, clearly needs a journal entry, and routine choices clearly do not.
- **Cost and risk:** No added length; the owner must agree this is the intended threshold.

### P7: No action
- **Type:** no-action
- **Addresses:** STD-1, SMELL-1, SMELL-2, SMELL-3, SMELL-4
- STD-1 is one ambiguous sentence with one occurrence: if `new Date(iso)` reappears in #20–#23, reword `SKILL.md:58` to "zero-argument `new Date()`" and let `toZonedParts` accept a string. The smells are local and have no shared cause; fix them in the PR and add no rule.

## Not explained

- SMELL-1: no cause reached low confidence; the agent's transcript would show whether it read the ordering guarantee in `packages/tools/src/repos/types.ts:80,85-86`.
- SMELL-2: the worked example explains the guard but not the duplicated check; the transcript would show whether the second check was added only to satisfy the type of `Map.get`.
- SPEC-1: whether the task-worker's prompt included any coordination decision about the slot limit is unknown; the orchestrator's prompt would settle it.
