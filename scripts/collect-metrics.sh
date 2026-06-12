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
# Requires: xurl, jq
# Note: uses the raw X API v2 tweets lookup endpoint. If your xurl wrapper
# exposes a different interface for raw GET requests, adjust the call below.

set -euo pipefail

[[ $# -ge 2 ]] || { echo "Usage: $0 <window: T+24h|T+7d> <tweet_id>..." >&2; exit 1; }
WINDOW="$1"; shift
ROOT_ID="$1"

command -v xurl >/dev/null || { echo "Error: xurl not found in PATH" >&2; exit 1; }
command -v jq >/dev/null || { echo "Error: jq not found in PATH" >&2; exit 1; }

IDS=$(IFS=,; echo "$*")
OUT=$(xurl get "/2/tweets?ids=${IDS}&tweet.fields=public_metrics")

if ! jq -e '.data' >/dev/null 2>&1 <<<"$OUT"; then
  echo "Error: unexpected API response:" >&2
  echo "$OUT" >&2
  exit 1
fi

read -r IMP LIKES RT REPLIES QUOTES <<<"$(jq -r '
  [.data[].public_metrics]
  | "\(map(.impression_count) | add) \(map(.like_count) | add) \(map(.retweet_count) | add) \(map(.reply_count) | add) \(map(.quote_count) | add)"
' <<<"$OUT")"

echo "Paste into metrics.md (fill Topic/lang and Notes):"
echo
echo "| $(date +%F) | <topic (en/ko)> | \`$ROOT_ID\` | $WINDOW | $IMP | $LIKES | $RT | $REPLIES | $QUOTES | |"
