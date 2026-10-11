<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

**Issue:** #233 [M3] Plain-text replies: no Markdown and no repeated pre-tool narration in the chat bubble · **Read at:** 2026-10-11T07:53Z · **Default branch:** `main` @ `9c70182`

The issue asks for a prompt change (plain text, and no pre-tool narration that repeats the answer), a version bump, and two eval checks: one for Markdown and one for a doubled handoff line. The prompt work is clear. The checks are not. The owner needs to settle three things: whether the checks count as safety violations and run on every case, what the Markdown matcher flags, and what "the handoff line appears twice" means. On that last point, every doubled handoff on record is a paraphrase followed by the exact line, so a check on the exact text would never fail. The issue was also written against `system.v1`, which #230 renamed to `system.v2` after the issue was filed, and its owned paths miss the test and version-pin files the work has to touch.

Round: 1 · Questions: 3 · Assumptions: 11 · Suggested edits: 8 · Spec commit: 9c701827947ab2d0f09096ec88a314a5b53ba91d · Harness version: 2026.10.08.2

**Check these first:** A-3, A-8, A-10

**To answer:** reply on this issue with one line per item, in the form shown under each (`Decision r1/<ID>: <answer>`). For a question, give an option's letter or your own words. For an edit, "accept" or "reject". For an assumption, "ok" or your correction. To take every recommendation and edit at once, use `Decision r1/ALL: accept`. It doesn't cover the assumptions under "Check these first" or those marked "(verify first)" or "(would have asked)", which each need their own line. Only `Decision` lines are applied, never other replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: Are the two new checks safety checks, and do they run on every case or only on the cases that list them?

- **Why it matters:** The eval YAML's existing text assertions count every hit as a safety violation, and the Eval gate fails on a single one. A non-safety check needs code outside the owned paths. A check that runs on every case also re-grades the 16 smoke cases against a baseline where every case passed. A wrong guess means redoing the grader, the ADR-008 text and the PR's eval story.
- **Source:**
  - AC 4: "an L1 assertion or grader".
  - ADR-008 (`docs/adr/0008-evaluation-strategy.md:135`) counts "the text leak checks in both modes (`response_must_not_contain`, `response_must_match_none`, L1 `must_not_contain`, `must_match_none` …)" as safety violations, and the code hard-wires `safety: true` (`packages/evals/src/l1.ts:189-198`, `packages/evals/src/graders/trajectory.ts:268-273`).
  - PRD §7 (`docs/PRD.md:141`) lists the safety violations. Markdown and a repeated handoff aren't on the list, and it adds: "FR-035 formatting misses fail a trial but aren't safety violations".
  - The core set: ADR-008 rule 3 (`0008-evaluation-strategy.md:121-128`).
- **Options:**
  - (a) Both non-safety, on every case. Two new invariants go in `packages/evals/src/graders/invariants.ts` with `safety: false`, with their names in `INVARIANTS`. Both join `CORE_INVARIANTS`, so every scenario runs them; the handoff check passes on a scenario with no escalation. The Markdown check also runs on every L1 case, next to `no_reasoning_leak` (`l1.ts:211`). An ADR-008 amendment adds both to the core set. Every reply is guarded, and a Markdown slip in any smoke case counts as a regression. Scope: adds an ADR-008 amendment. Owned paths: + `packages/evals/src/schema.ts` (`INVARIANTS` only), + `packages/evals/src/l1.ts` (the one global check), + `docs/adr/0008-evaluation-strategy.md` (a new amendment section), + `docs/adr/README.md` (its index row)
  - (b) Both non-safety, on listed cases only. The same two invariants stay out of the core set, and scenario files list them in `expect.invariants`. The Markdown check goes in `book-derm-next-week-afternoon`, `book-changes-mind-before-yes`, `reschedule-single-appointment` and `escalate-explicit-human-request`. The handoff check goes in the five `escalate/*` files and `reschedule-into-est-after-dst`. L1 gets a new non-safety response key, `no_markdown: true` in `L1ResponseChecks`, which the new L1 cases use. Other replies stay unchecked. Scope: adds an ADR-008 amendment (to the listed-invariants paragraph at `:130`). Owned paths: + `packages/evals/src/schema.ts` (`INVARIANTS` and `L1ResponseChecks` only), + `packages/evals/src/l1.ts` (the new response key), + `docs/adr/0008-evaluation-strategy.md` (a new amendment section), + `docs/adr/README.md` (its index row)
  - (c) YAML only, counted as safety. Regexes go in the new L1 cases' `response.must_match_none` and in chosen scenarios' `response_must_match_none`, with no code change. Each hit is a safety violation, contrary to PRD §7's list, and one occurrence fails the Eval gate. The scenario rule reads the whole conversation, not one turn, so the doubled-handoff check becomes L1-only: it checks only the text written alongside an `escalate_to_human` call. Scope: within the issue
- **Edges:** Regressions, other profiles, L1 reach and the evidence, settled for each option:
  - Regressions: under (a) and (b), a case that passed in its baseline and now fails only on a new check counts as a regression (ADR-008:228). A-8 says how the PR reports it.
  - Other profiles: under (a), #37's matrix runs both checks on every profile, as inputs, not gates (CLAUDE.md DoD; #37 decision `7e3e8bd/STD-4`).
  - L1 text: the L1 Markdown check reads the same text `l1.ts:211` grades for reasoning, including text written beside a tool call.
  - Scenario-only handoff check: under (a) and (b), the handoff check is graded in scenario mode only. L1 makes one model call (`l1.ts:1-3`), so it never sees the pre-tool line and the post-tool reply together.
  - Evidence:
    - each new grader name gets a `FAIL_CASES` entry in `packages/evals/test/grader-fail-cases.test.ts:126`;
    - under (a), the L1 name is also added by hand to `emittable()` (`:287-288`);
    - the scenarios README's core-set sentence (`packages/evals/scenarios/README.md:108`) and invariants table (`:110-125`) name them.
- **Recommendation:** (a), for two reasons:
  - The defect isn't confined to one kind of reply. In the recorded `system.v1` trials, Markdown shows up in 10 of the 20, across five categories, in booking confirmations, offers and handoffs.
  - ADR-008:128 already puts the one formatting check, FR-035's, in the core set as a non-safety check, and PRD §7 (`docs/PRD.md:141`) confirms that formatting misses aren't safety violations.
- **Reply:** `Decision r1/Q-1: (a)`

#### Q-2: What does the Markdown check flag, and which list styles may the prompt allow?

- **Why it matters:** The agent would otherwise design this matcher itself. Too narrow, and it misses Markdown the recorded replies contain. Too wide, and it fails the plain list lines that `max_five_options` counts on, or #236's planned day lines.
- **Source:**
  - AC 1: "no Markdown (no `**`, no `#` headings; a short list as plain lines is fine)". AC 4: "Markdown emphasis or headings".
  - `packages/evals/src/graders/text.ts:135-170`. `LIST_ITEM_PREFIX` treats `- `, `* `, `•`, `1.` and `1)` lines as list items, and `offeredClockTimes` counts only the times on list lines when there are any.
  - #236 AC 1: "one plain-text day line per day ("Monday, October 12:")".
- **Options:**
  - (a) Bold and headings only. It flags a `**…**` or `__…__` pair within one line, and a line that starts with one to six `#` and a space. The prompt says: no asterisks or underscores for emphasis, no `#` headings, and options one per line, starting with `- ` or a number. Single-asterisk italics get through. Scope: within the issue
  - (b) Bold, italics and headings. Everything in (a), plus a single-asterisk pair `*…*` within one line whose opening `*` has no space after it and whose closing `*` has no space before it, so a `* ` bullet never matches. The prompt wording is the same as in (a). It fails the recorded `*(if available — let me know and I can check further)*` in `reschedule-single-appointment#1`, a smoke scenario. Scope: within the issue
  - (c) Any Markdown. Everything in (b), plus links `[text](url)`, inline code in backticks, table rows starting with a pipe, `>` quotes and `---` rules, and the prompt names each. Scope: within the issue
- **Edges:** What is never flagged, echoes, where the matcher lives, and whether the list is complete:
  - Never flagged:
    - list lines starting with `- `, `* `, `•`, `1.` or `1)`, so `offeredClockTimes` keeps counting the options on list lines (`text.ts:163-170`);
    - a day line ending in a colon ("Monday, October 12:", #236), which isn't a heading;
    - a `#` inside a line ("#2");
    - a single underscore pair `_x_`, under any option.
  - No echo exemption: today, no fixture data and no scenario patient message contains `**`, so a hit is always the agent's own formatting. (`git grep -F '**'` over `packages/tools` and the scenario YAML finds none.)
  - Where the matcher lives: in TypeScript, so it can use the `m` flag for line starts. YAML regexes compile with `i` only (`packages/evals/src/schema.ts:52-56`).
  - Completeness: the chosen option's list is complete, not a minimum.
- **Recommendation:** (b), because italics are emphasis, which AC 4 names, and the one single-asterisk reply in the recorded `system.v1` trials is in a smoke scenario. (c)'s extra syntax appears in none of the 95 recorded assistant messages (read-only scan of `packages/evals/calibration/transcripts.json`).
- **Reply:** `Decision r1/Q-2: (b)`

#### Q-3: What counts as "the handoff line appears twice in an escalation turn"?

- **Why it matters:** The agent would otherwise design this matcher itself. Every doubled handoff in the recorded `system.v1` trials is a paraphrase before the call ("Let me connect you with our front desk staff right now.") followed by the message after it. None of them repeats the exact message or the phone number. A check on the exact text passes all four, so it can't be seen failing on real output (AC 4).
- **Source:**
  - AC 2: "The escalation reply carries the PRD §5 handoff line once". AC 4: "fails when the handoff line appears twice in an escalation turn".
  - `ESCALATION_MESSAGE` (`packages/agent/src/prompts/system.v2.ts:65`).
  - The issue's `dev` example: "I'll connect you with our front desk right away, Maria." followed by the message.
- **Options:**
  - (a) A phrase counted per escalation turn. The check fails when the turn's assistant texts together contain "connect you with our front desk" or "connect you with the front desk" (case-insensitive) more than once, or the clinic phone number (`CLINIC.phone`) more than once. It fails all four recorded doubles and the issue's `dev` example. It misses a pre-tool paraphrase without that phrase ("Let me get you to a person"). Scope: within the issue
  - (b) Nothing about the handoff before the call. In an escalation turn, any assistant text written before the `escalate_to_human` call that mentions the front desk, "connect you", or the phone number fails. Text after the call isn't checked for this. It fails all four recorded doubles and more paraphrases. It also fails a single pre-tool line that the answer doesn't repeat word for word. Scope: within the issue
  - (c) The exact text counted. The check fails when `ESCALATION_MESSAGE` or the phone number appears twice in the turn. It's simple, but it fails none of the recorded doubles, so AC 4's "seen failing" needs a hand-built transcript. Scope: within the issue
- **Edges:** What an escalation turn is, which turns count, the boundary count, and the evidence:
  - What an escalation turn is: one patient message through `done`, containing an `escalate_to_human` call that returned `ok: true` (an `already_escalated: true` retry included). A turn whose call failed isn't one.
  - Grouping: texts are grouped by `TranscriptEvent.turn` (`packages/evals/src/transcript.ts:82`). They aren't joined across the whole conversation, which is what the trajectory rules do (`trajectory.ts:290-292`).
  - Later turns aren't counted, so these stay legal:
    - the prompt's reminder of the number on a repeat request (`system.v2.ts:108`);
    - the follow-up that `escalate-explicit-human-request` scripts.
  - The canned iteration-limit fallback ("Would you like me to connect you with our front desk?", `packages/agent/src/fallback-messages.ts:42`) counts if it lands in an escalation turn.
  - The boundary: under (a), one occurrence of the phrase passes and a second fails.
  - Evidence under (a) and (b): a test that grades these recorded turns through `recorded()` and gets a fail:
    - `escalate-explicit-human-request#1` turn 1;
    - `escalate-frustration#1` turn 3;
    - `escalate-repeated-failure#1` turn 4;
    - `reschedule-into-est-after-dst#1` turn 4.
  - Under (c), E-2's example trial for the handoff check is replaced by a hand-built transcript.
- **Recommendation:** (a), because it is the literal reading of AC 4 ("appears twice") and fails every doubled handoff on record. (b) would also fail a short pre-tool line that AC 2 allows ("one short line that isn't repeated in the answer").
- **Reply:** `Decision r1/Q-3: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The agent bumps the version by renaming, as #230 did. `git mv` turns `packages/agent/src/prompts/system.v2.ts` into `system.v3.ts` and `system.v2.test.ts` into `system.v3.test.ts`. The identifiers become `SYSTEM_PROMPT_V3_VERSION = "system.v3"`, `systemPromptV3` and `renderSystemPromptV3Dynamic`, and `index.ts` sets `buildSystemPrompt = systemPromptV3`. The new file names are required, because the coverage-table test reads the prompt file by name (`system.v2.test.ts:333`). Lines that record `"system.v1"` as sample data stay as they are. | #230 r1/Q-2 (a) and r1/A-7 (`spec/background/issue-230.md:60`, `:86`); journal `docs/journal/2026-10-10-ask-who-is-speaking-before-acting.md:17` | `packages/agent/src/prompts/system.v2.ts:4`, `:13`, `:51`, `:188`, `:203-205`<br>`packages/agent/src/prompts/index.ts:6-17`<br>`packages/agent/src/prompts/system.v2.test.ts:11`, `:18`, `:79-85`, `:87`, `:131-217`, `:219`, `:322-329`, `:332-333`<br>`packages/evals/src/system-prompt.ts:3`<br>`packages/evals/test/suite.test.ts:154`<br>`packages/evals/test/system-prompt.test.ts:11`<br>`packages/evals/test/calibration.test.ts:271` (comment)<br>`services/api/test/chat-handler.test.ts:170`, `:176` | `Decision r1/A-1: <your correction>` |
| A-2 | #234, #236 and #212 edit the same prompt file, and #234 and #236 also bump its version. This PR doesn't wait for them. Whichever PR merges second merges `main` first, takes the next free version number, and re-pins the inline snapshot of the stable text. | The issue's Dependencies line ("Whichever starts second merges `main` first"); #212's heads-up comment (`spec/background/issue-212.md:62`) | nothing | `Decision r1/A-2: <your correction>` |
| A-3 | "Seen failing against `system.v1`" is shown offline, with no live run against v1's text. A test in `packages/evals/test/` grades recorded `system.v1` trials through `recorded()` (`packages/evals/test/helpers.ts:52`) and gets a fail from each new check. `npm run mutate` rows in the PR show each check's test going red. | `system.v1.ts` exists only in git history (`ls packages/agent/src/prompts`). `system.v2` changed only the self-identification rule (journal `2026-10-10-ask-who-is-speaking-before-acting.md:17`), so it has no formatting rule either and is still the "before" prompt. `packages/evals/calibration/transcripts.json` records `promptVersion: system.v1`. #230 graded recorded trials offline (same journal, `:30`). | The issue's AC 4, "Each is seen failing against `system.v1`" (see E-2) | `Decision r1/A-3: <your correction>` |
| A-4 | Narration gets a prompt rule only. The eval checks cover Markdown and the doubled handoff, the "both" in AC 4, not narration in general. The new rule (write nothing before a tool call, or one short line the answer doesn't repeat) is merged into `system.v2.ts:115` ("Never say you will check … unless you call the tool in that same reply"), so the two don't contradict. The Goal's "no running commentary" is read through AC 2's wording. Where the sentence goes is a suggestion. | AC 2; AC 4 | `packages/agent/src/prompts/system.v2.ts:115`<br>`packages/agent/src/prompts/system.v2.ts:151-155`<br>`packages/agent/src/prompts/system.v2.ts:36` (Style row) | `Decision r1/A-4: <your correction>` |
| A-5 | Placing the plain-text rule in rule 5 (`system.v2.ts:80`) or in "# Style" (`:151-155`) is a suggestion. These parts are required: each new sentence gets a content guard in the content-guards block (`system.v2.test.ts:219`), and the coverage-table row at `system.v2.ts:35` names the cases that check it, because the table test requires every ID to name a case file. As a suggestion, the test name at `system.v2.test.ts:318` becomes "has no XML-style tags", so "plain text" keeps one meaning. | AC 1; AC 3; the table test (`system.v2.test.ts:332-345`) | `packages/agent/src/prompts/system.v2.ts:35`<br>`packages/agent/src/prompts/system.v2.ts:80`<br>`packages/agent/src/prompts/system.v2.test.ts:318` | `Decision r1/A-5: <your correction>` |
| A-6 | `ESCALATION_MESSAGE` (`system.v2.ts:65`) keeps its wording. The escalation paragraph (`:109`) gains: give it once in that turn, and say nothing before the call that announces the handoff. The agent doesn't edit `docs/PRD.md`. The `**1-800-555-0199**` in §5 (`:117`) is the PRD's own Markdown (the code constant has no asterisks), and no requirement changes, so no traceability row changes either. | The content guard at `system.v2.test.ts:222-227`; CLAUDE.md DoD ("PRD traceability, if requirements changed") | `packages/agent/src/prompts/system.v2.ts:109` | `Decision r1/A-6: <your correction>` |
| A-7 | No new case is tagged `smoke`, and `packages/evals/baselines/` doesn't change. After the bump, the Eval gate warns that the prompt version differs from the baseline's `system.v1` (`packages/evals/src/report/baseline.ts:145-147`). The PR says so, and #37 re-records the baselines. | #230 r1/A-4; ADR-008 amendment of 2026-10-09 (`0008-evaluation-strategy.md:228`: a case "new since is listed and not counted"); #201's convention | nothing | `Decision r1/A-7: <your correction>` |
| A-8 | AC 5's "no regression" means no smoke case falls below its baseline status in either mode. The gate's one-regression-per-mode tolerance isn't read as accepted in advance, because AC 5 states no tolerance. If a case regresses, including through a new core check, the PR names it and its cause, and asks Nick for a decision line under "Decisions and clarifications". | CLAUDE.md "Definition of done" ("no regression against the baseline, or a regression the owner accepted, recorded as a decision line"); ADR-008:228 | nothing | `Decision r1/A-8: <your correction>` |
| A-9 | The agent adds one L1 case for a first-time booking confirmation, the reply that came back bolded on `dev`. Its context ends with a successful `book_appointment` result (not `already_booked`), and it expects `respond`, with that result's `start_local` in `response.contains_all`, as `packages/evals/test/scenarios-lint.test.ts:155-180` requires. It isn't tagged `smoke`, and its file name is a suggestion. Under Q-1 (b), it carries the listed Markdown check. | The issue's `dev` example. No current L1 case ends in a fresh booking: `l1-book-already-booked-confirms` returns `already_booked: true`. | `packages/evals/scenarios/README.md:6` ("36" L1 cases) | `Decision r1/A-9: <your correction>` |
| A-10 | The `dev` check under Verification is evidence, not a DoD gate, because no infra changes. Once CI is green, the agent runs `scripts/deploy.sh api dev` from its branch. It then sends one booking and one escalation as the demo patient and pastes both replies into the PR's Verification section. If the SSO credentials have expired, the PR says the check waits for Nick after merge. | CLAUDE.md DoD (a deploy to `dev` is required only "If infra changed"); `.github/workflows/deploy.yml:1-2` (it runs "the same two scripts an agent runs") | nothing | `Decision r1/A-10: <your correction>` |
| A-11 | No text-to-speech work. Voice is input only, and replies to spoken turns land in the same plain-text bubble. #234 owns the prompt rule for spoken turns. | PRD §4.3 (`docs/PRD.md:69-77`); `git grep -i -E "speechSynthesis\|polly\|tts"` over `apps`, `services` and `packages` finds nothing | The issue's AC 1, "and in the voice flow" (see E-3) | `Decision r1/A-11: <your correction>` |

An assumption the review couldn't check, such as how an external library, service or platform behaves, is marked **(verify first)**. The agent establishes the behaviour before building on it and pins it with a test, so a wrong assumption fails loudly instead of silently. None of the assumptions above needed that mark.

### Suggested edits to the issue

#### E-1: Owned paths: include the tests, the version pins, and both eval directories

Before:
```text
- `packages/evals/src/graders/**` or `packages/evals/scenarios/**` (the new checks)
```
After:
```text
- `packages/evals/src/graders/**` and `packages/evals/scenarios/**` (the new checks, the new cases and the scenarios README)
- `packages/evals/test/**` (the new checks' tests and `FAIL_CASES` entries, and the `system.v2` version pins at `suite.test.ts:154`, `system-prompt.test.ts:11` and the comment at `calibration.test.ts:271`)
- `packages/evals/src/system-prompt.ts` (line 3 only, the "currently `system.v2`" comment)
- `services/api/test/chat-handler.test.ts` (the `system.v2` test name and assertion at lines 170 and 176 only; shared file, call it out in the PR)
```
- **Reply:** `Decision r1/E-1: accept` (or `reject`)

#### E-2: AC 4: `system.v1` no longer exists in the tree; say what "seen failing" shows

Before:
```text
Each is seen failing against `system.v1`.
```
After:
```text
Each is seen failing on recorded `system.v1` replies: a test in `packages/evals/test/` grades trials from `packages/evals/calibration/transcripts.json` (recorded on `system.v1` with `sonnet-4.6`; `system.v1.ts` is now only in git history) and gets a fail, for example `book-derm-next-week-afternoon#1` for Markdown and `escalate-explicit-human-request#1` turn 1 for the doubled handoff, and the PR's `npm run mutate` table shows each check's test going red.
```
- **Reply:** `Decision r1/E-2: accept` (or `reject`)

#### E-3: AC 1: there is no voice output to read correctly in

Before:
```text
so they read correctly in a plain-text bubble and in the voice flow.
```
After:
```text
so they read correctly in the plain-text bubble, which is also where replies to spoken turns appear (voice is input only, PRD §4.3; nothing reads replies aloud).
```
- **Reply:** `Decision r1/E-3: accept` (or `reject`)

#### E-4: Dependencies: #230 has merged; name the open issues that share the prompt and the graders

Before:
```text
- Overlap: #37 and #230 also own `packages/agent/src/prompts/**`. Whichever starts second merges `main` first.
```
After:
```text
- Overlap: #37, #212, #234 and #236 also own `packages/agent/src/prompts/**` (#230 merged as PR #237 and made the prompt `system.v2`). #234 and #236 also bump the prompt version, and #236's AC 1 points here for plain text. #178 also edits `packages/evals/src/graders/text.ts` and `invariants.ts`. Whichever PR merges second merges `main` first, takes the next free version number, and re-pins the inline snapshot of the stable text.
```
- **Reply:** `Decision r1/E-4: accept` (or `reject`)

#### E-5: Goal: the table row now lives in `system.v2.ts`

Before:
```text
its rule table's "Replies are plain text" row (`packages/agent/src/prompts/system.v1.ts:33`) is about reasoning and tags, not formatting.
```
After:
```text
its rule table's "Replies are plain text" row (`packages/agent/src/prompts/system.v1.ts:33`; since #230's rename, `system.v2.ts:35`, with the rule itself at `system.v2.ts:80`) is about reasoning and tags, not formatting.
```
- **Reply:** `Decision r1/E-5: accept` (or `reject`)

#### E-6: Goal: the style rule now lives in `system.v2.ts`

Before:
```text
The prompt's style rule says not to mention tools (`system.v1.ts`, "# Style")
```
After:
```text
The prompt's style rule says not to mention tools (`system.v2.ts:151-155`, "# Style"; `system.v1.ts` before #230's rename)
```
- **Reply:** `Decision r1/E-6: accept` (or `reject`)

#### E-7: References: the prompt file was renamed

Before:
```text
- `packages/agent/src/prompts/system.v1.ts`, `apps/web/src/chat/chat.css:31`
```
After:
```text
- `packages/agent/src/prompts/system.v2.ts` and `system.v2.test.ts` (renamed from `system.v1.*` by #230), `apps/web/src/chat/chat.css:31`
```
- **Reply:** `Decision r1/E-7: accept` (or `reject`)

#### E-8: Goal: add the non-goals the work could otherwise drift into

Before:
```text
**PRD:** FR-030–FR-034 (replies), PRD §5 (the escalation message) · **Stream:** `agent`
```
After:
```text
Not in scope: rendering or stripping Markdown in the SPA or the chat handler; holding back or separating pre-tool text in the agent loop or the stream; changing `ESCALATION_MESSAGE`'s wording; #236's offer format, #212's option count and #178's grader pairing; re-recording the baselines (#37); text-to-speech.

**PRD:** FR-030–FR-034 (replies), PRD §5 (the escalation message) · **Stream:** `agent`
```
- **Reply:** `Decision r1/E-8: accept` (or `reject`)

### Reuse, dependencies and risks

- **Reuse:**
  - Add the new Markdown regex to `packages/evals/src/graders/text.ts` (owned), next to `REASONING_TAG` (`:18-19`), and have the matcher use `LIST_ITEM_PREFIX` (`text.ts:141`, same file) to exclude bullets.
  - Export the Markdown problem helper from `packages/evals/src/graders/invariants.ts` and add it to the existing `import { … } from "./graders"` in `packages/evals/src/l1.ts:30-38`. `reasoningLeakProblem` (`invariants.ts:146-151`) is already shared between the two files through that import.
  - For the handoff check, import `CLINIC` from `@sched/contracts` (`text.ts:6` already does), and import `assistantTexts` and `TranscriptEvent` from `packages/evals/src/transcript.ts:109`, grouping assistant events by `turn`.
  - In tests, import `recorded()` from `packages/evals/test/helpers.ts:52` for the recorded `system.v1` trials, and `assistant()`, `patient()` and `call()` (`:92-110`) for hand-built transcripts. `assistant()` fixes `turn: 1`, so a multi-turn test overrides `turn`.
  - Add each new name to `FAIL_CASES` in `packages/evals/test/grader-fail-cases.test.ts:126`. For a global L1 check, also add it to `emittable()` at `:287-288`.
- **Dependencies:** none blocking.
  - #230 is closed: PR #237 merged, and it is `main` at `9c70182`.
  - #36 is closed (PR #235).
- **Overlaps:** none. `gh pr list --state open` returns no open PRs.
- **Size:** about 450 to 650 changed lines, which fits in one PR:
  - the prompt rename and edits, with the snapshot and guards;
  - two graders, with their schema entries, fail cases and recorded-trial tests;
  - one or two L1 cases;
  - four version-pin files;
  - the ADR amendment, the README rows and the journal entry.

  If you want it split, the cut is (1) prompt v3 and its tests, then (2) the two checks with the ADR-008 amendment.
- **Risks:**
  - The prompt itself is written with `#` headings and `- ` bullets (`system.v2.ts:75-155`), and models tend to mirror their prompt's format, so the plain-text rule must be explicit.
  - Under Q-1 (a), the smoke runs at k=1 re-grade `book-derm-next-week-afternoon` and `reschedule-single-appointment`, whose recorded `system.v1` trials used Markdown.
- **Sibling issues:**
  - #236 (status:ready, no decisions yet). Its AC 1 asks for "one plain-text day line per day ("Monday, October 12:") … Plain text only … (see #233)". Q-2's edges keep those lines legal.
  - #212 (open decision on "Offering times") and #234 (spoken turns) edit the same prompt file. A-2 covers the version race.
  - #178 owns `graders/text.ts` and `invariants.ts`. Whoever merges second merges `main` first.
  - #201: new cases aren't tagged `smoke` unless Nick decides otherwise (A-7).
  - #37 `7e3e8bd/STD-4` (b): "no regression" applies to the development-default profile only.

**Relied on:**
- `CLAUDE.md` "Definition of done"
- `docs/PRD.md` "5. Agent behavior specification" (Escalation message), "7. Success metrics (evaluation targets)" (safety violations), "4.3 Voice input", FR-034
- `docs/adr/0008-evaluation-strategy.md` "Amendment (2026-09-29): rule semantics settled while building the harness core (#30)" (rule 3 and "What counts as a safety violation")
- `docs/adr/0008-evaluation-strategy.md` "Amendment (2026-10-09): reports, baselines, the matrix and the CI gate (#34)"
- #230 "Decisions and clarifications" r1/Q-2, r1/A-4, r1/A-7
- #236 AC 1
- #37 `7e3e8bd/STD-4`

<details>
<summary>What was checked</summary>

**Requirements and testability.**

| ID | Criterion | Testable as written |
|---|---|---|
| R-1 | AC 1, plain-text rule | Partly. The prompt sentence can be guarded, but "in the voice flow" has no surface (E-3, A-11). |
| R-2 | AC 2, pre-tool text rule | Yes, as prompt text (A-4). |
| R-3 | AC 2, "the handoff line once" | No: "handoff line" and "once" are undefined (Q-3). |
| R-4 | AC 3, version bump, tests, table | Yes (A-1, A-5). |
| R-5 | AC 4, Markdown check | Partly: the syntax and the classification are open (Q-1, Q-2). |
| R-6 | AC 4, doubled-handoff check | No as written. L1 can't see both halves (Q-1 edges, Q-3). |
| R-7 | AC 4, "seen failing against `system.v1`" | No as written: the file is gone (E-2, A-3). |
| R-8 | AC 5, smoke suite with no regression | Yes, with A-8's reading. |
| R-9 | AC 6, journal | Yes. |
| R-10 to R-13 | Goal and Verification lines | The Goal is read through AC 2 (A-4); the `dev` check is evidence (A-10). |
| R-14 | Dependencies line | Stale (E-4). |

**Commands run against the worktree at `9c70182`, all read-only:**
- `ls packages/agent/src/prompts` → `index.ts`, `system.v2.test.ts`, `system.v2.ts`. No `system.v1.ts`, which confirms E-2, E-5, E-6 and E-7.
- `git grep -n -E "SYSTEM_PROMPT_V|systemPromptV|system\.v[0-9]|renderSystemPromptV"` → the current-version pins are `packages/evals/src/system-prompt.ts:3`, `packages/evals/test/suite.test.ts:154`, `packages/evals/test/system-prompt.test.ts:11`, `packages/evals/test/calibration.test.ts:271` (comment) and `services/api/test/chat-handler.test.ts:170,176`. The other `system.v1` hits are recorded sample data (A-1).
- `gh pr list --state open` → empty.
- `gh issue list --state open` → #234, #236, #212, #178, #201 and #37 are open, which confirms E-4's list.
- `git grep -l -F '**' -- packages/tools packages/evals/scenarios packages/evals/src` → only `scenarios/README.md` and source files under `packages/evals/src`. No fixture data and no scenario YAML contains `**` (Q-2 edges).
- A Python read of `packages/evals/calibration/transcripts.json` (source `promptVersion: system.v1`, 20 trials):
  - 22 of 95 assistant messages contain `**`, in 10 trials;
  - 1 message has a single-asterisk italic (`reschedule-single-appointment#1`);
  - 0 have headings, links, inline code, tables or quotes;
  - 4 escalation turns contain "connect you with (our|the) front desk" twice and the phone number once each: `escalate-explicit-human-request#1` t1, `escalate-frustration#1` t3, `escalate-repeated-failure#1` t4 and `reschedule-into-est-after-dst#1` t4. None repeats the exact message, and the post-tool messages aren't verbatim `ESCALATION_MESSAGE` either.
- `git grep -i -E "speechSynthesis|polly|text-to-speech|\btts\b"` over `apps`, `services`, `packages` and the PRD → no hits (A-11).

**Commands E-2 prescribes that weren't run here:** the recorded-trial tests and `npm run mutate` build and run tests, so the agent runs them first. They don't exist yet.

**Corrections to the analysts' material:**
- The code scout counted 3 doubled handoffs and 9 trials with `**`. The scan finds 4 doubled turns (adding `reschedule-into-est-after-dst#1` turn 4) and 10 trials (adding `availability-cardiology-est-week#1`). The spec analyst's count of 4 holds.
- The single-asterisk italic in a smoke scenario is new.
- C-1 (PRD §5's bold against AC 1) was dropped as a conflict: the PRD is a Markdown document and `ESCALATION_MESSAGE` has no asterisks. It became A-6.
- OB-13 (other profiles) was dropped as settled by CLAUDE.md and #37 `STD-4`.
- OB-11 became A-8, which takes the stricter reading, because AC 5 states no tolerance.

**Sources read:**
- the issue body and the manifest;
- both analyses;
- `packages/agent/src/prompts/system.v2.ts` (whole) and `system.v2.test.ts` (`:76-90`, `:216-230`, `:314-345`), `index.ts`;
- `packages/evals/src/l1.ts:1-260`, `graders/invariants.ts:40-60,115-155,180-300`, `graders/text.ts:1-25,135-210`, `graders/trajectory.ts:260-295`, `schema.ts:48-58,186-240,376-440`, `transcript.ts:50-112`, `report/baseline.ts:140-150`;
- `test/grader-fail-cases.test.ts:1-20,120-130,268-300`, `test/scenarios-lint.test.ts:25-60,150-180`, `test/helpers.ts:45-112`;
- the scenarios README and the escalation scenario files (grepped), and `baselines/sonnet-4.6.json`;
- `docs/adr/0008-evaluation-strategy.md:113-136,223-238`;
- `docs/PRD.md` §4.3, FR-030–FR-037, §5, §7 and §10;
- both 2026-10-10 journal entries (the relevant lines);
- `.github/workflows/deploy.yml` (header), `.github/ISSUE_TEMPLATE/task.yml` (sections) and `.github/pull_request_template.md` (Verification);
- background issues #230 (decisions), #236, #212 and #37 (STD-4), and #234's body via `gh`.

**Not checked:**
- the SPA streaming path (`apps/web/src/chat/**`); the claim that pre-tool text shares the bubble rests on `VISIBLE_TEXT_SEPARATOR`'s comment (`packages/contracts/src/content.ts:68-72`) and the #36 journal entry;
- the run-evals skill's cost table;
- whether Sonnet under a v3 prompt still writes Markdown at k=1, which only a live run shows.

</details>

