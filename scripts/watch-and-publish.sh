#!/usr/bin/env bash
#
# watch-and-publish.sh — poll main for newly merged drafts and publish them.
#
# Runner-free alternative to .github/workflows/publish-on-merge.yml for nodes
# where the official GitHub Actions runner can't run (e.g. Termux/Android).
# Run it on the Hermes node via cron or a job scheduler, e.g. every 5 min:
#
#   */5 * * * * cd /path/to/x-posting-sop && scripts/watch-and-publish.sh
#
# First-time setup on the node (marks existing drafts as already published
# so only FUTURE merges get posted):
#
#   scripts/watch-and-publish.sh --init
#
# State lives in .watch-published.list (gitignored, node-local).
# Safety: refuses to publish more than 2 new drafts in one run (safety.md
# daily cap) — clear the backlog manually if that ever triggers.

set -euo pipefail
cd "$(dirname "$0")/.."

STATE_FILE=".watch-published.list"
touch "$STATE_FILE"

list_drafts() {
  local f
  for f in drafts/*.md; do
    [[ -e "$f" && "$f" != */README.md ]] && echo "$f"
  done
}

if [[ "${1:-}" == "--init" ]]; then
  list_drafts > "$STATE_FILE"
  echo "Initialized: $(wc -l < "$STATE_FILE") existing draft(s) marked as published."
  exit 0
fi

# Sync to latest main; abort if tracked files are modified. Untracked files
# are tolerated (locally rendered mp4s live in videos/), but if origin/main
# now ships a CI-rendered mp4 with the same name, the CI version is
# canonical — drop the local copy so the fast-forward can't collide.
git fetch origin main --quiet
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "Error: tracked files modified — resolve manually before auto-publish." >&2
  exit 1
fi
git checkout main --quiet
while IFS= read -r f; do
  if [[ -f "$f" ]] && ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo "Replacing locally rendered $f with the CI-rendered version from main."
    rm -f "$f"
  fi
done < <(git diff --name-only HEAD origin/main -- 'videos/*.mp4')
git merge --ff-only origin/main --quiet

# Emergency stop: create .publish-paused (node-local file or committed to
# main) to halt all auto-publishing; remove it to resume.
if [[ -f .publish-paused ]]; then
  echo "Auto-publish paused (.publish-paused present) — remove the file to resume."
  exit 0
fi

NEW=()
while IFS= read -r f; do
  grep -qxF "$f" "$STATE_FILE" || NEW+=("$f")
done < <(list_drafts)

[[ ${#NEW[@]} -eq 0 ]] && exit 0

# Merge = approval (safety.md). A draft counts as approved only when the
# commit that ADDED it belongs to a merged PR. Authoritative check via the
# GitHub API when gh is available — this correctly recognizes squash,
# merge, AND rebase merges. Without gh, falls back to commit heuristics
# (squash subject "(#N)" or two parents), which cannot recognize rebase
# merges — use squash merges if running heuristic-only. Drafts pushed
# straight to main bypass owner review and are NEVER auto-published.
commit_is_pr_merge() {
  local sha="$1" merged
  if command -v gh >/dev/null 2>&1; then
    merged=$(gh api "repos/{owner}/{repo}/commits/$sha/pulls" \
      --jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null) || merged=""
    if [[ "$merged" =~ ^[0-9]+$ ]]; then
      [[ "$merged" -gt 0 ]]
      return
    fi
    echo "Note: gh API check failed for $sha — falling back to commit heuristics." >&2
  fi
  local info parents subject
  info=$(git log --format='%P%x09%s' -1 "$sha")
  parents=${info%%$'\t'*}
  subject=${info#*$'\t'}
  [[ "$subject" =~ \(#[0-9]+\)$ || "$parents" == *" "* ]]
}

APPROVED=()
for f in "${NEW[@]}"; do
  sha=$(git log --diff-filter=A --format='%H' -1 -- "$f")
  if commit_is_pr_merge "$sha"; then
    APPROVED+=("$f")
  else
    echo "WARNING: $f reached main without a PR merge (direct push?) — refusing to publish (safety.md)." >&2
  fi
done

[[ ${#APPROVED[@]} -eq 0 ]] && exit 0

if [[ ${#APPROVED[@]} -gt 2 ]]; then
  echo "Safety: ${#APPROVED[@]} unpublished drafts exceed the 2-thread daily cap (safety.md)." >&2
  printf '  %s\n' "${APPROVED[@]}" >&2
  echo "Publish manually with scripts/publish-thread.sh, then append each to $STATE_FILE." >&2
  exit 1
fi

# Resolve the video for a draft, rendering the source if needed.
# Convention: drafts/YYYY-MM-DD-topic-en.md -> videos/YYYY-MM-DD-topic.mp4
video_for() {
  local topic="$1" src
  if [[ ! -f "videos/$topic.mp4" ]]; then
    for src in "videos/$topic.slides.txt" "videos/$topic.cast" "videos/$topic.tape"; do
      if [[ -f "$src" ]]; then
        scripts/render-video.sh "$src" >&2 || return 1
        break
      fi
    done
  fi
  [[ -f "videos/$topic.mp4" ]] && echo "videos/$topic.mp4"
  return 0
}

# Glob order is lexicographic, so YYYY-MM-DD-topic-en.md precedes -ko.md
# (EN-first rule). The EN upload's media id is reused for the KO thread
# within the same run (X keeps media ids valid ~15 days).
declare -A MEDIA_CACHE
for f in "${APPROVED[@]}"; do
  b=$(basename "$f" .md)
  topic=${b%-en}; topic=${topic%-ko}

  MEDIA_ARGS=()
  VIDEO=$(video_for "$topic") || { echo "Error: video render failed for $topic — not publishing." >&2; exit 1; }
  if [[ -n "$VIDEO" ]]; then
    if [[ -z "${MEDIA_CACHE[$topic]:-}" ]]; then
      UP=$(xurl media upload --auth oauth1 "$VIDEO")
      MID=$(grep -oE '[0-9]{15,}' <<<"$UP" | head -1) || true
      if [[ -z "$MID" ]]; then
        echo "Error: could not parse media id from upload output — not publishing:" >&2
        echo "$UP" >&2
        exit 1
      fi
      MEDIA_CACHE[$topic]=$MID
      echo "Uploaded $VIDEO (media id ${MID})"
    fi
    MEDIA_ARGS=(--media-id "${MEDIA_CACHE[$topic]}")
  fi

  echo "=== Publishing $f ${VIDEO:+(with $VIDEO)} ==="
  scripts/publish-thread.sh "$f" ${MEDIA_ARGS[@]+"${MEDIA_ARGS[@]}"}
  echo "$f" >> "$STATE_FILE"
done

echo
echo "Reminder: Phase F checklist, update log.md, label backlog issue 'published'."
