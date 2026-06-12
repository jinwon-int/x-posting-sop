# Metrics

발행 성과 기록과 정기 리뷰. 이 데이터가 SOP의 권장값(발행 시간대, 트윗 길이,
영상 정책)을 갱신하는 근거가 된다 — **수치는 감이 아니라 이 파일로 바꾼다.**

## Collection (Phase G)

- 수집 시점: 발행 후 **T+24h** 와 **T+7d**, 스레드(EN/KO)별로 각각.
- 명령: `scripts/collect-metrics.sh <window> <tweet_id>...` — 스레드의 모든
  트윗 ID를 넘기면 합산된 markdown 행을 출력한다. 그대로 아래 표에 붙여넣는다.

```bash
scripts/collect-metrics.sh T+24h 2065015595238863269 2065015595238870001 ...
```

## Log

| Captured | Topic (lang) | Root ID | Window | Impressions | Likes | Reposts | Replies | Quotes | Notes |
|----------|--------------|---------|--------|-------------|-------|---------|---------|--------|-------|

## Quarterly Review

분기마다(3·6·9·12월) 다음을 수행하고, 결론은 README 수정 PR로 반영한다:

- [ ] 임프레션 상·하위 3개 스레드를 뽑아 비교한다.
- [ ] 비교 축: 발행 시간대 / 훅 스타일 / 영상 유무 / 스레드 길이 / EN vs KO.
- [ ] README의 **Posting Schedule** 권장 시간대를 실측으로 갱신한다.
- [ ] README의 **Tweet Length** 권장 범위를 실측으로 갱신한다.
- [ ] **Video Policy** 의 미검증 가정("15–30s 영상 = 10–20x reach")을 자체
      데이터로 검증하고, 수치를 교체하거나 "검증됨(날짜)"으로 표기한다.
- [ ] 리뷰 결과 한 줄 요약을 이 파일 하단 History에 남긴다.

## Review History

| Date | Conclusion | README change |
|------|-----------|---------------|
