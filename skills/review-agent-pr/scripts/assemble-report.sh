#!/usr/bin/env bash
# Assemble the single-comment review report from the phase outputs in a run directory.
#
# Usage: assemble-report.sh <run-dir>
#
# Reads   <run-dir>/report-head.md, verified.md, root-cause.md (optional),
#         findings/*.md, report-meta.md
# Writes  <run-dir>/report.md
#
# The full check tables are included only when the report stays within the soft limit.
# Exits 1, with the size of each section, when the report cannot be made to fit.

set -euo pipefail

MARKER='<!-- agent-pr-review:report -->'
SOFT_LIMIT=60000

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: $(basename "$0") <run-dir>" >&2
  exit 2
fi

run="$(cd "$1" && pwd)"
verified="$run/verified.md"
rootcause="$run/root-cause.md"
out="$run/report.md"

for required in "$run/report-head.md" "$run/report-meta.md" "$verified"; do
  [ -s "$required" ] || { echo "error: missing or empty $required" >&2; exit 1; }
done

missing=""
need() {
  local file="$1" heading
  shift
  for heading in "$@"; do
    grep -qxF "## $heading" "$file" || missing="$missing
  $(basename "$file"): ## $heading"
  done
}
need "$verified" "Confirmed findings" "Minor findings table" "Rejected findings" "Verification summary" "Reviewer tables"
if [ -s "$rootcause" ]; then
  need "$rootcause" "Cause summary" "Patterns" "Proposals" "Not explained"
fi
if [ -n "$missing" ]; then
  echo "error: required sections are missing:$missing" >&2
  exit 1
fi

# Body of the "## <title>" section of a file. Headings inside code fences are ignored.
h2() {
  awk -v want="## $2" '
    /^[ ]*```/ { fence = !fence }
    !fence && /^## / { on = ($0 == want); next }
    on
  ' "$1"
}

# Body of the first "### <prefix>..." section of a file.
h3() {
  awk -v want="### $2" '
    /^[ ]*```/ { fence = !fence }
    !fence && /^##+ / { on = (/^### / && index($0, want) == 1); next }
    on
  ' "$1"
}

# Drop leading and trailing blank lines.
trim() {
  awk 'NF { seen = 1 } seen { buf[++n] = $0 } END { while (n > 0 && buf[n] !~ /[^ \t]/) n--; for (i = 1; i <= n; i++) print buf[i] }'
}

# Number of data rows in the markdown tables on stdin.
rows() {
  awk '/^\|/ { n++; if ($0 ~ /^\|[ :|-]+\|?$/) n -= 2 } END { print (n > 0 ? n : 0) }'
}

# Number of top-level list items on stdin.
items() {
  awk '/^- / { n++ } END { print n + 0 }'
}

# Confirmed findings of blocker or major severity, as report blocks.
top_findings() {
  h2 "$verified" "Confirmed findings" | awk '
    function flush() { if (keep) printf "%s", block; block = ""; keep = 0 }
    /^[ ]*```/ { fence = !fence }
    !fence && /^### / { flush(); sub(/^### /, "#### ") }
    /^- \*\*Severity:\*\* (blocker|major)/ { keep = 1 }
    /^- \*\*(Checked by verifier|Introduced by this PR|Merged|Category):\*\*/ { next }
    { block = block $0 "\n" }
    END { flush() }
  '
}

or_default() {
  local text
  text="$(cat)"
  if [ -n "$text" ]; then printf '%s\n' "$text"; else printf '%s\n' "$1"; fi
}

reviewers="standards code-smells spec-alignment test-adequacy"

label() {
  case "$1" in
    standards) echo "Standards" ;;
    code-smells) echo "Code smells" ;;
    spec-alignment) echo "Spec alignment" ;;
    test-adequacy) echo "Test adequacy" ;;
  esac
}

build() {
  local with_tables="$1" r f

  echo "$MARKER"
  trim < "$run/report-head.md"

  printf '\n### Findings\n\n'
  top_findings | trim | or_default "No blocker or major findings."

  local minor minor_count
  minor="$(h2 "$verified" "Minor findings table" | trim)"
  minor_count="$(printf '%s\n' "$minor" | rows)"
  printf '\n<details>\n<summary>Minor findings and nits (%s)</summary>\n\n' "$minor_count"
  printf '%s\n' "$minor" | or_default "None."
  printf '\n</details>\n'

  printf '\n### Spec alignment\n\n'
  h3 "$verified" "Spec traceability" | trim | or_default "Not reviewable: no spec found."
  printf '\n**Unrequested changes**\n\n'
  h3 "$verified" "Unrequested changes" | trim | or_default "None."

  printf '\n### Why this happened\n\n'
  if [ -s "$rootcause" ]; then
    echo "These are inferences from the repository. The agent's prompt and transcript were not available."
    echo
    h2 "$rootcause" "Cause summary" | trim
    printf '\n**Patterns**\n\n'
    h2 "$rootcause" "Patterns" | trim | or_default "None."
    printf '\n**Not explained**\n\n'
    h2 "$rootcause" "Not explained" | trim | or_default "Nothing."

    printf '\n### Proposed process improvements\n\n'
    h2 "$rootcause" "Proposals" | awk '
      /^[ ]*```/ { fence = !fence }
      !fence && /^### / { sub(/^### /, "#### ") }
      { print }
    ' | trim | or_default "None."
  else
    echo "No cause analysis was run."
  fi

  printf '\n### Evidence of review\n\n'
  echo "| Reviewer | Checks recorded | Searches run | Items not reviewed |"
  echo "|---|---|---|---|"
  for r in $reviewers; do
    f="$run/findings/$r.md"
    if [ -s "$f" ]; then
      echo "| $(label "$r") | $(h3 "$f" "Checks performed" | rows) | $(h3 "$f" "Searches run" | rows) | $(h2 "$f" "3. Not reviewed" | items) |"
    else
      echo "| $(label "$r") | did not run | | |"
    fi
  done

  printf '\n<details>\n<summary>Not reviewed</summary>\n\n'
  for r in $reviewers; do
    f="$run/findings/$r.md"
    [ -s "$f" ] || continue
    printf '**%s**\n\n' "$(label "$r")"
    h2 "$f" "3. Not reviewed" | trim | or_default "Nothing skipped."
    echo
  done
  printf '</details>\n'

  printf '\n<details>\n<summary>Findings rejected or merged in verification</summary>\n\n'
  h2 "$verified" "Rejected findings" | trim | or_default "None."
  printf '\n**Verification summary**\n\n'
  h2 "$verified" "Verification summary" | trim
  printf '\n</details>\n'

  if [ "$with_tables" = "yes" ]; then
    printf '\n<details>\n<summary>Every check performed</summary>\n\n'
    for r in $reviewers; do
      f="$run/findings/$r.md"
      [ -s "$f" ] || continue
      printf '**%s**\n\n' "$(label "$r")"
      h3 "$f" "Checks performed" | trim
      echo
    done
    printf '**Behaviour coverage**\n\n'
    h3 "$verified" "Behaviour coverage" | trim | or_default "Not produced."
    printf '\n</details>\n'
  fi

  printf '\n<details>\n<summary>Run metadata</summary>\n\n'
  trim < "$run/report-meta.md"
  if [ "$with_tables" = "yes" ]; then
    echo "- Full check tables: included above."
  else
    echo "- Full check tables: left out to fit one comment; they are in the run directory (\`findings/*.md\`, \`verified.md\`)."
  fi
  printf '\n</details>\n'
}

size() {
  LC_ALL=en_US.UTF-8 wc -m < "$1" | tr -d '[:space:]'
}

build yes > "$out"
tables="included"
if [ "$(size "$out")" -gt "$SOFT_LIMIT" ]; then
  build no > "$out"
  tables="left out"
fi

chars="$(size "$out")"
if [ "$chars" -gt "$SOFT_LIMIT" ]; then
  {
    echo "error: report is $chars characters without the check tables; the limit is $SOFT_LIMIT."
    echo "Section sizes (characters):"
    awk '
      /^### / { if (name != "") printf "  %6d  %s\n", n, name; name = $0; n = 0 }
      { n += length($0) + 1 }
      END { if (name != "") printf "  %6d  %s\n", n, name }
    ' "$out"
    echo "Shorten the largest section in its source file and run this again."
  } >&2
  exit 1
fi

echo "wrote $out ($chars characters; check tables $tables)"
