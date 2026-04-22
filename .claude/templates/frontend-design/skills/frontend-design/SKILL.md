---
name: frontend-design
description: Use when creating, refactoring, or reviewing web UI. Trigger when the user mentions components, layouts, landing pages, design systems, tokens, typography, spacing, responsiveness, dark mode, accessibility, micro-interactions, or says the existing UI looks "AI-generated" or "generic." Also triggers on requests to style with Tailwind/CSS/Styled-components, build with React/Vue/Svelte/Next, or produce pages from a Figma/screenshot reference.
---

# Frontend Design

프론트엔드 UI를 **사람이 의도적으로 다듬은 수준**으로 설계·구현·리뷰한다. "AI 디폴트"(뻔한 카드 나열, 평균적 간격, 기본 shadow)를 거부하고 의도·토큰·상태·접근성을 모두 통제한다.

## 작업 절차

1. **Intent** — 대상 사용자 · 핵심 과업 · 톤을 1~2줄로 명시. 참조 사례 3개를 머릿속으로 비교.
2. **Tokens** — 색·타이포·스페이싱·라운드·그림자·모션 토큰. reference/semantic 2계층 분리.
3. **Components** — 프리미티브 단위로 해부. 상태 매트릭스(default/hover/focus-visible/active/disabled/loading/empty/error).
4. **Compose** — 페이지·뷰를 컴포넌트 조합으로. 반응형 breakpoint 명시.
5. **Micro-interaction** — 전환 150~250ms, `ease-out`/spring. `prefers-reduced-motion` 대응.
6. **A11y pass** — WCAG AA 4.5:1 (가능하면 APCA Lc ≥ 60), 키보드 포커스, ARIA, 터치 타깃 44×44.
7. **Review** — `frontend-ux-reviewer` 에이전트가 있으면 감사 요청.

## 핵심 원칙 (압축 요약)

- **AI 디폴트 거부**: 모든 선택에 "왜" 를 답할 수 없으면 바꾼다.
- **Raw 리터럴 금지**: 컴포넌트 코드에 hex·rgb·임의 px 값 직접 금지. semantic 토큰만.
- **타입 스케일 1.125 or 1.25**: 랜덤 크기 금지. 본문 16px+, 줄 길이 45~75자, line-height 1.5±0.1.
- **4/8px grid**: 모든 간격은 그리드 값. "눈대중" 금지.
- **상태 커버리지**: 프리미티브마다 최소 6개 상태 + 빈/에러/스켈레톤.
- **아이콘 한 세트**: Lucide / Phosphor / Radix / Heroicons 중 하나만.
- **피드백 즉각성**: 100ms 이내 첫 반응, 1s 이상 작업은 스켈레톤/progress.
- **파괴적 동작 방어**: 삭제·결제·로그아웃은 확인 단계 + 계급 낮은 위치.

## 색상 원칙 (내장 · 외부 의존 없음)

이 스킬은 다음 색상 규칙을 **자체 내장**한다. 추가 스킬 설치 없이 이 섹션만으로 팔레트·대비·토큰 설계가 가능하다.

### 토큰 2계층 (필수)
- **Reference tokens**: 원시 색 — 팔레트 정의·변환·진단에만 사용.
  - 예: `ref.brand.500 = oklch(0.62 0.18 254)`
- **Semantic tokens**: 역할에 매핑 — 컴포넌트는 **오직 semantic 만 참조**.
  - 예: `semantic.surface.default = ref.neutral.50`, `semantic.text.muted = ref.neutral.600`, `semantic.state.danger = ref.red.600`
- 컴포넌트 파일에 raw hex/rgb 리터럴 금지. 테마·다크 모드 전환이 불가능해진다.

### 색 공간 선택
- **OKLCH 우선**: 명도(L) 조작이 균일 — hover/active 상태를 `oklch(from var(--ref) calc(l - 0.08) c h)` 로 유도 가능.
- **HSL 피하기**: 같은 명도(L) 값이라도 hue 에 따라 실제 밝기 차이가 커 무작위 결과 생성.
- **hex**: 최종 출력·디자인 토큰 export 에만.

### 대비 기준
- **WCAG AA**: 본문 4.5:1, 큰 텍스트(18.66px 이상 또는 14pt bold) 3:1, UI 컴포넌트/그래픽 객체 3:1. 최소 기준.
- **APCA (권장)**: Lc ≥ 60 (본문), Lc ≥ 45 (큰 텍스트), Lc ≥ 30 (비필수 UI). 지각적으로 더 정확.
- 다크 모드에서 흰 배경용 색을 그대로 쓰지 말 것. 명도 축을 뒤집은 별도 semantic 매핑.

### 팔레트 생성 휴리스틱
- **하나의 기준 색** 을 정하고 OKLCH 명도 축으로 8~11단계 램프 생성 (50/100/…/950).
- **채도(C)** 는 양끝에서 감쇄, 중간(400~600)에서 최고.
- **대비 쌍** 을 쌍으로 검증: `surface/on-surface`, `brand/on-brand`, `danger/on-danger` — 각 쌍이 AA 이상.
- **60-30-10**: 중립(60%) + 서포트(30%) + 강조/액션(10%) 비율로 구성. 균일 분포 UI 는 시선 우선순위 상실.

### 색맹 대응
- 의미를 **색에만** 실지 말 것 (red = 위험, green = OK 단독 금지). 항상 아이콘·형태·텍스트 레이블 병행.
- Deuteranopia/Protanopia 시뮬레이션으로 주요 상태 색이 구별 가능한지 확인.

### 자동 검증 (권장 도구)
- **Color Buddy** (오픈소스): 38개 팔레트 린트 규칙 (WCAG, CVD, distinctness, fairness).
- **APCA 계산기**: https://www.myndex.com/APCA/
- **Coolors / Oklch.com**: 팔레트 실험.

## 도구 연계 (옵션 — 있으면 보조, 없어도 동작)

- **`.interface-design/system.md` 같은 토큰 메모리 파일이 있다면**: 먼저 Read하여 기존 값(8px grid, Button 36px 등)과 충돌 방지. 없으면 이 스킬 기준으로 새로 수립.
- **`color-expert` 스킬이 설치돼 있다면** (선택): 지각 기반 팔레트·역사적 색명·Munsell/NCS 표기 같은 **심화 색상 분석**이 필요할 때 선호출 가능. **이 스킬만으로도 기본 팔레트·대비·토큰 설계는 완결**되므로 설치 필수 아님.
- **Radix / Headless UI / React Aria**: 접근성 기본 내장된 컴포넌트 베이스를 선호.

## 에이전트 소환 기준

| 상황 | 소환 대상 | 리뷰 짝 |
|------|-----------|---------|
| 단일 컴포넌트 수정, 소규모 스타일 | (메인 세션 직접 처리) | 중요도 높으면 `frontend-ux-reviewer` |
| 화면·페이지 신설, 디자인 시스템 수립 | `frontend-designer` | **`frontend-ux-reviewer` (필수)** |
| 리팩터 후 / 머지 전 / "어색함" 원인 파악 | `frontend-ux-reviewer` | — |

두 에이전트는 하네스 세팅 과정에서 자동 설치된다. 별도 설치 불필요.

### 생성-리뷰 페어 규약

**화면·컴포넌트·디자인 시스템을 새로 만드는 작업은 반드시 designer → reviewer 쌍으로 실행**한다 (생성형 파이프라인의 리뷰 게이트). 리뷰 결과 처리 래더:

| 회차 | BLOCK 처리 |
|------|-----------|
| 1회차 | 자동 재작업 (리뷰 사유·제안 반영) |
| 2회차 | 사용자에게 3선택 — 재작업 / 수용 후 진행 / 수동 편집 |
| 3회차 | 작업 중단 + 3선택 — 무시 진행 / 수동 편집 / 해당 부분 스킵 |

ASK 는 사용자에게 전달 후 답변 반영. NOTE 는 요약 후 진행. 단순 스타일 수정(색 변경 1건·패딩 조정 등)은 이 규약에서 제외한다.

## 산출 형식

통짜 코드 덤프 금지. 항상 다음 순서:

1. **Intent** (3줄)
2. **Tokens diff** (신설·변경된 토큰)
3. **Components diff** (상태 매트릭스 포함)
4. **Compose result** (실제 페이지/뷰)
5. **A11y check** (대비 수치·키보드·ARIA 체크리스트)
6. **Next** (후속 정리 필요 항목)

## 금지 패턴

- 통짜 페이지 재작성 (구성 요소 단위 진단이 먼저)
- raw hex 리터럴 하드코딩
- `prefers-reduced-motion` 무시한 큰 모션
- 터치 타깃 < 44×44
- 로딩 스피너 단독 사용(1s 이상 작업에)
- 아이콘-only 버튼의 `aria-label` 누락
- "No data" 단독 빈 상태 (원인·복구 동작 누락)

## Self-check (산출 전)

- 모든 수치(크기·간격·대비)가 규정된 기준 안에 있는가?
- 상태 매트릭스 6개 + 빈/에러/스켈레톤이 모두 설계됐는가?
- semantic 토큰만 사용했는가?
- 모바일 뷰(360~430px)에서도 의미 있는 레이아웃인가?
- 이 선택을 1줄로 정당화할 수 있는가?
