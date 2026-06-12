#!/usr/bin/env bash
#
# collect-metrics.sh — fetch public metrics for a published thread and print
# a markdown row ready to paste into metrics.md.
#
# Usage:
#   scripts/collect-metrics.sh <window> <tweet_id> [tweet_id...]
#
#   window    label for the capture window, e.g. T+24h or T+7d
#   tweet_id  every tweet id in the thread (metrics are summed across them);
#             publish-thread.sh prints these ids at publish time
#
# Requires: xurl, jq (optional — falls back to grep)
# Note: Uses individual xurl read calls because xurl get batch endpoint
#       (/2/tweets?ids=) is unreliable on this install.

set -euo pipefail

[[ $# -ge 2 ]] || { echo "Usage: $0 <window: T+24h|T+7d> <tweet_id>..." >&2; exit 1; }
WINDOW="$1"; shift
ROOT_ID="$1"

command -v xurl >/dev/null || { echo "Error: xurl not found in PATH" >&2; exit 1; }

IMP=0 LIKES=0 RT=0 REPLIES=0 QUOTES=0

for tid in "$@"; do
  OUT=$(xurl read "$tid" 2>/dev/null) || { echo "Error: xurl read $tid failed" >&2; continue; }

  # Extract metrics with jq if available, otherwise grep
  if command -v jq >/dev/null 2>&1; then
    read -r i l r re q <<<"$(echo "$OUT" | jq -r '
      .data.public_metrics |
      "\(.impression_count) \(.like_count) \(.retweet_count) \(.reply_count) \(.quote_count)"
    ' 2>/dev/null)"
  else
    i=$(echo "$OUT" | grep -oP '"impression_count":\s*\K\d+' | head -1)
    l=$(echo "$OUT" | grep -oP '"like_count":\s*\K\d+' | head -1)
    r=$(echo "$OUT" | grep -oP '"retweet_count":\s*\K\d+' | head -1)
    re=$(echo "$OUT" | grep -oP '"reply_count":\s*\K\d+' | head -1)
    q=$(echo "$OUT" | grep -oP '"quote_count":\s*\K\d+' | head -1)
  fi

  IMP=$((IMP + ${i:-0}))
  LIKES=$((LIKES + ${l:-0}))
  RT=$((RT + ${r:-0}))
  REPLIES=$((REPLIES + ${re:-0}))
  QUOTES=$((QUOTES + ${q:-0}))
done

echo "Paste into metrics.md (fill Topic/lang and Notes):"
echo
echo "| $(date +%F) | <topic (en/ko)> | \`$ROOT_ID\` | $WINDOW | $IMP | $LIKES | $RT | $REPLIES | $QUOTES | |"
