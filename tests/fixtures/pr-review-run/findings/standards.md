# Standards review: PR #70 (head d34b6df)

## 1. Findings

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
- **Why it matters:** The PR body's "Deferred / follow-ups" section lists two items with no issue link: "Consolidating the duplicated `ProviderSummary` mapper across tool files (planned after #19–#23 land)" and "The header comment in `test/registry.test.ts` (...) becomes stale as tools register. Not touched (outside owned paths)." This PR makes that header false: `TOOL_REGISTRY` now has two entries (`packages/tools/src/registry.ts:109-110`). With no issue behind either item, nobody owns fixing them once this PR merges. Leaving the header alone was correct, because the file is outside the owned paths. The gap is only the missing link.
- **Suggested fix:** Link an existing issue for each deferred item, or open one (the stale header can be a one-line chore; the mapper consolidation is the follow-up the issue #19 comment already plans), and put the links in the "Deferred / follow-ups" section.
- **Introduced by this PR:** yes
- **Action:** fix now

## 2. Coverage ledger

### Sources read
| Source | Why |
|---|---|
| `CLAUDE.md` (full, 130 lines) | standards: architecture rules, how work flows, definition of done, doc style |
| `.claude/skills/add-agent-tool/SKILL.md` (full) | standards the issue says to follow for tools |
| `.claude/skills/task-workflow/SKILL.md` (full) | process standards: owned paths, commits, PR body, journal |
| `.claude/skills/dev-journal/SKILL.md` (full) | journal template and voice |
| `.claude/agents/task-worker.md` (full) | subagent obligations (the issue was claimed by a task-worker) |
| `.github/pull_request_template.md` (full) | PR description format |
| `docs/adr/0004-data-model.md` (full) | access patterns AP-3/4/5, repository-layer entry point |
| `docs/adr/0009-safety-and-privacy.md` (full) | identity, data, untrusted-text rules |
| `docs/adr/0001-agent-runtime.md` (tool/caching lines via grep) | prompt-cache rule for tool definitions |
| `docs/adr/README.md` (full) | ADR index and template (no ADR added; owner decided none needed) |
| `docs/architecture.md` (full) | where tools code lives |
| `docs/PRD.md` (FR-030 lines) | traceability row for FR-030 |
| `docs/backlog.md` (S4-01 lines) | milestone/chapter for the journal entry |
| `README.md` (grep) | README-as-story rule (not touched by PR) |
| `packages/evals/scenarios/README.md` (lines 1-60) | eval scenario conventions; checked referenced ids exist |
| `docs/journal/README.md` (full) | journal convention; changed file |
| `packages/tools/src/tools/check_availability.ts` (full) | changed file |
| `packages/tools/src/tools/find_providers.ts` (full) | changed file |
| `packages/tools/src/registry.ts` (full) | changed file |
| `packages/tools/test/tools/check_availability.test.ts` (full) | changed file |
| `packages/tools/test/tools/find_providers.test.ts` (full) | changed file |
| `docs/journal/2026-09-30-a-past-date-is-an-error-not-an-empty-list.md` (full) | changed file |
| `packages/contracts/src/clinic.ts`, `packages/contracts/src/__snapshots__/tools.test.ts.snap` (diff hunks) and `packages/contracts/src/tools.ts:166-170,226` | changed contract files; check the constant flows into schema and description |
| `packages/tools/src/clock.ts` (header, exports, lines 200-230) | sibling (src): header-comment convention; helpers used |
| `packages/tools/src/repos/in-memory.ts`, `packages/tools/src/repos/types.ts` (headers, method signatures) | siblings (src): header-comment convention; repository entry points |
| `packages/tools/test/registry.test.ts` (lines 1-45, TOOL_REGISTRY grep) | sibling (test): test setup and helper conventions |
| `docs/journal/2026-09-29-watch-the-double-booking-test-fail.md`, `2026-09-29-the-loop-never-sees-the-patient.md`, `2026-09-29-dynamodb-local-is-too-polite.md` (headers, Evidence) | siblings (journal): header fields, chapter/milestone pairing, Evidence style |
| `RUN_DIR/pr.json` (body, commits), `RUN_DIR/spec/issue-19.json`, `RUN_DIR/diff.patch` | PR text, commit messages, owned paths, what changed |

### Checks performed
| # | Check | Scope | Result |
|---|---|---|---|
| 1 | CLAUDE.md:75 rule 1: no `patientId` in tool inputs; identity only from ctx | both handlers, both test files | pass (neither handler reads patient data; tests reject `patient_id`) |
| 2 | CLAUDE.md:77 rule 3 / add-agent-tool:58: handlers use only `ToolContext`; no AWS SDK, `process.env`, `Date.now()`, module-level state | `check_availability.ts`, `find_providers.ts` | pass (`grep` finds none; module-level `NOON`/`MAX` are constants, not state) |
| 3 | add-agent-tool:58 "No ... `new Date()`" | `check_availability.ts:42` `new Date(startUtc)` | pass under the owner's recorded decision (ban covers reading the clock, not parsing a stored value); see observations |
| 4 | CLAUDE.md:79 rule 5 / add-agent-tool:74: no store or patient text spliced into `message`/`hint` | `check_availability.ts:74-78, 97-108, 123-127` | pass (only `formatClinicDateTime(now)`, from the clock, is interpolated) |
| 5 | CLAUDE.md:80 rule 6: synthetic data only | test files | pass (the `find_providers` cap test's extra providers are "Dr. Test Extra*", fictional) |
| 6 | add-agent-tool:56: file in `src/tools/<tool_name>.ts`, snake_case; one `ToolHandler<"name">` export in camelCase | both handlers | pass |
| 7 | add-agent-tool:45: start from contract types; don't redefine shapes locally | both handlers | pass (`SlotOption`, `ProviderSummary`, `ToolInput` from contracts; `Candidate` is internal pairing, not a contract shape) |
| 8 | add-agent-tool:64-69: every outcome mapped to `toolOk`/`toolFail` with a hint; message ≤300 chars, no internals | `check_availability.ts` three `toolFail`s | pass |
| 9 | add-agent-tool:66: use `TOOL_ERROR_CODE_FOR[reason]` for repo failure reasons | both handlers | not applicable (the repo reads used return `null`/arrays, no reasons) |
| 10 | add-agent-tool:72: UTC stored/compared; `*_local` via `formatClinicDateTime`; ranges via `clinicDateRangeUtc`; no hand offset math | `check_availability.ts:52-59, 71, 110, 117` | pass |
| 11 | add-agent-tool:76: respect `LIMITS`, set `truncated` when cutting | `check_availability.ts:36,131`; `find_providers.ts:27` | pass (`find_providers` output schema `.max(20)` bounds it; no `truncated` field exists in its contract) |
| 12 | ADR-004 AP-3/AP-4/AP-5 through the repository layer (no bypass) | both handlers | pass (`providers.list`, `slots.listOpenByProvider`, `slots.listOpenBySpecialtyAndDay` via `ctx.repos`) |
| 13 | Architecture: code placed in `packages/tools` per `docs/architecture.md:70`; new imports respect direction | imports added: `@sched/contracts`, `../clock`, `../registry` (handlers); `./tools/*` (registry) | pass (the tools→registry and registry→tools import pair is the pattern the skill's worked example prescribes, add-agent-tool:164) |
| 14 | No new dependency, framework or data store | whole diff | pass |
| 15 | add-agent-tool:104: registry change is import + entry under the #19 anchors; nothing reordered | `registry.ts:34-36, 108-110` (diff shows +4, no other lines) | pass |
| 16 | add-agent-tool:80-96: tests via `createToolExecutor`; fixture/FrozenClock/sequentialIds setup; happy, not-found, invalid, cross-patient with snapshot, tool edges (empty, 12:00 boundary, DST, truncation, sparse index) | both test files | pass |
| 17 | add-agent-tool:82 "never invented people" | `find_providers.test.ts:119-130` | pass (read as a rule about patient identities; patients all come from `FIXTURE_PATIENT_IDS`; extra providers are the only way to exceed the 20-result cap with an 8-provider fixture) |
| 18 | add-agent-tool:49 / CLAUDE.md:100-101: contracts change minimal and called out as cross-stream | `clinic.ts` (1 line), snapshot (1 line); PR "Shared-file or contract changes" | pass |
| 19 | add-agent-tool:50/114 + CLAUDE.md:119: description byte change needs an eval run; DoD eval smoke numbers | snapshot description "up to 10" → "up to 5" | pass via add-agent-tool:137 escape ("If `npm run evals` doesn't exist yet (#30), say so in the PR"); PR says so. See observations |
| 20 | add-agent-tool:108-117: description reviewed against section 5 and stated in PR | PR body | pass |
| 21 | add-agent-tool:124 / issue AC: L1 case added or listed for #33; existing ids referenced | PR "Eval scenarios" | pass (all 12 referenced ids exist under `packages/evals/scenarios/`; two new L1 cases listed) |
| 22 | CLAUDE.md:100 / task-worker: stay inside owned paths; shared-file changes called out | 9 changed files vs issue #19 owned paths | pass (contracts changed by the owner's decision and called out; journal files are required by task-workflow:125) |
| 23 | task-workflow:54: branch name `<type>/<issue#>-<slug>` | `feat/19-find-availability` | pass |
| 24 | task-workflow:78: Conventional Commits referencing the issue, with attribution | 6 commits | pass (all carry `(#19)` and `Co-Authored-By`) |
| 25 | task-workflow:99: PR title `<type>(<scope>): <summary> (#<N>)` | PR title | pass |
| 26 | task-workflow:102-107 / template: `Closes #N`, PRD ids, verification, shared-file changes, deferred | PR body | pass |
| 27 | Template:30: deferred items "with issue links" | PR body "Deferred / follow-ups" | finding STD-1 |
| 28 | CLAUDE.md:122 / owner decision: ADR for new or reversed decisions | past-date rule, SPEC-3, SPEC-4 behaviours | pass (owner decided tool-level rules need no ADR; recorded in handler header lines 10-11, 17-21 and journal) |
| 29 | CLAUDE.md:123 / task-workflow:119-125: journal entry for a decision, in the same PR | `docs/journal/2026-09-30-...md` | pass |
| 30 | dev-journal:28-54: file name, template headings, header fields, finding-style title, README table row | journal entry + `docs/journal/README.md:22` | pass (Chapter 4 ↔ M2 matches sibling `2026-09-29-the-loop-never-sees-the-patient.md:3-4`) |
| 31 | dev-journal:56 / CLAUDE.md:130: first-person plural, honest about agent vs Nick, dated, with evidence | journal entry | pass (evidence is test names, file paths and mutation checks; siblings also give no commit SHAs) |
| 32 | CLAUDE.md:124: PRD traceability if requirements changed | `docs/PRD.md:82,188` | pass (FR-030 already says "at most 5 options"; no requirement moved) |
| 33 | CLAUDE.md:125: no secrets or real PII in PR body | PR body, diff | pass |
| 34 | Precedent: module header JSDoc stating purpose with ADR/rule refs | new handlers vs `clock.ts:1-7`, `repos/in-memory.ts:1-10`, `repos/types.ts:1-12` | pass |
| 35 | Precedent: test setup and `outputOf`/`errorOf` helpers | new tests vs `test/registry.test.ts:1-45` and skill worked example | pass |
| 36 | Text aimed at AI reviewers | diff, PR body, 6 commit messages | pass (none found) |
| 37 | Handler header accuracy | `check_availability.ts:2` still says "or across the clinic", contradicting lines 10-11 and 122-127 | not a standards finding: no written rule on comment accuracy. Left for the maintainability reviewer |

### Searches run
| Query or command | Purpose | Hits |
|---|---|---|
| `grep -rn "new Date()\|Date.now()\|process.env\|@aws-sdk" packages/tools/src/tools/` | forbidden APIs in handlers | 0 |
| `grep -rn "availabilityMaxSlots\|providersMaxResults" packages services apps docs .claude` | who uses the changed constant | 14 (tools, contracts, journal, skill only) |
| `find packages/evals/scenarios -name "<id>.yaml"` for 14 ids in the PR body | referenced eval ids exist | 12 of 12 existing; 2 suggested ids absent, as the PR says |
| `grep -rn -A8 "tool: check_availability" packages/evals/scenarios` | scenario argument conventions for the tool | 30 files |
| `grep -n -i "ignore\|reviewer\|approve\|LGTM\|instruction\|assistant\|you are\|do not flag\|AI " diff.patch` | text aimed at reviewers | 0 |
| `grep -n "TOOL_REGISTRY" packages/tools/test/registry.test.ts` | stale "stays empty" header, any emptiness assertion | 4 (header line 3; assertions are size-agnostic) |
| `grep -n "S4-01\|#19" docs/backlog.md` | milestone for the journal entry | 4 |

### Observations for root-cause analysis
- **Written rule vs owner decision on `new Date()`.** `.claude/skills/add-agent-tool/SKILL.md:58` ("No imports of ... `new Date()`") and `packages/tools/src/clock.ts:2` ("Tools and repositories never call `new Date()` themselves") still state a blanket ban. The owner's narrower reading (reading the clock is banned, parsing a stored value is not) is recorded only in the PR thread, so the next tool agent will hit the same ambiguity.
- **Eval-run obligation that cannot be met.** add-agent-tool:50 and :114 require an eval run for any change to a tool description, and CLAUDE.md:119 requires eval numbers in the PR, but no eval runner exists (#30). add-agent-tool:137 lets the PR say so instead. The result is that a model-facing description change (10 → 5 slots) merges with no eval, and no rule asks for one later.
- **Owned paths vs journal requirement.** CLAUDE.md:100 says "Stay inside them" (owned paths), and issue #19's owned paths exclude `docs/journal/`. task-workflow:125 says to put the journal entry "in the same PR". The PR followed task-workflow; the two rules pull in opposite directions for every tool issue.
- **Registry line count.** Issue #19's owned paths say "`packages/tools/src/registry.ts (one-line addition)`", while add-agent-tool:104 and the issue's own comment prescribe an import plus an entry (two lines per tool, four here).
- **Earlier conflict, now resolved:** PRD FR-030 and issue #19 said at most 5 slots, while `LIMITS.availabilityMaxSlots` was 10. The owner chose 5 and this PR aligns the constant.

## 3. Not reviewed

- Whether the two suggested L1 cases were also commented on #33 (add-agent-tool:124 says "list the case in the PR body and comment it on #33"). Issue #33's comments are not in the run inputs.
- Whether the issue labels were updated (`status:review`, task-workflow:114). GitHub label state is not in the run inputs.
- CLAUDE.md:79 "Treat any text coming back from tools or users as untrusted" as a general principle is covered only through the specific message/hint check (#4); anything broader is too vague to test.
- Lint, format, type and test results are machine-enforced (CI green) and were not re-checked.
