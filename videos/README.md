# Videos

첫 트윗에 첨부할 ~15초 영상의 소스와 렌더 결과를 보관하는 디렉토리.
영상은 **optional** — 없으면 텍스트만 발행된다 (SOP Video Policy).

## Naming convention

드래프트의 basename에서 언어 접미사를 뺀 이름을 쓴다:

```
drafts/2026-06-15-topic-en.md
drafts/2026-06-15-topic-ko.md
videos/2026-06-15-topic.slides.txt   ← 소스
videos/2026-06-15-topic.mp4          ← 렌더 결과 (자동 첨부 대상)
```

`watch-and-publish.sh`가 이 규칙으로 드래프트와 영상을 매칭한다.
mp4가 없고 소스(.cast/.tape/.slides.txt)만 있으면 발행 시 자동 렌더링하고,
EN 첫 트윗에 업로드한 media ID를 KO 첫 트윗에 재사용한다.

## Source types

| 확장자 | 도구 | 용도 |
|--------|------|------|
| `.slides.txt` | ffmpeg만 (추가 의존성 없음) | 핵심 메시지 텍스트 슬라이드. `---` 한 줄로 슬라이드 구분 |
| `.cast` | asciinema + agg | 노드에서 실제 터미널 세션 녹화 |
| `.tape` | vhs (charmbracelet) | 선언형 터미널 데모 — 재현 가능, PR 리뷰 가능 |
| `.mp4` `.mov` `.gif` | — | 기존 영상, 정규화만 수행 |

## Render

```bash
scripts/render-video.sh videos/2026-06-15-topic.slides.txt
# 슬라이드당 초 조정:
SLIDE_SECONDS=4 scripts/render-video.sh videos/2026-06-15-topic.slides.txt
```

출력은 X 업로드 스펙으로 정규화된다: 1280x720 레터박스, 30fps,
H.264 yuv420p, faststart, 무음. 140초 초과는 거부, 30초 초과는 경고.

## Safety

렌더 결과를 발행 전에 반드시 재생해서 확인한다 — 터미널 녹화는 토큰,
시크릿, 개인 경로, 알림이 프레임에 노출되기 쉽다 (safety.md 체크리스트).

> 참고: 렌더 결과 mp4는 `.gitignore`의 미디어 차단 규칙에서 이 디렉토리만
> 예외로 커밋할 수 있다. 용량이 크면 커밋하지 말고 노드에서 렌더만 한다.
