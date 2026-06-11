# X (Twitter) Posting SOP

**Owner:** [@jinon_seo](https://x.com/jinon_seo)  
**Operator:** Gongyung (공융, Android Hermes node)  
**Repository:** [jinwon-int/x-posting-sop](https://github.com/jinwon-int/x-posting-sop)

---

Build in Public 콘텐츠를 `@jinon_seo` 계정으로 X에 발행하는 표준 운영 절차(SOP).
Agent Olympics, A2A, Hermes/OpenClaw 비교, Termux/Android 셀프호스팅, 인프라 인사이트를 EN/KO 이중 언어로 발행한다.

## Table of Contents

- [1. Required Tools](#1-required-tools)
- [2. Core Rules](#2-core-rules)
- [3. Step-by-Step Workflow](#3-step-by-step-workflow)
- [4. Thread Structure Template](#4-thread-structure-template)
- [5. Example Log](#5-example-log)
- [6. Troubleshooting](#6-troubleshooting)

---

## 1. Required Tools

| Tool | Purpose |
|------|---------|
| `xurl` | X API v2 CLI — posting, search, mentions, media upload |
| `ffmpeg` | 15-second video creation (optional) |
| `gh` / GitHub API | Repository content review |
| Hermes Agent | Drafting, translation, execution |

---

## 2. Core Rules

### 2.1 EN/KO Strict Separation

- **EN-only thread** and **KO-only thread** are published as **separate threads**.
- Never mix both languages in one thread.
- KO thread is NOT a reply to the EN thread — completely independent.

### 2.2 Posting Sequence

```
EN draft → Owner review → KO draft → Owner approval → EN publish → KO publish
```

1. Present EN draft first.
2. On "번역본도 보여줘" (show me the translation), present KO draft.
3. On "진행" (proceed), publish EN thread first, then KO thread.

### 2.3 Video Policy (Optional)

- First tweet with 15-second ffmpeg video recommended (X Algorithm: video 15–30s = 10–20x reach over text).
- Same media ID reusable across EN and KO threads (media ID valid for 15 days).
- Video is produced separately when needed.

### 2.4 Hashtags

- Primary: `#AgentOlympics` `#BuildInPublic` `#AgentOrch` `#DevOps`
- Place hashtags on the **last tweet only**, not the first.

### 2.5 Error Recovery

- If EN/KO get mixed or thread order is broken, **delete the entire thread and republish**.

---

## 3. Step-by-Step Workflow

### Phase A: Research

```bash
# 1. Review repository content
gh repo view jinwon-int/agent-olympics

# 2. Check existing post history (avoid duplication)
xurl search "from:jinon_seo <keyword>" -n 5

# 3. Read previous post for follow-up positioning
xurl read <previous_post_id>
```

### Phase B: Draft

1. Extract 3–5 key messages from repo README, docs, issues.
2. Compose EN thread (4–8 tweets):
   - **Tweet 1**: Hook — problem statement or counter-intuitive claim
   - **Middle tweets**: Detailed explanation — architecture, philosophy, examples
   - **Last tweet**: CTA — repo link + hashtags
3. Present to owner → incorporate feedback.
4. Translate to KO thread → present to owner → wait for "진행".

### Phase C: Publish (EN)

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
- X Premium allows ~4,000 characters per tweet; keep to 250–350 chars for readability.

### Phase D: Publish (KO)

Same method as EN, as a **separate independent thread**.

```bash
xurl post "<KO tweet content>"
xurl reply <previous_id> "<KO tweet content>"
# ...repeat
```

### Phase E: Media (Optional)

```bash
# Upload video
xurl media upload video.mp4
# → Save MEDIA_ID

# Attach to first tweet
xurl post "<tweet content>" --media-id MEDIA_ID

# Reuse same media-id for KO first tweet
xurl post "<KO tweet content>" --media-id MEDIA_ID
```

### Phase F: Verification

```bash
# Read published thread
xurl read <first_tweet_id>

# Check mentions / engagement
xurl mentions -n 10
```

---

## 4. Thread Structure Template

### EN Template

```
1/6 (Hook)
<Problem statement or counter-intuitive claim>
<Brief context>

2/6 (Detail)
<Core architecture or concept explanation>

3/6 (Example)
<Concrete example or real application>

4/6 (Insight)
<Lesson learned or key takeaway from experience>

5/6 (Core Message)
<Single most important point to convey>

6/6 (CTA)
<Repo link>
<Hashtags>
```

### KO Template

Same structure as EN, translated to Korean. Maintains the same narrative arc.

---

## 5. Example Log

| Date | Topic | Type | EN Thread | KO Thread |
|------|-------|------|-----------|-----------|
| 2026-06-10 | Agent Olympics intro | New | [`2064682670312075513`](https://x.com/jinon_seo/status/2064682670312075513) (2 tweets) | — |
| 2026-06-11 | Agent Olympics architecture | Follow-up | [`2065015595238863269`](https://x.com/jinon_seo/status/2065015595238863269) (6 tweets) | [`2065015698464931912`](https://x.com/jinon_seo/status/2065015698464931912) (6 tweets) |

---

## 6. Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `xurl post` returns 401 | OAuth token expired | Re-run `xurl auth oauth2 --app <app-name>` |
| `xurl post` returns 403 | Insufficient scope | Check OAuth2 scopes in X Developer Portal |
| Thread order broken | Reply attached to wrong ID | Delete entire thread and republish |
| Media processing failed | Wrong category | Add `--category tweet_image --media-type image/png` |
| Duplicate content | Skipped history check | Always `xurl search` before drafting |
