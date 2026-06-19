# Simplified Draft Writing Logic for X Threads (2026-06-19 Update)

**Goal:** Make draft creation straightforward with minimal trimming cycles. Focus on substance over perfect char count. (Added per gongyung cron improvement request)

## Easy 5-Tweet Structure (use this every time)
1. **Hook** (Tweet 1): Strong number/question + personal observation from gongyung's real ops (target ~240 chars)
2. **Context/Story** (Tweet 2): What actually happened in practice (fallback layers, token sync, etc.)
3. **Technical Lesson** (Tweet 3): The key mechanism or fallback layer
4. **Application** (Tweet 4): How it applies to 11 VPS fleet / Hermes nodes / multi-agent orchestration
5. **Conclusion + Hashtags** (Tweet 5): Takeaway + 2-3 relevant hashtags (#BuildInPublic #AgentOrch #DevOps etc.)

## Char Target (simplified): 200-280 chars per tweet
- Quick verifier (run on **clean strings only** — strip all meta notes like "(267 chars)", "**Tweet 5:**" first):
  ```bash
  python3 -c '
  tweets = ["""paste clean tweet 1 here""", """tweet 2""", """tweet 3""", """tweet 4""", """tweet 5"""]
  for i, t in enumerate(tweets, 1):
      length = len(t.strip())
      status = "GOOD" if 200 <= length <= 280 else "ADJUST"
      print(f"Tweet {i}: {length} chars - {status}")
  '
  ```
- Under 200 → add one concrete example or "why it matters for autonomous fleet".
- Over 280 → remove 1-2 adjectives or shorten one sentence. Usually 1-2 passes max.

## KO Writing (2-step easy expansion)
1. Direct translation of the EN version.
2. Insert:
   - "이는 [specific detail from story or mechanism] 때문이다."
   - End with "결과적으로 [practical outcome]다."

**Example (MCP Fallback theme from recent tweet):**
- EN Hook: "One Android device orchestrates an 11-VPS fleet with multiple Hermes nodes, daily X threads, Wiki management, and multi-agent workflows."
- KO Expanded: "안드로이드 기기 하나로 11대 VPS 플릿을 AI 에이전트들이 자율 운영하게 하고, 여러 Hermes 노드, 매일 X 스레드, 위키 관리, 멀티에이전트 워크플로우를 조율한다. 이는 모델을 완벽하게 만드는 것이 아니라 실패 상황에서도 정상 동작하는 폴백 레이어를 여러 개 둔 덕분이다. 원격 위키가 닿지 않아도 지식은 로컬에 살아있다. 결과적으로 이것이 진짜 자율 에이전트 시스템을 만드는 방법이다."

## Slides.txt (easy 4-slide template)
```
주제 Hook + Number
11 VPS on Android + Fallbacks
---
Core Insight
Not perfect models but multiple safety layers
---
Real Mechanism
Local knowledge survives when remote Wiki is unreachable
---
Outcome
True autonomous agent system
```

This logic is now the recommended default in the 21:00 cron agent runbook (`references/x-posting-cron-agent.md` in the Hermes skill). It dramatically reduces friction while keeping the density and quality that produces high-engagement threads.

See also: `char-density-verification.md` (updated with the new 200-280 range and one-liner).

Submitted via gongyung on 2026-06-19.
