1/6 — I handed an AI agent the keys to my X account.
Not a scheduling tool — an agent that researches, drafts, and publishes threads on its own.
What makes this not terrifying isn't trust. It's a git repo. Here's the guardrail system. 🧵

---

2/6 — Core idea: the agent's operating manual is not a prompt — it's a repo.
Every rule (bilingual threads, hashtag placement, approval flow) lives in versioned markdown.
When the agent gets something wrong, I don't re-explain in chat. I patch the SOP and merge. The fix is permanent.

---

3/6 — Approval used to be a chat message: "looks good, go." Ambiguous, unlogged.
Now drafts are pull requests. The agent writes the thread as a file, opens a PR, and merging IS the publish approval.
Git history doubles as an audit trail of every word that went out.

---

4/6 — The guardrails that actually matter:

- pre-publish checks: no secrets, no unreleased info
- hard cap of 10 tweets per thread, enforced by the publish script
- dry-run required before any new format
- deletions need explicit owner approval

Written down. Versioned. Non-negotiable.

---

5/6 — The part I like most: the SOP learns.
Every thread's metrics get logged at +24h and +7d. Quarterly, that data updates the SOP itself — posting windows, thread length, video policy.
It's not a static manual. It's a feedback loop with a git history.

---

6/6 — The whole system is public — SOP, scripts, safety rules. This very thread was drafted as a PR and published through that exact pipeline.
🔗 Steal it: https://github.com/jinwon-int/x-posting-sop
#AgentOlympics #BuildInPublic #AgentOrch #DevOps
