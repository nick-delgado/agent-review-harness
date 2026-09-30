# agent-review-harness

Skills for reviewing pull requests written by AI coding agents, and for working out why the
agent produced the problems the review finds.

An ordinary code review lists defects. This harness also treats each defect as evidence
about the project's agent setup: the instruction files, skills, specs and guardrails the
authoring agent worked from. It ends with concrete changes to those, so the same problem
does not come back on the next PR.

Works with Claude Code, OpenAI Codex and Google Antigravity. GitHub only for now, through
the `gh` CLI.

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
                                  7 one PR comment ─ 8 offer a PR with the process fixes
```

| Reviewer | Checks |
|---|---|
| Standards | The project's documented rules, architecture boundaries, and conventions shown by existing code |
| Code smells | Duplication of existing code, bloaters, change preventers, couplers, dispensables, and patterns typical of agent output (placeholders, swallowed errors, unrequested shims) |
| Spec alignment | Every requirement traced into the code, every change traced back to a requirement, conflicts with the project's longer-term goals, PR description versus the actual diff |
| Test adequacy | Whether the tests would fail if the change were wrong, and whether any verification was weakened to get a green run |

The spec comes from the linked issue or ticket first, then from spec files in the
repository.

The harness does not run tests, linters or builds. It assumes CI does, and reads the CI
result.

## The report

One general comment on the PR, updated in place on a re-run:

- a verdict and the confirmed findings, each with `file:line`, the quoted code and the
  quoted rule or spec clause it breaks;
- a spec traceability table;
- the inferred cause of each finding, with its confidence and evidence;
- proposed changes to docs, prompts, skills, tests and CI checks, written as diffs;
- evidence of review: how many checks and searches each reviewer recorded, what was not
  reviewed and why, and the findings the verifier rejected. The full table of every check
  (including the ones that passed) is included when it fits in one comment, and is always
  kept in the run directory.

## Install

Clone this repository next to the project you want to review, then:

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

A user-level install keeps the harness out of the reviewed repository. A project install can
be committed so the whole team has it.

The skill is a plain [Agent Skills](https://agentskills.io) directory, so copying
`skills/review-agent-pr/` into any of the locations above by hand works too.

## Use

Start a **new session** in the project, in a different session (and ideally a different
tool or model) from the one that wrote the PR, and ask:

> Use the review-agent-pr skill to review PR 123.

Requirements: `gh` installed and authenticated, and the working directory is a clone of the
PR's repository. The review checks the PR out into a temporary git worktree and does not
touch your working tree.

## Layout

```
skills/review-agent-pr/
  SKILL.md                     orchestrator: the phases
  reviewers/                   one brief per specialist reviewer
  analysts/                    verifier and root-cause analyst briefs
  references/                  finding format, cause taxonomy, report template
  scripts/assemble-report.sh   builds the report from the phase outputs, within one comment
  scripts/post-report.sh       creates or updates the PR comment
install.sh
```

There are no tool-specific subagent definition files. The three tools keep those in
different places and formats (`.claude/agents/*.md`, `.codex/agents/*.toml`,
`.agents/agents/*.md`), so each reviewer's instructions live in the skill as a brief, and
the orchestrator hands a brief to the tool's built-in general-purpose subagent.

To add a reviewer: write a brief in `reviewers/`, give it a finding prefix, and add it to
the table in phase 4 of `SKILL.md` and to the report template.

## Status

First version. The skill has not yet been run end to end against a real PR in any of the
three tools.
