#!/usr/bin/env bash
#
# publish-thread.sh — publish a whole X thread from a draft file via xurl.
#
# Draft file format (see templates/):
#   - one tweet per block, blocks separated by a line containing only "---"
#   - HTML comment blocks (<!-- ... -->) are ignored, so template headers
#     can stay in the draft
#
# Usage:
#   scripts/publish-thread.sh <thread-file> [--media-id MEDIA_ID] [--delay SECONDS]
#                             [--dry-run] [--force]
#
# Behavior:
#   - tweet 1 is posted with `xurl post` (with --media-id if given)
#   - every subsequent tweet replies to the IMMEDIATELY PREVIOUS tweet id
#   - sleeps DELAY seconds between tweets (default 10) to avoid rate limits
#   - refuses threads longer than MAX_TWEETS (safety.md cap) unless --force
#   - --dry-run parses and prints the tweets with character counts without
#     calling xurl at all — required before first publish of a new format
#   - prints every created tweet id; keep this output until the thread is
#     verified (Phase F), so the thread can be deleted in reverse order
#     if anything went wrong

set -euo pipefail

DELAY=10
MEDIA_ID=""
THREAD_FILE=""
DRY_RUN=0
FORCE=0
MAX_TWEETS=10
MAX_CHARS=280

usage() {
  echo "Usage: $0 <thread-file> [--media-id MEDIA_ID] [--delay SECONDS] [--dry-run] [--force]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --media-id) MEDIA_ID="${2:?--media-id requires a value}"; shift 2 ;;
    --delay)    DELAY="${2:?--delay requires a value}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --force)    FORCE=1; shift ;;
    -h|--help)  usage ;;
    *)          [[ -n "$THREAD_FILE" ]] && usage; THREAD_FILE="$1"; shift ;;
  esac
done

[[ -n "$THREAD_FILE" ]] || usage
[[ -f "$THREAD_FILE" ]] || { echo "Error: file not found: $THREAD_FILE" >&2; exit 1; }
if [[ $DRY_RUN -eq 0 ]]; then
  command -v xurl >/dev/null || { echo "Error: xurl not found in PATH" >&2; exit 1; }
fi

# Split the draft into one temp file per tweet, skipping HTML comments.
SPLIT_DIR=$(mktemp -d)
trap 'rm -rf "$SPLIT_DIR"' EXIT

awk -v dir="$SPLIT_DIR" '
  /<!--/ { in_comment = 1 }
  in_comment { if (/-->/) in_comment = 0; next }
  /^---[[:space:]]*$/ { n++; next }
  { print > (dir "/" sprintf("%03d", n) ".txt") }
' n=0 "$THREAD_FILE"

TWEET_FILES=("$SPLIT_DIR"/*.txt)
COUNT=${#TWEET_FILES[@]}
[[ $COUNT -ge 1 && -s "${TWEET_FILES[0]}" ]] || { echo "Error: no tweets parsed from $THREAD_FILE" >&2; exit 1; }

if [[ $COUNT -gt $MAX_TWEETS && $FORCE -eq 0 ]]; then
  echo "Error: $COUNT tweets exceeds the safety cap of $MAX_TWEETS (see safety.md)." >&2
  echo "Split the thread, or re-run with --force after owner approval." >&2
  exit 1
fi

trim_tweet_file() {
  awk 'NF {found=1} found' "$1" | awk '{lines[NR]=$0} NF {last=NR} END {for (j=1; j<=last; j++) print lines[j]}'
}

x_weighted_count() {
  python3 -c '
import re, sys
text = sys.stdin.read()
url_re = re.compile(r"https?://\S+")
total = 0
pos = 0
for match in url_re.finditer(text):
    segment = text[pos:match.start()]
    total += sum(1 if ord(ch) <= 0x7F else 2 for ch in segment)
    total += 23
    pos = match.end()
total += sum(1 if ord(ch) <= 0x7F else 2 for ch in text[pos:])
print(total)
'
}

validate_tweet_lengths() {
  local i=0 f text chars failed=0
  for f in "${TWEET_FILES[@]}"; do
    i=$((i + 1))
    text=$(trim_tweet_file "$f")
    chars=$(printf %s "$text" | x_weighted_count)
    if [[ "$chars" -gt "$MAX_CHARS" ]]; then
      echo "Error: tweet $i exceeds X character limit of $MAX_CHARS ($chars chars):" >&2
      echo "$text" >&2
      failed=1
    fi
  done
  [[ $failed -eq 0 ]]
}

validate_tweet_lengths

if [[ $DRY_RUN -eq 1 ]]; then
  echo "DRY RUN — $COUNT tweets parsed from $THREAD_FILE, nothing will be posted."
  echo
  i=0
  for f in "${TWEET_FILES[@]}"; do
    i=$((i + 1))
    TEXT=$(trim_tweet_file "$f")
    # approximate X weighted length: ASCII counts 1, non-ASCII counts 2, URLs count 23
    CHARS=$(printf %s "$TEXT" | x_weighted_count)
    echo "── tweet $i/$COUNT ($CHARS chars) ──"
    echo "$TEXT"
    echo
  done
  echo "Review against the Phase F checklist and safety.md before publishing."
  exit 0
fi

echo "Publishing $COUNT tweets from $THREAD_FILE (delay ${DELAY}s)..."
echo

PREV_ID=""
IDS=()
i=0
for f in "${TWEET_FILES[@]}"; do
  i=$((i + 1))
  # strip leading/trailing blank lines but keep internal line breaks
  TEXT=$(trim_tweet_file "$f")
  [[ -n "$TEXT" ]] || { echo "Error: tweet $i is empty — aborting before posting it" >&2; exit 1; }

  if [[ -z "$PREV_ID" ]]; then
    if [[ -n "$MEDIA_ID" ]]; then
      OUT=$(xurl post "$TEXT" --media-id "$MEDIA_ID")
    else
      OUT=$(xurl post "$TEXT")
    fi
  else
    OUT=$(xurl reply "$PREV_ID" "$TEXT")
  fi

  ID=$(grep -oE '[0-9]{15,}' <<<"$OUT" | head -1) || true
  if [[ -z "$ID" ]]; then
    echo "Error: could not parse tweet id from xurl output after tweet $i:" >&2
    echo "$OUT" >&2
    echo "Already posted ids (delete in reverse order to clean up): ${IDS[*]:-none}" >&2
    exit 1
  fi

  IDS+=("$ID")
  echo "[$i/$COUNT] posted: $ID"
  PREV_ID=$ID

  [[ $i -lt $COUNT ]] && sleep "$DELAY"
done

echo
echo "Done. Thread root: ${IDS[0]}"
echo "All ids (keep until Phase F verification passes):"
printf '  %s\n' "${IDS[@]}"
echo
echo "Next: run Phase F checklist (README.md) and update log.md"
