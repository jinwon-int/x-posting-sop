# Drafts

발행 전 스레드 드래프트와 발행 후 아카이브를 보관하는 디렉토리.

## Workflow

1. `templates/thread-en.md` 를 복사해 `YYYY-MM-DD-<topic>-en.md` 로 작성한다.
2. PR을 열어 오너 리뷰를 받는다 — 승인 이력이 git에 남는다.
3. 피드백 반영 후, 같은 PR에 `YYYY-MM-DD-<topic>-ko.md` 번역본을 추가한다.
4. 오너의 명시적 승인(예: "진행", "go", PR approve) 후
   `scripts/publish-thread.sh` 로 발행한다.
5. 발행 후에도 드래프트는 삭제하지 않는다 — 실제 발행 내용의 아카이브로 유지하고,
   스레드 ID는 `log.md` 에 기록한다.

## File format

- 트윗 1개 = 블록 1개, 블록 사이는 `---` 한 줄로 구분 (템플릿 참고).
- 이 형식 그대로 `scripts/publish-thread.sh <file>` 에 넣으면 스레드가 발행된다.
