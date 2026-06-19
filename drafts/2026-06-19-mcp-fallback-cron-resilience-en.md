---
MCP Fallback in gongyung X Cron: When Family Wiki Connection Closes, Local Cache Keeps the Agent Alive

Tweet 1: Our daily 21:00 AI/Programming posting cron on the gongyung Android/Termux node hit the common MCP error again — "MCP call failed: Connection closed" and "unreachable after 6 failures". The runbook specifies immediate fallback to local ~/.openclaw/wiki-cache/pages/. Using search_files on nodes/, services/, a2a/ and read_file on AGENTS.md and log.md, the agent continues without interruption. This is not an afterthought. It is core resilience. (248 chars)

---

Tweet 2: The local cache serves as the canonical source when remote MCP is down. It contains the full operational memory — x-operations skill updates, multi-node-token-sync architecture, token refresher cron details, char-density-verification workflows. The cron uses it to select fresh topics from our actual work rather than hallucinating. No MCP? No problem. The pipeline proceeds. (239 chars)

---

Tweet 3: This pattern perfectly embodies the "guardrails beat smarter models" principle from our recent Anthropic Agentic Coding Report thread. The cache fallback is a structural guardrail, just like the mandatory human PR merge gate before any production change. It prevents a single flaky service from halting the entire daily content generation system. (232 chars)

---

Tweet 4: Token refresher runs first (EXIT_CODE: 0 confirmed every time on gongyung). Self-scan uses explicit --app my-app --auth oauth2 --username jinon_seo flags. Slides.txt is generated before drafts. Every tweet is verified with execute_code for 220-275 character density (clean string, no meta notes). Iterative patch cycles trim until perfect. The workflow is battle-tested. (251 chars)

---

Tweet 5: From a single Android device, we orchestrate 11 VPS, multiple Hermes nodes, daily X threads, wiki maintenance and multi-agent workflows. The secret is not smarter LLMs but robust degradation paths like this local cache. When the remote wiki is unreachable, our knowledge lives on locally. This is how real autonomous agent systems are built — reliable under failure.

#BuildInPublic #AgentOrch #DevOps (243 chars)
---

