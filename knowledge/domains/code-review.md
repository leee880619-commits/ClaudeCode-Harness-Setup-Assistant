---
name: Code Review (Parallel Multi-Dimensional Audit)
slug: code-review
quality: full
sources_count: 4
last_verified: 2026-04-17
---

# Code Review — 병렬 다차원 감사

변경된 코드에 대해 여러 차원(정확성/보안/성능/가독성/테스트)을 병렬로 감사하는 체계적 리뷰 시스템.

## 표준 워크플로우

1. **Diff Collection** — PR/브랜치의 변경 범위 수집. 완료 조건: 변경 파일 목록 + 라인 단위 diff 확보.
2. **Static Analysis Pass** — 린터/타입체커/보안스캐너(Semgrep/CodeQL) 자동 실행. 완료 조건: 새로 도입된 경고 0 또는 승인된 suppression.
3. **Parallel Multi-Dimensional Review** — 여러 차원의 reviewer가 동시 실행:
   - 정확성 (로직 버그, 엣지케이스)
   - 보안 (OWASP Top 10, 인증/인가, 비밀값 노출)
   - 성능 (N+1, 메모리 누수, 알고리즘 복잡도)
   - 테스트 커버리지 (새 로직에 테스트 존재 여부)
   - 가독성/디자인 (명명, 구조, 중복)
   완료 조건: 각 차원에서 BLOCK/NIT 분류된 코멘트.
4. **Dedupe & Prioritize** — 여러 reviewer의 중복 지적 병합, 우선순위 할당 (BLOCK/ASK/NIT).
5. **Author Response Loop** — 작성자가 지적에 대응 (수정/반박/지연). 완료 조건: BLOCK 0건.
6. **Approve & Merge** — 최종 승인 후 merge. 완료 조건: 모든 필수 리뷰어 승인 + CI green.

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Author | 변경사항 제안, PR 설명, 리뷰 대응 | 도메인 지식, 자기 리뷰 | 1 |
| Domain Reviewer | 해당 모듈의 정확성/설계 검토 | 코드베이스 이해, 도메인 전문성 | 1~2 |
| Security Reviewer | OWASP·인증·데이터 흐름 검토 | 보안 지식, 위협 모델링 | 1 (보안 민감 변경 시) |
| Test Reviewer | 커버리지·테스트 설계 검증 | 테스트 전략, flakiness 감지 | 1 (해당 시) |
| Approver / Maintainer | 최종 승인, 아키텍처 일관성 | 프로젝트 전체 관점 | 1~2 |

## 표준 도구·스킬 스택

- **정적 분석**: ESLint/Prettier/Ruff/Rubocop (린트), TypeScript/mypy/Flow (타입), Semgrep·CodeQL·Snyk (보안), SonarQube (통합)
- **PR 플랫폼**: GitHub PR, GitLab MR, Gerrit, Reviewable
- **CI 통합**: GitHub Actions, GitLab CI, Buildkite, CircleCI — 필수 status check
- **AI 어시스트**: GitHub Copilot for PRs, CodeRabbit, Graphite Diamond, Claude Code review
- **리뷰 템플릿**: Google Engineering Practices의 CL author/reviewer 가이드, Conventional Comments 스펙

## 흔한 안티패턴

1. **거대한 PR** — 500+ 라인 변경을 한 PR에. 리뷰 품질 급락, 놓치는 이슈 증가. 해결: 논리적 단위로 분할 (≤200~400 라인). 출처: Google Engineering Practices.
2. **Nit 폭격** — BLOCK/ASK/NIT 구분 없이 사소한 스타일 지적만 대량. 작성자 피로 + 진짜 이슈 묻힘. 해결: Conventional Comments의 `nit:` 프리픽스 사용. 출처: Conventional Comments 스펙.
3. **Rubber-stamp 승인** — 리뷰어가 diff를 실제로 보지 않고 LGTM. 특히 자동화된 어시스트에 의존 시. 해결: 의무 코멘트 정책 + 중요 변경에 2인 리뷰. 검증되지 않은 추정.
4. **Author 자기방어** — 지적을 반박으로만 대응, 변경 거부. 해결: 문서화된 "disagree & commit" 규약. 출처: Google Engineering Practices "The Standard of Code Review".
5. **테스트 없는 변경 승인** — 새 로직인데 테스트 누락을 리뷰어가 지적 안 함. 해결: CI에서 커버리지 diff 게이트. 출처: SmartBear Code Review Best Practices.

## Reference Sources

- [Google] "Google's Engineering Practices documentation — Code Review" — https://google.github.io/eng-practices/review/ — Google 내부 코드 리뷰 기준의 공개 버전. 발췌일 2026-04-17.
- [SmartBear] "Best Practices for Peer Code Review" — https://smartbear.com/learn/code-review/best-practices-for-peer-code-review/ — 산업 벤치마크 데이터 기반 리뷰 가이드. 발췌일 2026-04-17.
- [Conventional Comments] — https://conventionalcomments.org/ — 코멘트 분류 체계 스펙. 발췌일 2026-04-17.
- [GitHub Docs] "About pull request reviews" — https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests — 플랫폼 관점의 PR 리뷰 워크플로우. 발췌일 2026-04-17.
