---
name: Frontend Design System (UI/UX Craft)
slug: frontend-design
quality: full
sources_count: 5
last_verified: 2026-04-22
---

# Frontend Design — UI/UX 의도 설계·구현 파이프라인

"기능만 동작하는 화면"을 사람이 의도적으로 다듬은 수준의 인터페이스로 끌어올리는 파이프라인. 디자인 토큰·컴포넌트 계층·접근성·인터랙션까지 모든 시각·체감 레이어를 다룬다. `website-build`가 풀스택 생애주기라면, 이 도메인은 그 중 **UI 생성·다듬기·리뷰 축** 만을 깊게 본다.

## 표준 워크플로우

1. **Intent Framing** — 대상 사용자·핵심 과업·톤·브랜드 방향을 1페이지로 정의. 완료 조건: 디자인 의도 문서 + 참조 사례(Reference) 3개.
2. **Token Foundation** — 색상(reference/semantic 2계층), 타이포 스케일(1.125~1.25 비율), 스페이싱(4px or 8px grid), 라운드·그림자·모션 토큰 확정. 완료 조건: 토큰 JSON + CSS 변수 export + 다크 모드 변형.
3. **Component Dissection** — Button·Input·Card·Modal·Nav·Table 등 프리미티브를 상태(default/hover/active/focus/disabled/loading/empty/error)별로 해부. 완료 조건: 상태 매트릭스 + 스토리북 스냅샷.
4. **Compose (Parallel)** — 페이지·뷰를 컴포넌트 조합으로 구현. 레이아웃 그리드(12-col/container query), 반응형 breakpoint, 빈 상태·에러·스켈레톤 포함. 완료 조건: 주요 뷰 3~5개 통과.
5. **Motion & Micro-interaction** — 진입/전환/호버/선택 마이크로 인터랙션. 150~250ms 범위, easing은 ease-out/spring. 완료 조건: 주요 인터랙션 Lighthouse INP < 200ms.
6. **Accessibility Pass** — 키보드 포커스 순서, ARIA 시맨틱, 명도 대비(WCAG AA 4.5:1 또는 APCA Lc≥60), 모션 감소 환경 대응. 완료 조건: axe-core·Lighthouse a11y ≥ 95, 스크린리더 샘플 3개 통과.
7. **Design Review** — 의도·토큰 일관성·컴포넌트 합성·접근성·인터랙션 리뷰어가 감사. 완료 조건: BLOCK 0건, ASK 해소.
8. **Visual Regression & Docs** — 스크린샷 스냅샷(Chromatic/Loki/Percy) + 컴포넌트 문서 + 사용 가이드. 지속 반복.

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Design Lead | 의도·토큰·톤 결정, 시각 방향 단일 소스 | 디자인 시스템, 브랜드, 타이포 | 1 |
| UI Engineer | 컴포넌트·레이아웃·모션 구현 | HTML/CSS 숙련, 프레임워크(React/Vue/Svelte), Tailwind/CSS-in-JS | 1~3 |
| Interaction/Motion | 마이크로 인터랙션·전환·제스처 | Framer Motion, CSS 애니메이션, INP 튜닝 | 0~1 (겸임 가능) |
| Accessibility Specialist | a11y 감사, 스크린리더 검증 | WCAG/APCA, axe-core, NVDA/VoiceOver | 0~1 (겸임 가능) |
| Design Reviewer (Red-team) | 의도·토큰·일관성 방어적 검증 | 디자인 비평, 패턴 감지, 시각적 차이 탐지 | 1 |
| Product / PM | 사용자 여정·성공 지표 | 제품 기획, 사용자 조사 | 0~1 |

## 표준 도구·스킬 스택

- **디자인 토큰**: Style Dictionary, Design Tokens Community Group 표준, Panda CSS의 `css({})` 토큰 스킴
- **프레임워크**: React (Next.js, Remix), Vue (Nuxt), Svelte (SvelteKit), Solid, Qwik
- **스타일링**: Tailwind CSS v4, CSS Modules, Vanilla Extract, Panda CSS, shadcn/ui(Radix + Tailwind 합성)
- **컴포넌트 기반**: Radix UI, Headless UI, Ark UI, React Aria — 모두 접근성 기본 내장
- **모션**: Framer Motion, Motion One, CSS `@keyframes` + `prefers-reduced-motion`
- **타이포**: Inter, Pretendard, Geist, Satoshi (본문용), JetBrains Mono (코드), Google Fonts / Fontsource
- **색상 도구**: OKLCH 기반 팔레트 생성(Huetone, Oklch.com), Color Buddy(38 lint rule), APCA 계산기
- **접근성**: axe-core, Lighthouse a11y, Pa11y, NVDA/VoiceOver/JAWS 스크린리더, `prefers-*` 미디어 쿼리
- **시각 회귀**: Chromatic, Percy, Loki, Playwright + Pixelmatch
- **문서화**: Storybook 8+, Ladle, Histoire (Vue), Ariakit 스타일의 example-first 문서
- **AI 보조 스킬(옵션·외부)**: `color-expert`(meodai, 색채 이론·토큰 아키텍처), `interface-design`(Dammyjay93, 토큰 메모리 패턴), `cc-frontend-skills`(oikon48, 테마 프리셋 레퍼런스). 모두 선택 사항이며, 기본 워크플로우는 이 도메인의 표준 지침만으로 완결된다.

## 흔한 안티패턴

1. **AI 기본형 그대로 제출** — 뻔한 Claude/ChatGPT가 생성할 법한 박스 나열, 기본 shadow, 평균적 간격. "사람이 골랐다는 흔적"이 없음. 해결: 의도 레이어(Intent Framing) 의무화 + 최소 3개 참조 사례 비교. 출처: Refactoring UI (Wathan·Schoger).
2. **Raw 색상 리터럴 사용** — 컴포넌트에 `#3B82F6` 같은 hex를 직접 넣어 테마·다크 모드 전환 불가. 해결: reference/semantic 2계층 토큰 강제, 컴포넌트는 semantic만 참조. 출처: Design Tokens Community Group draft.
3. **접근성 사후 반영** — 디자인 끝난 뒤에야 대비·키보드·스크린리더 점검. 수정 비용 폭증. 해결: Token Foundation 단계에서 AA 대비 선점, 컴포넌트 단위에서 포커스 링·ARIA 계약 의무. 출처: WCAG 2.2 / APCA.
4. **상태 커버리지 빈곤** — `default`·`hover`만 구현하고 `loading`·`empty`·`error`·`disabled`는 빠뜨림. 프로덕션에서 화면 깨짐. 해결: 프리미티브마다 상태 매트릭스 문서화. 출처: Nielsen Norman Group "Visibility of System Status".
5. **반응형·밀도 무감각** — 데스크톱만 보고 모바일은 그리드 축소로 끝. 터치 타깃 44px·밀도 감각 무시. 해결: 모바일 내비게이션·터치 타깃·밀도(compact/comfortable) 명시. 출처: WCAG 2.2 Target Size (Minimum) 2.5.5 / 2.5.8.

## Reference Sources

- [Refactoring UI] Wathan & Schoger, "Refactoring UI" — https://refactoringui.com/ — 디자인 의도와 시각 계층의 실전 원칙. 발췌일 2026-04-22.
- [Design Tokens CG] W3C Community Group, "Design Tokens Format Module" — https://tr.designtokens.org/format/ — 토큰 포맷·계층 표준 초안. 발췌일 2026-04-22.
- [WCAG 2.2] W3C, "Web Content Accessibility Guidelines 2.2" — https://www.w3.org/TR/WCAG22/ — 대비·터치 타깃·포커스 등 접근성 필수 기준. 발췌일 2026-04-22.
- [APCA] Myndex, "Advanced Perceptual Contrast Algorithm" — https://github.com/Myndex/SAPC-APCA — WCAG 3.0 초안의 지각적 대비 척도. 발췌일 2026-04-22.
- [web.dev INP] Chrome team, "Interaction to Next Paint (INP)" — https://web.dev/articles/inp — 인터랙션 응답성 Core Web Vitals. 발췌일 2026-04-22.

## Credits (참고 자료 출처 — KB 본문에 녹여 재작성)

본 KB는 아래 오픈 자료의 패턴·어휘를 참고해 업계 용어로 재구성했다. 번들이 아닌 참고.

- `meodai/skill.color-expert` (MIT) — 색상 토큰 아키텍처·APCA·팔레트 린팅
- `oikon48/cc-frontend-skills` (MIT) — Anthropic 공식 프론트엔드 스킬 블로그 기반 참조 구현 (테마 프리셋)
- `Dammyjay93/interface-design` (MIT) — `system.md` 토큰 메모리 패턴, 8px grid, 컴포넌트 고정값
- `pbakaus/impeccable` (MIT) — `typeset`/`layout`/`adapt`/`audit` 동사형 액션 분해 원리
