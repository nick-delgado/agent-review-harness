<!-- agent-pr-review:readiness-applied round=1 -->
## Readiness answers applied (round 1)

Only `Decision r1/<ID>: ...` lines count; other replies are not applied. `ALL` accepted the recommendations and edits, but not the assumptions that need an explicit answer.

**Applied:**
- Q-1: accepted the recommendation, (a) Both non-safety, on every case. Two new invariants go in `packages/evals/src/graders/invariants.ts` with `safety: false`, with their names in `INVARIANTS`. Both join `CORE_INVARIANTS`, so every scenario runs them; the handoff check passes on a scenario with no escalation. The Markdown check also runs on every L1 case, next to `no_reasoning_leak` (`l1.ts:211`). An ADR-008 amendment adds both to the core set. Every reply is guarded, and a Markdown slip in any smoke case counts as a regression. Scope: adds an ADR-008 amendment. Owned paths: + `packages/evals/src/schema.ts` (`INVARIANTS` only), + `packages/evals/src/l1.ts` (the one global check), + `docs/adr/0008-evaluation-strategy.md` (a new amendment section), + `docs/adr/README.md` (its index row)
- Q-2: accepted the recommendation, (b) Bold, italics and headings. Everything in (a), plus a single-asterisk pair `*…*` within one line whose opening `*` has no space after it and whose closing `*` has no space before it, so a `* ` bullet never matches. The prompt wording is the same as in (a). It fails the recorded `*(if available — let me know and I can check further)*` in `reschedule-single-appointment#1`, a smoke scenario. Scope: within the issue
- Q-3: accepted the recommendation, (a) A phrase counted per escalation turn. The check fails when the turn's assistant texts together contain "connect you with our front desk" or "connect you with the front desk" (case-insensitive) more than once, or the clinic phone number (`CLINIC.phone`) more than once. It fails all four recorded doubles and the issue's `dev` example. It misses a pre-tool paraphrase without that phrase ("Let me get you to a person"). Scope: within the issue
- owned path already listed: `packages/evals/src/schema.ts`
- owned path added: `packages/evals/src/l1.ts`
- owned path added: `docs/adr/0008-evaluation-strategy.md`
- owned path added: `docs/adr/README.md`

**Not applied:**
- E-1 (Owned paths: include the tests, the version pins, and both eval directories): its Before text is not in the description any more; not applied
- E-2 (AC 4: `system.v1` no longer exists in the tree; say what "seen failing" shows): its Before text is not in the description any more; not applied
- E-3 (AC 1: there is no voice output to read correctly in): its Before text is not in the description any more; not applied
- E-4 (Dependencies: #230 has merged; name the open issues that share the prompt and the graders): its Before text is not in the description any more; not applied
- E-5 (Goal: the table row now lives in `system.v2.ts`): its Before text is not in the description any more; not applied
- E-6 (Goal: the style rule now lives in `system.v2.ts`): its Before text is not in the description any more; not applied
- E-7 (References: the prompt file was renamed): its Before text is not in the description any more; not applied
- E-8 (Goal: add the non-goals the work could otherwise drift into): its Before text is not in the description any more; not applied

**Still open** (each needs its own `Decision` line):
- nothing

**To check** (written for an answer you did not choose; correct with a new `Decision` line or a refresh):
- A-9 mentions only Q-1 (b), but (a) was chosen: check whether it still applies
