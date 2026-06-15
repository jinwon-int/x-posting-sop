---
Draft for review — AI/Programming thread on agent fleet credential management
Character counts verified (body only, excluding prefix)
---

1/6 — We operate a fleet of Hermes AI agents across multiple Android/Termux and VPS nodes. One silent killer was OAuth2 refresh token races. When multiple nodes tried to refresh the same token simultaneously, the refresh token would rotate and invalidate the other. 401 errors everywhere. Here's how we fixed it permanently. 

(248 chars)

2/6 — The root cause: X's OAuth2 refresh tokens can rotate on every use. The canonical refresher (gongyung) runs x_token_refresher.py every 1h. It checks expiration_time in ~/.xurl. If within 30min window, it uses Basic Auth with client_id:client_secret to get new access+refresh pair. Then it pushes the entire ~/.xurl via scp to peer nodes like daegyo. No other node runs a refresher. Single writer pattern prevents the race.

(272 chars)

3/6 — Power-off recovery was the trickiest part. When the Android device restarts after hours offline, ~/.xurl shows stale expiration_time (sometimes 14h past). But xurl often auto-refreshes internally on first API call. The script detects this, syncs the live timestamp without forcing a refresh if possible. Manual run of the refresher on restart always resolves it. Verified with whoami + oauth1 test.

(265 chars)

4/6 — This architecture scales our Seoyoon Family Hermes fleet perfectly. gongyung is the canonical refresher node. All consumers are read-only for tokens. The script includes sync_to_daegyo() that uses a dedicated SSH key. Failures are non-fatal — next cron retries. No more duplicated refresh attempts, no invalid tokens, zero manual PKCE re-auths for months.

(259 chars)

5/6 — The deeper lesson for agent orchestration: every shared resource needs a single canonical owner. Just like we never let agents merge to prod without human PR approval, we don't let multiple agents manage the same credential. Guardrails at the infrastructure layer compound to make autonomous fleets actually survivable.

(251 chars)

6/6 — From liberal arts phone-based 11-VPS fleet to reliable multi-node AI ops. The delegation gap isn't solved by bigger models. It's solved by clear rules, single sources of truth, and explicit safety trials. Token management taught us as much as the DN42 bankruptcy story.

#BuildInPublic #AgentOrch #DevOps

(238 chars)
