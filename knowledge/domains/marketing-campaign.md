---
name: Marketing Campaign (Asset Production & Testing)
slug: marketing-campaign
quality: stub
sources_count: 0
last_verified: 2026-04-17
---

# Marketing Campaign — 캠페인 에셋 제작 및 테스트

> **Stub**: 1차 출처 미수집. Phase 2.5는 라이브 검색으로 보강한다.

## 표준 워크플로우 (검증되지 않은 추정)

1. **Brief & Objectives** — 타겟·KPI(CTR, CPA, ROAS)·예산·기간 정의. 완료 조건: 승인된 캠페인 브리프.
2. **Audience & Segmentation** — 페르소나·세그먼트·룩얼라이크 정의. 완료 조건: 타겟팅 명세.
3. **Creative Strategy & Messaging** — 핵심 메시지·가치 제안·톤. 완료 조건: 카피 프레임워크.
4. **Asset Production** — 카피·비주얼·동영상·랜딩 페이지 제작. 완료 조건: 각 채널 규격 맞춘 에셋 세트.
5. **Multivariate Test Plan** — 크리에이티브 조합(카피×비주얼×오디언스) 설계. 완료 조건: 실험 매트릭스 + 통계 파워 계산.
6. **Launch & Monitoring** — 채널 런칭, 실시간 성과 모니터링. 완료 조건: 초기 24~72시간 이상 신호 검출.
7. **Optimize** — 승자 크리에이티브 스케일업, 패자 중단, 예산 재배분. 완료 조건: KPI 목표 수렴 또는 종료.
8. **Retrospective** — 캠페인 결과 리포트, 학습 정리. 완료 조건: 다음 캠페인에 이관 가능한 인사이트 문서.

## 표준 역할/팀 분업 (검증되지 않은 추정)

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Campaign Manager | 브리프·일정·예산·스테이크홀더 | 프로젝트 관리, KPI 이해 | 1 |
| Strategist / Planner | 오디언스·메시징 전략 | 인사이트 분석, 브랜드 | 1 |
| Copywriter | 카피·슬로건·CTA | 글쓰기, 브랜드 톤 | 1~2 |
| Designer | 비주얼 에셋, 랜딩 페이지 | Figma/Photoshop, 모션 | 1~2 |
| Video Producer | 영상 콘텐츠 | 촬영·편집 | 1 (해당 시) |
| Performance Marketer | 광고 집행·입찰·최적화 | 플랫폼 광고관리자, 분석 | 1 |
| Analytics | 실험 설계·결과 해석·대시보드 | GA/Amplitude, 통계 | 1 |

## 표준 도구·스킬 스택 (검증되지 않은 추정)

- **광고 플랫폼**: Google Ads, Meta Ads, TikTok Ads, LinkedIn Ads, Naver/Kakao
- **디자인/영상**: Figma, Photoshop, Illustrator, After Effects, Canva
- **랜딩/실험**: Unbounce, Instapage, Optimizely, VWO, Google Optimize (deprecated; 대체: GrowthBook, Statsig)
- **분석**: GA4, Amplitude, Mixpanel, Looker Studio, Snowflake + dbt (대기업)
- **어트리뷰션**: Adjust, Appsflyer, Branch (모바일), server-side conversion (웹)
- **크리에이티브 관리**: Frame.io, Celtra, Smartly (대규모 크리에이티브 자동화)
- **프로젝트 관리**: Asana, Monday, Notion (캠페인 캘린더)

## 흔한 안티패턴 (검증되지 않은 추정)

1. **A/B 없이 감 최적화** — 승자 판정을 클릭 몇 건으로. 통계적 유의성 미달.
2. **KPI 혼동** — Vanity metric(노출수) 추종, ROAS/CAC 같은 비즈니스 지표 무시.
3. **채널 사일로** — 검색·소셜·이메일 따로. 크로스채널 어트리뷰션 실패.
4. **크리에이티브 피로** — 동일 에셋을 장기간 사용, CTR 급락. 해결: 주기적 refresh.
5. **개인정보 처리 누락** — 쿠키/픽셀 정책 미준수로 규제 리스크. 해결: 컨센트 매니지먼트 통합.

## TODO (Full로 승격 시 필요)

- [ ] Meta Business / Google Ads 공식 캠페인 가이드
- [ ] MMM(Marketing Mix Modeling) 관련 1차 자료 (Nielsen, McKinsey)
- [ ] iOS 14+ 이후 어트리뷰션 변화 문서 (AAID/IDFA, SKAdNetwork)
- [ ] 업계 협회(IAB) 측정 표준

## Reference Sources

(Stub 상태 — Phase 2.5는 라이브 검색으로 보강한다.)
