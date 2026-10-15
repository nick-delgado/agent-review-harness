<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

**Issue:** #37 [M3-02] Full eval matrix + production model decision (finalize ADR-002) · **Read at:** 2026-10-11 22:35 UTC · **Default branch:** `main` @ `160aa3c`

The issue asks the agent to run the 14-cell model matrix live, fix what fails, pick the production profile by the cheapest-qualifying rule, confirm NFR-001 on the deployed stack and the refusal fallback live, and record the outcome in ADR-002. The harness is already built (`npm run evals:matrix`) and every listed blocker has merged. Before starting, the owner needs to settle six things: what moves if the default changes (the CI gate and its IAM role are pinned to Claude), how far the fix loop goes, how the deployed latency and the forced refusal are produced, how a winning effort level is adopted, and whether the choice waits for judge calibration (#159).

Round: 1 · Questions: 6 · Assumptions: 12 · Suggested edits: 8 · Spec commit: 160aa3cbec564d979c509dcfe65deafa8c8404bf · Harness version: 2026.10.11.1

**Check these first:** A-3, A-4, A-1

**To answer:** reply on this issue with one line per item, in the form shown under each
(`Decision r1/<ID>: <answer>`): an option's letter or your own words for a question,
"accept" or "reject" for an edit, "ok" or your correction for an assumption. To take every
recommendation and edit at once, `Decision r1/ALL: accept`; it does not cover the
assumptions under "Check these first" or those marked "(verify first)" or "(would have
asked)", which each need their own line. Only `Decision` lines are applied, never other
replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: If the matrix picks a profile other than `sonnet-4.6`, do the development default, the CI Eval gate and its baseline move with it, or only the deployed production profile?

- **Why it matters:** The issue moves three things together (`DEFAULT_MODEL_PROFILE`, the `AgentModelProfile` default, CLAUDE.md's development-default line). The rest of the setup assumes the development default is what the gate measures, and the gate is pinned to Claude:
  - the gate hard-codes `--profile sonnet-4.6` and `BASELINE: packages/evals/baselines/sonnet-4.6.json` (`.github/workflows/evals.yml:33-35`);
  - its IAM role allows only `sonnet-4.6` and `haiku-4.5` ("If #37 changes the default, this role needs a bootstrap change", `infra/bootstrap/bootstrap.yaml:406-409`), and CLAUDE.md requires asking before touching the bootstrap stack;
  - CLAUDE.md:146 (definition of done) and PRD FR-041 (`docs/PRD.md:98`) say PRs are gated "on the development-default profile".

  If the agent moves only the three listed items, CLAUDE.md:146 becomes false for every later PR. If it moves everything, the PR grows by about ten files outside its owned paths and needs a bootstrap deploy that only Nick may make.
- **Source:** the issue: "If the default changes, these change together: `DEFAULT_MODEL_PROFILE` …, the `AgentModelProfile` default in `infra/stacks/api.yaml`, and `CLAUDE.md`'s development-default line." ADR-002 `:59`: "the eval matrix shows a cheaper model meets every PRD target (then it becomes the default)". PRD §9 (`docs/PRD.md:169`): "only the development-default profile gates PRs". The issue doesn't mention the gate.
- **Options:**
  - (a) Everything follows in this PR: `DEFAULT_MODEL_PROFILE` and its test, the `AgentModelProfile` default, the gate's profile and baseline in `evals.yml`, a new `packages/evals/baselines/<profile>.json`, the eval role's Bedrock resources in `bootstrap.yaml` (Nick deploys the bootstrap stack before the PR's gate can pass), CLAUDE.md, PRD FR-041, an ADR-008 amendment and the docs that name the gate's profile. Scope: adds the gate and the bootstrap stack. Owned paths: + `.github/workflows/evals.yml`, `infra/bootstrap/bootstrap.yaml`, `CLAUDE.md` (whole file), `docs/PRD.md`, `docs/adr/0008-evaluation-strategy.md`, `docs/adr/README.md`, `.github/pull_request_template.md`, `.claude/skills/task-workflow/SKILL.md`, `.claude/skills/run-evals/SKILL.md`, `docs/runbooks/aws-setup.md`, `services/api/src/lib/config.ts`, `docs/architecture.md`, `docs/adr/0010-provider-neutral-llm-layer.md`
  - (b) Only the production profile moves: the `AgentModelProfile` default in `infra/stacks/api.yaml` becomes the chosen profile. `DEFAULT_MODEL_PROFILE`, the Eval gate, its baseline and CLAUDE.md's "Development default" stay `sonnet-4.6`. CLAUDE.md gets a "Production profile: `<profile>` (ADR-002's amendment, #37)" line under the model-profile lines, and AC 10 is reworded to match. The deployed chat then runs a profile the PR gate doesn't measure. Scope: within the issue (CLAUDE.md's model-profile lines)
  - (c) The three listed items move in this PR (AC 10 as written). Moving the gate, its baseline and the eval role is filed as a follow-up issue that this PR opens, and Nick does the bootstrap change there. Until it merges, the gate keeps measuring `sonnet-4.6`, and this PR appends a pointer to that follow-up on the CLAUDE.md lines that name the gate's profile (`CLAUDE.md:130`, `:146`). The lines outside CLAUDE.md that say "default `sonnet-4.6`" also change. Scope: within the issue plus three doc and comment files. Owned paths: + `CLAUDE.md` (whole file), `services/api/src/lib/config.ts`, `docs/architecture.md`
- **Makes stale:** by option, as listed:
  - every option, when the chosen profile isn't `sonnet-4.6`: `infra/stacks/api.yaml:21`;
  - options (a) and (c): `packages/agent/src/profiles.ts:28-29`, `packages/agent/src/profiles.ts:110-111`, `packages/agent/test/profiles.test.ts:15-18`, `CLAUDE.md:110`, `CLAUDE.md:113`, `services/api/src/lib/config.ts:15`, `docs/architecture.md:56`;
  - option (a) also: `.github/workflows/evals.yml:7-8`, `.github/workflows/evals.yml:33-35`, `infra/bootstrap/bootstrap.yaml:406-409`, `CLAUDE.md:69-70`, `CLAUDE.md:130`, `CLAUDE.md:146`, `docs/PRD.md:98`, `docs/adr/0008-evaluation-strategy.md:178`, `docs/adr/0010-provider-neutral-llm-layer.md:60`, `.github/pull_request_template.md:17`, `.claude/skills/task-workflow/SKILL.md:89`, `.claude/skills/run-evals/SKILL.md:92-93`;
  - option (c) also: `CLAUDE.md:130`, `CLAUDE.md:146` (a pointer only);
  - option (b): `CLAUDE.md:110` (a new line beside it).
- **Edges:** each case below is settled as stated:
  - If `sonnet-4.6` is chosen, or if no profile qualifies (AC 6), nothing in this question changes under any option.
  - If `haiku-4.5` is chosen, the judge (default `haiku-4.5`, `packages/evals/src/judge/judge.ts:32-34`) is the same model as the agent. That contradicts the judge's stated reason (`judge.ts:3-5`, ADR-008 `:199`). Under every option the judge stays `haiku-4.5`, and the ADR-002 amendment records the overlap. A judge change belongs to #159.
  - The simulator stays `sonnet-4.6` under every option (#108, E-4).
  - An empty `JUDGE_MODEL_PROFILE` resolves to `DEFAULT_MODEL_PROFILE` (`packages/evals/src/cli-args.ts:406-409`). Under (a) and (c) it then follows the new default. That quirk is kept and named in the PR.
  - No test ties `api.yaml`'s `Default:` to `DEFAULT_MODEL_PROFILE` (`services/api/test/api-template.test.ts` checks only `AllowedValues` and IAM). Evidence that they match is the PR diff of both lines.
  - If an effort cell wins, Q-5 decides what the profile name means. This question decides only which places carry the name.
- **Recommendation:** (c), because it follows AC 10 as Nick wrote it and ADR-002 `:59` ("then it becomes the default"), keeps this PR out of the bootstrap stack (CLAUDE.md: "Ask before … anything touching the bootstrap stack"), and leaves the gate move to an issue Nick can sequence with his own bootstrap deploy.
- **Reply:** `Decision r1/Q-1: (c)`

#### Q-2: How far does "Failures triaged → prompt/tool fixes → re-run until PRD §7 targets met" go, and what gets re-run after a fix?

- **Why it matters:**
  - **No bound.** The criterion has no bound on rounds or spend. One full matrix is about $72 at the dry-run estimate (`.claude/skills/run-evals/SKILL.md:116`) and most of a day of wall-clock, because every scenario run's simulator shares `sonnet-4.6`'s 10 RPM (`packages/agent/src/profiles.ts:115`).
  - **Prompt versions.** A prompt fix is a new prompt version, so cells from before and after it can't be compared (`packages/evals/src/report/exit.ts:91-92` refuses mixed versions within a cell).
  - **Owned paths.** "Tool fixes" fall outside them: only `packages/agent/src/prompts/**` is owned, while tool descriptions live in `packages/contracts/src/tools.ts` and handlers in `packages/tools/src/tools/`.

  A wrong guess means either an open-ended spend or a PR that grows into other streams' files.
- **Source:** the issue's AC 9. AC 6: "If none qualifies, `sonnet-4.6` stays the default and the PR and ADR-002 record why." AC 8: "'No regression' for prompt changes applies to the development-default profile only (PR #102, `7e3e8bd/STD-4`)".
- **Options:**
  - (a) At most one fix round, prompt only. If a profile qualifies on the first matrix, there is no fix round. Otherwise the agent triages every failure, makes one prompt version bump in `packages/agent/src/prompts/**`, and re-runs the full matrix once on it, after Nick approves that run's estimate. The selection uses the re-run. Tool, contract, grader and scenario defects become new issues and aren't fixed here. If no profile qualifies after the round, `sonnet-4.6` stays and ADR-002 and the PR record why. Scope: within the issue
  - (b) At most one fix round, prompt only, re-running only the candidate. The fix round is the same as option (a), but after the prompt bump only the cheapest candidate that failed and `sonnet-4.6` (for the no-regression rule) re-run. Cheaper cells that failed on the old prompt aren't re-run, so the "cheapest that qualifies" comparison mixes prompt versions, and the report says so. Scope: within the issue
  - (c) Rounds until §7 is met on the chosen profile, with tool, contract, grader and scenario fixes in this PR too. Scope: adds the tools, contracts and evals streams' files. Owned paths: + `packages/tools/src/tools/`, `packages/tools/test/`, `packages/contracts/src/tools.ts`, `packages/contracts/src/__snapshots__/tools.test.ts.snap`, `packages/evals/src/graders/`, `packages/evals/test/`, `packages/evals/scenarios/`
  - (d) No fix round in this issue: the matrix runs once on the current prompt, the decision follows the selection rule, and each triaged failure class becomes a follow-up issue. AC 9 moves to those issues. Scope: narrows the issue
- **Makes stale:** by option, as listed:
  - options (a), (b) and (c), if a fix round happens: `packages/agent/src/prompts/index.ts:6`, `packages/agent/src/prompts/index.ts:14` (the current version's import), and `packages/evals/baselines/sonnet-4.6.json:9` (already stale, see A-5);
  - option (d): the issue's AC 9 line.
- **Edges:** each case below is settled as stated:
  - **The "today or later" line.** A failure of `l1-availability-past-dates` decides whether `check_availability`'s description needs that line (`docs/journal/2026-10-06-tool-pr-cases-land-as-l1.md:51`). Under (a), (b) and (d) that change is a follow-up issue in the tools stream. Under (c) it lands here, following the `add-agent-tool` skill.
  - **The five-option cap.** It is #212's under every option. #212 says "this issue takes this one out of that queue".
  - **Re-run estimate.** A re-run's estimate is approved on its own (A-1). A run that the budget guard stops isn't an exit run (`packages/evals/src/report/exit.ts:81-82`), so a stopped cell is re-run, not counted.
  - **No regression.** It is judged on `sonnet-4.6` only (AC 8), against the baseline re-recorded under A-5.
  - **Fixes landing during the run.** If a sibling prompt PR (#212, #234, #236) lands during the fix round, A-3 applies.
- **Recommendation:** (a), because it bounds the spend at two matrices (about $144 at the estimate, before reasoning-token overrun), keeps the selection fair on one prompt version, stays in the owned paths, and AC 6 already says what happens if nothing qualifies.
- **Reply:** `Decision r1/Q-2: (a)`

#### Q-3: How is NFR-001 measured on the deployed stack: who drives the 30 turns, with what, and on which deployment?

- **Why it matters:** The selection rule needs NFR-001 met "on the deployed stack … over at least 30 turns, from the handler's logs or metrics", but the issue doesn't say how the turns are produced. The choice decides whether the agent writes new code outside its owned paths, needs Nick's time, or changes `dev`, which is shared. Each candidate measured is a deploy plus real Bedrock spend.
- **Source:** the issue's AC 6. PRD NFR-001 (`docs/PRD.md:123`). `.github/ISSUE_TEMPLATE/task.yml:35-40` (Verification: "say how it is shown and who runs it"). The issue has no Verification section (E-7).
- **Options:**
  - (a) The agent drives the turns with the existing S-2 driver, run unchanged. It deploys the candidate to `dev` with `scripts/deploy.sh api dev -- AgentModelProfile=<profile>`, then runs `spikes/s2-streaming/measure.ts --runs 30 --targets cloudfront`. The `--text` is one availability question that makes the agent call `check_availability` and book nothing, and `--pace-ms` keeps the candidate's Bedrock calls under its `rpm`. It reads p50 `firstTextMs` and p95 `totalMs` from a CloudWatch Logs Insights query over the "chat turn" log lines, filtered on `modelProfile` and the run's time window. `dev` is left on the chosen profile. Scope: within the issue (runs spike code without changing it)
  - (b) Nick drives at least 30 turns by hand in the deployed SPA, mixing availability, booking and rescheduling, after the agent deploys the candidate to `dev`. The agent runs the same Logs Insights query and reports the figures. Scope: within the issue; needs Nick's time
  - (c) The agent writes a new committed driver with a mixed turn set (availability, booking, rescheduling), with tests, and runs it against `dev`. Scope: adds a script. Owned paths: + `scripts/nfr001-turns.ts`, `scripts/nfr001-turns.test.ts`
- **Makes stale:** nothing
- **Edges:** each case below is settled as stated:
  - **Order (every option).** The agent measures the cheapest §7-qualifying candidate first, and the next one only if the first misses NFR-001. It doesn't measure every candidate up front. If no measured candidate meets NFR-001, AC 6's "none qualifies" applies.
  - **Sample.** "At least 30" is a minimum: 30 turns are enough. A turn that ends in an error counts in the sample and is listed, not dropped.
  - **What `totalMs` measures.** It is logged after the stream ends (`services/api/src/lib/chat-turn.ts:208-224`), so it is at or above the `done` time, which errs on the strict side. `firstTextMs` is the first `text_delta` (`chat-turn.ts:515-516`), the figure #38 also defines.
  - **Turn cap.** The cap is 50 turns per patient per clinic-local day (`infra/stacks/api.yaml:26-30`). A second candidate measured the same day needs another seeded demo patient or the next day.
  - **Pacing.** A turn with a tool call makes two or more Bedrock calls, so on a 10 RPM Claude profile the pace is at least 20 s per turn. The spike's default 8 s would throttle and inflate the latency.
  - **Overlapping deploys.** Nick's manual "Deploy dev" workflow (`.github/workflows/deploy.yml`) redeploys `main`'s default. The measurement window must not overlap one, and the `modelProfile` filter drops any turn on another profile.
  - **Evidence.** The query text, its output (p50, p95, turn count) and the deploy command go in the PR.
  - **(verify first), under (a):** the spike's credentials file (`spikes/s2-streaming/.env`) and its test user still exist and sign in on `dev`.
- **Recommendation:** (a), because it adds no code, reuses a driver that already measures first `text_delta` and `done` on the deployed stack (spike S-2, ADR-007), and reads the handler's own log line, which is the source PRD NFR-001 names.
- **Reply:** `Decision r1/Q-3: (a)`

#### Q-4: How is the "one forced refusal-fallback turn" forced live, and what does "confirmed" mean?

- **Why it matters:** Nothing in the code can make Bedrock refuse on demand: no guardrail is configured, and `ConverseLlmClient` maps only provider stop reasons. ADR-010 records that "we can't trigger one cheaply" (`docs/adr/0010-provider-neutral-llm-layer.md:104`). The agent would otherwise invent the mechanism, possibly as AWS infrastructure. "Confirmed" has no observable outcome, so the PR reviewer can't check it.
- **Source:** the issue's AC 7. PR #53 deferred the risky case: "Mid-turn fallback between profiles with and without thinking (sonnet-4.6 ↔ haiku-4.5) isn't verified against live Bedrock" (`spec/background/issue-53.md:163`). ADR-008 `:181`: "one forced refusal-fallback turn runs live".
- **Options:**
  - (a) A spike in a new `spikes/refusal-fallback/` directory, which has no tests, as spikes don't. It runs two turns through `runAgentTurn` with the in-memory repositories, the clinic fixture and a synthetic patient. Turn 1 runs live on the chosen profile. In turn 2, a wrapper `LlmClient` returns `scriptedRefusal()` for the first call and sends every later call to Bedrock through `ConverseLlmClient`, so the loop retries on `fallbackProfileFor(chosen)` with turn 1's history in the request. "Confirmed" means turn 2 ends with outcome `completed` on the fallback's model ID. The PR shows the trace: each call's model ID and stop reason, and the outcome. `REFUSAL_FALLBACKS` stays as is unless Nick decides otherwise in the PR. Scope: adds a spike. Owned paths: + `spikes/refusal-fallback/`
  - (b) A Bedrock Guardrail resource in the api stack that blocks one fixed test phrase, attached to Converse requests when configured, so the deployed chat gets a real `guardrail_intervened` that maps to `refusal`. Scope: adds infra and adapter code. Owned paths: + `infra/stacks/api.yaml` (whole file), `packages/agent/src/llm/converse.ts`, `packages/agent/test/`, `docs/adr/0010-provider-neutral-llm-layer.md`, `docs/adr/README.md`
  - (c) No live forced turn. The loop's existing unit tests of the retry stand, the ADR-002 amendment records that a refusal can't be forced cheaply, and AC 7 shrinks to "the chosen profile's pair in `REFUSAL_FALLBACKS` is named in ADR-002 with the fallback's matrix row". Scope: narrows the issue
- **Makes stale:** `packages/agent/src/profiles.ts:87-90` ("The eval matrix may revise this"), under every option: the comment then points at ADR-002's amendment
- **Edges:** each case below is settled as stated:
  - **History in the request.** Under (a), turn 2 must follow a live turn 1, so that the fallback request carries the chosen profile's earlier messages (and its reasoning blocks, where the profile replays them, `replaysReasoning`). A single fresh turn would not exercise PR #53's risk.
  - **If the fallback call fails.** If the live fallback call fails (for example, the API rejects the history), that is the finding. The PR reports outcome `error` and asks Nick before any change to `REFUSAL_FALLBACKS`.
  - **If the fallback has safety violations.** If the fallback profile has safety violations in the matrix (Nova Pro, the fallback of `nova-2-lite`, had 2 in the 2026-10-05 L1 run), the PR names them beside the pair and asks Nick whether to re-pair. The agent doesn't re-pair on its own.
  - **Evidence.** The spike's printed trace, pasted into the PR. Spend is 3 to 4 live calls.
- **Recommendation:** (a), because it is the only option that runs the one thing PR #53 left unverified (a live switch mid-conversation) without new AWS resources, for a few cents. `scriptedRefusal` is already exported from `@sched/agent` (`packages/agent/src/index.ts:64`).
- **Reply:** `Decision r1/Q-4: (a)`

#### Q-5: If an effort cell wins (for example `gpt-oss-120b@medium`), how does it become the production configuration?

- **Why it matters:** Effort cells exist only inside the matrix ("`@sched/agent` is unchanged", `packages/evals/src/matrix.ts:6-7`), and `AgentModelProfile` accepts only the six plain names (`infra/stacks/api.yaml:24`). Changing a profile's `modelFields` also breaks the matrix's own pin: `packages/evals/test/matrix.test.ts:66-73` requires each switch's `default` level to reproduce the plain profile's fields. So the obvious fix also forces a change to `matrix.ts` and its test, outside the owned paths.
- **Source:** the issue is silent. ADR-002 `:47`: "We tune the setting with evals rather than guessing."
- **Options:**
  - (a) The winning level becomes the plain profile's level. The agent changes that profile's `modelFields` in `profiles.ts` and its `EFFORT_SWITCHES` `default` in `matrix.ts` together, and updates the cell names the matrix test expects. Every later run of that profile name uses the new level, and its baseline is recorded at that level. Scope: adds the matrix module. Owned paths: + `packages/evals/src/matrix.ts`, `packages/evals/test/matrix.test.ts`
  - (b) Only each profile's current default level can be chosen. Effort cells are reported for information, and the selection compares the six plain cells. Scope: within the issue
  - (c) Each adopted level gets a new profile name (for example `gpt-oss-120b-medium`), added to the profile list, the refusal pairs, the api stack's allowed values and every list of six profiles. Scope: adds many files. Owned paths: + `infra/stacks/api.yaml` (whole file), `services/api/test/api-template.test.ts`, `packages/evals/src/matrix.ts`, `packages/evals/test/matrix.test.ts`, `docs/PRD.md`, `docs/adr/0010-provider-neutral-llm-layer.md`, `docs/adr/README.md`, `CLAUDE.md` (whole file)
- **Makes stale:** by option, as listed:
  - option (a): `packages/agent/src/profiles.ts:110-111` (if `sonnet-4.6`'s level changes), the winning profile's doc comment in `profiles.ts`, `packages/evals/src/matrix.ts:2-7`, and `.claude/skills/run-evals/SKILL.md:120-121` ("a profile's default level is the plain cell" stays true, but which level that is changes);
  - option (b): the issue's AC 2 and AC 6 gain "effort cells inform, plain cells compete";
  - option (c): `CLAUDE.md:110-113`, `docs/PRD.md:99`, `docs/adr/0010-provider-neutral-llm-layer.md:60-64`.
- **Edges:** each case below is settled as stated:
  - If a plain cell wins, nothing changes under any option.
  - Under (a), the following apply:
    - If `sonnet-4.6` wins at another level, only `sonnet-4.6`'s entry changes. `CLAUDE_ADAPTIVE` is shared with `sonnet-5` and `opus-5` (`profiles.ts:103`), so the agent gives `sonnet-4.6` its own fields rather than editing the shared constant. The development baseline is then recorded at the new level (A-5).
    - A refusal fallback switches to the plain fallback profile at its own level (`packages/agent/src/loop.ts:244`).
    - The changed `modelFields` are a source change, so they need a KILLED row (A-11).
- **Recommendation:** (a), because the matrix exists to tune the effort level (ADR-002 `:47`), it is the smallest change that ships a winning cell, and the matrix test turns red if `profiles.ts` and `matrix.ts` drift apart.
- **Reply:** `Decision r1/Q-5: (a)`

#### Q-6: Does the choice wait for judge calibration (#159), since "every PRD §7 target" includes judge–human agreement and a rubric average "after calibration"?

- **Why it matters:** Two §7 rows are properties of the judge, not the profile: "Judge rubric average (tone, clarity), after calibration ≥ 4.0" and "Judge–human agreement … ≥ 80%" (`docs/PRD.md:143-144`). #159 (Nick's labels) is open, has `needs:human`, and isn't a blocker of this issue. If the choice must wait, the issue is blocked on Nick's labelling. If it doesn't, the matrix's "Meets §7" already treats agreement as met ("measured elsewhere", `packages/evals/src/report/exit.ts:149-154, 186-188`) and counts the rubric before calibration.
- **Source:** the issue's AC 6 ("meets every PRD §7 target"). ADR-008 `:202`: "Nick's labels, the first agreement number and any recalibration are #159; 80% is the PRD §7 exit metric, not a merge gate."
- **Options:**
  - (a) The choice doesn't wait. It uses each cell's rows as the matrix computes them: the rubric average before calibration, and agreement as pending #159. The ADR-002 amendment says so. If #159's recalibration later puts the chosen profile's rubric below 4.0, that is recorded on #159 and the choice is revisited there. Scope: within the issue
  - (b) #159 blocks the choice. The agent runs the matrix, the chosen candidate's scenario results feed `--export-calibration`, Nick labels them, `--calibrate` runs, and only then is the choice recorded. #159 is added to "Blocked by". Scope: adds a dependency. Owned paths: + `docs/backlog.md`
  - (c) The choice doesn't wait, and it ignores the rubric row until #159, since §7 says "after calibration". A cell whose pre-calibration rubric is below 4.0 can still qualify, and agreement is treated as pending #159. Scope: within the issue
- **Makes stale:** by option, as listed:
  - every option: `packages/evals/src/report/exit.ts:151`, which says agreement comes from "the calibration report (`--calibrate`, #38)", when calibration is #159 (out of scope here, reported in the PR);
  - option (b): `docs/backlog.md:299` and the graph edges in `docs/backlog.md` (`scripts/backlog-map.test.ts` checks the two agree).
- **Edges:** each case below is settled as stated:
  - **Judge failures.** A cell whose judge produced no rubric average shows "n/a" and doesn't qualify (`exit.ts:186-188`) under (a) and (b). Under (c) it can qualify.
  - **`haiku-4.5`'s rubric.** The `haiku-4.5` cell is scored by `haiku-4.5` itself (the judge's default, `judge.ts:32-34`), so under every option its rubric figure carries that caveat in the report.
  - **Prompt version for calibration.** Under (b), `--export-calibration` refuses a results file whose prompt version differs from the current one (`docs/journal/2026-10-10-ask-who-is-speaking-before-acting.md:56`). The export therefore comes from the matrix run on the current prompt.
  - **M3 exit.** M3's own exit ("§7 targets met", `docs/PRD.md:155`) still needs #159 under every option. That isn't this issue's work.
- **Recommendation:** (a), because agreement measures the judge, not the profile; the harness already treats it that way (`matrix.ts:300`: "agreement and NFR-001 are measured elsewhere"); and ADR-008 `:202` keeps calibration in #159.
- **Reply:** `Decision r1/Q-6: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The agent posts one estimate comment on this issue, covering the first matrix (the `npm run evals:matrix -- --dry-run` total and the `--max-cost` it proposes, at least the default 1.5× because the estimate doesn't model reasoning tokens), the six smoke baseline runs (A-5), the refusal turn (Q-4) and the deployed NFR-001 turns (Q-3). Nick's approval covers exactly those. Every later live run, such as a fix-round re-run, gets its own estimate comment and approval first. | CLAUDE.md "AWS rules": "Say what a run will cost before any live run beyond what was approved"; `.claude/skills/run-evals/SKILL.md:116` (about $72), `:124-125` ("doesn't model reasoning tokens, so effort cells estimate alike"); `packages/evals/src/matrix.ts:16` (default 1.5×) | nothing | `Decision r1/A-1: <your correction>` |
| A-2 | Only one live eval process runs at a time, and the matrix may run in `--cells` batches (to survive an SSO expiry; there is no resume). The rate limiter's bucket is per process, and every scenario run's simulator draws on `sonnet-4.6`'s 10 RPM. The agent pushes no commit touching a gated path to the PR while a live run is going, because the Eval gate draws on the same account quota. | `packages/evals/src/rate-limit.ts:2-3` ("one token bucket per model ID, shared by every live call in the process"); `packages/agent/src/profiles.ts:115` (`rpm: 10`); `packages/evals/src/matrix.ts:11` (cells run one after another) | nothing | `Decision r1/A-2: <your correction>` |
| A-3 | The matrix runs on the prompt at the branch's base when it starts (`system.v3` today), and the report and ADR-002 name that `promptVersion`. Prompt PRs that land later (#212, #234, #236, all open and each editing the system prompt) don't trigger a re-run here; Q-2's fix round is the only re-run. The agent records the baselines last, after merging `main`, on the prompt version the PR merges with. #212's five-option cap isn't fixed here. | `packages/agent/src/prompts/index.ts:6`; `packages/evals/src/report/exit.ts:91-92` (one prompt version per exit run); #212's References: "#37: … this issue takes this one out of that queue"; `docs/journal/2026-10-11-plain-text-for-a-plain-text-bubble.md:58` | `packages/evals/baselines/sonnet-4.6.json:9` | `Decision r1/A-3: <your correction>` |
| A-4 | A safety violation that is #239's false positive (`no_hallucinated_slots` reading the patient's own stated or booked time as a quoted slot, confirmed by reading the transcript) is listed in the report by case and trial and isn't counted against the profile. Every other safety violation counts, including Nova Pro's. #178 (list offers under a date heading aren't graded) means the safety count may miss hallucinated slots in list offers. The report says so, and those slots don't count either way. | The 2026-10-05T21:12 comment on this issue ("doesn't count items 2 and 3 against `sonnet-4.6`", grader false positives Nick accepted); #239's Goal: "Nick accepted it as a grader false positive on #233"; the 2026-10-05T11:08 comment ("Nova Pro's two safety violations, which still count for the matrix") | nothing | `Decision r1/A-4: <your correction>` |
| A-5 | The agent re-records `packages/evals/baselines/sonnet-4.6.json` on the current prompt, and writes `<profile>.json` for each of the other five entitled profiles, from smoke k=1 runs in both modes and `npm run evals -- --update-baseline`. Effort cells get no baseline file; a profile changed under Q-5 (a) is recorded at its new level. | ADR-008 `:227`: "#34 commits `sonnet-4.6.json`; other profiles' files are #37's"; `docs/journal/2026-10-09-the-eval-gate-and-an-estimate-that-was-7x-high.md:50`: "#37 runs the matrix live and writes the other profiles' baselines"; `docs/journal/2026-10-11-plain-text-for-a-plain-text-bubble.md:58`: "#37 re-records the baselines on `system.v3`" | `packages/evals/baselines/sonnet-4.6.json:9` | `Decision r1/A-5: <your correction>` |
| A-6 | NFR-001's figures come from the existing "chat turn" log line (`firstTextMs`, `totalMs`, `modelProfile`) through a Logs Insights query, so #38's dashboard isn't needed, and #38 doesn't become a blocker. | PRD NFR-001 (`docs/PRD.md:123`: "read from the handler's logs or metrics (#38)"); `services/api/src/lib/chat-turn.ts:210-225, 515-516, 540` | nothing | `Decision r1/A-6: <your correction>` |
| A-7 | (would have asked) A tie between candidates is an equal agent cost per completed conversation at the report's precision ($0.0001, `exit.ts` prints `toFixed(4)`). It is broken by the deployed `done` p95 from Q-3's measurement, taken for each tied candidate. The matrix's harness p95 is never used for the tie. | PRD NFR-001 (`docs/PRD.md:123`: eval-harness latencies "are reported for information only"); `packages/evals/src/matrix.ts:281` (the harness p95 includes rate-limit pacing) | nothing | `Decision r1/A-7: <your correction>` |
| A-8 | The measured NFR-003 figure goes into PRD §7's row as a parenthesis in the Target cell of the "Agent cost per completed conversation" row, "≤ $0.25 (measured $X on `<profile>`, #37)". The other §7 rows are left as they are (E-1 adds the PRD to the owned paths). | the issue's AC 5 ("The figure is in the report and in PRD §7's row"); `docs/PRD.md:137-146` (the table has only Metric and Target columns) | `docs/PRD.md:145` | `Decision r1/A-8: <your correction>` |
| A-9 | ADR-002 gets a dated `## Amendment (<date>): production profile (#37)` section with the decision table. The `**Status:**` line keeps its text and adds "model-selection decision accepted <date> (#37)". The `**Amended:**` line and ADR-002's row in `docs/adr/README.md` add the date. Body lines the amendment answers keep their wording and gain an italic pointer. | `docs/adr/README.md:6` (amendment rules); `scripts/adr-history.test.ts:10-11` (the date must be in the header and the index row); the issue's AC 11 | `docs/adr/0002-model-and-bedrock-client.md:3`<br>`docs/adr/0002-model-and-bedrock-client.md:5`<br>`docs/adr/0002-model-and-bedrock-client.md:47`<br>`docs/adr/0002-model-and-bedrock-client.md:48`<br>`docs/adr/0002-model-and-bedrock-client.md:59`<br>`docs/adr/0002-model-and-bedrock-client.md:133`<br>`docs/adr/0002-model-and-bedrock-client.md:135`<br>`docs/adr/README.md:15` | `Decision r1/A-9: <your correction>` |
| A-10 | Outside Q-1's lists, the agent updates only the owned comments that name #37 in the future tense, pointing them at ADR-002's amendment. The other lines that name #37 describe the method or history and stay as they are: ADR-008 `:181`, ADR-010 `:74`, PRD `:155`, `matrix.ts:19`, `run-evals` SKILL `:74`, `:125`. | `git grep -nE "#37([^0-9]\|$)\|M3-02"` (output under "What was checked") | `packages/agent/src/profiles.ts:4`<br>`packages/agent/src/profiles.ts:28`<br>`packages/agent/src/profiles.ts:87-90` | `Decision r1/A-10: <your correction>` |
| A-11 | For a source file the PR changes only in comments (`packages/evals/src/report/results-file.ts`'s header, `profiles.ts`'s comments), the agent gets its KILLED row by mutating code in the same file and naming the test that goes red. Examples: drop a field from the results-file schema, or swap a `REFUSAL_FALLBACKS` pair (`packages/agent/test/profiles.test.ts:104-112`). | `scripts/pr-evidence.ts:2-13` (every changed source file needs a KILLED row; only docs-only and test-only PRs pass) | nothing | `Decision r1/A-11: <your correction>` |
| A-12 | The ADR-002 amendment and the journal entry state the comparison table's cell results as the matrix printed them, and the chosen profile's `REFUSAL_FALLBACKS` pair with the fallback's own matrix row beside it. The journal entry also gets its row in `docs/journal/README.md` (owned through `docs/journal/**`). | CLAUDE.md "Definition of done" (journal entry and its index row); the issue's AC 7 and AC 11 | nothing | `Decision r1/A-12: <your correction>` |

### Suggested edits to the issue

#### E-1: Add the files the criteria and the deferred notes require to the owned paths

Before:
```text
- `docs/adr/0002-*`
```
After:
```text
- `docs/adr/0002-*`
- `docs/adr/README.md` (ADR-002's row only: the amendment date, checked by `scripts/adr-history.test.ts`)
- `docs/PRD.md` (§7's "Agent cost per completed conversation" row only, for the measured figure AC 5 asks for)
- `.github/workflows/evals.yml` (the comment above the "Smoke suite, L1" step only; deferred from PR #229, VER-1)
- `packages/evals/src/report/results-file.ts` (the header comment only; deferred from PR #229, VER-2)
```
- **Reply:** `Decision r1/E-1: accept`

#### E-2: Correct the stale "#49 tracks them"

Before:
```text
Opus 5 and Sonnet 5 aren't in it: AWS denied them for this account (ADR-010), and #49 tracks them.
```
After:
```text
Opus 5 and Sonnet 5 aren't in it: AWS denied them for this account (ADR-010), and #49 was closed as not planned on 2026-10-09 (ADR-002's 2026-10-09 amendment).
```
- **Reply:** `Decision r1/E-2: accept`

#### E-3: #107 has landed, so the "otherwise" branch can't happen

Before:
```text
#107's Nova Pro guards are in before Nova Pro is scored (#107 blocks this issue); otherwise Nova Pro's safety numbers are reported as known failures.
```
After:
```text
#107's Nova Pro guards are in (PR #162, merged 2026-10-05). Nova Pro's remaining safety violations are its own behaviour and count like every profile's (2026-10-05 comment on this issue).
```
- **Reply:** `Decision r1/E-3: accept`

#### E-4: The simulator's default is already settled by #108

Before:
```text
The simulator's default follows the agent's unless #108 has given it its own; the PR says which.
```
After:
```text
The simulator keeps its own default (`DEFAULT_SIMULATOR_PROFILE` = `sonnet-4.6`, #108) and doesn't follow the agent's; PRD §7's exit runs use it.
```
- **Reply:** `Decision r1/E-4: accept`

#### E-5: Make the report criterion testable: where the summary lives and what it links

Before:
```text
- [ ] Full matrix report committed (summary) with links
```
After:
```text
- [ ] When the matrix has run, ADR-002's amendment and the journal entry show the comparison table (one row per cell, as `npm run evals:matrix` writes it to `<stamp>-matrix.md`) and the chosen cell's exit table, and link a secret gist holding the raw `<stamp>-matrix.{md,json}` and each cell's results JSON (synthetic data only). `packages/evals/results/` is git-ignored, so nothing there is committed.
```
- **Reply:** `Decision r1/E-5: accept`

#### E-6: Make the two notes deferred from PR #229 acceptance criteria

Before:
```text
- [ ] ADR-002 Accepted with the decision table (an amendment recording the rule and the outcome); journal entry 'What the evals showed'
```
After:
```text
- [ ] ADR-002 Accepted with the decision table (an amendment recording the rule and the outcome); journal entry 'What the evals showed'
- [ ] The two notes deferred from PR #229 are done, with the steps' behaviour unchanged: the comment above `.github/workflows/evals.yml`'s "Smoke suite, L1" step names the re-run step (`eval-gate.ts errored`, exit 2 on missing results) as the one that fails after a crash, and still matches `cli.ts`'s exit codes; `packages/evals/src/report/results-file.ts`'s header says the conversation metrics use turns, stop reason and simulator cost, and that `judgeCost` and `turnDurationsMs` are checked only as part of the trial's shape, with no check removed.
```
- **Reply:** `Decision r1/E-6: accept`

#### E-7: Add the Verification section the issue template requires

Before:
```text
## References
```
After:
```text
## Verification
- Matrix, baselines and estimates: the agent runs them (`npm run evals:matrix`, smoke runs, `npm run evals -- --update-baseline`) after Nick approves the estimate on this issue; the PR quotes the estimate, the comparison table and each baseline's counts.
- NFR-001 on the deployed stack: run as decided in r1/Q-3; the PR quotes the deploy command, the Logs Insights query and its output (p50 first `text_delta`, p95 `done`, turn count, profile).
- Refusal-fallback turn: run as decided in r1/Q-4; the PR quotes the turn's trace (each call's model ID and stop reason, and the outcome).
- `npm run lint && npm run typecheck && npm test` pass, and all five CI checks are green, the Eval gate against the re-recorded baseline included.

## References
```
- **Reply:** `Decision r1/E-7: accept`

#### E-8: Add non-goals, so the run doesn't grow into neighbouring work

Before:
```text
Unblocks: #43 (M4-01), #45 (M4-03)
```
After:
```text
Unblocks: #43 (M4-01), #45 (M4-03)

## Non-goals
- Changing the matrix harness (`packages/evals/src/matrix.ts`, the estimate, the cells), except as r1/Q-5 decides.
- Adding an effort switch to a profile without one (`haiku-4.5`, `nova-pro` run once, drift-audit decision 12).
- Judge calibration and labels (#159), observability and the dashboard (#38), the five-option cap (#212), and grader fixes (#178, #239).
```
- **Reply:** `Decision r1/E-8: accept`

### Reuse, dependencies and risks

- **Reuse:**
  - **The whole run and its table:** run `npm run evals:matrix` as is (`packages/evals/src/matrix.ts:113-127, 255-317`). It already prints the estimate, asks y/N, shares the budget, writes per-cell exit tables and the comparison table, and copies results outside the checkout.
  - **Exit tables for one cell's re-run:** use `--exit-report`. Import `exitReport` and `exitMet` from `packages/evals/src/report/exit.ts`; they are already used by the matrix.
  - **Agent-share cost:** import `agentCostUsd` and `conversationMetrics` from `packages/evals/src/report/metrics.ts:33-74`. They are already the exit row and the matrix's "Agent $ / completed".
  - **Baselines:** use `npm run evals -- --update-baseline <l1.json> <scenario.json>` (`packages/evals/src/report/baseline.ts:63`).
  - **The forced refusal (Q-4 a):** import `scriptedRefusal`, `ConverseLlmClient`, `runAgentTurn` and `fallbackProfileFor` from `@sched/agent` (`packages/agent/src/index.ts:64`). The wrapper `LlmClient` is new spike code. Ask, in the PR, before moving it out of `spikes/`.
  - **The 30 deployed turns (Q-3 a):** run `spikes/s2-streaming/measure.ts` unchanged. Ask before copying it into a committed path.
  - **Deploying a candidate:** run `scripts/deploy.sh api dev -- AgentModelProfile=<profile>`. Overrides go only to templates that declare the parameter (`scripts/deploy.sh:4-7, 118-121`).
- **Dependencies:**
  - Every listed blocker has merged on `main`: #36 (`7f0486f`), #34 (`33fc645`), #80 (`8630a99`), #107 (`3ee2249`).
  - So have the fixes the 2026-10-05 comments asked for: #98 (`b94e3ff`), #166 (`1755475`), #170 (`16f15f6`), #171 (`fef4d45`).
  - Open and not listed: #38 (not needed, A-6), #159 (Q-6), #178 and #239 (A-4).
- **Overlaps:** no open pull requests (`gh pr list --state open` is empty).
- **Size:**
  - **Code:** small. `profiles.ts` and its test, one `api.yaml` line, two comment fixes, possibly a `system.v4` prompt and a spike of about 100 lines.
  - **Docs:** the ADR-002 amendment, the journal entry, and the CLAUDE.md and PRD lines.
  - **Total:** about 300 to 700 changed lines, which fits one PR.
  - **Run time:** one to two days of live runs (one or two matrices at most of a day each, per A-2's pacing).
  - **Split:** no split is needed unless Q-2 is answered (d).
- **Risks:**
  - **Budget stops.** The estimate is calibrated on `sonnet-4.6` and `system.v1` and ignores reasoning tokens, so `@high` cells can overrun. A budget-stopped cell is "not an exit run", and the cells after it don't run (`matrix.ts:262-269`). A-1 asks for a cap above 1.5× when needed.
  - **Undercounted safety violations.** #178's gap may hide hallucinated slots in list offers, so the safety count may be low (A-4).
  - **`haiku-4.5` judges its own cell** (Q-6 edges).
- **Sibling issues:**
  - #212, #234 and #236 each edit the system prompt (A-3). #212 explicitly takes the five-option cap out of this issue's fix queue.
  - #239 and #178 change `no_hallucinated_slots` (A-4). #201 adds full-suite cases, and cases landing mid-matrix would make cells incomparable, so A-3's "prompt at the branch base" applies to the case set too.
  - #159 is calibration (Q-6). #38 is observability (A-6). #43 and #45 wait on this issue.
  - None of these has a "Decisions and clarifications" section or a readiness review yet.

**Relied on:**
- `docs/PRD.md`: "FR-041", "FR-042", "NFR-001", "NFR-003", "7. Success metrics (evaluation targets)", "8. Milestones" (M3), "9. Risks and open questions"
- `docs/adr/0002-model-and-bedrock-client.md`: "Decision", "Consequences" (Revisit if), "Interim decision (accepted by Nick, 2026-09-28)", "Amendment (2026-10-09): AWS declined the entitlement and quota increases (#227)"
- `docs/adr/0008-evaluation-strategy.md`: the 2026-10-03 amendment (the CI gate, latency and cost, the model matrix, the judge model, calibration) and the 2026-10-09 amendment (baseline format, the matrix)
- `docs/adr/0010-provider-neutral-llm-layer.md`: the profiles list and "Not verified live"
- `docs/adr/README.md`: the amendment rules
- `CLAUDE.md`: "AWS rules", "How work flows", "Definition of done"
- `.github/ISSUE_TEMPLATE/task.yml`: "Verification"
- the issue's comments of 2026-10-05T11:08, 2026-10-05T21:12 and 2026-10-09T19:32 (VER-1, VER-2)
- #212 "References" and #239 "Goal"
- `docs/journal/2026-10-09-the-eval-gate-and-an-estimate-that-was-7x-high.md` and `docs/journal/2026-10-11-plain-text-for-a-plain-text-bubble.md`: the #37 follow-up lines

<details>
<summary>What was checked</summary>

**Requirements** (from the spec analysis, checked against the issue and code):
- R-1, the cost approval: testable as an approval comment. Its scope is set by A-1.
- R-2, the matrix: testable. `matrixCells()` (`packages/evals/src/matrix.ts:113-127`) with `EFFORT_SWITCHES` (`:87-104`) gives 3 + 1 + 3 + 1 + 3 + 3 = 14 cells. "#49 tracks them" is stale (E-2).
- R-3, the report: not testable as written. E-5 fixes it.
- R-4, agent-share cost: testable. It is already computed (`packages/evals/src/report/metrics.ts:33-34`).
- R-5, the NFR-003 gate: testable at ≤ $0.25 (`exit.ts:19`). "PRD §7's row" needs an owned path (E-1) and a place in the row (A-8).
- R-6 and R-7, the selection rule and NFR-001: thresholds testable. The procedure is Q-3, the tie is A-7, calibration is Q-6, effort cells are Q-5.
- R-8, the refusal fallback: not testable as written. Q-4 fixes it.
- R-9, #107: satisfied, and the line is stale (E-3).
- R-10, the fix loop: unbounded as written. Q-2 settles it.
- R-11, the default change: a checklist, but incomplete for the gate. Q-1 settles it; the simulator clause is stale (E-4).
- R-12, the ADR-002 amendment: testable with `docs/adr/README.md` owned (E-1, A-9).
- R-15 and R-16, the deferred VER-1 and VER-2: testable by inspection. E-6 adds them; the text is confirmed at `.github/workflows/evals.yml:82-84` and `packages/evals/src/report/results-file.ts:1-9`.

**Claims checked in the code** (at `160aa3c`):
- **Effort pin.** `packages/evals/test/matrix.test.ts:66-73` pins each switch's default level to the plain profile's `modelFields`. This was found here and is not in either analysis; it drives Q-5 (a)'s owned paths.
- **"Meets §7".** `exitMet` treats "measured elsewhere" rows as met, and the rubric row is computed before calibration (`packages/evals/src/report/exit.ts:143-154, 186-188`).
- **Per-process rate bucket.** Confirmed by `packages/evals/src/rate-limit.ts:2-3`.
- **Handler log line.** It carries `firstTextMs` (`services/api/src/lib/chat-turn.ts:515-516`), `totalMs`, logged after `#out.end` (`:208-224`), and `modelProfile` and `promptVersion` (`:540-541`).
- **Gate pinned to Claude.** `.github/workflows/evals.yml:33-35` and `infra/bootstrap/bootstrap.yaml:406-409` (quoted in Q-1).
- **Simulator default.** `DEFAULT_SIMULATOR_PROFILE = "sonnet-4.6"`, with a comment naming #37 and #108 (`packages/evals/src/simulator/llm.ts:41-46`).
- **Stale baseline.** It is still `system.v1` (`packages/evals/baselines/sonnet-4.6.json:9`), while the prompt imports `system.v3` (`packages/agent/src/prompts/index.ts:6`).
- **Deploys.** Overrides are taken after `--` (`scripts/deploy.sh:4-7, 30, 118-121`). "Deploy dev" is manual from `main` only (`.github/workflows/deploy.yml:1-11`).
- **Refusal trace.** `LlmCallTrace.attempt` is a number (`packages/contracts/src/trace.ts:20`), not a named `refusal_fallback`. The evidence wording in Q-4 and E-7 uses the model IDs and stop reasons instead.

**Analyst claims corrected or dropped:**
- The spec analysis put ADR-002's index row at `docs/adr/README.md:16`; it is `:15`.
- The spec analysis's OB-12 (ADR status wording) became A-9.
- OB-13 ("today or later") became an edge of Q-2.
- C-4 (the tie-break latency) became A-7.
- OB-2 (the report location) became E-5 rather than a question: the decision table already belongs in ADR-002 (AC 11), and the gist precedent is on the issue (the 2026-10-05T12:47 comment).
- The code analysis's sibling note that #178 removes a false positive was refined: #178 is about a grader gap (offers under date headings aren't graded), while the 2:30 PM heading false positive is #239's case (#239's Goal, read with `gh issue view 239`).

**Commands run, with their output:**
- `git check-ignore -v packages/evals/results/x.json` printed `.gitignore:22:packages/evals/results/	packages/evals/results/x.json`, which is the basis of E-5's "nothing there is committed".
- `git log --merges --oneline --grep="/<n>-"` for each blocker found `33fc645` (#34), `7f0486f` (#36), `8630a99` (#80), `b94e3ff` (#98), `3ee2249` (#107), `1755475` (#166), `16f15f6` (#170), `fef4d45` (#171). It found none for #38, #159, #178, #201, #212, #234, #236, #239.
- `gh issue view` showed #38, #159, #178, #201, #212, #234, #236, #239, #43 and #45 all OPEN.
- `gh pr list --state open` was empty.
- `git grep -nE "#37([^0-9]|$)|M3-02" -- . ':!docs/journal' ':!docs/backlog.md'` returned:
  - `.claude/skills/run-evals/SKILL.md:74, :125`
  - `docs/PRD.md:99, :125, :155, :204, :207, :209`
  - `docs/adr/0002-model-and-bedrock-client.md:47, :135, :139`
  - `docs/adr/0008-evaluation-strategy.md:180, :181, :227`
  - `docs/adr/0010-provider-neutral-llm-layer.md:74`
  - `infra/bootstrap/bootstrap.yaml:408`
  - `packages/agent/src/profiles.ts:4`
  - `packages/evals/src/matrix.ts:19`
  - `packages/evals/src/simulator/llm.ts:44`

  These are the basis of A-10's "stay as they are" list. The PRD traceability rows (`:204-209`) and the requirement text stay true.

**Sources read:**
- the brief, the format, and the manifest (to line 46 of 46);
- `spec/issue-37.md` (to line 128 of 128) and `issue-body.md` (to line 45 of 45);
- `analysis/spec.md` (to line 255 of 255) and `analysis/code.md` (to line 184 of 184);
- the code and docs cited above, in the ranges cited.

**Not checked:**
- Whether `spikes/s2-streaming/.env` and its test user still work on `dev`. This needs AWS access and is marked "(verify first)" in Q-3.
- The actual `--dry-run` total on the current prompt. Running it executes project code.
- Whether `LlmResponse` can be returned directly from a wrapper around `ConverseLlmClient` without adaptation (Q-4 (a)).
- The live behaviour of a mid-conversation fallback, which is what Q-4 asks to run.

</details>

