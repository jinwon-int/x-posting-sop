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

# Sync to latest main; abort quietly if the tree isn't clean.
git fetch origin main --quiet
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree not clean — resolve manually before auto-publish." >&2
  exit 1
fi
git checkout main --quiet
git merge --ff-only origin/main --quiet

NEW=()
while IFS= read -r f; do
  grep -qxF "$f" "$STATE_FILE" || NEW+=("$f")
done < <(list_drafts)

[[ ${#NEW[@]} -eq 0 ]] && exit 0

if [[ ${#NEW[@]} -gt 2 ]]; then
  echo "Safety: ${#NEW[@]} unpublished drafts exceed the 2-thread daily cap (safety.md)." >&2
  printf '  %s\n' "${NEW[@]}" >&2
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
for f in "${NEW[@]}"; do
  b=$(basename "$f" .md)
  topic=${b%-en}; topic=${topic%-ko}

  MEDIA_ARGS=()
  VIDEO=$(video_for "$topic") || { echo "Error: video render failed for $topic — not publishing." >&2; exit 1; }
  if [[ -n "$VIDEO" ]]; then
    if [[ -z "${MEDIA_CACHE[$topic]:-}" ]]; then
      UP=$(xurl media upload "$VIDEO")
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
