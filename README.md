# X (Twitter) Posting SOP

**Owner:** [@jinon_seo](https://x.com/jinon_seo)  
**Operator:** Gongyung (공융, Android Hermes node)  
**Repository:** [jinwon-int/x-posting-sop](https://github.com/jinwon-int/x-posting-sop)

---

Build in Public 콘텐츠를 `@jinon_seo` 계정으로 X에 발행하는 표준 운영 절차(SOP).
Agent Olympics, A2A, Hermes/OpenClaw 비교, Termux/Android 셀프호스팅, 인프라 인사이트를 EN/KO 이중 언어로 발행한다.

## Table of Contents

- [Repository Layout](#repository-layout)
- [Required Tools](#required-tools)
- [Content Backlog](#content-backlog)
- [Core Rules](#core-rules)
- [Step-by-Step Workflow](#step-by-step-workflow)
- [Publishing Script](#publishing-script)
- [Auto-Publish on Merge](#auto-publish-on-merge)
- [Troubleshooting](#troubleshooting)

---

## Repository Layout

| Path | Purpose |
|------|---------|
| `README.md` | 본 SOP 문서 (허브) |
| `safety.md` | **에이전트 안전 규칙 — 모든 규칙에 우선** |
| `voice.md` | 보이스/스타일 가이드 + EN↔KO 용어집 |
| `engagement.md` | 발행 후 멘션·리플라이 대응 SOP |
| `metrics.md` | 성과 기록 + 분기 리뷰 — SOP 권장값 갱신의 근거 |
| `log.md` | 발행 이력 (회차별 스레드 ID, 토픽, 비고) |
| `templates/` | EN/KO 스레드 템플릿 — 복사해서 드래프트 시작 |
| `drafts/` | 발행 전 드래프트. PR로 올려 오너 리뷰 → 승인 이력이 git에 남음 |
| `scripts/` | 발행 자동화 (`publish-thread.sh`), 메트릭 수집 (`collect-metrics.sh`) |
| `.github/` | 콘텐츠 백로그 이슈 템플릿, 머지 시 자동 발행 워크플로 |

---

## Required Tools

| Tool | Purpose |
|------|---------|
| `xurl` | X API v2 CLI — posting, search, mentions, media upload |
| `ffmpeg` | 15-second video creation (optional) |
| `gh` / GitHub API | Repository content review |
| Hermes Agent | Drafting, translation, execution |
| `jq` | Metrics collection (`collect-metrics.sh`) |

---

## Content Backlog

토픽 관리는 GitHub Issues로 한다. **토픽 1개 = 이슈 1개.**

- 새 아이디어는 "Content idea" 이슈 템플릿으로 등록한다 (`idea` 라벨 자동 부착).
- 라벨 파이프라인: `idea` → `drafted` (드래프트 PR 연결 시) → `approved`
  (오너 승인 시) → 발행 후 이슈 close + `published`.
- 드래프트 PR 본문에 `Closes #<이슈번호>` 를 넣어 백로그와 연결한다.
- 에이전트는 다음 토픽을 백로그에서 고른다. 오너는 이슈에 코멘트/라벨로
  우선순위를 지정할 수 있다.
- 사전 준비: 레포에 `idea` / `drafted` / `approved` / `published` 라벨 4개를
  만들어 둔다.

---

## Core Rules

> **전제: [safety.md](safety.md)의 에이전트 안전 규칙이 아래 모든 규칙에
> 우선한다.** 발행 전 콘텐츠 체크, 볼륨 한도, 삭제 규칙은 그쪽을 따른다.
> 문체·용어는 [voice.md](voice.md)를 따른다.

### EN/KO Strict Separation

- **EN-only thread** and **KO-only thread** are published as **separate threads**.
- Never mix both languages in one thread.
- KO thread is NOT a reply to the EN thread — completely independent.

### Approval & Posting Sequence

```
EN draft → Owner review → KO draft → Owner approval → EN publish → KO publish
```

1. Present EN draft first (as a PR adding a file under `drafts/`).
2. When the owner asks for the translation (in any wording), present the KO draft.
3. Publish only after the owner gives an **explicit go-ahead** — any clear
   approval expression counts (e.g. "진행", "go", "ship it", PR approval).
   When in doubt whether something was an approval, ask; never publish on an
   ambiguous signal.
4. Publish EN thread first, then KO thread.

### Posting Schedule

Initial guideline — tune with engagement analytics over time:

| Audience | Recommended window (KST) | Rationale |
|----------|--------------------------|-----------|
| EN | 22:00–01:00 | US East Coast morning / Europe afternoon |
| KO | 08:00–10:00 or 19:00–22:00 | KR commute & evening peak |

- Target cadence: 1–3 threads per week. Consistency beats volume.
- Avoid publishing EN and KO back-to-back within the same minute; space them
  to land in their respective audience windows when possible.

### Video Policy (Optional)

- First tweet with a 15-second ffmpeg video is recommended. Internal working
  assumption (unverified, last reviewed 2026-06): 15–30s video gets roughly
  10–20x reach over text on the current X algorithm — re-validate
  periodically against own analytics.
- Same media ID is reusable across EN and KO threads. Per X API docs the
  media ID stays valid for a limited period (observed ~15 days as of
  2026-06) — confirm before reusing old media.
- Video is produced separately when needed.

### Hashtags

- Primary: `#AgentOlympics` `#BuildInPublic` `#AgentOrch` `#DevOps`
- Place hashtags on the **last tweet only**, not the first.

### Tweet Length

- X Premium allows ~4,000 characters per tweet, but keep tweets short for
  readability.
- **EN:** 250–350 characters per tweet.
- **KO:** 한글은 같은 정보량에서 글자 수가 더 적게 나오므로 EN 기준을 그대로
  쓰지 않는다. 트윗당 **140–220자(한글 기준)** 권장.

### Error Recovery (Delete & Republish)

If EN/KO get mixed or the thread order is broken, **delete the entire thread
and republish**. Concrete procedure:

```bash
# Delete in REVERSE order (last tweet first) so no orphaned replies remain.
xurl delete <tweet_id_last>
# ...
xurl delete <tweet_id_first>

# Then republish the whole thread:
scripts/publish-thread.sh drafts/<file>.md
```

- `scripts/publish-thread.sh` prints every tweet ID it creates — keep that
  output until the thread is verified, so deletion is always possible.
- Record the incident in `log.md` (Notes column).

---

## Step-by-Step Workflow

### Phase A: Research

```bash
# 1. Review repository content
gh repo view jinwon-int/agent-olympics

# 2. Check existing post history (avoid duplication)
#    First grep the in-repo archive, then search X:
grep -ri "<keyword>" log.md drafts/
xurl search "from:jinon_seo <keyword>" -n 5

# 3. Read previous post for follow-up positioning
xurl read <previous_post_id>
```

### Phase B: Draft

1. Pick the topic from the [Content Backlog](#content-backlog) — the issue's
   "Key messages" field is the skeleton. (백로그에 없는 즉흥 토픽이면 이슈부터
   만든다.)
2. Copy `templates/thread-en.md` to `drafts/YYYY-MM-DD-<topic>-en.md` and
   compose the EN thread (4–8 tweets), following [voice.md](voice.md):
   - **Tweet 1**: Hook — problem statement or counter-intuitive claim
   - **Middle tweets**: Detailed explanation — architecture, philosophy, examples
   - **Last tweet**: CTA — repo link + hashtags
3. Open a PR with the draft (`Closes #<백로그 이슈>`) → owner reviews →
   incorporate feedback. 이슈 라벨을 `drafted`로 옮긴다.
4. Translate to KO (`drafts/YYYY-MM-DD-<topic>-ko.md`, based on
   `templates/thread-ko.md`, glossary in [voice.md](voice.md)) → present →
   wait for explicit approval. 승인되면 라벨을 `approved`로.
5. Run `safety.md` 발행 전 콘텐츠 체크 + `--dry-run` for new formats.
6. Drafts stay in the repo after publishing, as the archive of what was posted.

### Phase C: Publish (EN)

Preferred — use the script (handles ID chaining and rate-limit spacing):

```bash
scripts/publish-thread.sh drafts/2026-06-12-topic-en.md
```

Manual fallback:

```bash
# First tweet → save the ID
xurl post "<tweet content>"
# → Returns ID: 2065015595238863269

# Subsequent tweets: reply to the previous tweet
xurl reply <previous_tweet_id> "<tweet content>"

# Repeat for each tweet in the thread...
```

**Critical:**
- `xurl reply` targets the **immediately previous tweet ID**, not the first tweet ID.
- xurl auto-converts URLs to t.co short links.
- Wait 5–10 seconds between tweets to avoid rate limiting (the script does
  this automatically).

### Phase D: Publish (KO)

Same method as EN, as a **separate independent thread**:

```bash
scripts/publish-thread.sh drafts/2026-06-12-topic-ko.md
```

### Phase E: Media (Optional)

```bash
# Upload video
xurl media upload video.mp4
# → Save MEDIA_ID

# Attach to first tweet (script):
scripts/publish-thread.sh drafts/<file>-en.md --media-id MEDIA_ID

# Reuse same media-id for the KO thread:
scripts/publish-thread.sh drafts/<file>-ko.md --media-id MEDIA_ID
```

### Phase F: Verification (Checklist)

Run through ALL of these right after publishing each thread:

- [ ] `xurl read <first_tweet_id>` — thread reads top-to-bottom in correct order
- [ ] No EN/KO mixing anywhere in the thread
- [ ] Links work after t.co conversion (click through at least the repo link)
- [ ] Hashtags appear on the **last** tweet only
- [ ] Media attached and playing (if used)
- [ ] `log.md` updated with date, topic, type, and both thread IDs
- [ ] Backlog issue closed with `published` label
- [ ] `xurl mentions -n 10` — check early replies/engagement

If any check fails → follow [Error Recovery](#error-recovery-delete--republish).

발행 후 48시간은 [engagement.md](engagement.md)의 멘션 대응 케이던스를 따른다.

### Phase G: Metrics (T+24h / T+7d)

발행은 메트릭 기록까지가 한 사이클이다 — 이 데이터가 SOP를 갱신한다.

```bash
# 발행 후 24시간, 7일 시점에 스레드별로 실행 (IDs는 publish 출력에서):
scripts/collect-metrics.sh T+24h <id1> <id2> ...
scripts/collect-metrics.sh T+7d  <id1> <id2> ...
# 출력된 행을 metrics.md 표에 붙여넣는다.
```

분기마다 [metrics.md](metrics.md)의 Quarterly Review 체크리스트를 수행하고,
결론을 README 권장값(시간대/길이/영상 정책)에 PR로 반영한다.

---

## Publishing Script

`scripts/publish-thread.sh` posts a whole thread from a draft file:

- Input file format: tweets separated by a line containing only `---`
  (the format used by `templates/`).
- Posts tweet 1 with `xurl post` (optionally with `--media-id`), then chains
  each subsequent tweet with `xurl reply <previous_id>` — eliminating the
  most common manual error (replying to the wrong ID).
- Sleeps between tweets (default 10s, configurable with `--delay`).
- `--dry-run` parses and prints tweets with character counts without posting —
  required before the first publish of any new format (safety.md).
- Refuses threads over 10 tweets (safety cap); `--force` overrides only with
  owner approval.
- Prints every created tweet ID; keep the output until Phase F passes.

```bash
scripts/publish-thread.sh <thread-file> [--media-id MEDIA_ID] [--delay SECONDS] [--dry-run] [--force]
```

---

## Auto-Publish on Merge

drafts/에 파일을 추가하는 PR이 **머지되면 그 머지를 승인 신호로 삼아** 자동
발행한다. 승인·발행·기록이 전부 GitHub에서 일어난다. 구현 경로는 두 가지 —
어느 쪽이든 파일명 정렬 순서로 발행되므로 `-en.md`가 `-ko.md`보다 먼저
나간다(EN-first 규칙 자동 충족).

### Route A: 폴링 스크립트 (Termux/Hermes 노드 권장)

GitHub Actions runner가 안 도는 환경(Android/Termux)을 위한 runner-free 방식.
xurl 인증이 있는 노드에서:

```bash
# 1회: 기존 드래프트를 발행됨으로 표시 (이후 머지분만 발행됨)
scripts/watch-and-publish.sh --init

# cron 또는 잡 스케줄러로 5분마다:
*/5 * * * * cd /path/to/x-posting-sop && scripts/watch-and-publish.sh
```

main에 새로 머지된 드래프트를 발견하면 발행하고 노드 로컬 상태 파일에
기록한다. 한 번에 2개(하루 한도, safety.md) 초과분이 쌓여 있으면 발행을
거부하고 수동 처리를 요구한다.

### Route B: GitHub Actions (self-hosted runner가 가능한 환경)

`.github/workflows/publish-on-merge.yml`. **기본 비활성.** 활성화 조건:

1. xurl 인증이 잡혀 있는 노드에 self-hosted runner 등록.
2. 레포 변수 `AUTO_PUBLISH=true` 설정 (Settings → Actions → Variables).

두 경로를 동시에 켜면 중복 발행되므로 **하나만 선택**한다. 활성화 전까지는
머지 후 수동으로 `publish-thread.sh`를 실행한다.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `xurl post` returns 401 | OAuth token expired | Re-run `xurl auth oauth2 --app <app-name>` |
| `xurl post` returns 403 | Insufficient scope | Check OAuth2 scopes in X Developer Portal |
| `xurl post` returns 429 | Rate limit hit (posting too fast, or daily/monthly tier cap) | Wait and retry; keep ≥5–10s between tweets; check your API tier limits in the X Developer Portal before long threads |
| Thread order broken | Reply attached to wrong ID | Delete entire thread (reverse order, see [Error Recovery](#error-recovery-delete--republish)) and republish with the script |
| Media processing failed | Wrong category | Add `--category tweet_image --media-type image/png` |
| Duplicate content | Skipped history check | Always grep `log.md` + `xurl search` before drafting |
