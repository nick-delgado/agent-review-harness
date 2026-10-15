<!-- agent-pr-review:readiness-applied round=1 -->
## Readiness answers applied (round 1)

Only `Decision r1/<ID>: ...` lines count; other replies are not applied. `ALL` accepted the recommendations and edits, but not the assumptions that need an explicit answer.

**Applied:**
- Q-1: accepted the recommendation, (c) The three listed items move in this PR (AC 10 as written). Moving the gate, its baseline and the eval role is filed as a follow-up issue that this PR opens, and Nick does the bootstrap change there. Until it merges, the gate keeps measuring `sonnet-4.6`, and this PR appends a pointer to that follow-up on the CLAUDE.md lines that name the gate's profile (`CLAUDE.md:130`, `:146`). The lines outside CLAUDE.md that say "default `sonnet-4.6`" also change. Scope: within the issue plus three doc and comment files. Owned paths: + `CLAUDE.md` (whole file), `services/api/src/lib/config.ts`, `docs/architecture.md`
- Q-2: accepted the recommendation, (a) At most one fix round, prompt only. If a profile qualifies on the first matrix, there is no fix round. Otherwise the agent triages every failure, makes one prompt version bump in `packages/agent/src/prompts/**`, and re-runs the full matrix once on it, after Nick approves that run's estimate. The selection uses the re-run. Tool, contract, grader and scenario defects become new issues and aren't fixed here. If no profile qualifies after the round, `sonnet-4.6` stays and ADR-002 and the PR record why. Scope: within the issue
- Q-3: accepted the recommendation, (a) The agent drives the turns with the existing S-2 driver, run unchanged. It deploys the candidate to `dev` with `scripts/deploy.sh api dev -- AgentModelProfile=<profile>`, then runs `spikes/s2-streaming/measure.ts --runs 30 --targets cloudfront`. The `--text` is one availability question that makes the agent call `check_availability` and book nothing, and `--pace-ms` keeps the candidate's Bedrock calls under its `rpm`. It reads p50 `firstTextMs` and p95 `totalMs` from a CloudWatch Logs Insights query over the "chat turn" log lines, filtered on `modelProfile` and the run's time window. `dev` is left on the chosen profile. Scope: within the issue (runs spike code without changing it)
- Q-4: accepted the recommendation, (a) A spike in a new `spikes/refusal-fallback/` directory, which has no tests, as spikes don't. It runs two turns through `runAgentTurn` with the in-memory repositories, the clinic fixture and a synthetic patient. Turn 1 runs live on the chosen profile. In turn 2, a wrapper `LlmClient` returns `scriptedRefusal()` for the first call and sends every later call to Bedrock through `ConverseLlmClient`, so the loop retries on `fallbackProfileFor(chosen)` with turn 1's history in the request. "Confirmed" means turn 2 ends with outcome `completed` on the fallback's model ID. The PR shows the trace: each call's model ID and stop reason, and the outcome. `REFUSAL_FALLBACKS` stays as is unless Nick decides otherwise in the PR. Scope: adds a spike. Owned paths: + `spikes/refusal-fallback/`
- Q-5: accepted the recommendation, (a) The winning level becomes the plain profile's level. The agent changes that profile's `modelFields` in `profiles.ts` and its `EFFORT_SWITCHES` `default` in `matrix.ts` together, and updates the cell names the matrix test expects. Every later run of that profile name uses the new level, and its baseline is recorded at that level. Scope: adds the matrix module. Owned paths: + `packages/evals/src/matrix.ts`, `packages/evals/test/matrix.test.ts`
- Q-6: accepted the recommendation, (a) The choice doesn't wait. It uses each cell's rows as the matrix computes them: the rubric average before calibration, and agreement as pending #159. The ADR-002 amendment says so. If #159's recalibration later puts the chosen profile's rubric below 4.0, that is recorded on #159 and the choice is revisited there. Scope: within the issue
- owned path added: `CLAUDE.md`
- owned path added: `services/api/src/lib/config.ts`
- owned path added: `docs/architecture.md`
- owned path added: `spikes/refusal-fallback/`
- owned path added: `packages/evals/src/matrix.ts`
- owned path added: `packages/evals/test/matrix.test.ts`

**Not applied:**
- E-1 (Add the files the criteria and the deferred notes require to the owned paths): its Before text is not in the description any more; not applied
- E-2 (Correct the stale "#49 tracks them"): its Before text is not in the description any more; not applied
- E-3 (#107 has landed, so the "otherwise" branch can't happen): its Before text is not in the description any more; not applied
- E-4 (The simulator's default is already settled by #108): its Before text is not in the description any more; not applied
- E-5 (Make the report criterion testable: where the summary lives and what it links): its Before text is not in the description any more; not applied
- E-6 (Make the two notes deferred from PR #229 acceptance criteria): its Before text is not in the description any more; not applied
- E-7 (Add the Verification section the issue template requires): its Before text is not in the description any more; not applied
- E-8 (Add non-goals, so the run doesn't grow into neighbouring work): its Before text is not in the description any more; not applied

**Still open** (each needs its own `Decision` line):
- nothing
