---
name: Website Build (Full-Stack Pipeline)
slug: website-build
quality: full
sources_count: 4
last_verified: 2026-04-17
---

# Website Build — 풀스택 빌드 파이프라인

디자인부터 배포·운영까지의 웹 애플리케이션 생애주기를 분업된 파이프라인으로 구축·운영하는 시스템.

## 표준 워크플로우

1. **Discovery & Spec** — 요구사항 수집, 페이지 인벤토리, 성능/접근성 목표 설정. 완료 조건: 명세 문서 + 수용 기준.
2. **Design** — UX 플로우, 디자인 시스템 토큰, 핵심 컴포넌트 시안. 완료 조건: 디자인 리뷰 승인 + 토큰 export.
3. **Scaffold** — 프레임워크 선택·초기 구조, CI/CD·환경 구성. 완료 조건: 헬스체크 페이지 프로덕션 배포.
4. **Implement (Parallel)** — Frontend / Backend / Infra 병렬 구현. Feature flag로 점진 통합. 완료 조건: 기능별 승인.
5. **Test** — 단위/통합/E2E + 접근성(a11y) + 성능(Lighthouse/Web Vitals). 완료 조건: CI 게이트 통과.
6. **Staging & UAT** — 스테이징 배포, 이해관계자 검수. 완료 조건: UAT 체크리스트 완료.
7. **Production Deploy** — 블루/그린 또는 카나리 릴리스. 완료 조건: 에러율·Core Web Vitals 기준치 이하 유지.
8. **Observability & Iteration** — RUM(Real User Monitoring), 로그, 에러 추적, A/B 테스트. 지속 반복.

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Product / PM | 요구사항·로드맵·우선순위 | 제품 기획, 이해관계자 관리 | 1 |
| Designer (UX/UI) | 플로우·시안·디자인 시스템 | Figma, 디자인 토큰, 접근성 | 1~2 |
| Frontend Engineer | UI 구현, 상태 관리, 성능 | React/Vue/Svelte, CSS, Web API | 1~3 |
| Backend Engineer | API, DB, 인증/인가, 도메인 로직 | Node/Python/Go, SQL, 인증 | 1~3 |
| DevOps / Platform | CI/CD, 인프라, 관측성 | Docker, K8s/Serverless, Terraform, 모니터링 | 1 |
| QA / Test | 테스트 설계, E2E, 접근성 검증 | Playwright/Cypress, axe, Lighthouse | 1 |
| SRE (대규모) | 가용성, 용량 계획, 인시던트 대응 | SLO, 페이지옵스, 관측성 | 1 |

## 표준 도구·스킬 스택

- **프레임워크**: Next.js, Nuxt, Remix, Astro, SvelteKit (풀스택) / React, Vue, Svelte (SPA)
- **스타일링**: Tailwind, CSS Modules, Vanilla Extract, Panda CSS
- **백엔드**: Node(Express/Nest/Fastify), Python(Django/FastAPI), Go(Gin/Echo), Ruby on Rails
- **DB/ORM**: PostgreSQL/MySQL/SQLite + Prisma/Drizzle/TypeORM/SQLAlchemy
- **인증**: Auth.js, Clerk, Supabase Auth, Keycloak, OAuth2/OIDC
- **CI/CD**: GitHub Actions, GitLab CI, Vercel/Netlify(미리보기), ArgoCD(K8s)
- **배포 타겟**: Vercel, Netlify, Cloudflare Pages/Workers, AWS(ECS/Lambda), Fly.io, Render
- **관측성**: Sentry (에러), Datadog/New Relic/Grafana (APM+로그), PostHog/Mixpanel (제품 분석)
- **테스트**: Vitest/Jest (단위), Playwright/Cypress (E2E), Lighthouse CI (성능), axe-core (a11y)

## 흔한 안티패턴

1. **Twelve-Factor 위반** — 설정을 코드에 하드코딩, 환경별 분기가 코드 내부에. 해결: 환경변수화, 빌드 아티팩트 불변성. 출처: The Twelve-Factor App.
2. **테스트 없이 배포** — E2E/통합 없이 단위 테스트만. 프로덕션 회귀 빈발. 해결: 핵심 사용자 여정 3~5개 E2E 의무. 출처: Atlassian DevOps.
3. **관측성 사후 도입** — 배포 후 문제 발생하고서야 로그/모니터링 추가. 해결: 스캐폴드 단계에서부터 로그/에러/메트릭 배선. 출처: Google SRE Book.
4. **Core Web Vitals 무시** — 번들 크기, LCP, CLS를 측정하지 않아 UX 저하. 해결: Lighthouse CI를 PR 게이트로. 출처: web.dev.
5. **인증을 직접 구현** — 세션/토큰/비밀번호 해시를 직접. 보안 취약점 다발. 해결: Auth.js/Clerk 같은 검증된 솔루션. 검증되지 않은 추정 (일반 권고).

## Reference Sources

- [Twelve-Factor] Adam Wiggins, "The Twelve-Factor App" — https://12factor.net/ — SaaS 빌드의 정석 12원칙. 발췌일 2026-04-17.
- [web.dev] "Core Web Vitals" — https://web.dev/articles/vitals — 사용자 경험 측정 표준. 발췌일 2026-04-17.
- [Atlassian] "DevOps best practices" — https://www.atlassian.com/devops — CI/CD, 관측성, 인시던트 대응. 발췌일 2026-04-17.
- [Google SRE] "Site Reliability Engineering" book — https://sre.google/sre-book/table-of-contents/ — SLO, 관측성, 온콜 운영. 발췌일 2026-04-17.
