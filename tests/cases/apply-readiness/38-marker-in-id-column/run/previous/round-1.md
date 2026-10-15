<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

**Issue:** #38 [M3-03] Observability: Powertools logs/metrics/traces, dashboard, trace viewer · **Read at:** 2026-10-13 21:20 UTC · **Default branch:** `main` @ `e4f6510`

The issue asks for six things in the API Lambdas:
- Powertools logging, metrics and tracing;
- a CloudWatch dashboard that shows NFR-001 latency, tokens and errors;
- a report when an escalation's status write fails;
- a `BookingConflictRetries` metric;
- a decision on who the failed-notification alarm tells;
- a `scripts/trace.ts` viewer.

The chat handler's one "chat turn" log line per turn already holds nearly every figure. What needs settling is design: where the metrics come from and what each widget counts, whether the log line may change shape, how far tracing goes, and who the alarm tells. The SNS option for the alarm needs a bootstrap change that only Nick can deploy.

Round: 1 · Questions: 7 · Assumptions: 9 · Suggested edits: 4 · Spec commit: e4f65109be79ab87618ec4485914b2efffca0a92 · Harness version: 2026.10.11.1

**Check these first:** A-1, A-2

**To answer:** reply on this issue with one line per item, in the form shown under each (`Decision r1/<ID>: <answer>`): an option's letter or your own words for a question, "accept" or "reject" for an edit, "ok" or your correction for an assumption. To take every recommendation and edit at once, `Decision r1/ALL: accept`; it does not cover the assumptions under "Check these first" or those marked "(verify first)" or "(would have asked)", which each need their own line. Only `Decision` lines are applied, never other replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: When #35's failed-notification alarm fires, who is told?

- **Why it matters:** an SNS action can't be deployed through `scripts/deploy.sh` today.
  - The CloudFormation execution role's service list has no `sns:*`: `infra/bootstrap/bootstrap.yaml:111-127` lists apigateway through xray, and SNS isn't among them.
  - Changing the bootstrap stack is Nick's to do. CLAUDE.md, "AWS rules": "Ask before … anything touching the bootstrap stack".
  - An email subscription needs a confirmation click, which adds a manual exception.
  - An agent that picks SNS gets stuck at the deploy. One that picks the dashboard alone without your word fails the criterion, which asks for a decision.
- **Source:** issue AC6, "Decide who is told when #35's failed-notification alarm fires (owner decision `ba2afda/SPEC-3` (c) on PR #131). … Options include an SNS topic with an email subscription to the verified identity, passed through the `NoEcho` parameter path and never from a committed file, or the dashboard alone." Also `docs/adr/0003-iac-layout.md:87`: "with no alarm action (#38 decides actions with its dashboard)".
- **Options:** (one per line)
  - (a) Dashboard only: the alarm keeps no action and only changes state, and the dashboard shows its state beside the `Sched/NotificationFailed` widget; the PR records the choice, and an ADR-003 amendment says #38 chose no action. Scope: within the issue. Owned paths: + `docs/adr/0003-iac-layout.md`
  - (b) An SNS topic, created only when SES is configured (the stack's `SesConfigured` condition), with one email subscription whose endpoint is the existing `SesStaffRecipient` NoEcho parameter (no new parameter, secret or `scripts/deploy.sh` change), set as the alarm's `AlarmActions`; Nick first adds the SNS actions to the CFN execution role in `infra/bootstrap/bootstrap.yaml` and deploys the bootstrap stack; the recipient confirms the subscription by email, which is added to the runbook's manual-exceptions table and CLAUDE.md's list; ADR-003 and ADR-009 get amendments. Scope: adds a bootstrap change and a manual step. Owned paths: + `infra/bootstrap/bootstrap.yaml`, + `scripts/bootstrap-template.test.ts`, + `docs/runbooks/aws-setup.md`, + `CLAUDE.md`, + `docs/adr/0003-iac-layout.md`, + `docs/adr/0009-safety-and-privacy.md`
  - (c) An SNS topic with one email subscription to a separate operator address in a new `NoEcho` parameter `AlarmEmail`, set as the alarm's `AlarmActions`; `scripts/deploy.sh` passes it from the environment or `.env`, and the deploy workflow from a new repository secret Nick sets; Nick first adds the SNS actions to the CFN execution role in `infra/bootstrap/bootstrap.yaml` and deploys the bootstrap stack; the confirmation click is added to the runbook's manual-exceptions table and CLAUDE.md's list; ADR-003 and ADR-009 get amendments. Scope: adds a bootstrap change, a manual step, a GitHub secret, and a change to `scripts/deploy.sh`, which #257 owns. Owned paths: + `infra/bootstrap/bootstrap.yaml`, + `scripts/bootstrap-template.test.ts`, + `scripts/deploy.sh`, + `scripts/deploy.test.ts`, + `.github/workflows/deploy.yml`, + `.env.example`, + `docs/runbooks/aws-setup.md`, + `CLAUDE.md`, + `docs/adr/0003-iac-layout.md`, + `docs/adr/0009-safety-and-privacy.md`
- **Makes stale:** these lines, by option:
  - `docs/adr/0003-iac-layout.md:87` (every option: "#38 decides actions" is then decided)
  - `docs/runbooks/aws-setup.md:187-198` ((b) and (c): the manual-exceptions table)
  - `CLAUDE.md:105` ((b) and (c): the manual-exceptions list)
  - `docs/adr/0009-safety-and-privacy.md:72-75` ((b) and (c): where the addresses go)
  - `infra/stacks/api.yaml:160-165` ((b) and (c): the alarm's comment)
- **Edges:** settled as follows:
  - An env deployed without SES addresses gets no action under every option: no topic under (b), and no address under (c) unless `AlarmEmail` is set.
  - A redeploy with an unchanged address keeps the confirmed subscription. A changed address creates a new subscription, which waits for its own confirmation.
  - Every merge to `main` redeploys `all dev` (`.github/workflows/deploy.yml:87-90`), so the address must arrive on every deploy or the parameter falls back to its default. Under (b) it arrives through the `SES_STAFF_RECIPIENT` secret, which is already passed there. Under (c) the new secret has to be passed there too.
  - The evidence under (a) is the PR's statement and the ADR-003 amendment. Under (b) or (c) it is a template test asserting `AlarmActions`, plus a journal note that the subscription was confirmed, without quoting the address.
- **Recommendation:** (a). It stays within the issue and needs no bootstrap change (`bootstrap.yaml:111-127` has no SNS actions). An email action can come later as its own issue once the bootstrap change is planned.
- **Reply:** `Decision r1/Q-1: (a)`

#### Q-2: Where do the dashboard's per-turn figures come from?

- **Why it matters:** every figure the dashboard needs for a turn lives in one place, the "chat turn" log entry (`services/api/src/lib/chat-turn.ts:210-225`):
  - `firstTextMs` is set at `chat-turn.ts:515-517`;
  - `usage` and `tools[]` are set at `chat-turn.ts:535-558`.

  That file isn't an owned path. The `ChatTurnSummary` returned to `services/api/src/lib/lambda.ts:42` holds no timings or usage. The choice decides whether `chat-turn.ts` changes, and whether NFR-007's "CloudWatch metrics for latency, tokens, errors" (`docs/PRD.md:129`) is met as written.
- **Source:** issue AC2, "CloudWatch dashboard: turn latency p50/p95, TTFT, tokens, cache reads, errors, tool error rate"; AC1, "Lambda Powertools logger/metrics/tracer". The owned paths leave out `chat-turn.ts`.
- **Options:** (one per line)
  - (a) A `Logger` decorator in `services/api/src/lib/observability/` passes every entry on unchanged and, for the entry whose `msg` is `"chat turn"`, writes that turn's metrics (Q-3) as one EMF record; `chat-turn.ts` doesn't change; a test in `services/api/test/` runs a turn through `handleChatTurn` with the decorator, so renaming the entry or one of the fields it reads fails that test. Scope: within the issue.
  - (b) `ChatTurnDeps` gains an optional metrics sink that `chat-turn.ts` calls once per turn with typed figures, and the chat handler passes the sink that writes the EMF record; the log entry is unchanged. Scope: adds a change to the turn core. Owned paths: + `services/api/src/lib/chat-turn.ts`
  - (c) No new per-turn metrics: the dashboard's latency, TTFT, token, error and tool widgets are Logs Insights query widgets over the "chat turn" lines, and the only EMF metrics are `BookingConflictRetries` and `NotificationFailed`; NFR-007's "CloudWatch metrics for latency, tokens, errors" is then not met as written, and each dashboard view runs the queries, which are billed per GB scanned. Scope: within the issue (falls short of NFR-007).
- **Makes stale:** nothing. Every option leaves the entry's fields as they are.
- **Edges:** settled as follows:
  - Under (a), the population rules of Q-3 are applied by reading the entry's `replayed`, `terminal`, `firstTextMs` and `usage`.
  - Under (a) and (b), a turn that lacks a figure (for example, one rejected before any model call) emits no value for that metric, rather than a zero.
  - The EMF record is always its own raw stdout line, never a field of the log entry (A-4).
  - The evidence is the test in `services/api/test/` that names the decorator (a) or the sink (b).
- **Recommendation:** (a). It stays inside the owned paths and reads the same per-turn record that #37's NFR-001 reading used (`docs/adr/0002-model-and-bedrock-client.md:198`, "Read with Logs Insights on the chat function's 'chat turn' lines").
- **Reply:** `Decision r1/Q-2: (a)`

#### Q-3: What does each dashboard metric count, and with which dimensions?

- **Why it matters:** the issue names the widgets but not their statistics, which turns they include, or their dimensions. Those choices set the metric names the code emits and the template test pins, so a wrong guess means another round on code, template and tests. The dimensions also set the number of custom metrics, which counts against NFR-003's idle budget ("Idle ≤ $5/month", `docs/PRD.md:125`).
- **Source:**
  - AC2;
  - AC3, "not the first event of any kind, so a status chip doesn't count";
  - NFR-001 (`docs/PRD.md:123`);
  - the only precedent: `Sched/NotificationFailed` with dimension `Env` (`packages/tools/src/notify/ses.ts:27-31`).
- **Options:** (one per line)
  - (a) Namespace `Sched`, dimension `Env`, one EMF record per chat turn: `Turns` (1 per turn); `TurnErrors` (1 per turn ending `error`, also under the dimension set `Env`+`ErrorCode`, the five `ChatErrorCode` values); `TimeToFirstTextMs` (`firstTextMs`, for non-replayed turns that wrote a `text_delta`); `TurnLatencyMs` (`totalMs`, for non-replayed turns ending `done`); `InputTokens`, `OutputTokens`, `CacheReadTokens`, `CacheWriteTokens` (the turn's `usage`, for non-replayed turns that called a model); `ToolCalls` (calls in the turn) and `ToolErrors` (calls with `ok: false`, any code, also under `Env`+`ErrorCode`); widgets show TTFT and turn latency at p50 and p95, tokens and cache reads as sums per period, `TurnErrors` by code beside `AWS/Lambda` `Errors` for both functions, and tool error rate as the metric-math ratio `ToolErrors / ToolCalls`; about 20 custom metrics per env. Scope: within the issue.
  - (b) Namespace `Sched`, one EMF record per chat turn, with the same metric names, populations and widgets as the `Env`-only catalog (`Turns`, `TurnErrors`, `TimeToFirstTextMs`, `TurnLatencyMs`, the four token sums, `ToolCalls`, `ToolErrors`), but with a `ModelProfile` dimension added to the latency and token metrics and a `Tool` dimension added to `ToolCalls` and `ToolErrors`, so profiles and tools can be compared on one env; about 60–80 custom metrics per env while traffic flows. Scope: within the issue.
- **Makes stale:** nothing.
- **Edges:** settled as follows:
  - **Turns outside the latency and token figures:**
    - Replays (`replayed: true`, `chat-turn.ts:354-362`) count only in `Turns`.
    - Daily-cap rejections and 400s make no model call, so they count only in `Turns` and `TurnErrors`.
    - An `error` turn that streamed text before it failed gives a `TimeToFirstTextMs` but no `TurnLatencyMs`.
  - **Dimensions:** IDs are never dimensions, only EMF properties.
  - **What the error codes can't separate:** `RATE_LIMITED` covers both the daily cap and Bedrock throttling (`services/api/src/lib/errors.ts:24-25`), so the code split doesn't tell them apart.
  - **Fallback tokens:** a refusal fallback's `haiku-4.5` tokens add into the turn's `usage`.
  - **Invented tools:** a call to a tool that doesn't exist (`known: false`) counts in `ToolCalls`, and in `ToolErrors` under `NOT_FOUND`.
  - **The list is complete.** Besides these widgets, the dashboard shows only `NotificationFailed` (AC5) and `BookingConflictRetries` (Q-6).
  - **#251:** its unanswered option (c) would count the `status` event towards NFR-001. If it's chosen, TTFT changes in #251, not here.
  - **Evidence:**
    - a template test naming each widget's metric;
    - a test of the EMF record for a `done` turn, a replayed turn and an `error` turn.
- **Recommendation:** (a). One `Env` dimension follows the `NotificationFailed` precedent (`ses.ts:27-31`) and keeps the custom-metric count small for NFR-003. Each env runs one profile (`AgentModelProfile`, `infra/stacks/api.yaml`), so a profile dimension adds little.
- **Reply:** `Decision r1/Q-3: (a)`

#### Q-4: May the log lines change shape when the Powertools Logger comes in?

- **Why it matters:** today each entry goes through `console.*`, and with `LogFormat: JSON` the runtime nests it under `message` (`services/api/src/lib/log.ts:20-23`). Two things read that shape:
  - #37's NFR-001 method filters on `message.modelProfile` (`docs/adr/0002-model-and-bedrock-client.md:198`);
  - #251 plans to re-run "the Logs Insights query in the #37 comment".

  A Powertools Logger writes its own JSON line, with its own keys and `message` holding the text (verify first). That query, and the `console.info` spy in `services/api/test/chat-handler.test.ts:152`, would then stop matching.
- **Source:** issue AC1, "replacing or wrapping the existing structured logger (`services/api/src/lib/log.ts`, `consoleLogger`, used by both handlers)".
- **Options:** (one per line)
  - (a) Wrap: a Powertools `Logger` writes the entries behind the existing `Logger` type (`log.ts:16`), so the log calls in `chat-turn.ts` and `session.ts` and their field names don't change; the entry's `msg` becomes the line's `message`, and Powertools adds its keys (cold start, the Lambda request ID, the X-Ray trace ID when tracing is on); `consoleLogger` is removed from `log.ts` and `index.ts`; if the lines are no longer nested under `message`, the PR amends ADR-002's NFR-001 reading line with the new Logs Insights query and quotes it in the PR body for #251. Scope: within the issue. Owned paths: + `services/api/src/index.ts`, + `docs/adr/0002-model-and-bedrock-client.md`
  - (b) Keep `consoleLogger` as the writer, with no Powertools Logger: the observability adapter adds the Lambda request ID and cold start to each entry, and Powertools is used for metrics (and tracing, per Q-5); the log shape and #37's query stay as they are, and AC1's "logger" is met by the existing structured logger. Scope: within the issue (narrows AC1).
  - (c) Replace: `chat-turn.ts` and `session.ts` log through the Powertools Logger's own API and key names, and `consoleLogger` is removed; the PR amends ADR-002's NFR-001 reading line with the new Logs Insights query and quotes it in the PR body for #251. Scope: adds the turn and session cores. Owned paths: + `services/api/src/lib/chat-turn.ts`, + `services/api/src/lib/session.ts`, + `services/api/src/index.ts`, + `docs/adr/0002-model-and-bedrock-client.md`
- **Makes stale:** these lines, by option:
  - `services/api/src/lib/log.ts:20-23` ((a), (c))
  - `services/api/src/index.ts:21` ((a), (c))
  - `services/api/test/log.test.ts:38-53` ((a), (c))
  - `services/api/test/chat-handler.test.ts:147-155` ((a), (c): asserts `console.info`)
  - `services/api/src/handlers/chat.ts:37,98` ((a), (c))
  - `services/api/src/handlers/session.ts:12,18` ((a), (c))
  - `docs/adr/0002-model-and-bedrock-client.md:198` ((a) if the nesting changes; (c))
- **Edges:** settled as follows:
  - AC1's rule ("IDs, timings, counts and token usage, never message text") holds under every option, Powertools' own keys included. Logging the Lambda event or the request body stays off.
  - The eval harness keeps `silentLogger` under every option.
  - `spikes/s2-streaming/measure.ts:194-205` already reads a field the log no longer writes (`firstDeltaMs`), so no option makes it newly stale.
  - The evidence of the shape is a test that reads the written line. Under (a) or (c), the new query is also quoted in the PR.
- **Recommendation:** (a). The criterion names a Powertools logger, and wrapping keeps every call site and field name behind the existing seam (`log.ts:16`), so only the query text may need updating.
- **Reply:** `Decision r1/Q-4: (a)`

#### Q-5: What does the tracer cover?

- **Why it matters:**
  - X-Ray needs `Tracing: Active` in `infra/stacks/api.yaml`, which has none today. That goes beyond "(the dashboard only)".
  - The DynamoDB client is created in `services/api/src/lib/aws.ts:22`, which isn't owned.
  - By default, the Powertools Tracer's method capture records return values and errors (verify first). That would put model replies or patient text into X-Ray.
  - ADR-009's "not message text" covers CloudWatch logs only (`docs/adr/0009-safety-and-privacy.md:23`).
- **Source:** issue AC1, "Lambda Powertools logger/metrics/tracer"; Goal, "per-turn agent traces".
- **Options:** (one per line)
  - (a) X-Ray on the chat function only: `Tracing: Active` on `ChatFunction`; the Powertools Tracer captures the Bedrock client (passed through `ConverseLlmClient`'s `client` option, `packages/agent/src/llm/converse.ts:69-71`), the DynamoDB client (in `aws.ts`) and the SES client (`sesNotifierFromEnv`'s client argument); response and error capture are off; no method decorators on the agent loop or the tools, and no custom subsegments or annotations. Scope: within the issue with E-1 (`aws.ts`).
  - (b) X-Ray on both functions (`Tracing: Active` in `Globals`): the Powertools Tracer captures the Bedrock, DynamoDB and SES clients in the chat function and the DynamoDB client in the session function; response and error capture are off; no method decorators, custom subsegments or annotations; the session bundle then carries the X-Ray SDK. Scope: within the issue with E-1 (`aws.ts`).
  - (c) No X-Ray: "tracer" in AC1 means the per-turn DynamoDB trace (FR-051), which already ships, read through `scripts/trace.ts`; no Powertools Tracer is added, and AC1's wording drops "tracer". Scope: within the issue (narrows AC1).
- **Makes stale:** nothing. `grep -rni "x-ray\|xray" docs/` outside the journal has no hits, so no doc describes tracing today.
- **Edges:** settled as follows:
  - X-Ray's default sampling applies, so not every turn has an X-Ray trace. The DynamoDB trace (FR-051) stays the per-turn record.
  - Powertools' handler wrapper may not apply to a `streamifyResponse` handler (A-5). Capturing the SDK clients doesn't need it.
  - The permissions boundary already allows `xray:PutTraceSegments` and `xray:PutTelemetryRecords` (`infra/bootstrap/bootstrap.yaml:52-53`), and the CFN execution role has `xray:*` (`:126`), so no bootstrap change is needed.
  - The evidence is a template test for `Tracing: Active`, and a trace on `dev` with Bedrock and DynamoDB subsegments, named in the PR by its trace ID.
- **Recommendation:** (a). The chat function is where a turn's time goes: three model calls before the first text (ADR-002, 2026-10-12 amendment). The session function makes no model call (`services/api/src/handlers/session.ts:4`).
- **Reply:** `Decision r1/Q-5: (a)`

#### Q-6: Which retries does `BookingConflictRetries` count?

- **Why it matters:** `retrying` (`packages/tools/src/repos/dynamo/repositories.ts:116-124`) serves `book` (:283), `reschedule` (:357) and the conversation append (:518). In `book` it also retries after a `ConditionalCheckFailed` whose re-read finds the slot `OPEN` (:335), which isn't a `TransactionConflict`. Where the hook sits decides what the number means, and it's the number used to tune `MAX_ATTEMPTS`.
- **Source:** issue AC7, "counts the re-attempts of booking transactions cancelled only by `TransactionConflict` (the `retrying` loop and `MAX_ATTEMPTS` in `packages/tools/src/repos/dynamo/repositories.ts`)".
- **Options:** (one per line)
  - (a) Count at the `isConflictOnly(codes)` branches of `book` and `reschedule` only (`repositories.ts:337` and `:468`), one count per conflict-only cancellation, as `BookingConflictRetries` with dimension `Env`; the conversation append's conflicts and `book`'s re-read retry are not counted. Scope: within the issue.
  - (b) Count at all three `isConflictOnly(codes)` branches (`:337`, `:468`, `:535`), one count per conflict-only cancellation, in one metric named `TransactionConflictRetries` with the dimension sets `Env` and `Env`+`Operation` (`book`, `reschedule`, `append`). Scope: within the issue (renames the criterion's metric).
  - (c) Count inside `retrying` on every `RETRY` result of all three callers, `book`'s re-read retry included, as `BookingConflictRetries` with dimension `Env`. Scope: within the issue.
- **Makes stale:** nothing. The header's retry bullet (`repositories.ts:9-10`) stays true under every option.
- **Edges:** settled as follows:
  - The loop's last attempt still returns `RETRY` and backs off before it gives up (`:118-122`). So a call that runs out of attempts records 5 counts, and one that succeeds on attempt k records k−1. The count is per cancellation, not per call.
  - Running out of attempts isn't a separate metric. `book` then throws (`:342`), which reaches the tool as `INTERNAL` and counts in Q-3's `ToolErrors`. `reschedule` returns `CONFLICT` (`:472`).
  - `batchWrite` has its own wait and isn't covered (journal 2026-10-07: "#38's hook on `retrying` doesn't cover `batchWrite`").
  - The in-memory repositories never conflict, so they get no hook. The hook defaults to a no-op, so `scripts/retry-escalations.ts:277` doesn't change.
  - The evidence is the injected-`TransactionConflict` test in `packages/tools/test/dynamo/dynamo.test.ts:269-301` (E-1), extended to see the hook called twice for two injected cancellations.
- **Recommendation:** (a). It is what the criterion's words describe ("booking transactions cancelled only by `TransactionConflict`"), and it answers the journal's question for bookings (`docs/journal/2026-09-29-dynamodb-local-is-too-polite.md:34`).
- **Reply:** `Decision r1/Q-6: (a)`

#### Q-7: What does `scripts/trace.ts` take and print?

- **Why it matters:**
  - A stored trace's tool calls carry their inputs (`packages/contracts/src/trace.ts:46`), and those are patient free text (`services/api/src/lib/log.ts:3-4`).
  - The conversation's messages share the trace's partition (`CONV#<id>`).
  - The repo is public, so output pasted into an issue or PR would carry that text.
  - The CLI, how the table is chosen, and what happens when there's no trace are all unspecified, and they decide the tests.
- **Source:** issue AC8, "`scripts/trace.ts <conversationId>` prints a turn-by-turn trace from DynamoDB". ADR-009: "Per-turn traces live in DynamoDB (with TTL) for authorized inspection" (`docs/adr/0009-safety-and-privacy.md:51`).
- **Options:** (one per line)
  - (a) `npx tsx scripts/trace.ts <env> <conversationId> [--table <name>] [--json] [--inputs]`: the table comes from SSM `/sched/<env>/data/table-name` unless `--table` is given; it reads only the `TRACE#` items under `CONV#<conversationId>`, never messages; turns are sorted by `startedAt`; each turn prints its turn ID, start time, outcome, model profile, prompt version, iterations, duration and usage (cache reads included), each model call's model ID, stop reason, TTFT, duration and usage, and each tool call's name, ok, error code and duration; tool inputs print only with `--inputs`; no patient ID; `--json` prints one JSON object per turn with the same fields; with no traces it says so on stderr and exits 1. Scope: within the issue with E-1 (`scripts/trace.test.ts`).
  - (b) `npx tsx scripts/trace.ts <env> <conversationId> [--table <name>]`: the table comes from SSM `/sched/<env>/data/table-name` unless `--table` is given; it reads only the `TRACE#` items under `CONV#<conversationId>`, sorted by `startedAt`, and prints each stored `TurnTrace` in full as JSON, tool inputs included; with no traces it says so on stderr and exits 1. Scope: within the issue with E-1 (`scripts/trace.test.ts`).
- **Makes stale:** nothing.
- **Edges:** settled as follows:
  - **No traces.** An unknown conversation, one whose traces have expired (30-day TTL, `TRACE_TTL_DAYS`, `services/api/src/lib/dynamo-turn-store.ts:20`) and one with no traces all look the same, and all exit 1.
  - **Missing turns.** Replayed turns, and turns whose trace save failed (`chat-turn.ts:468-476`), have no trace and are simply absent.
  - **An unreadable item.** An item whose `trace` doesn't parse as `TurnTrace` prints its turn ID as unreadable, and the script exits 1 once the rest have printed.
  - **The query.** It pages through results with `begins_with(SK, "TRACE#")`, so message items are never read.
  - **Checking `<env>`.** Before any AWS call it rejects an `<env>` such as `../x` and accepts `dev`.
  - **Evidence.** `scripts/trace.test.ts` with an injected client, covering a two-turn conversation printed in `startedAt` order and the exit 1 with no traces.
- **Recommendation:** (a). Output limited to IDs and figures follows ADR-009 and the operator-script precedent ("Output is ids and statuses only (ADR-009)", `scripts/retry-escalations.ts:20`), and `--inputs` keeps the authorized inspection that ADR-009:51 allows.
- **Reply:** `Decision r1/Q-7: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The agent reads TTFT from the existing `firstTextMs` and turn latency from the existing `totalMs` of the "chat turn" entry (only for turns ending `done`). Both are timed from the handler's start (`#t0`, `services/api/src/lib/chat-turn.ts:193`). The agent doesn't move the zero point to API Gateway's `requestTimeEpoch`, which would include API Gateway, the authorizer and cold start, and doesn't add a separate `doneMs`. | ADR-007, 2026-10-05 amendment: "`firstTextMs` stays the time to first token (NFR-001)" (`docs/adr/0007-chat-transport.md:163`). #37 read NFR-001 from these lines (`docs/adr/0002-model-and-bedrock-client.md:196-198`). Journal 2026-10-05: "#38 measures time to first token with `firstTextMs`" (`docs/journal/2026-10-05-name-the-conversation-before-the-agent-runs.md:59`). AC3 says "from the API receiving `POST /api/chat`", which the handler's start only approximates. | nothing | `Decision r1/A-1: <your correction>` |
| A-2 | The agent extends `withNotificationFailedMetric` in `services/api/src/handlers/chat.ts`. That place is **required**: it is the only wrapper around the chat function's `updateNotification` (`chat.ts:50-75`). When `updateNotification` throws or returns `null`, it writes one error-level log entry (the name `"notification status write failed"` is a suggestion). The entry carries `conversationId`, the attempted status and, for a throw, `errorSummary`. It carries no `patientId`, since no log line carries one today, and no `escalationId`, which isn't known on a throw. The wrapper then rethrows the error or returns the `null`, so the tool still swallows it (`packages/tools/src/tools/escalate_to_human.ts:79-83`). It writes no `Sched/NotificationFailed` record. | `chat.ts:18-19` defers both cases: "a write that throws or finds no record writes none (reporting those is #38's)". #36 r1/Q-1 (a): "Exactly one record per FAILED escalation". PR #68, SMELL-1 (a): the swallow stays in the tool. AC4 allows "a metric or a log entry with IDs only". Outside the repositories, `updateNotification(` is called only at `escalate_to_human.ts:80`, `chat.ts:62` and `scripts/retry-escalations.ts:118`. The script uses its own undecorated repos, so it doesn't change. | `services/api/src/handlers/chat.ts:18-19` | `Decision r1/A-2: <your correction>` |
| A-3 | The agent adds one optional callback to `DynamoRepositoryOptions` (`packages/tools/src/repos/dynamo/repositories.ts:86-95`; the name `onConflictRetry` is a suggestion), with a no-op default. `createAwsStores` (`services/api/src/lib/aws.ts:21-27`) passes the callback that counts the metric. That place is **required**: it's the only place the chat function builds its repositories, and E-1 adds it to the owned paths. Because the change touches `packages/tools/`, the PR's Eval gate runs the smoke suite on Bedrock, and the PR reports the result. | AC7, "reported through an injected hook so `packages/tools` stays pure (CLAUDE.md rule 3)". `scripts/eval-gate.ts:52-54` lists `packages/tools/` as gated. `createDynamoRepositories(` is called only in `aws.ts:24` and `scripts/retry-escalations.ts:277`. | nothing | `Decision r1/A-3: <your correction>` |
| A-4 (verify first) | Every EMF record must be a raw stdout line. Lambda's JSON log format wraps `console.*` output, and CloudWatch then doesn't read it as EMF. Before relying on Powertools Metrics, the agent checks whether it writes raw stdout under `LogFormat: JSON`, and pins the result with a test that reads the written line. If it doesn't, the agent asks before moving `emfFailureReporter`'s raw write out of `packages/tools`. The NotificationFailed assertions in the chat-handler test then filter by metric name. | `packages/tools/src/notify/ses.ts:70-73`. #36 r1/Q-4 (a) proved the raw line live. `LogFormat: JSON` is set at `infra/stacks/api.yaml:58,107`. | `services/api/test/chat-handler.test.ts:132-140` (`escalate()` treats every `"_aws"` stdout line as a NotificationFailed record; under Q-2 (a) or (b)) | `Decision r1/A-4: <your correction>` |
| A-5 (verify first) | Powertools' handler wrappers (`injectLambdaContext`, `logMetrics`, `captureLambdaHandler`) may not wrap an `awslambda.streamifyResponse` handler. The agent checks this. If they don't, it instruments a wrapper around the function `chatStreamHandler` returns, in `services/api/src/handlers/chat.ts` (a suggestion), and flushes metrics once per invocation. | `services/api/src/handlers/chat.ts:87-100`; `services/api/src/lib/lambda.ts:38-55` | nothing | `Decision r1/A-5: <your correction>` |
| A-6 | The "chat turn" entry already carries the API Gateway `requestId`, `conversationId` and `turnId` (`chat-turn.ts:210-225`). Error entries carry `requestId` only and join their turn through it. The agent leaves the log calls in `chat-turn.ts` as they are, unless Q-4 is answered (c), and adds the Lambda request ID to every entry through the adapter. | AC1, "with conversation/request IDs"; the owned paths leave out `chat-turn.ts` | nothing | `Decision r1/A-6: <your correction>` |
| A-7 | The session handler gets the same logger change as the chat handler, since both use `consoleLogger`, but no per-turn metrics. Its bundle still carries no agent loop or Bedrock client. | AC1, "used by both handlers"; `services/api/src/handlers/session.ts:4`; `services/api/test/session-bundle.test.ts:1-5` | nothing beyond Q-4's lines | `Decision r1/A-7: <your correction>` |
| A-8 | The agent records the decisions of this review in a journal entry and the PR, and writes no new ADR. An Accepted ADR changes by amendment only where a line becomes false: ADR-003:87 under Q-1, and ADR-002:198 under Q-4 (a) or (c). | CLAUDE.md, "Definition of done": "An ADR for any new or reversed significant technical decision"; "How work flows": "an Accepted ADR changes by amendment" | nothing | `Decision r1/A-8: <your correction>` |
| A-9 | The agent deploys the api stack to `dev`. Before running a few live `sonnet-4.6` turns to fill the widgets, it states what they will cost, then quotes the widgets in the PR. It doesn't re-run the 30-turn NFR-001 measurement. | CLAUDE.md, "Definition of done" (an infra change is "deployed to `dev` or the PR says why not") and "AWS rules" ("Say what a run will cost before any live run"); #251's second criterion re-measures after its change | nothing | `Decision r1/A-9: <your correction>` |

An assumption the review could not check, such as how an external library, service or platform behaves, is marked **(verify first)**. The agent establishes the behaviour before building on it and pins it with a test, so a wrong assumption fails loudly instead of silently.

### Suggested edits to the issue

#### E-1: Add to the owned paths the files the criteria can't be met without

Before:
```text
- `packages/tools/src/repos/dynamo/repositories.ts` (the conflict-retry hook only; call it out in the PR)
- `infra/stacks/api.yaml` (the dashboard only)
- `scripts/trace.ts`
```
After:
```text
- `packages/tools/src/repos/dynamo/repositories.ts` (the conflict-retry hook only; call it out in the PR)
- `packages/tools/test/dynamo/dynamo.test.ts` (the conflict-retry hook's test only)
- `services/api/src/lib/aws.ts` (passing the conflict-retry hook to `createDynamoRepositories`, and capturing the DynamoDB client for the tracer if tracing is chosen)
- `infra/stacks/api.yaml` (the dashboard, plus the tracing, Powertools environment and alarm settings the readiness answers choose)
- `scripts/trace.ts`, `scripts/trace.test.ts`
```
- **Reply:** `Decision r1/E-1: accept`

#### E-2: Say where the NFR-001 figures are read, and that this issue doesn't re-measure them

Before:
```text
NFR-001's targets (first `text_delta` ≤ 3 s p50, `done` ≤ 15 s p95, on the deployed stack with the production profile, over at least 30 turns) can be read from these metrics or the handler's logs.
```
After:
```text
When the api stack is deployed to `dev`, the dashboard's TTFT and turn-latency widgets show their p50 and p95 for that env, so NFR-001's targets (first `text_delta` ≤ 3 s p50, `done` ≤ 15 s p95, on the deployed stack with the production profile, over at least 30 turns) can be read from them or from the handler's "chat turn" log lines; the PR quotes the widgets after a few live turns. This issue doesn't re-run the 30-turn measurement: #37 measured it (ADR-002, 2026-10-12 amendment) and #251 re-measures after its change.
```
- **Reply:** `Decision r1/E-2: accept`

#### E-3: Name what is out of scope

Before:
```text
Unblocks: #45 (M4-03)
```
After:
```text
Unblocks: #45 (M4-03)

Out of scope: tuning `MAX_ATTEMPTS` (this issue only counts retries); latency work on the first `text_delta` (#251); alarms beyond #35's failed-notification alarm; a conflict-retry hook in the in-memory repositories, which never conflict; `batchWrite`'s own wait (journal 2026-10-07).
```
- **Reply:** `Decision r1/E-3: accept`

#### E-4: Add the template's Verification section

Before:
```text
## References
```
After:
```text
## Verification
- `npm run lint && npm run typecheck && npm test`, and the `npm run mutate -- … --markdown` table in the PR body for each changed source file.
- `sam validate --lint -t infra/stacks/api.yaml --region us-east-1`, and the api stack deployed to `dev` (CLAUDE.md, definition of done).
- The Eval gate runs on this PR, since it changes `packages/tools/` (`scripts/eval-gate.ts`); its result goes in the PR.

## References
```
- **Reply:** `Decision r1/E-4: accept`

### Reuse, dependencies and risks

- **Reuse:**
  - Import `NOTIFICATION_FAILED_METRIC` from `@sched/tools/ses` (`packages/tools/src/notify/ses.ts:27-31`) for the `NotificationFailed` widget and its template test.
  - Import `Logger`, `LogEntry` and `errorSummary` from `services/api/src/lib/log.ts` (:10-45) for the observability adapter (Q-2) and A-2's entry.
  - Extend `withNotificationFailedMetric` in `services/api/src/handlers/chat.ts:50-75` (owned) for A-2.
  - Import `TurnTrace` from `@sched/contracts` (`packages/contracts/src/trace.ts:72-86`) to parse stored traces in `scripts/trace.ts`.
  - Import `ssmParamFrom`, `ssmClientFor` and `dynamoClientFor` from `scripts/seed-data.ts` (:357-380) for the table lookup and the DynamoDB Local endpoint.
  - Import the template-text helpers from `scripts/test/yaml-text.ts` for the dashboard and tracing template tests in `services/api/test/api-template.test.ts`.
  - `turnKeys` (`services/api/src/lib/dynamo-turn-store.ts:27-33`) can't be reached from `scripts/` today: `@sched/api` exports only `src/index.ts`, which keeps the DynamoDB SDK out (`services/api/src/index.ts:4-7`). Add a `./dynamo-turn-store` subpath export to `services/api/package.json` (owned) and import `turnKeys` from it.
  - Under A-4: if Powertools Metrics output is wrapped, ask before moving `emfFailureReporter`'s raw stdout write (`ses.ts:74-81`) out of `packages/tools`.
- **Dependencies:**
  - #36 (blocker) is closed; its decorator, raw-stdout EMF and `SCHED_ENV` are merged.
  - #35 is closed (PR #131 merged); PR #68 is merged.
  - Under Q-1 (b) or (c): a bootstrap-stack change by Nick before the api deploy.
- **Overlaps:** no open PRs (`gh pr list --state open` returned none).
- **Size:** about 1,100–1,500 changed lines, at the split threshold. A clean split: `scripts/trace.ts` (AC8) as its own PR first. It shares no code with the rest and isn't an Eval-gated path. Everything else stays together.
- **Sibling issues:**
  - #251 (open, backlog) touches NFR-001's TTFT. Its unanswered option (c) would count the `status` event, against AC3's "a status chip doesn't count". Its second criterion re-runs "the Logs Insights query in the #37 comment", which Q-4 (a) or (c) may change.
  - #257 (open, ready) owns `scripts/deploy.sh`, which Q-1 (c) would touch. It has no decisions yet.
  - #39 (open, backlog) will review the IAM and log content this issue adds.
  - #42 (open, backlog) owns `scripts/**` and `docs/runbooks/**`. It has no decisions.
  - #45 (open) reads this issue's dashboard.

**Relied on:**
- `docs/PRD.md` "NFR-001", "NFR-003", "NFR-007", "FR-051"
- `docs/adr/0002-model-and-bedrock-client.md` "Amendment (2026-10-12): production profile (#37)"
- `docs/adr/0007-chat-transport.md` "Amendment (2026-10-05): name a new conversation before the agent runs (#160)"
- `docs/adr/0003-iac-layout.md` "Amendment (2026-10-04): the SES grant and parameters as built (#35)"
- `docs/adr/0009-safety-and-privacy.md` "Decision", "Consequences", "Amendment (2026-10-04): the SES grant as built (#35)"
- `CLAUDE.md` "Architecture rules (non-negotiable)" (rule 3), "AWS rules", "How work flows" (Eval gate), "Definition of done"
- `docs/runbooks/aws-setup.md` "Documented non-CloudFormation exceptions"
- #36 "Decisions and clarifications" r1/Q-1, r1/Q-4
- PR #68 decision SMELL-1 (a)
- `docs/journal/2026-09-29-dynamodb-local-is-too-polite.md` "What's next"
- `docs/journal/2026-10-05-name-the-conversation-before-the-agent-runs.md`
- `docs/journal/2026-10-07-three-rules-each-written-once.md` "What's next"

<details>
<summary>What was checked</summary>

**Requirements** (issue description at `e4f6510`):
- R-1, AC1 (Powertools logger, metrics and tracer, with IDs, no message text): partly testable. "No message text" and "carries IDs" can be asserted on the written line. "Replacing or wrapping" and "tracer" have no observable outcome until Q-4 and Q-5 are answered.
- R-2, AC2 (dashboard widgets): testable as a template test once Q-2 and Q-3 settle the names and statistics.
- R-3, AC3 (TTFT and turn latency): the definitions are testable at unit level (A-1). "Can be read" becomes observable with E-2.
- R-4, AC4 (failed `updateNotification` reported): testable. A-2 settles both the throw and the `null` case.
- R-5, AC5 (`NotificationFailed` on the dashboard): testable against `NOTIFICATION_FAILED_METRIC`.
- R-6, AC6 (alarm recipient): an owner decision (Q-1). It is testable as "the choice is recorded".
- R-7, AC7 (`BookingConflictRetries`): testable with the injected-conflict test once Q-6 places the hook.
- R-8, AC8 (`scripts/trace.ts`): testable once Q-7 sets the CLI and output.

**Sources read:**
- the brief, the format and the manifest;
- both analysts' outputs, read to their ends;
- `spec/issue-38.md` (all 55 lines) and `issue-body.md` (all 43 lines);
- `background/issue-36.md`, the decisions r1/Q-1 and r1/Q-4.

**Code checked at the cited lines:**
- `services/api/src/lib/log.ts`, `services/api/src/handlers/chat.ts`, `services/api/src/handlers/session.ts`, `services/api/src/lib/aws.ts`, `services/api/src/lib/lambda.ts`, `services/api/src/index.ts`;
- `services/api/src/lib/chat-turn.ts:175-235, 340-365, 395-565`, `services/api/src/lib/errors.ts:20-38`, `services/api/src/lib/dynamo-turn-store.ts:1-40`;
- `packages/tools/src/repos/dynamo/repositories.ts:1-20, 84-130, 320-345, 464-476, 514-545`;
- `packages/tools/src/notify/ses.ts:15-85`, `packages/tools/src/tools/escalate_to_human.ts:74-86`, `packages/contracts/src/trace.ts`;
- `infra/stacks/api.yaml:50-110, 155-185`, `infra/bootstrap/bootstrap.yaml:40-70, 105-175`;
- `scripts/deploy.sh:64-95`, `.github/workflows/deploy.yml:36-46, 84-92`, `scripts/retry-escalations.ts:1-47`, `scripts/eval-gate.ts:52-68`, `vitest.config.ts:1-20`, `services/api/Makefile`;
- `services/api/test/chat-handler.test.ts:20-40, 128-156, 228-252`, `services/api/test/api-template.test.ts:98-106`, `services/api/test/session-bundle.test.ts:1-30`, `packages/tools/test/dynamo/dynamo.test.ts:265-302`;
- `spikes/s2-streaming/measure.ts:165-210`.

**Docs checked:**
- `docs/PRD.md:99-146, 206-213`;
- ADR-002:190-206, ADR-003:85-88, ADR-007:160-165, ADR-009:20-25, 48-52, 68-78;
- `docs/runbooks/aws-setup.md:183-200, 236-246`;
- the journal lines cited above.

**Sibling issues:** #251 and #257, read with `gh issue view`. The states of #39 and #42 were checked.

**Searches run (read-only), with their output:**
- `grep -rn "updateNotification(" packages services scripts` (non-test): the repo definitions, `escalate_to_human.ts:80`, `chat.ts:61-62` and `scripts/retry-escalations.ts:118`. This is A-2's "stays as is".
- `grep -rn "createDynamoRepositories(" packages services scripts apps` (non-test): `repositories.ts:136` (the definition), `services/api/src/lib/aws.ts:24` and `scripts/retry-escalations.ts:277`. This is A-3's "only place".
- `grep -rn "consoleLogger"`: `log.ts:24`, `index.ts:21`, `chat.ts:37,98`, `session.ts:12,18`, `log.test.ts`. These are Q-4's stale lines.
- `grep -n "sns" infra/bootstrap/*.yaml infra/bootstrap/*.json`: no hits (Q-1).
- `grep -rni "x-ray\|xray" docs/` outside the journal: no hits (Q-5's "nothing").
- `grep -rn "#38"` in code: `infra/stacks/api.yaml:163`, `services/api/src/handlers/chat.ts:19`, `packages/evals/src/report/exit.ts:151,164`, `packages/tools/src/notify/ses.ts:26`.
- `gh pr list --state open`: empty.

**Analyst material dropped or corrected:**
- `spikes/s2-streaming/measure.ts:194-205` is not newly stale under any option. It already reads `firstDeltaMs`, which the current log line doesn't write.
- `services/api/test/api-template.test.ts:100-105` breaks only if `POWERTOOLS_*` variables go on the session function itself. A `Globals` variable doesn't break it, so it is left out of the stale lines.
- `packages/evals/src/report/exit.ts:164` ("the chat handler's logs (#38)") stays true under every option and isn't flagged. `exit.ts:151` names #38 for calibration, which is #159's. That is a pre-existing wrong pointer in an Eval-gated file, outside this issue, and noted here only.
- `docs/PRD.md:146` ("NFR-001 … met") is the §7 target column, not a status, so it doesn't conflict with ADR-002's "first text not met".
- The spec analyst's S-2 (the created date) was dropped. The file references are current.
- OB-6, OB-7 and OB-9 became assumptions (A-1, A-2), because a source settles each. OB-16 became A-9 plus E-2. OB-17 became A-8.

**Not checked:**
- How Powertools for TypeScript behaves under `LogFormat: JSON` and with `streamifyResponse`, and the Tracer's default capture. No package source or docs were available (A-4, A-5, Q-4, Q-5).
- CloudWatch custom-metric and dashboard pricing against NFR-003. The counts in Q-3 are estimates.
- The text of #37's Logs Insights query, which lives in an issue comment, not the repo.
- The commands E-4 prescribes (`npm run lint && npm run typecheck && npm test`, `sam validate --lint`, `npm run mutate`) build, test or validate, so they weren't run here (verify first).

</details>

