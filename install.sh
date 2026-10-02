#!/usr/bin/env bash
# Install the skills in this repository into a project, or into your user-level
# skill directories, for Claude Code, OpenAI Codex and Google Antigravity.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install.sh <project-dir> [options]   install into a project
  install.sh --user [options]          install for your user, available in every project

Options:
  --tools <list>   comma-separated: claude,codex,antigravity (default: all three)
  --link           symlink to this repository instead of copying, so a git pull here
                   updates the install
  --uninstall      remove the skills instead of installing them
  -h, --help       show this help

Where skills are installed:
                 project                  user
  claude         .claude/skills/          ~/.claude/skills/
  codex          .agents/skills/          ~/.agents/skills/
  antigravity    .agents/skills/          ~/.gemini/config/skills/
EOF
}

src_root="$(cd "$(dirname "$0")" && pwd)/skills"
# Skills that use Claude Code-only frontmatter; installed for Claude Code only.
claude_root="$(cd "$(dirname "$0")" && pwd)/claude-code/skills"
claude_dest=""

target=""
scope="project"
tools="claude,codex,antigravity"
mode="copy"
action="install"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user) scope="user" ;;
    --tools)
      [ "$#" -ge 2 ] || { echo "error: --tools needs a value" >&2; exit 2; }
      tools="$2"
      shift
      ;;
    --link) mode="link" ;;
    --uninstall) action="uninstall" ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "error: unknown option '$1'" >&2
      usage >&2
      exit 2
      ;;
    *)
      [ -z "$target" ] || { echo "error: more than one project directory given" >&2; exit 2; }
      target="$1"
      ;;
  esac
  shift
done

if [ "$scope" = "project" ]; then
  [ -n "$target" ] || { usage >&2; exit 2; }
  [ -d "$target" ] || { echo "error: '$target' is not a directory" >&2; exit 1; }
  target="$(cd "$target" && pwd)"
elif [ -n "$target" ]; then
  echo "error: give either a project directory or --user, not both" >&2
  exit 2
fi

[ -d "$src_root" ] || { echo "error: no skills directory at $src_root" >&2; exit 1; }

# Resolve the destination skill directories, without duplicates
# (Codex and Antigravity share .agents/skills in a project).
dests=""
add_dest() {
  case "
$dests
" in
    *"
$1
"*) ;;
    *) dests="${dests:+$dests
}$1" ;;
  esac
}

old_ifs="$IFS"
IFS=','
for tool in $tools; do
  case "$tool" in
    claude)
      if [ "$scope" = "user" ]; then claude_dest="$HOME/.claude/skills"; else claude_dest="$target/.claude/skills"; fi
      add_dest "$claude_dest"
      ;;
    codex)
      if [ "$scope" = "user" ]; then add_dest "$HOME/.agents/skills"; else add_dest "$target/.agents/skills"; fi
      ;;
    antigravity)
      if [ "$scope" = "user" ]; then add_dest "$HOME/.gemini/config/skills"; else add_dest "$target/.agents/skills"; fi
      ;;
    *)
      IFS="$old_ifs"
      echo "error: unknown tool '$tool' (expected claude, codex or antigravity)" >&2
      exit 2
      ;;
  esac
done
IFS="$old_ifs"

[ -n "$dests" ] || { echo "error: no tools selected" >&2; exit 2; }

echo "$dests" | while IFS= read -r dest; do
  extra=""
  [ "$dest" = "$claude_dest" ] && [ -d "$claude_root" ] && extra="$claude_root"
  for skill in "$src_root"/*/ ${extra:+"$extra"/*/}; do
    [ -f "${skill}SKILL.md" ] || continue
    skill="${skill%/}"
    name="$(basename "$skill")"
    path="$dest/$name"

    # Only ever touch the directory named after one of our own skills.
    if [ -L "$path" ]; then
      rm "$path"
      had_previous="yes"
    elif [ -d "$path" ]; then
      rm -rf "$path"
      had_previous="yes"
    elif [ -e "$path" ]; then
      echo "error: $path exists and is not a directory; leaving it alone" >&2
      exit 1
    else
      had_previous="no"
    fi

    if [ "$action" = "uninstall" ]; then
      if [ "$had_previous" = "yes" ]; then echo "removed    $path"; else echo "not found  $path"; fi
      continue
    fi

    mkdir -p "$dest"
    if [ "$mode" = "link" ]; then
      ln -s "$skill" "$path"
      verb="linked"
    else
      cp -R "$skill" "$path"
      verb="copied"
    fi
    chmod +x "$path"/scripts/*.sh 2>/dev/null || true
    if [ "$had_previous" = "yes" ]; then
      echo "updated    $path ($verb)"
    else
      echo "installed  $path ($verb)"
    fi
  done
done
