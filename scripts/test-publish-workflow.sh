#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1" needle="$2"
  grep -Fq -- "$needle" <<<"$haystack" || fail "expected output to contain: $needle"
}

test_watch_upload_uses_oauth1() {
  if ! grep -Eq 'xurl[[:space:]]+media[[:space:]]+upload[[:space:]]+--auth[[:space:]]+oauth1|xurl[[:space:]]+--auth[[:space:]]+oauth1[[:space:]]+media[[:space:]]+upload' scripts/watch-and-publish.sh; then
    fail "watch-and-publish.sh must upload media with xurl --auth oauth1"
  fi
}

test_dry_run_rejects_overlong_tweet() {
  local draft out rc
  draft=$(mktemp)
  python3 - <<'PY' > "$draft"
print('가' * 281)
PY
  set +e
  out=$(scripts/publish-thread.sh "$draft" --dry-run 2>&1)
  rc=$?
  set -e
  rm -f "$draft"
  [[ $rc -ne 0 ]] || fail "dry-run should reject tweets over 280 characters"
  assert_contains "$out" "exceeds X character limit"
}

test_separate_hashtag_lines_count_toward_limit() {
  local draft out rc
  draft=$(mktemp)
  {
    python3 - <<'PY'
print('가' * 275)
PY
    printf '#BuildInPublic\n#AgentOrch\n'
  } > "$draft"
  set +e
  out=$(scripts/publish-thread.sh "$draft" --dry-run 2>&1)
  rc=$?
  set -e
  rm -f "$draft"
  [[ $rc -ne 0 ]] || fail "separate hashtag lines must be parsed and counted before publish"
  assert_contains "$out" "#BuildInPublic"
  assert_contains "$out" "exceeds X character limit"
}

test_korean_weighted_length_rejects_even_under_280_codepoints() {
  local draft out rc
  draft=$(mktemp)
  python3 - <<'PY' > "$draft"
print('가' * 141)
PY
  set +e
  out=$(scripts/publish-thread.sh "$draft" --dry-run 2>&1)
  rc=$?
  set -e
  rm -f "$draft"
  [[ $rc -ne 0 ]] || fail "Korean weighted length over 280 must be rejected even when codepoint count is below 280"
  assert_contains "$out" "exceeds X character limit"
}

main() {
  test_watch_upload_uses_oauth1
  test_dry_run_rejects_overlong_tweet
  test_separate_hashtag_lines_count_toward_limit
  test_korean_weighted_length_rejects_even_under_280_codepoints
  echo "publish workflow tests passed"
}

main "$@"
