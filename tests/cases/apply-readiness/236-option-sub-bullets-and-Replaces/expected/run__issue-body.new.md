## Goal
Give the agent one friendly, consistent way to present appointment options: grouped by day, spread sensibly over a broad request, and patient when asked again. Found by Nick on `dev` on 2026-10-10, during #36's run-through, with the real `system.v1` prompt.

What he saw, asking Dr. Lee's availability "next week" and then "Are there any times on Tuesday?":
- **Inconsistent format.** The first reply listed five options, each repeating the full date ("1. Monday, October 12 at 8:00 AM ET", "2. Monday, October 12 at 8:30 AM ET", …). The second reply used a day heading ("Dr. Lee has these openings on Tuesday, October 13:") and listed only the times.
- **Bunched first offer.** For "next week", all five options were the earliest ones, Monday 8:00 to 10:30 AM, and the reply only said that "there are more times available later in the week".
- **Tone on a repeat.** Asked the same question again, the agent opened with "I just showed those above!" before repeating the times.

The cause of the first: `system.v1.ts:121` says "Always give times in Eastern Time with the weekday and date … Quote start_local from tool results as written", and each `start_local` is the full "Monday, October 12, 2026 at 8:00 AM ET" (`packages/contracts/src/tools.ts:33`). Nothing says how to present several times on one day, so the model sometimes repeats the full string and sometimes groups.

**PRD:** FR-030 (availability: at most 5 options, with provider and weekday), FR-035 (clinic timezone with a weekday) · **ADRs:** ADR-008 (graders), ADR-009 · **Stream:** `agent`

## Acceptance criteria
- [ ] The system prompt gives one offer format: options are grouped by day, with one plain-text day line per day ("Monday, October 12:") followed by that day's times in ET. The weekday and date in the day line come from the tool's `start_local`, never computed by the model, keeping the reason for the quote-verbatim rule (models get weekdays wrong). Plain text only, so it reads correctly in the chat bubble (see #233).
- [ ] For a broad request (a week, "next week", "any time"), the agent spreads its options across days, or asks one narrowing question (morning or afternoon, or a preferred day) before listing, instead of offering only the earliest times. The exact rule is settled in this issue's readiness review, and stays within the five-option limit (FR-030; the criteria from #212 below set how options across days are counted).
- [ ] When the patient asks for something already shown, the agent answers again plainly, without remarks such as "I just showed those above".
- [ ] The graders accept the grouped format: a time listed under a day line counts as that day's time. #239 (which carries #178) fixes `no_hallucinated_slots` and lands first; this issue fixes `times_in_clinic_tz_with_weekday` and pins `max_five_options`, by the rule r1/Q-2 settles. Grader tests in `packages/evals/test/` show a grouped offer in that format passing all three, and each check failing on: a listed time no tool returned (`no_hallucinated_slots`); six listed times across two day lines (`max_five_options`, "6 times in one message"); a listed time without the zone the format requires, and gate run 4's heading "Tuesday, October 13 (earlier than your 2:30 PM visit):", which #239 hands to this issue (`times_in_clinic_tz_with_weekday`).
- [ ] Eval cases: a single-day offer and a multi-day offer in the grouped format, a broad "next week" request that gets spread or a narrowing question, and a repeated question. The eval smoke suite ran on the development-default profile with no regression against the baseline (the Eval gate). Results in the PR.
- [ ] The prompt version changes to `system.v4` (or the next free version if another prompt PR merges first; #230 and #233 took v2 and v3), with the prompt's tests and its rules → eval cases table updated.
- [ ] Journal entry (dev-journal skill).

## Combined scope (Nick, 2026-10-15)

Nick combined #212 into this issue: both change the system prompt's "Offering times" section, and #212's rule (five options in total across all days) is the option-count half of this issue's grouped format. One readiness review and one PR, which closes #236 and #212. The system prompt is now `system.v3` (`packages/agent/src/prompts/`), not `system.v1` as both issues' text says (#230 bumped it to v2, #233 to v3). #212's owned paths are a subset of this issue's. This PR lands after #239's combined grader PR, which carries #178's date-heading fix.

### From #212: no more than five options in one message when an offer spans two days

The goal and evidence are in #212's description. Its acceptance criteria are part of this issue:

- [ ] Measure first: rerun `book-derm-next-week-afternoon` (and `reschedule-single-appointment`, which lists slots under two day headings too) on `main`, 3 trials each, and count the messages listing more than five options from the transcripts. The PR reports the rate as the before number. Whatever it is, the prompt change goes ahead, because the grouped format (the first acceptance criterion) rewrites the "Offering times" section.
- [ ] Change the prompt so the cap holds for the whole message whatever headings the reply uses: five options in total across all days, not five per day. Either change the "Offering times" wording, or add a guard outside the prompt. Which one is the owner's decision, made on this issue before work starts.
- [ ] A test quotes each new or changed sentence (the "content guards" block in `system.v3.test.ts`, renamed with the version bump), and each is seen failing with `npm run mutate`.
- [ ] Eval evidence per CLAUDE.md: the same reruns on the branch show no message with more than five options, and the smoke suites (L1 and scenario, `sonnet-4.6`, 1 trial) show no regression against `packages/evals/baselines/sonnet-4.6.json` (the Eval gate; CLAUDE.md's definition of done). The spend is approved before the run.
- [ ] `npm run lint && npm run typecheck && npm test` pass.

## Non-goals
- The restatement before a write, the confirmation after it, and the "which appointment" list keep the full `start_local` for each time; only offers of open slots are grouped.
- No change to `check_availability` or its contract (unless r1/Q-1 chooses it), and no re-recording of the baselines for the new prompt version (the Eval gate only warns on it).
- No grader that checks a weekday against its date.

## Owned paths
- `packages/agent/src/prompts/**`
- `packages/evals/src/graders/**` (only the format-related checks; #239's heading reader in `text.ts` is exported and extended, not rewritten, r2/A-1)
- `packages/evals/scenarios/**` (new cases and the README's coverage table), `packages/evals/test/**` (grader and lint tests)
- `packages/evals/baselines/**` (only if a new case joins the smoke set)
- `packages/contracts/src/tools.ts` (only if a tool description's "quote start_local" wording must change; cross-stream, call it out)
- `docs/journal/**`
- `packages/evals/src/system-prompt.ts` (the prompt-version comment only) and `services/api/test/chat-handler.test.ts` (the prompt-version test only), for the version bump; cross-stream, call it out
- `docs/adr/0008-evaluation-strategy.md`
- `docs/adr/README.md`

## Dependencies
- **Combined (Nick, 2026-10-15):** this issue also carries #212 (see "Combined scope"). #230 is closed. Lands after #239's combined grader PR (which includes #178).
- Blocked by: nothing open. #239's grader PR (PR #278, carrying #178, #244 and #245) is on `main` at `190eb32`; its heading reader is `headingListTimes` in `packages/evals/src/graders/text.ts` (r2/A-1). #230 and #233 are closed; they took `system.v2` and `system.v3`.
- Coordinates with: #234, #249 and #250 (and #248 and #251 if they choose a prompt change), which edit the same prompt file; whichever merges later merges `main` first and takes the next free version number (#233 r1/A-2).

## Verification
- `npm run lint && npm run typecheck && npm test`
- The eval smoke suite and the new cases (run-evals skill; dry-run first).

## References
- Nick's `dev` run on 2026-10-10 (#36, PR #235); `packages/agent/src/prompts/system.v1.ts:121`, `:138`; `packages/contracts/src/tools.ts:33`; #178; #212; #233; #230.



## Decisions and clarifications

Settled before work started, in answer to readiness reviews: the owner's answers, and the assumptions the owner let stand. Coding agents and PR reviewers treat these as part of the spec.

- **r1/Q-1** (settled against `c05cb79`): When a patient asks about a whole week or longer ("next week", "any time"), how does the agent spread its five options across days? → (a) Search each day in the same reply. Once the kind of visit or the provider is known, and the request covers more than one weekday with no specific time, the agent makes one `check_availability` call per weekday, all in the same reply, for at most the first five weekdays of the range. It keeps any time of day the patient gave. It then offers up to five options: at most two per day, days in date order, earliest first within a day. A day with fewer slots leaves its share to the following days. Time to first text adds no model call, because the loop runs one reply's calls together (`packages/agent/src/loop.ts:362-376`) and allows 16 calls per turn (`loop.ts:71`). It costs up to five tool results instead of one. The smoke L1 cases `l1-availability-specialty-next-week` and `l1-availability-after-dst` expect one whole-week search. Each case's `end_date` list therefore gains the range's first day, so that the Monday-only search matches. A case passes when any call matches (`packages/evals/src/graders/matchers.ts:44-47`). Scope: within the issue (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199128747))
  - makes stale: by option, one line each:
    - `packages/agent/src/prompts/system.v3.ts:131` ("the earliest first when nothing narrows it down"): all options
    - `packages/agent/src/prompts/system.v3.test.ts:273-278` (the #171 guard quotes that sentence): all options
    - `packages/evals/scenarios/l1/l1-availability-specialty-next-week.yaml:18`: option (a)
    - `packages/evals/scenarios/l1/l1-availability-after-dst.yaml:19`, `:27`: option (a)
    - `packages/agent/src/prompts/system.v3.ts:119`: option (c)
    - `packages/tools/src/tools/check_availability.ts:8-9`, `packages/contracts/src/tools.ts:237`: option (d)
  - edges: each case below is settled by the choice.
  - not chosen: (b) Search the whole range, then widen if it bunches. The agent searches the whole range once. If every slot returned falls on one day and `truncated` is true, it searches again in the same turn, from the next day to the end of the range. It then offers up to five over the days found: at most two per day, days in date order. The first call is unchanged, so no L1 case changes. A result that bunches, which is the usual case for a week, adds one model call before the first text. Scope: within the issue
  - not chosen: (c) Ask first when nothing narrows the request. If the request names neither a day nor a time of day, the agent asks one question first: a preferred day, or morning or afternoon. If it names either, the agent searches the whole range once and offers the earliest five, grouped by day. Nothing is spread, so "next week, afternoons" still gets one day's times. This departs from PRD §5 rule 2, and `system.v3.ts:119` must be reworded. Scope: within the issue
  - not chosen: (d) Spread inside the tool. `check_availability` gains a per-day cap or a spread input, so one call returns slots across days. This is a cross-stream contract change on a gated path, and it re-pins the contract snapshot (`packages/contracts/src/tools.test.ts:68`). Scope: adds a tool and contract change. Owned paths: + `packages/tools/src/tools/check_availability.ts`, + `packages/tools/test/tools/check_availability.test.ts`, + `packages/contracts/src/tools.test.ts` and its snapshot under `packages/contracts/src/__snapshots__/`
- **r1/Q-2** (settled against `c05cb79`): What exactly does a grouped offer look like, and how does the weekday/ET check read a time under a day line? → (a) ET after every time, and the provider on each line only when there are several providers. Scope: within the issue (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199128747))
  - makes stale: by option, one line each:
    - `packages/agent/src/prompts/system.v3.ts:126` (the per-time "weekday and date" example): all options
    - `packages/agent/src/prompts/system.v3.ts:131` ("each with the weekday, date, time in ET, and provider name"): all options
    - `packages/evals/src/graders/text.ts:213-217` (the `mentionHasWeekdayAndZone` doc): all options
    - `packages/evals/scenarios/README.md:117`: all options
    - `docs/adr/0008-evaluation-strategy.md:128`: option (c) only
  - edges: each case below is settled by the choice.
  - not chosen: (b) ET and the provider on every time line. Scope: within the issue
  - not chosen: (c) ET once, on the day line. The day line is "Tuesday, October 13 (ET):" and the times under it are bare ("- 1:00 PM with Dr. Priya Lee"). `times_in_clinic_tz_with_weekday` takes both the weekday and the zone from the day line. That changes what ADR-008 `:128` says, so it needs a dated amendment. Scope: adds an ADR-008 amendment. Owned paths: + `docs/adr/0008-evaluation-strategy.md`, + `docs/adr/README.md`
- **r1/Q-3** (settled against `c05cb79`): Is #212's cap (five options in total across all days) held by the prompt's wording alone, or also by a guard in code? → (a) Prompt only. The "Offering times" rule says at most five options in one message, counted across all day lines, not five per day, and a content guard pins the sentence. Scope: within the issue (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199128747))
  - makes stale: by option, one line each:
    - `packages/agent/src/prompts/system.v3.ts:131`: both options
    - `packages/agent/src/prompts/system.v3.test.ts:273-278`: both options
    - `packages/agent/src/loop.ts:6-20` (header contract): option (b)
  - edges: each case below is settled by the choice.
  - not chosen: (b) Prompt plus a loop guard. The "Offering times" rule says at most five options in one message, counted across all day lines, and a content guard pins the sentence. In addition, the loop counts the options in a final reply; above five, it discards the reply with `text_reset` and retries once with a nudge. The counting rule (`offeredClockTimes`, `packages/evals/src/graders/text.ts:201-208`) moves to a new module that both the agent and the evals import. Each miss costs one extra model call. Scope: adds a loop change. Owned paths: + `packages/agent/src/loop.ts`, + `packages/agent/test/**`, + `packages/contracts/src/offer-count.ts` (new), + `packages/contracts/src/offer-count.test.ts` (new), + `packages/contracts/src/index.ts`
- **r1/Q-4** (settled against `c05cb79`): What kind of eval cases does AC 5 add, do they join the smoke suite, and what does each one check? → (a) Five L1 cases, run in the full suite only and not tagged smoke, so the baseline is unchanged. Scope: within the issue (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199128747))
  - makes stale: by option, one line each:
    - `packages/evals/scenarios/README.md:6` ("37 of them"): options (a) and (b)
    - `packages/evals/scenarios/README.md:154` and `:159` (FR-030 and FR-035 coverage rows): all options
    - `packages/evals/scenarios/README.md:5`, `packages/evals/test/scenarios-lint.test.ts:30`, `:57`: option (c)
    - `packages/evals/baselines/sonnet-4.6.json:15-24`: option (b)
  - edges: each case below is settled by the choice.
  - not chosen: (b) Five L1 cases (single-day offer, multi-day offer, broad request's next action, broad request's reply, repeated question), with the response checks listed under Q-4 (a), and the single-day and multi-day cases tagged smoke. The Eval gate then checks the format on every gated PR, and `packages/evals/baselines/sonnet-4.6.json` gains their ids (owned, "only if a new case joins the smoke set"). Scope: within the issue
  - not chosen: (c) Multi-turn scenarios for the broad-request and repeated-question cases, which see the whole turn and the scenario-only invariants, with L1 cases for the other two. This needs an ADR-008 budget amendment and new lint pins. Scope: adds an ADR-008 amendment. Owned paths: + `docs/adr/0008-evaluation-strategy.md`, + `docs/adr/README.md`
- **r1, assumed** (as of `c05cb79`):
  - A-1: The agent bumps the version by renaming. `git mv` turns `system.v3.ts` into `system.v4.ts` and `system.v3.test.ts` into `system.v4.test.ts`. The new file names are required, because the coverage-table test reads the prompt file by name (`system.v3.test.ts:354`). The identifiers become `SYSTEM_PROMPT_V4_VERSION`, `systemPromptV4` and `renderSystemPromptV4Dynamic`, and `index.ts` points `buildSystemPrompt` at v4. If #234, #249 or #250 merges first, the agent merges `main`, takes the next free number and re-pins the inline snapshot. The baselines keep `"system.v3"` (they record what they ran on, and the gate only warns, `packages/evals/src/report/baseline.ts:143-148`). The sample data in `scripts/trace.test.ts:55`, `:197`, `:236` stays as is. A search for `system\.v3` outside the prompts folder finds only the lines listed here, plus those baselines, that sample data, ADR-002 `:152` (history) and journals. (makes stale: `packages/agent/src/prompts/system.v3.ts:1-6`, `:15`, `:54`, `:191`, `:206-208`; `packages/agent/src/prompts/index.ts:6-17`; `packages/agent/src/prompts/system.v3.test.ts:11`, `:18`, `:84`, `:87`, `:219`, `:345`, `:349`, `:353-354`; `packages/evals/src/system-prompt.ts:3`; `packages/evals/test/system-prompt.test.ts:11`; `packages/evals/test/suite.test.ts:154`; `packages/evals/test/calibration.test.ts:271`; `services/api/test/chat-handler.test.ts:234`, `:240` (outside the owned paths; see E-9)) (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199128747)) — partly superseded by r2/A-2
  - A-2: The agent writes the day line from `start_local`'s weekday and date, without the year: "Monday, October 12, 2026 at 8:00 AM ET" gives "Monday, October 12:". Each time line takes the time and "ET" exactly as `start_local` writes them ("8:00 AM ET"). The prompt's "Dates and times" rule says how a grouped offer splits `start_local`. Unless Q-1 (d) is chosen, `packages/contracts/src/tools.ts` stays as is: its descriptions keep "quote verbatim" (`:33`, `:237`, `:244`, `:258`, `:265`; a search for "verbatim" finds only these), and changing them would re-pin the contract snapshot (`packages/contracts/src/tools.test.ts:68`) on a cross-stream path. (makes stale: `packages/agent/src/prompts/system.v3.ts:126`) (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))
  - A-3: The restatement before a write, the confirmation after it and the "which appointment" list keep the full `start_local` for each time. The agent groups only offers of open slots. (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))
  - A-4: When the patient asks again for something the conversation already answered, the agent answers again from the tool results already in the conversation, in the grouped format. It makes no remark that the question was asked or answered before. It searches again only for what those results don't cover (another day, a later time, another provider). The agent adds a "Style" sentence and a content guard for this. Rejected replies: "I just showed those above!" and "As I mentioned, …". Accepted: "Dr. Lee has these openings:\nTuesday, October 13:\n- 1:00 PM ET". (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))
  - A-5: The agent rewrites the #171 content guard to quote the new "Offering times" sentence and renames its test. It adds one content guard for each other new or changed sentence: the day line, the broad-request rule, the repeat rule and the five-in-total wording. Each one is seen failing with `npm run mutate`. The guard for "mention that time without its date" (`system.v3.test.ts:268-270`) stays, because that sentence doesn't change. (makes stale: `packages/agent/src/prompts/system.v3.test.ts:273-278`) (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))
  - A-6: The agent starts only after #239's PR is on `main`. In `times_in_clinic_tz_with_weekday`, it imports the pairing #239 adds for a time listed under a day line, instead of writing a second parser. If #239 leaves that pairing unexported, the agent exports it from `packages/evals/src/graders/text.ts`, which is owned. If #239 already makes the check read listed times, the agent changes only the weekday window, by the rule in Q-2. (makes stale: `packages/evals/src/graders/text.ts:213-217`) (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803)) — superseded by r2/A-1
  - A-7: For #212's measurement, the agent counts the messages with more than five options in both scenarios' transcripts by `max_five_options`' rule (`offeredClockTimes`). It doesn't add `max_five_options` to `reschedule-single-appointment.yaml`, which is a smoke case whose baseline status would then depend on a new check. Before the 12 scenario trials (3 + 3 on `main`, 3 + 3 on the branch), the agent states the dry-run estimate and waits for Nick's approval. (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))
  - A-8: The agent edits no ADR and no PRD line. Under Q-2 (a) or (b), ADR-008 `:128` stays true. FR-030's row (`docs/PRD.md:83`) already says "at most 5 options … with provider and weekday", and the traceability row is left alone, as #171 and #233 left it. The new cases' `covers:` lists FR-030 and FR-035. (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6199136803))


- **r2/Q-1** (settled against `8e6d8ea`): When this issue makes the weekday/ET check read times listed under a day line, does it add an ADR-008 amendment saying so? → (a) Reuse #239's heading reader and add a dated ADR-008 amendment. The amendment says what `times_in_clinic_tz_with_weekday` now grades and which readers it uses (details below). Scope: adds an ADR-008 amendment. Owned paths: + `docs/adr/0008-evaluation-strategy.md`, + `docs/adr/README.md` (accept all, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6205609051))
  - **What the check grades:** every clock time on a list line under a date heading, with the reach from #239's amendment (first bullet). It takes the weekday from the heading line and looks for ET within 16 characters after the time, on the time's own line. Times on a heading line and in prose keep the `dateTimeMentions` reading.
  - **Which readers:** the heading-list reader serves both checks. Reading later times in a sentence stays with the slot check only.
  - **Edits around it:** an inline "Refined by" note on the `times_in_clinic_tz_with_weekday` line (`:128`), the status line (`:3`) and the README row (`docs/adr/README.md:21`). The `headingListTimes` and `slotMentions` doc comments in `text.ts` are updated to match.
  - **What it replaces:** the "no ADR" half of r1/A-8. Its PRD half stands.
  - makes stale: by option, one line each:
    - `docs/adr/0008-evaluation-strategy.md:255` (the "serves the slot check only" sentence): option (a), refined by the new amendment, not edited in place
    - `docs/adr/0008-evaluation-strategy.md:3`, `:128`: option (a)
    - `docs/adr/README.md:21`: option (a)
    - `packages/evals/src/graders/text.ts:299-305` (`headingListTimes` doc), `:327-332` (`slotMentions` doc, "for `no_hallucinated_slots` only"): option (a)
    - `packages/evals/src/graders/text.ts:360-364` (`mentionHasWeekdayAndZone` doc): both options (already listed under r1/Q-2)
  - edges: each case below is settled by the choice.
    - **Reach, under both options:** #239's rule. The reach runs over blank lines and list lines, and a prose line or a weekday-only line ends it. "Tuesday, October 13:\n- 1:00 PM ET" grades 1:00 PM with Tuesday and passes. In "Tuesday, October 13:\nHere they are:\n- 1:00 PM", the 1:00 PM is no date-time mention and isn't graded, as r1/Q-2's edge says.
    - **Rejected under both:**
      - "October 13:\n- 1:00 PM ET" fails, because the heading has no weekday.
      - "Tuesday, October 13:\n- 1:00 PM" fails, because the time has no ET.
      - Gate run 4's heading still fails on its own 2:30 PM. Its test (`packages/evals/test/no-hallucinated-slots.test.ts:97-103`) stays green.
    - **Prose, under both:** later times in a sentence ("Monday, November 2 at 9:00 AM ET and 11:30 AM") stay outside the weekday check (r1/Q-2 (a): "A time written inside a day line or in prose keeps today's rule").
    - **Evidence:** under (a), the ADR diff and the README row in the PR. Under both, AC 4's grader tests.
  - not chosen: (b) Keep #239's reader for the slot check only, and give the weekday check its own day-line reader in `packages/evals/src/graders/text.ts`, with no ADR edit. Scope: within the issue
- **r2, assumed** (as of `8e6d8ea`):
  - A-1: Replaces r1/A-6. #239 is on `main` (PR #278, merge `190eb32`). The pairing it added is `headingListTimes` (`packages/evals/src/graders/text.ts:306-325`). It is not exported, and its result carries the heading's month and day (`NamedDate`, `:239-244`) but not the heading line or its weekday. The agent exports it from `text.ts` (**required**: confirmed r1/A-6 forbids a second parser) and extends what it returns so `times_in_clinic_tz_with_weekday` can read the weekday on the heading line. Carrying the heading line's start index on each mention is a **suggestion**. The check then grades the `dateTimeMentions` pairs as today, plus the `headingListTimes` mentions, which take the weekday from the heading line and need ET within 16 characters after the time. It doesn't use `pairsAndLaterTimes` (`:278`), so prose keeps today's rule (r1/Q-2 (a)). A list line that names its own month-day is a heading under #239's rule, so it is read as today. (makes stale: `packages/evals/src/graders/text.ts:299-305`, `:327-332`, `:360-364`; `packages/evals/src/graders/invariants.ts:317-324` (the check)) (confirmed, [answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/236#issuecomment-6205609051))
  - A-2: Replaces r1/A-1's last sentence (the search). A search for `system\.v3` outside the prompts folder, journals and baselines now finds two more lines than in round 1. Both stay as they are, and the PR names them. The first is `docs/adr/0008-evaluation-strategy.md:253`, the 2026-10-15 amendment's "(`system.v3.ts`, "# Offering times")". An Accepted ADR changes only by amendment, and that line describes the prompt as it was when #239 merged. The second is `docs/research/security-review.md:241` ("`packages/agent/src/prompts/system.v3.ts:152`"), in a review dated "against `main` at `c05cb79`" (`:12`). The rest of r1/A-1 holds: every line it lists is unchanged at `8e6d8ea`.
  - A-3: The owner accepted `book-derm-next-week-afternoon`'s gate regressions on #239 "for PR #278" only, so they don't carry over to this PR. On this issue's PR the agent applies CLAUDE.md's rule to that case: one regressed case per mode is accepted in advance, and the same case regressing on two or more gate runs needs a decision line. The PR cites PR #278's two over-five runs (38793901154, and 38826769844 with "10 times in one message") beside r1/A-7's before number, as evidence that the over-five reply recurs on `main`. It doesn't count them in the 3 + 3 rate.


## Readiness notes

Pointers from readiness reviews. They are not owner decisions: follow them, or say in the PR why not.

- **r2, reuse** (as of `8e6d8ea`): 
  - **The heading reader:** export `headingListTimes` from `packages/evals/src/graders/text.ts:306-325` and import it in `times_in_clinic_tz_with_weekday` (A-1). Extend `mentionHasWeekdayAndZone` (`text.ts:360-375`) rather than adding a second helper (r1 reuse note; its lines have moved since `c05cb79`).
  - **Line moves:** r1's other reuse pointers now sit at `listItemLines`, `LIST_ITEM_PREFIX` and `offeredClockTimes` `text.ts:192-220`. `markdownIn` is unchanged at `:35-45`. The test helpers are `recorded` `packages/evals/test/helpers.ts:64`, `invariants` `:71`, `byName` `:98` and `assistant` `:130`.
  - **Recorded-trial sweep:** import `failing` (`packages/evals/test/helpers.ts:88-96`, added by #239) to list the recorded trials that fail `times_in_clinic_tz_with_weekday` before and after the change, and `inTurn` (`:133-134`) to build multi-turn events.
  - **Gate run 4:** the heading case AC 4 names is already tested at `packages/evals/test/no-hallucinated-slots.test.ts:97-103`. Keep that test green, and cite it from the new grader tests rather than copying its fixture.

