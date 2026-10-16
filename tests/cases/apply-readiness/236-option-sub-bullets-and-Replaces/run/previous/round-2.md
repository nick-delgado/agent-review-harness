<!-- agent-pr-review:readiness round=2 -->
## Readiness refresh (round 2): Needs answers

**Issue:** #236 [M3] Offer format: grouped by day, five options in total across days, spread over broad requests, patient on repeats (#212) · **Read at:** 2026-10-16 00:57 UTC · **Default branch:** `main` @ `8e6d8ea`

Round 1 settled this issue against `c05cb79`. This refresh checks it against `8e6d8ea`. Since then #239's grader PR (PR #278) has merged with an ADR-008 amendment. That amendment says #239's new reader serves only the slot check, and that `times_in_clinic_tz_with_weekday` keeps the old `dateTimeMentions` reading. This issue's settled answers (AC 4, r1/Q-2 (a), r1/A-6) change that check to read listed times through #239's reader, so the amendment's sentence becomes false. CLAUDE.md says a false ADR line is fixed in the same PR, by amendment, but confirmed r1/A-8 says "The agent edits no ADR". Q-1 settles this. Every other answer still holds. Two assumptions update details that #239's merge made concrete, and two edits record that the blocker is gone.

Round: 2 · Questions: 1 · Assumptions: 3 · Suggested edits: 2 · Spec commit: 8e6d8ead9a06653041bb192d689053f4e356f299 · Harness version: 2026.10.15

**Check these first:** A-1

**To answer:** reply on this issue with one line per item, in the form shown under each (`Decision r2/<ID>: <answer>`): an option's letter or your own words for a question, "accept" or "reject" for an edit, "ok" or your correction for an assumption. To take every recommendation and edit at once, `Decision r2/ALL: accept`; it does not cover the assumptions under "Check these first" or those marked "(verify first)" or "(would have asked)", which each need their own line. Only `Decision` lines are applied, never other replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: When this issue makes the weekday/ET check read times listed under a day line, does it add an ADR-008 amendment saying so?

- **Why it matters:** #239's amendment now records which checks use which reader, and this issue's work makes that record false. Either the PR amends ADR-008, which is outside the owned paths and against r1/A-8, or a reviewer finds a stale ADR line. Both cost a fix round, and r1/A-8 was confirmed on the old ADR text.
  - What the amendment says: "This reader (`slotMentions`) serves the slot check only, in both modes; `dateTimeMentions` keeps its "first time after a date" reading for the tool-output keys, `times_in_clinic_tz_with_weekday` and L1's known keys (r1/A-1)" (`docs/adr/0008-evaluation-strategy.md:255`). The code comments say the same (`packages/evals/src/graders/text.ts:299-305`, `:327-332`).
  - What this issue's answers do to it: AC 4 and r1/Q-2 (a) make `times_in_clinic_tz_with_weekday` take a listed time's weekday from the day line above it. Confirmed r1/A-6 says the check "imports the pairing #239 adds … instead of writing a second parser". Once that lands, the sentence above is false.
- **Source:**
  - CLAUDE.md, "How work flows": "A line your change makes false, in `CLAUDE.md` or any other doc, skill or keep-in-sync comment … is fixed in the same PR, called out the same way; an Accepted ADR changes by amendment."
  - r1/A-8 (confirmed): "The agent edits no ADR and no PRD line. Under Q-2 (a) or (b), ADR-008 `:128` stays true." `docs/adr/**` is not in the owned paths.
  - #239 r1/A-1: "a new reader that only the slot check uses … `dateTimeMentions` doesn't change, so … `times_in_clinic_tz_with_weekday` … keep their verdicts". #239's non-goals: "No change to `times_in_clinic_tz_with_weekday`'s verdicts; its grouped-format half is #236's (#236 AC4)".
  - `docs/journal/2026-10-15-a-quoted-slot-is-an-offer-not-an-echo.md:45`: "#236 (the offer format, with #212) lands next; its day lines get their dates from this reader."
- **Options:** (one per line)
  - (a) Reuse #239's heading reader and add a dated ADR-008 amendment. The amendment says what `times_in_clinic_tz_with_weekday` now grades and which readers it uses (details below). Scope: adds an ADR-008 amendment. Owned paths: + `docs/adr/0008-evaluation-strategy.md`, + `docs/adr/README.md`
    - **What the check grades:** every clock time on a list line under a date heading, with the reach from #239's amendment (first bullet). It takes the weekday from the heading line and looks for ET within 16 characters after the time, on the time's own line. Times on a heading line and in prose keep the `dateTimeMentions` reading.
    - **Which readers:** the heading-list reader serves both checks. Reading later times in a sentence stays with the slot check only.
    - **Edits around it:** an inline "Refined by" note on the `times_in_clinic_tz_with_weekday` line (`:128`), the status line (`:3`) and the README row (`docs/adr/README.md:21`). The `headingListTimes` and `slotMentions` doc comments in `text.ts` are updated to match.
    - **What it replaces:** the "no ADR" half of r1/A-8. Its PRD half stands.
  - (b) Keep #239's reader for the slot check only, and give the weekday check its own day-line reader in `packages/evals/src/graders/text.ts`, with no ADR edit. Scope: within the issue
    - **Why no ADR edit:** the 2026-10-15 sentence stays literally true, because `slotMentions` still serves only the slot check and `dateTimeMentions` is unchanged. The check's wider reading is recorded only in the grader's header comment and the journal.
    - **What it replaces:** r1/A-6's "instead of writing a second parser". Two readers then define a date heading's reach, so a later change to one can leave the other behind.
- **Makes stale:** by option, one line each:
  - `docs/adr/0008-evaluation-strategy.md:255` (the "serves the slot check only" sentence): option (a), refined by the new amendment, not edited in place
  - `docs/adr/0008-evaluation-strategy.md:3`, `:128`: option (a)
  - `docs/adr/README.md:21`: option (a)
  - `packages/evals/src/graders/text.ts:299-305` (`headingListTimes` doc), `:327-332` (`slotMentions` doc, "for `no_hallucinated_slots` only"): option (a)
  - `packages/evals/src/graders/text.ts:360-364` (`mentionHasWeekdayAndZone` doc): both options (already listed under r1/Q-2)
- **Edges:** each case below is settled by the choice.
  - **Reach, under both options:** #239's rule. The reach runs over blank lines and list lines, and a prose line or a weekday-only line ends it. "Tuesday, October 13:\n- 1:00 PM ET" grades 1:00 PM with Tuesday and passes. In "Tuesday, October 13:\nHere they are:\n- 1:00 PM", the 1:00 PM is no date-time mention and isn't graded, as r1/Q-2's edge says.
  - **Rejected under both:**
    - "October 13:\n- 1:00 PM ET" fails, because the heading has no weekday.
    - "Tuesday, October 13:\n- 1:00 PM" fails, because the time has no ET.
    - Gate run 4's heading still fails on its own 2:30 PM. Its test (`packages/evals/test/no-hallucinated-slots.test.ts:97-103`) stays green.
  - **Prose, under both:** later times in a sentence ("Monday, November 2 at 9:00 AM ET and 11:30 AM") stay outside the weekday check (r1/Q-2 (a): "A time written inside a day line or in prose keeps today's rule").
  - **Evidence:** under (a), the ADR diff and the README row in the PR. Under both, AC 4's grader tests.
- **Recommendation:** (a), for four reasons:
  - it keeps confirmed r1/A-6's single parser;
  - it does what #239 handed over ("its day lines get their dates from this reader", journal `:45`);
  - it follows CLAUDE.md's rule for a false ADR line;
  - it records what a check reads the way the last two grader changes did, as ADR-008 amendments (#233 on 2026-10-11, #239 on 2026-10-15).
- **Reply:** `Decision r2/Q-1: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | Replaces r1/A-6. #239 is on `main` (PR #278, merge `190eb32`). The pairing it added is `headingListTimes` (`packages/evals/src/graders/text.ts:306-325`). It is not exported, and its result carries the heading's month and day (`NamedDate`, `:239-244`) but not the heading line or its weekday. The agent exports it from `text.ts` (**required**: confirmed r1/A-6 forbids a second parser) and extends what it returns so `times_in_clinic_tz_with_weekday` can read the weekday on the heading line. Carrying the heading line's start index on each mention is a **suggestion**. The check then grades the `dateTimeMentions` pairs as today, plus the `headingListTimes` mentions, which take the weekday from the heading line and need ET within 16 characters after the time. It doesn't use `pairsAndLaterTimes` (`:278`), so prose keeps today's rule (r1/Q-2 (a)). A list line that names its own month-day is a heading under #239's rule, so it is read as today. | ADR-008's 2026-10-15 amendment (first bullet: the heading rule and its reach); `text.ts:224-332` at `8e6d8ea`; r1/A-6 and r1/Q-2 (a) (confirmed) | `packages/evals/src/graders/text.ts:299-305`, `:327-332`, `:360-364`<br>`packages/evals/src/graders/invariants.ts:317-324` (the check) | `Decision r2/A-1: <your correction>` |
| A-2 | Replaces r1/A-1's last sentence (the search). A search for `system\.v3` outside the prompts folder, journals and baselines now finds two more lines than in round 1. Both stay as they are, and the PR names them. The first is `docs/adr/0008-evaluation-strategy.md:253`, the 2026-10-15 amendment's "(`system.v3.ts`, "# Offering times")". An Accepted ADR changes only by amendment, and that line describes the prompt as it was when #239 merged. The second is `docs/research/security-review.md:241` ("`packages/agent/src/prompts/system.v3.ts:152`"), in a review dated "against `main` at `c05cb79`" (`:12`). The rest of r1/A-1 holds: every line it lists is unchanged at `8e6d8ea`. | The search under "What was checked"; CLAUDE.md ("an Accepted ADR changes by amendment"); r1/A-1 (confirmed) | nothing | `Decision r2/A-2: <your correction>` |
| A-3 | The owner accepted `book-derm-next-week-afternoon`'s gate regressions on #239 "for PR #278" only, so they don't carry over to this PR. On this issue's PR the agent applies CLAUDE.md's rule to that case: one regressed case per mode is accepted in advance, and the same case regressing on two or more gate runs needs a decision line. The PR cites PR #278's two over-five runs (38793901154, and 38826769844 with "10 times in one message") beside r1/A-7's before number, as evidence that the over-five reply recurs on `main`. It doesn't count them in the 3 + 3 rate. | #239 "Decisions and clarifications", the owner's two lines of 2026-10-15 (both checks "owned by #236/#212"); CLAUDE.md "Definition of done"; `packages/evals/baselines/sonnet-4.6.json:36` (the case is `pass`) | nothing | `Decision r2/A-3: <your correction>` |

### Suggested edits to the issue

#### E-1: Record that the blocker has landed

#239 closed when PR #278 merged at `190eb32`.

Before:
```text
- Blocked by: #239 (open), whose grader PR (carrying #178) must be on `main` first. #230 and #233 are closed; they took `system.v2` and `system.v3`.
```
After:
```text
- Blocked by: nothing open. #239's grader PR (PR #278, carrying #178, #244 and #245) is on `main` at `190eb32`; its heading reader is `headingListTimes` in `packages/evals/src/graders/text.ts` (r2/A-1). #230 and #233 are closed; they took `system.v2` and `system.v3`.
```
- **Reply:** `Decision r2/E-1: accept`

#### E-2: Replace the closed #178 in the graders' owned-path note

#178 closed with PR #278, so there is nothing left to coordinate with.

Before:
```text
- `packages/evals/src/graders/**` (only the format-related checks, coordinated with #178)
```
After:
```text
- `packages/evals/src/graders/**` (only the format-related checks; #239's heading reader in `text.ts` is exported and extended, not rewritten, r2/A-1)
```
- **Reply:** `Decision r2/E-2: accept`

### Reuse, dependencies and risks

- **Reuse:**
  - **The heading reader:** export `headingListTimes` from `packages/evals/src/graders/text.ts:306-325` and import it in `times_in_clinic_tz_with_weekday` (A-1). Extend `mentionHasWeekdayAndZone` (`text.ts:360-375`) rather than adding a second helper (r1 reuse note; its lines have moved since `c05cb79`).
  - **Line moves:** r1's other reuse pointers now sit at `listItemLines`, `LIST_ITEM_PREFIX` and `offeredClockTimes` `text.ts:192-220`. `markdownIn` is unchanged at `:35-45`. The test helpers are `recorded` `packages/evals/test/helpers.ts:64`, `invariants` `:71`, `byName` `:98` and `assistant` `:130`.
  - **Recorded-trial sweep:** import `failing` (`packages/evals/test/helpers.ts:88-96`, added by #239) to list the recorded trials that fail `times_in_clinic_tz_with_weekday` before and after the change, and `inTurn` (`:133-134`) to build multi-turn events.
  - **Gate run 4:** the heading case AC 4 names is already tested at `packages/evals/test/no-hallucinated-slots.test.ts:97-103`. Keep that test green, and cite it from the new grader tests rather than copying its fixture.
- **Dependencies:** none open. #239, #244, #245 and #178 closed with PR #278 (`190eb32`).
- **Overlaps:** no open PRs at `8e6d8ea`.
- **Size:** as in round 1, plus about 15 lines of ADR and README under Q-1 (a).
- **Risks:**
  - **A newly graded trial can fail:** once listed times are graded, a recorded trial whose list under a date heading has no ET would fail `times_in_clinic_tz_with_weekday`. `packages/evals/test/false-positives.test.ts:147-153` pins `reschedule-into-est-after-dst#1` as passing that check. The sweep above shows which trials change.
  - **The over-five reply recurs:** `book-derm-next-week-afternoon` went over five on 2 of PR #278's 5 gate runs (A-3), against round 1's "8 of 8" history under #171's prompt. Under r1/Q-3 (a), the prompt alone has to bring #212's branch reruns to zero.
- **Sibling issues:** no answers settled since round 1.
  - #234, #248, #249, #250 and #251 have no readiness decisions yet, and #212 has no new comment since 17:50 UTC on 2026-10-15.
  - #276 (open, `npm run mutate` and a timed-out unedited run) touches only the tool that produces the seen-failing evidence.
  - #239's owner decisions are covered in A-3.

**Relied on:** #236 description, "Acceptance criteria" (AC 4), "Owned paths", "Dependencies", "Decisions and clarifications" (r1/Q-1 to r1/Q-4, r1/A-1 to r1/A-8); #239 description, "Non-goals", "Dependencies", "Decisions and clarifications" (r1/A-1, the owner's two lines of 2026-10-15); `docs/adr/0008-evaluation-strategy.md` status line, the `no_hallucinated_slots` and `times_in_clinic_tz_with_weekday` lines (`:125`, `:128`), "Amendment (2026-10-15): what `no_hallucinated_slots` reads as a quoted slot (#239)"; `docs/adr/README.md` ADR-008 row; `docs/journal/2026-10-15-a-quoted-slot-is-an-offer-not-an-echo.md` "What's next"; `CLAUDE.md` "How work flows" (false lines, ADR amendments), "Definition of done" (Eval gate regressions).

<details>
<summary>What was checked</summary>

**Spec changes** (`spec-changes.patch`, `c05cb79..8e6d8ea`), each against what the issue relies on:
- **ADR-008 status line and README row** (2026-10-15, #239): matter only as places Q-1 (a) would extend.
- **ADR-008 `:125`** (the `no_hallucinated_slots` refinement note): matches what AC 4 expects #239 to deliver. Still holds.
- **ADR-008 amendment, opening paragraph:** "breaking that rule without quoting a slot is an offer-format matter (#236)". This repeats the hand-off r1 already carried (A-5 keeps the "mention that time without its date" sentence; Q-2 (a)'s day line has "no time and no other words"). Still holds. Its "(`system.v3.ts`, …)" mention is new for the A-1 search (r2/A-2).
- **ADR-008 amendment, first bullet** (the heading rule, later times in a sentence, `slotMentions` slot-only): reopens r1/A-8 against r1/A-6 (Q-1). It also makes r1/A-6's conditional concrete: the pairing exists and is unexported (r2/A-1). The heading's reach agrees with r1/Q-2 (a)'s edges ("A listed time with no day line above it and no date on its line … isn't graded").
- **ADR-008 amendment, bullets 2–4** (held appointment, clinic hours, same-turn restatement): exemptions of the slot check only. AC 4's "a listed time no tool returned" still fails, because a hand-built offer has no held appointment at that time, names no hours phrase and makes no same-turn check. Do not matter.
- **ADR-008 amendment, closing paragraph** (the recorded-trial count): does not matter.
- **ADR-009 amendment** (#39: the IAM index and model names, logging only AWS SDK error messages) and its `:23`, `:63` notes: about `infra/stacks/api.yaml` and `services/api` logging. Nothing in this issue touches them. Do not matter.
- **ADR README rows:** follow the two amendments above.
- **PRD, architecture:** not changed.

**Settled items, re-checked at `8e6d8ea`:**
- **r1/Q-1 (a):** still holds. `loop.ts`, `matchers.ts` and both smoke L1 cases are unchanged (`git diff --stat c05cb79..HEAD` lists none of them).
- **r1/Q-2 (a):** still holds. `mentionHasWeekdayAndZone`'s logic is unchanged; only its lines moved (`:211-227` → `:360-375`). Its "no ADR amendment" reasoning gives way to Q-1.
- **r1/Q-3 (a):** still holds. A-3 adds PR #278's runs as evidence.
- **r1/Q-4 (a):** still holds. The baseline and the scenarios README are unchanged. `availability-cardiology-est-week.yaml`'s `notes:` changed (#239), and it is not one of the cases Q-4 touches.
- **r1/A-1:** still holds, except its search, which A-2 replaces.
- **r1/A-2:** still holds. `packages/contracts/src/tools.ts` is unchanged, and Q-1 is (a), as the orchestrator's note says.
- **r1/A-3, r1/A-4, r1/A-5, r1/A-7:** still hold. `packages/agent/` is unchanged.
- **r1/A-6:** superseded by r2/A-1.
- **r1/A-8:** reopened as Q-1, for its ADR half only.

**Acceptance criteria and owned paths:**
- AC 4's "#239 … lands first" is now history and is not wrong.
- The "Dependencies" line is out of date: E-1.
- The graders' owned-path note names the closed #178: E-2.
- No owned file was renamed.

**Deferral notes:** none on #236 (no comment starts `<!-- agent-pr-review:deferred`).

**Searches run:**
- `git log --oneline c05cb79..HEAD` and `git diff --stat c05cb79..HEAD`: 49 files. Under the owned paths, the changes are in `packages/evals/src/graders/{text,invariants}.ts`, `packages/evals/test/{helpers,no-hallucinated-slots,plain-text}.test.ts`, one scenario's `notes:` and journals. `packages/agent/` and `packages/contracts/` are unchanged.
- `git diff c05cb79..HEAD -- packages/evals/src/graders/text.ts`: adds `slotKey`, `SlotMention`, `pairsAndLaterTimes`, `headingListTimes` (unexported), `slotMentions` and `namesClinicHours`, and leaves `mentionHasWeekdayAndZone` unchanged.
- `git grep -n -E "system\.v3|SYSTEM_PROMPT_V3|systemPromptV3|renderSystemPromptV3" -- . ':!packages/agent/src/prompts' ':!docs/journal' ':!packages/evals/baselines'`:
  ```text
  docs/adr/0002-model-and-bedrock-client.md:152
  docs/adr/0008-evaluation-strategy.md:253
  docs/research/security-review.md:241
  packages/evals/src/system-prompt.ts:3
  packages/evals/test/calibration.test.ts:271
  packages/evals/test/suite.test.ts:154
  packages/evals/test/system-prompt.test.ts:11
  scripts/trace.test.ts:55, :197, :236
  services/api/test/chat-handler.test.ts:234, :240
  ```
  The two lines new since `c05cb79` are ADR-008 `:253` and `security-review.md:241` (r2/A-2).
- `grep -rn times_in_clinic_tz_with_weekday packages/evals/test`: `graders.test.ts:575-600`, `no-hallucinated-slots.test.ts:97-103`, `false-positives.test.ts:147-153` and `grader-fail-cases.test.ts:201`.
- `gh api …/issues?state=all&since=2026-10-15T18:00:00Z` (issues updated since round 1): #279, #276, #273, #272, #271, #270, #268, #257, #256, #245, #244, #239, #236, #178, #72, #42 and #39. Only #239 (and the issues it closed) bears on this issue.
- `gh pr list --state open`: none.

**Sources read:**
- The brief and the manifest, whole.
- `spec/issue-236.md`, read to line 583 of 583.
- `previous/round-1.md` (380 lines; it matches the round 1 comment in the issue file) and `previous/applied-1.md`, whole.
- `spec-changes.patch`, whole.
- `spec/background/issue-239.md`: its decisions, non-goals, dependencies and later comments.
- The worktree files cited above.

**Not checked:**
- PR #278's gate-run artifacts, so the A-3 numbers are as the owner's comments quote them.
- The recorded transcripts, so it is not known which trials the wider weekday check would newly fail. A-1's sweep shows it.

</details>

