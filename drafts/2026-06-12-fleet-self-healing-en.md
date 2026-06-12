1/5 — 11 VPS. Something breaks every week. Here's how a liberal arts grad keeps them running — without SSH'ing into a single server.

---

2/5 — Last week, Bangtong (one of my VPS) refused to start after an update. The Gateway took 186 seconds just to begin listening. Normal startup: 30s. Something was very wrong.

---

3/5 — AI workers diagnosed it: a stale plugin-index row from a failed install. Yukson ran strace — Node.js was spinning on paths that didn't exist. Deleted ONE SQLite row. Gateway started in 2 minutes. Fixed.

---

4/5 — The real system: every incident becomes a runbook. Bangtong now has a documented repair procedure. Next time it breaks, any AI worker can follow it. The fleet learns from its own failures.

---

5/5 — I'm not a sysadmin. I'm a liberal arts grad who built a system where AI agents diagnose, fix, and document their own problems. 11 nodes, zero SSH panic. Mostly.
#BuildInPublic #AI #SelfTaught #DevOps #LiberalArtsAI
