#!/usr/bin/env bash
# Regression tests for the harness's scripts. Offline: GitHub is a fake `gh` (lib/gh) that
# answers from each case's recorded JSON.
#
# Usage: tests/run.sh [--update] [<filter>]
#   <filter>   run only the cases whose path contains it
#   --update   write the actual outputs as the expected ones (after a deliberate change;
#              review the diff before committing it)
#
# A case is a directory under tests/cases/<script>/<name>/ with:
#   cmd        the commands to run (bash), in a scratch copy of the case; $SKILLS is the
#              skills directory, $FIXTURES the shared fixtures
#   base       optional: the name of a directory in tests/fixtures/ copied in first
#   gh/        optional: what the fake gh answers (see lib/gh)
#   outputs    optional: files (relative to the case) to compare besides stdout
#   expected/  stdout.txt (output and exit status) and one file per output, '/' as '__'
# In what is compared, the scratch copy's path is written <CASE>, the current harness
# version <VERSION>, and character counts <n>.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
update=no
filter=""
for a in "$@"; do
  case "$a" in
    --update) update=yes ;;
    *) filter="$a" ;;
  esac
done

export LC_ALL=C TZ=UTC
version="$(sed -n 's/^  harness-version: "\(.*\)"$/\1/p' "$root/skills/review-agent-pr/SKILL.md")"
version_re="$(printf '%s' "$version" | sed 's/\./\\./g')"
pass=0
fail=0
failed=""

# Checks on the harness as a whole: every script parses, shared copies stay identical, and
# every skill carries the same release version.
check() {
  if [ -z "$2" ]; then pass=$((pass + 1)); echo "ok       $1"
  else fail=$((fail + 1)); failed="$failed $1"; echo "FAILED   $1"; printf '%s\n' "$2" | sed 's/^/         /'; fi
}
if [ -z "$filter" ] && [ "$update" = "no" ]; then
  out=""
  for s in "$root"/skills/*/scripts/*.sh "$here"/run.sh "$here"/lib/gh; do bash -n "$s" 2>/dev/null || out="$out
${s#$root/}: does not parse"; done
  check "harness/scripts-parse" "$(printf '%s' "$out" | sed '/^$/d')"
  out=""
  for f in get-reports.sh get-decisions.sh diff-size.sh; do
    cmp -s "$root/skills/review-agent-pr/scripts/$f" "$root/skills/address-pr-review/scripts/$f" || out="$out
$f differs between review-agent-pr and address-pr-review"
  done
  cmp -s "$root/skills/review-agent-pr/scripts/get-issue.sh" "$root/skills/review-agent-issue/scripts/get-issue.sh" || out="$out
get-issue.sh differs between review-agent-pr and review-agent-issue"
  check "harness/shared-copies-identical" "$(printf '%s' "$out" | sed '/^$/d')"
  versions="$(sed -n 's/^  harness-version: "\(.*\)"$/\1/p' "$root"/skills/*/SKILL.md | sort -u)"
  [ "$(printf '%s\n' "$versions" | wc -l | tr -d ' ')" = "1" ] && out="" || out="skills carry different versions: $(printf '%s' "$versions" | tr '\n' ' ')"
  check "harness/one-release-version" "$out"
fi

for case_dir in $(find "$here/cases" -name cmd -type f | sed 's|/cmd$||' | sort); do
  name="${case_dir#$here/cases/}"
  case "$name" in *"$filter"*) ;; *) continue ;; esac

  work="$(mktemp -d)"
  if [ -f "$case_dir/base" ]; then
    cp -R "$here/fixtures/$(cat "$case_dir/base")/." "$work/"
  fi
  cp -R "$case_dir/." "$work/"
  rm -rf "$work/expected"
  mkdir -p "$work/.actual"

  status=0
  (
    cd "$work"
    PATH="$here/lib:$PATH" FAKE_GH_DIR="$work/gh" FAKE_GH_LOG="$work/gh-writes.log" \
      SKILLS="$root/skills" FIXTURES="$here/fixtures" bash ./cmd
  ) > "$work/.actual/stdout.txt" 2>&1 || status=$?
  echo "exit: $status" >> "$work/.actual/stdout.txt"

  if [ -f "$case_dir/outputs" ]; then
    while IFS= read -r out; do
      [ -n "$out" ] || continue
      dest="$work/.actual/$(printf '%s' "$out" | sed 's|/|__|g')"
      if [ -f "$work/$out" ]; then cp "$work/$out" "$dest"; else echo "(missing)" > "$dest"; fi
    done < "$case_dir/outputs"
  fi

  # What differs between runs or releases: the scratch path, the harness version, and the
  # character counts that follow from its length.
  for f in "$work/.actual"/*; do
    sed -i.bak -e "s|$work|<CASE>|g; s|/private<CASE>|<CASE>|g" \
      -e "s|$version_re|<VERSION>|g" -e 's/([0-9][0-9]* characters/(<n> characters/g' "$f" && rm -f "$f.bak"
  done

  if [ "$update" = "yes" ]; then
    rm -rf "$case_dir/expected"
    mkdir -p "$case_dir/expected"
    cp "$work/.actual"/* "$case_dir/expected/"
    echo "updated  $name"
  elif diff -r "$case_dir/expected" "$work/.actual" > "$work/.diff" 2>&1; then
    pass=$((pass + 1))
    echo "ok       $name"
  else
    fail=$((fail + 1))
    failed="$failed $name"
    echo "FAILED   $name"
    diff -ru "$case_dir/expected" "$work/.actual" | head -n 60 | sed 's/^/         /' || true
  fi
  rm -rf "$work"
done

if [ "$update" = "no" ]; then
  echo
  echo "$pass passed, $fail failed"
  [ "$fail" -eq 0 ] || { echo "failed:$failed"; exit 1; }
fi
