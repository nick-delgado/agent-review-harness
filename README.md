# agent-review-harness

Skills for reviewing the work of AI coding agents at both ends, the issue before an agent
starts it and the pull request after, getting the code fixed, and working out why the agent
produced the problems the review finds.

An ordinary code review lists defects. This harness also treats each defect as evidence
about the project's agent setup: the instruction files, skills, specs and guardrails the
authoring agent worked from. It logs those causes across reviews and turns the ones that
recur into concrete changes, so the same problem does not come back on the next PR.

Works with Claude Code, OpenAI Codex and Google Antigravity. GitHub only for now, through
the `gh` CLI.

## The skills

| Skill | Who runs it | What it does |
|---|---|---|
| `review-agent-issue` | You, before an agent starts an issue | Posts the questions to settle first (with options and a recommendation), the assumptions the agent will otherwise follow, and exact edits to the issue; after you answer on the issue, writes your answers into its description. Advisory |
| `review-agent-pr` | Any session, including the coding one | Reviews the PR, posts the code findings as one PR comment, and logs causes and proposals on a tracking issue |
| `address-pr-review` | The agent that works on the PR | Fixes the findings marked "Fix now" and replies on the PR, finding by finding |
| `improve-agent-process` | You, once several reviews are logged | Reads the tracking issue across reviews and opens one batched PR with the process changes worth making |

```
   PR opened by an agent
            │
   review-agent-pr ──────────────┬───────────────► tracking issue (label: agent-process)
            │                    │                   causes + proposals, one comment per PR
            ▼                    │                            │
   PR comment: code findings     │                            │  after several reviews
     · Fix now                   │                            ▼
     · Needs the owner's decision│                  improve-agent-process
     · For the owner             │                            │
            │                    │                            ▼
   you answer the decisions      │                  one batched PR: docs, skills,
            │                    │                  tests, CI checks
   address-pr-review             │
            │                    │
   fixes pushed, reply posted ───┘ (each review and each reply is a new comment)
```

## What a review does

```
0 preflight ─ 1 intake ─ 2 find spec ─ 3 context manifest
                                             │
             ┌───────────────┬───────────────┼────────────────┐
         standards      code smells    spec alignment    test adequacy     4 parallel reviewers,
             └───────────────┴───────────────┼────────────────┘              fresh context each
                                             │
                                  5 verifier (tries to refute every finding)
                                             │
                                  6 root-cause analyst (why did the agent do this?)
                                             │
                                  7 publish: PR comment + tracking-issue comment
```

| Reviewer | Checks |
|---|---|
| Standards | The project's documented rules, architecture boundaries, and conventions shown by existing code |
| Code smells | Duplication of existing code, bloaters, change preventers, couplers, dispensables, and patterns typical of agent output (placeholders, swallowed errors, unrequested shims) |
| Spec alignment | Every requirement traced into the code, every change traced back to a requirement, conflicts with the project's longer-term goals, PR description versus the actual diff |
| Test adequacy | Whether the tests would fail if the change were wrong, and whether any verification was weakened to get a green run |

The spec comes from the linked issue or ticket first, then from spec files in the
repository.

The review does not run tests, linters or builds. It assumes CI does, and reads the CI
result.

## The PR comment

One general comment on the PR per review run, or several consecutive comments marked
"part k of n" when the report is longer than GitHub's comment limit (nothing is trimmed).
Earlier reports are never edited, so the PR's conversation is the audit trail: each report names the commit it reviewed (linked), and each
response from the fixing agent names the review it answers, the commit it started from and
the commit it produced. It holds code findings only:

- a verdict, and the confirmed findings, each with `file:line`, the quoted code and the
  quoted rule or spec clause it breaks;
- the findings in three groups, by who acts on them:
  - **Fix now:** the fix is settled and inside the PR's scope. The authoring agent does
    these.
  - **Needs the owner's decision:** the fix depends on a choice the spec does not settle.
    Nobody acts until you answer.
  - **For the owner:** real gaps the PR exposes but was not allowed to fix. No action in
    this PR, and no effect on the verdict.
- a spec traceability table;
- on a re-review, what became of each earlier finding (resolved, still present, decided),
  checked against the new commit, not taken from the agent's word;
- evidence of review: how many checks and searches each reviewer recorded, what was not
  reviewed and why, what the verifier rejected or merged, and a sample of passed checks
  that the verifier re-checked. Every `file:line` citation is checked by a script against
  the code at the reviewed commit. The full table of every check
  is included when it fits in one comment, and is always kept in the run directory.

## The tracking issue

Causes and proposals are kept out of the PR comment, so the agent fixing the code is not
distracted by them and does not act on them. They go to one issue per repository, labelled
`agent-process`, created on first use. Each review round gets one comment there (a
re-review after fixes adds another, so earlier causes stay in the log):

- the inferred cause of each finding, with its confidence and evidence (blockers and majors
  in depth, minors in a line, nits not at all);
- patterns across findings;
- proposed changes to docs, prompts, skills, tests and CI checks, written as diffs.

Causes are inferences: the review sees the PR and the repository, not the agent's prompt or
transcript.

## Working with a queue of PRs

Process changes are made in a separate, batched PR, never in the feature PR and never by
the agent being reviewed.

- **Each PR is judged against the rules it was written under.** The review reads the docs
  and skills from the PR's own branch, not from the default branch. Changing a skill
  afterwards does not move the goalposts for PRs already open. (The linked issue is read
  live, so edits to the issue do apply.)
- **When to merge the base branch in.** Before a PR's first review, merge it in freely (a
  review stops on a PR with a merge conflict). After a review, leave it to the fixing agent,
  which merges it after its fixes. If someone merges it in between anyway, the fixing agent
  notices that only the base came in and carries on. If the base moves again after the
  fixes, before the re-check, ask the fixing agent to "bring PR <n> up to date": its
  sync-only mode merges, resolves or raises conflicts, and confirms CI started.
- **Fix, then sync, then re-check.** The fixing agent fixes each PR against the commit that
  was reviewed, and only then merges the base branch in (never a rebase), resolving
  mechanical conflicts itself and asking you about conflicts in logic. It then checks that
  the PR is mergeable and that CI started: GitHub's `pull_request` CI runs on a trial merge,
  so a PR with a conflict silently gets no CI at all. The re-check reviews the fixes and the
  conflict resolutions but not what came in from the base branch, and checks whether
  changes other PRs made to code this PR relies on break it. A review stops on a PR that
  has a merge conflict, since resolving it will change the code.
- **Make CI run even with a conflict** (in the project, not the harness): add a `push`
  trigger for PR branches to the CI workflow, so the branch head is tested even when the
  trial merge cannot be built.
- **Work in rounds.** Review the whole queue under the current rules. Expect the same
  defects to repeat: that repetition is the evidence. Get the code fixed and merged. Then
  run `improve-agent-process`, merge its PR, and start the next batch of work under the new
  rules.
- **Two kinds of change should not wait:** guardrails (a test, lint rule or CI check),
  which apply to open PRs on their next rebase, and corrections to an instruction that is
  actively wrong.

## Install

### With the skills CLI

From the root of the project you want the skills in:

```sh
npx skills add nick-delgado/agent-review-harness                       # choose skills and agents interactively
npx skills add nick-delgado/agent-review-harness --list                # see what is available
npx skills add nick-delgado/agent-review-harness -a claude-code -a codex -a antigravity
npx skills add nick-delgado/agent-review-harness -s address-pr-review  # one skill
npx skills add nick-delgado/agent-review-harness -g                    # your user-level directories
npx skills update                                                      # later, to pull new versions
```

It installs the skills to `.agents/skills/` (read by Codex and Antigravity) and links them
into `.claude/skills/` for Claude Code. Pass `--copy` if you want plain copies to commit.

### With the install script

Clone this repository next to the project, then:

```sh
./install.sh ../my-project                    # all three tools, copied
./install.sh ../my-project --tools claude     # one tool
./install.sh ../my-project --link             # symlink, so `git pull` here updates it
./install.sh --user                           # your user-level skill directories
./install.sh ../my-project --uninstall
```

| Tool | Project | User |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.agents/skills/` |
| Antigravity | `.agents/skills/` | `~/.gemini/config/skills/` |

The installer copies all four skills. A user-level install keeps the harness out of the
reviewed repository. A project install can be committed so the whole team, and the agents
working in the repository, have it.

Each skill is a plain [Agent Skills](https://agentskills.io) directory, so copying a folder
from `skills/` into any of the locations above by hand works too.

## Use

Requirements for all four: `gh` installed and authenticated, and a working directory that
is a clone of the repository.

All GitHub access goes through the REST API (`gh api`), never GraphQL, so the skills also
run where GraphQL is blocked, such as Claude Code cloud sessions. The one exception is
optional: recovering review rounds from comments that older versions of the harness edited
in place, which is skipped with a note when GraphQL is unavailable. If `gh` cannot work out
the repository from the git remote (for example, behind a proxy remote), set
`GH_REPO=<owner>/<repo>`.

**Prepare an issue (optional, advisory).** Before an agent starts an issue:

> Use the review-agent-issue skill on issue 88.

It posts one comment on the issue: questions worth settling before work starts (at most
seven, each with options and a recommendation), the assumptions the agent will otherwise
follow, and suggested edits to the issue. Answer on the issue with lines like
`Decision r1/Q-1: (b)` or `Decision r1/E-1: accept`. `Decision r1/ALL: accept` takes every
recommendation and edit at once, but not the assumptions the comment lists under "Check
these first" or marks "(verify first)": answer each of those with `ok` or a correction.
Only `Decision` lines are applied, never replies in other words. Then:

> Use the review-agent-issue skill to apply the answers on issue 88.

A script writes your answers into a "Decisions and clarifications" section of the issue's
description and makes the accepted edits; it then records what it did in a comment, and labels the
issue `agent-ready` when nothing is left open. Your answers stay in the issue's comments
for the record; the description is what the coding agent and the PR review read as the
spec. Each answer records the commit of the spec it was settled against. The review also
checks sibling issues, so two issues prepared in the same wave are not settled differently
on the same behaviour.

If a PRD or ADR amendment merges while issues are waiting, refresh them before their agents
start:

> Use the review-agent-issue skill to refresh the readiness of issue 88.

It diffs the spec since the issue was settled, and posts only if something the issue relied
on changed (or a PR review deferred work to it), with new questions where an answer no
longer holds.

**Review.** Start a new session, not the one that wrote the PR, and ideally a different
tool or model:

> Use the review-agent-pr skill to review PR 123.

The review checks the PR out into a temporary git worktree and does not touch your working
tree. It also notes when the spec moved under the work (a PRD or ADR change merged after the
work began or after the issue's readiness review): such a finding is a question for you,
not counted as the agent's mistake. And it reads the open issues related to the PR, so its
suggestions agree with upcoming work, and it may offer to defer a fix to an issue that
already covers it (never a blocker or a fix the PR needs; you decide).

**Review from the coding session.** You do not need a second session. Every judgement in
the review (findings, verification, causes, the report's summary) is made by subagents
that start with no conversation history; the session that runs the skill only runs
scripts, spawns those subagents with fixed prompts and assembles their files. The skill
holds that session to rules that keep its own context out: it adds nothing to the
subagents' prompts, writes the manifest only from what the repository and GitHub show, and
never edits their output. So the coding session can run it directly; push your commits
first, since the review reads the PR from GitHub. A separate session (or another tool or
model, for a different perspective) still works the same way.

Run it in the main session, not as a subagent or forked skill: the review waits for many
subagents, and in some environments a subagent cannot wait for subagents of its own. The
waiting does not hold the session: between subagent notifications it takes your messages
as usual, so you can keep coding (through subagents, ideally) while a review runs. If the
session is interrupted or its context is compacted, asking for the same review again
resumes it from the last finished phase, without posting anything twice.

**Decide.** Each finding that needs your decision lists options (a), (b), ... with their
consequences, a recommendation, and the line to reply with. Reply on the PR with one line
per decision, giving a letter or your own answer:

```
Decision d34b6df/SPEC-1: (b)
Decision d34b6df/SPEC-2: keep as is; the booking tool checks this
```

The commit in each line ties the decision to one review round, since finding IDs restart in
every round. Only lines in this form, from someone with write access, count as decisions.

**Fix.** Then, in the session of the agent that works on the code:

> Use the address-pr-review skill on PR 123.

It picks up your `Decision` lines from the PR; you can also give decisions in the session.
If a fix turns out to need something the review did not foresee (a file outside the task's
scope, say), it collects those and asks you once, at the end, whether to make the change,
open a follow-up issue, or leave it. In an unattended run it leaves them undone and lists
them first in its response. It corrects facts in any file, instruction files included, but
never changes the rules agents follow: those go through `improve-agent-process`.
It pushes fixes to the PR branch and replies on the PR with one row per finding: fixed,
disputed, not fixed, deferred, or waiting for a decision. A fix you deferred to another
issue is noted on that issue, so its readiness review and its agent see it. It never edits
or deletes a comment; corrections go in its next response. It then recommends what comes next, from the
verdict and the size of the change: nothing, a re-check, or a full review.

**Re-check.** After fixes, a re-check is usually enough and costs about a fifth of a full
review: the four reviewers do not run, and one verifier checks the changes since the
reviewed commit and settles each earlier finding:

> Use the review-agent-pr skill to re-check PR 123.

It falls back to a full review when there is no earlier review, the earlier commit cannot be
fetched, or the PR's own source changes run past about 300 lines or 20% of the PR (tests
and changes merged in from the base branch do not count).

**Improve.** When several reviews are logged:

> Use the improve-agent-process skill.

It shows you what it would change, defer and drop, and opens the PR only after you choose.

**Log an incident.** For a process failure that no PR shows (secrets left in a scratch
folder, a push to the wrong branch):

> Use the improve-agent-process skill to log an incident: <what happened>.

It posts the incident on the tracking issue, and the next batch weighs it like review
findings.

## Layout

```
skills/
  review-agent-pr/
    SKILL.md                         orchestrator: the phases
    reviewers/                       one brief per specialist reviewer
    analysts/                        verifier and root-cause analyst briefs
    references/                      finding format, cause taxonomy, output layout
    scripts/assemble-report.sh       builds the PR comment and the tracking-issue comment
    scripts/post-report.sh           posts the report as new PR comments, one per part
    scripts/split-report.awk         splits a long report into comment-sized parts
    scripts/get-reports.sh           fetches every report on a PR, joining multi-part ones
    scripts/post-process-findings.sh creates or updates the tracking-issue comment
    scripts/get-pr.sh                saves the PR, its files, commits, diff and CI state
    scripts/get-issue.sh             saves an issue and its comments as the spec
    scripts/get-previous.sh          saves earlier reports, responses and decisions for a re-review
    scripts/get-decisions.sh         lists the owner's Decision lines for a review (same as above)
    scripts/check-citations.sh       checks every file:line citation against the code
    scripts/check-outputs.sh         checks each reviewer's output has its required sections
    scripts/validate.sh              checks every hand-off against references/contracts.md
    scripts/spec-moves.sh            direction-document changes since the work began and since readiness
    scripts/related-issues.sh        open issues that name the PR's files or are linked from its issues
  review-agent-issue/
    SKILL.md                         readiness review of an issue, and the apply step
    analysts/                        spec analyst, codebase scout, readiness verifier, refresh analyst
    references/readiness-format.md   the comment's layout and rules
    references/contracts.md          every exchanged file and its check
    scripts/apply-readiness.sh       builds the new description from the Decision lines
    scripts/validate.sh              checks every hand-off
    scripts/                         also: fetch the issue and earlier rounds, read answers, post, update the description
  address-pr-review/
    SKILL.md
    scripts/get-review.sh            prints the latest review report and whether the PR moved since
    scripts/get-reports.sh           (same as above)
    scripts/get-decisions.sh         lists the owner's Decision lines for a review
    scripts/post-response.sh         posts the response as a new PR comment
    scripts/post-deferral.sh         notes a deferred finding on its target issue
  improve-agent-process/
    SKILL.md
    references/harness-changes.md    the harness's own changes, with IDs and targets, to measure
    scripts/get-process-log.sh       prints the tracking issue, responses, reviewer signals and deferrals
install.sh
```

There are no tool-specific subagent definition files. The three tools keep those in
different places and formats (`.claude/agents/*.md`, `.codex/agents/*.toml`,
`.agents/agents/*.md`), so each reviewer's instructions live in the skill as a brief, and
the orchestrator hands a brief to the tool's built-in general-purpose subagent.

To add a reviewer: write a brief in `reviewers/`, give it a finding prefix, and add it to
the table in phase 4 of `SKILL.md`, to `references/report-template.md` and to the reviewer
list in `scripts/assemble-report.sh`.

## Measuring the project's process changes

Every finding is tagged with a **failure class**, what went wrong (a test that cannot fail,
a claim beyond the evidence, an unflagged spec guess, duplication, ...), as well as with a
cause, why. Causes drift as a project's rules change; failure classes do not, so they are
what the project counts. Each tracking-issue comment starts with a data line (first review
or re-review, changed lines, when the work began, harness version), and each change a batch
makes has an ID and a target class. `improve-agent-process` starts by measuring every
earlier change against PRs begun after it merged, and a change of words that failed is
followed by a guardrail or a removal, not by more words.

The harness is measured the same way. Its own changes are listed with IDs and targets in
`skills/improve-agent-process/references/harness-changes.md`, and measured by the harness
version on each data line. Each batch also reports the reviewer's quality (findings the
verifier rejected, recommendations the owner overrode, disputes a later round upheld,
defects a suggested fix introduced), the questions readiness reviews missed, how often the
spec moved under work, and the cost per review where the runtime reports it.

Every review round records what ran: the orchestrator's and each subagent's model, effort
level, tokens and time, as a table in the report's run metadata and a machine-readable run
line, so cost can be totalled per round and per PR. To compare models, ask for one ("review
PR 123 with the reviewers on Sonnet, label it sonnet-trial"): the run records the choice
and its label, and measurements keep labelled runs apart.

While a project measures, hold the reviewer steady: queue harness changes in `HELD.md` and
make them together when the window ends.

## Versioning

Every skill's frontmatter carries the same `metadata.harness-version`, the harness release
(a date, `YYYY.MM.DD`, with a suffix for a second release on the same day). Reports and
responses print it, so you can tell which release produced them. Any change bumps it in
every skill, so all skills always show the release they came with.

If a project commits copies of these skills (for example under `.agents/skills/`), those
copies do not update themselves: refresh them with `npx skills update` or `install.sh`, or
keep the skills out of the project and install them per user.

## Contributing: the generality check

The harness is meant for any project, but most of its evidence comes from one. So every
change passes one check: **mechanics in the harness, content in the project.** How reviews
and readiness reviews run, the exchange contracts, the decision format, measurement and
the default failure classes belong here. What agents must do in a particular project
(journal entries, ADR tests, task templates, mutation testing) belongs in that project,
written there by `improve-agent-process`; the harness at most offers a hook for it. Ask of
each change: would a project in another language, with another workflow and templates,
need it? Record the answer in the commit message. When a change could move a count, add
it to `harness-changes.md` with a target, and when a file's format changes, change its
producer, its contract and its check together.

## Status

In use on one project. All four skills have run on real PRs or issues, in Claude Code (locally and
in cloud sessions) and in Antigravity; Codex has not been tried. The harness changes often:
check `metadata.harness-version` in a report or response to see which version produced it.
