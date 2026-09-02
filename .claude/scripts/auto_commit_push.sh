#!/bin/bash
# Claude Code Stop hook: auto-commit & push any changes made during the session.
# Skips quietly if there is nothing to commit. Never blocks/fails the session
# (always exits 0) so a git/network hiccup doesn't interrupt Claude Code.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 0

# Not a git repo somehow? bail quietly.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

BRANCH="$(git branch --show-current)"
[ -z "$BRANCH" ] && exit 0

# Stage everything (new, modified, deleted).
git add -A

# Nothing staged -> nothing to do.
if git diff --cached --quiet; then
  exit 0
fi

# Build a descriptive commit message from the staged changes.
FILES_CHANGED="$(git diff --cached --name-status)"
SUMMARY="$(echo "$FILES_CHANGED" | awk '
  { count++
    if ($1 == "A") added++
    else if ($1 == "M") modified++
    else if ($1 == "D") deleted++
    else other++
  }
  END {
    out = ""
    if (added)    out = out added " added, "
    if (modified) out = out modified " modified, "
    if (deleted)  out = out deleted " deleted, "
    if (other)    out = out other " changed, "
    sub(/, $/, "", out)
    print out
  }')"

# Short list of touched file names (max 5) for context.
FILE_LIST="$(echo "$FILES_CHANGED" | awk '{print $2}' | head -5 | paste -sd ', ' -)"
TOTAL_FILES="$(echo "$FILES_CHANGED" | wc -l | tr -d ' ')"
if [ "$TOTAL_FILES" -gt 5 ]; then
  FILE_LIST="$FILE_LIST, ..."
fi

COMMIT_MSG="Auto-update: ${SUMMARY} (${FILE_LIST})

Automated commit by Claude Code Stop hook."

git commit -q -m "$COMMIT_MSG" || exit 0

# Push; don't fail the hook if push fails (e.g. offline) — leave the commit
# local and let the next successful push pick it up.
git push -q origin "$BRANCH" 2>/tmp/claude_auto_push_err.log || {
  echo "[auto_commit_push] git push failed, changes committed locally only. See /tmp/claude_auto_push_err.log" >&2
}

exit 0
