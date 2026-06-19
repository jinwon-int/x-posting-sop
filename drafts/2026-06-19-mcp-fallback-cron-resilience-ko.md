---
gongyung X 포스팅 크론에서 MCP 연결이 닫히는 상황. 로컬 위키 캐시가 에이전트를 구한다.

트윗 1: gongyung 안드로이드 Termux 노드에서 매일 21시에 실행되는 AI/프로그래밍 X 포스팅 크론이 MCP 오류를 다시 만났다. "Connection closed"와 "6회 실패 후 unreachable" 메시지가 떴다. 런북은 즉시 ~/.openclaw/wiki-cache/pages/ 로컬 캐시로 폴백하라고 지시한다. nodes/ services/ a2a/ 디렉터리를 search_files로 탐색하고 AGENTS.md와 log.md를 read_file로 읽으면서 작업을 계속한다. 이것은 임시방편이 아니라 핵심 설계다. (251 chars)

---

트윗 2: 로컬 캐시는 MCP가 다운됐을 때 정식 운영 메모리가 된다. x-operations 스킬의 최신 업데이트, multi-node token sync 아키텍처, token refresher 크론 세부사항, char density 검증 워크플로우 등이 모두 들어있다. 크론 에이전트는 이 캐시를 사용해 실제 우리 작업에서 신선한 주제를 선정한다. MCP가 없어도 문제없다. 파이프라인이 그대로 진행된다. (248 chars)

---

트윗 3: 이는 최근 Anthropic Agentic Coding Report 스레드에서 다룬 "가드레일이 더 똑똑한 모델보다 중요하다"는 원칙을 정확히 구현한 사례다. 캐시 폴백은 구조적 가드레일이다. PR을 사람이 머지하기 전까지 프로덕션 변경을 막는 규칙과 같다. 하나의 불안정한 서비스 때문에 전체 일일 콘텐츠 생성이 중단되는 것을 방지한다. (239 chars)

---

트윗 4: 먼저 token refresher를 실행해 EXIT_CODE 0을 확인한다. self-scan에는 --app my-app --auth oauth2 --username jinon_seo 플래그를 명시적으로 사용한다. slides.txt를 먼저 만들고 드래프트를 작성한다. 모든 트윗은 execute_code로 정확히 220-275자인지 깨끗한 문자열로 검증한다. 메타 노트는 모두 제거하고 patch 사이클을 여러 번 반복해 완성한다. (246 chars)

---

트윗 5: 안드로이드 기기 하나로 11대 VPS 플릿을 AI 에이전트들이 자율 운영하게 하고, 여러 Hermes 노드, 매일 X 스레드, 위키 관리, 멀티에이전트 워크플로우를 조율한다. 비결은 모델을 완벽하게 만드는 것이 아니라 실패 상황에서도 정상 동작하는 폴백 레이어를 여러 개 두는 것이다. 원격 위키가 닿지 않아도 지식은 로컬에 살아있다. 이것이 진짜 자율 에이전트 시스템을 만드는 방법이다.

#BuildInPublic #AgentOrch #DevOps (267 chars)
---
