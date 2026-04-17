<!-- File: 09-reference-pipeline.md | Source: architecture-report Section 10 -->
## SECTION 10: 기능 구현 요청 시 파일 참조 파이프라인 (Co-optris 사례)

이 섹션에서는 실제 프로젝트(Co-optris: 협동 테트리스 게임)에서 "새로운 게임 모드를 추가해줘"라는 요청이 들어왔을 때, **어떤 파일이 어떤 시점에 어떤 이유로 참조되는지**를 완전히 추적한다.

이것은 단순한 "파일 목록"이 아니라, Claude Code의 지침 시스템이 실제로 어떻게 **실시간으로 작동하는지**를 보여주는 실행 흐름도이다.

### 10.0 사전 조건: 프로젝트 하네스 구조

```
co-optris/
├── CLAUDE.md                              ← 프로젝트 지침 (18KB)
│   ├── @docs/architecture/code-map.md     ← 코드 맵 참조
│   ├── @docs/game-design/co-optris_pd_master_plan.md ← 기획서 참조
│   └── (8개 개발 원칙, 확인 필요 목록, 7단계 워크플로우)
├── CLAUDE.local.md                        ← 개인 오버라이드
├── .claude/
│   ├── settings.json                      ← 프로젝트 설정
│   ├── settings.local.json                ← 개인 설정
│   ├── rules/
│   │   ├── git-safety.md                  ← always-apply
│   │   ├── test-port.md                   ← always-apply
│   │   ├── dependency-management.md       ← always-apply
│   │   ├── code-navigation.md             ← always-apply
│   │   ├── handoff-contracts.md           ← always-apply
│   │   ├── server-verification.md         ← path-scoped: server/**/*.js
│   │   └── web-client.md                  ← path-scoped: web/**/*.js
│   └── skills/
│       ├── co-optris-tech-lead/SKILL.md
│       ├── co-optris-gameplay/SKILL.md
│       ├── co-optris-netcode/SKILL.md
│       ├── co-optris-qa-whitebox/SKILL.md
│       └── co-optris-qa-blackbox/SKILL.md
├── docs/
│   ├── architecture/code-map.md
│   └── game-design/co-optris_pd_master_plan.md
└── server/
    └── modes/
        ├── mode-registry.js
        ├── coop.js
        ├── versus.js
        ├── teams.js
        ├── items.js
        └── asymmetric.js
```

### 10.1 Phase 0: 컨텍스트 확인 — 이미 로딩된 것들

세션 시작 시 9.1의 로딩 순서에 따라 이미 컨텍스트에 존재하는 파일들:

```
[이미 로딩됨 — 세션 시작 시 자동]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

User Scope:
  ✓ ~/.claude/CLAUDE.md              ← 개인 코딩 원칙, Git 컨벤션
  ✓ ~/.claude/settings.json          ← 모델 설정, 실험 기능
  ✓ ~/.claude/rules/git-safety.md    ← 전역 Git 안전 규칙
  ✓ ~/.claude/rules/korean-encoding.md ← Windows UTF-8 규칙

Project Scope:
  ✓ CLAUDE.md                        ← 프로젝트 아이덴티티, 8개 원칙, 7단계 워크플로우
  ✓   └── @docs/architecture/code-map.md (import)
  ✓   └── @docs/game-design/co-optris_pd_master_plan.md (import)
  ✓ .claude/settings.json            ← 프로젝트 권한, 훅, 환경변수
  ✓ .claude/rules/git-safety.md      ← 프로젝트 Git 규칙 (QA 후 커밋)
  ✓ .claude/rules/test-port.md       ← 테스트 포트 4000, 3000 보호
  ✓ .claude/rules/dependency-management.md ← npm install 확인 필요
  ✓ .claude/rules/code-navigation.md ← code-map-first 전략
  ✓ .claude/rules/handoff-contracts.md ← 출력 포맷 요구사항

Local Scope:
  ✓ CLAUDE.local.md                  ← 개인 오버라이드
  ✓ .claude/settings.local.json      ← 개인 설정

Memory:
  ✓ MEMORY.md 인덱스                 ← 이전 세션 컨텍스트 포인터

[등록만 됨 — 아직 로딩되지 않음]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ◯ .claude/rules/server-verification.md   ← paths: ["server/**/*.js"]
  ◯ .claude/rules/web-client.md            ← paths: ["web/**/*.js"]
  ◯ .claude/skills/* (전부)                ← deferred tools로 등록
  ◯ memory/project_context.md              ← 토픽 파일 (on-demand)
  ◯ memory/feedback_workflow.md            ← 토픽 파일 (on-demand)
```

**사용자 메시지 수신:** "새로운 게임 모드를 추가해줘"

**Claude의 첫 번째 판단 — 확인 필요 여부 체크:**

CLAUDE.md에 다음과 같은 "확인 필요" 목록이 있음:
```markdown
## 반드시 사전 확인이 필요한 사항
- product direction change (기능 추가/삭제, 게임 모드 변경)
- architecture change (파일 구조 변경, 새 모듈 추가)
- dependency addition (새 npm 패키지)
- ...
```

"새로운 게임 모드 추가"는 **product direction change**에 해당:

```
Claude → 사용자:
"새로운 게임 모드를 추가하려면 어떤 종류의 게임 모드인지 알아야 합니다.
현재 구현된 모드는 coop, versus, teams, items, asymmetric 5가지입니다.
어떤 게임 모드를 추가하고 싶으신가요? 간단히 설명해주세요."
```

사용자가 "시간 제한 모드 - 2분 안에 40줄을 클리어해야 하는 모드"라고 답변.

### 10.2 Phase 1: Research (STEP 1 — 조사)

**이 단계에서 새로 참조되는 파일들:**

```
[Phase 1에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. @docs/architecture/code-map.md (이미 로딩됨, 재참조)
   목적: 기존 게임 모드 구현 위치 파악
   결과: server/modes/ 디렉토리 구조 확인, mode-registry.js 발견

2. .claude/skills/co-optris-tech-lead/SKILL.md (새로 로딩)
   트리거: Claude가 아키텍처 분석이 필요하다고 판단
   동작: ToolSearch로 스킬 스키마 조회 → Skill 도구로 호출
   목적: 아키텍처 분석 워크플로우, 위험 평가 프레임워크

3. .claude/skills/co-optris-gameplay/SKILL.md (새로 로딩)
   트리거: 게임 모드 도메인 지식이 필요
   동작: ToolSearch → Skill 도구 호출
   목적: 게임 모드 구조 패턴, 필수 인터페이스, 밸런스 고려사항

4. memory/project_context.md (새로 로딩, on-demand)
   트리거: MEMORY.md 인덱스에서 "프로젝트 아키텍처 결정 사항" 확인
   동작: Read 도구로 직접 읽기
   목적: 이전 세션에서의 아키텍처 결정, 현재 구현 상태 파악
```

**동적 규칙 활성화 발생:**

```
Claude가 server/modes/coop.js를 Read 도구로 읽음
→ "server/modes/coop.js" matches "server/**/*.js"
→ .claude/rules/server-verification.md 로딩됨!

내용: "server/**/*.js 파일 수정 후 반드시 node --check server.js 실행"
```

**실제 소스 파일 읽기:**
```
Read("server/modes/mode-registry.js")  ← 모드 등록 메커니즘 분석
Read("server/modes/coop.js")           ← 기존 모드 패턴 학습 (+ 규칙 활성화)
Read("server/modes/versus.js")         ← 또 다른 패턴 확인
Read("server/modes/teams.js")          ← 팀 기반 로직 확인 (시간제한과 유사성)
```

**STEP 1 출력물 — research.md:**

handoff-contracts.md 규칙에 따라 다음 5개 섹션이 필수:

```markdown
# Research: 시간 제한 게임 모드 추가

## 1. 분석 범위
- server/modes/ 디렉토리 전체
- mode-registry.js의 모드 등록 메커니즘
- 기존 5개 모드의 공통 패턴

## 2. 현재 구조
- server/modes/mode-registry.js: 모드 팩토리 패턴, registerMode() API
- 각 모드 파일: createMode(config) → { init(), onTick(), onLineClear(), isComplete(), getScore() }
- 모든 모드가 동일한 인터페이스 구현 (Strategy 패턴)

## 3. 핵심 발견
- mode-registry.js가 동적 로딩 지원 (require로 모드 파일 로딩)
- 타이머 메커니즘이 이미 coop.js에 부분 구현 (라운드 타이머)
- isComplete() 메서드가 게임 종료 조건 담당
- onTick()이 매 프레임 호출되므로 타이머 로직 삽입 가능

## 4. 변경 영향 범위
- 새 파일: server/modes/time-attack.js
- 수정: server/modes/mode-registry.js (새 모드 등록)
- 수정: web/ui/mode-selector.js (UI에 새 모드 추가)
- 수정: web/ui/hud.js (타이머 표시)
- 수정: docs/architecture/code-map.md (문서 업데이트)

## 5. 위험 요소
- 타이머 동기화: 서버-클라이언트 간 시간 동기화 필요
- 기존 밸런스: 40줄/2분이 적절한지 테스트 필요
- mode-registry.js 수정 시 기존 모드에 영향 없는지 확인 필요
```

### 10.3 Phase 2: Planning (STEP 2 — 계획)

**이 단계에서 새로 참조되는 파일들:**

```
[Phase 2에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. research.md (직전 단계 출력물, 필수 참조)
   목적: 분석 결과를 기반으로 구체적 구현 계획 수립

2. @docs/game-design/co-optris_pd_master_plan.md (이미 로딩됨, 재참조)
   목적: "시간 제한 모드"가 기획 방향에 부합하는지 확인
   결과: 마스터 플랜에 "타임어택 모드" 후보가 있음 → 방향 일치

3. .claude/skills/co-optris-tech-lead/SKILL.md (이미 로딩됨, 재참조)
   목적: Minimal Design Principle 적용 — 최소한의 변경으로 최대 효과

4. .claude/rules/handoff-contracts.md (이미 로딩됨, 재참조)
   목적: plan.md 출력 포맷 확인
```

**STEP 2 출력물 — plan.md:**

```markdown
# Plan: 시간 제한 게임 모드 (Time Attack) 추가

## 1. 목표
2분 제한 내 40줄 클리어를 목표로 하는 Time Attack 게임 모드를 추가한다.
기존 모드 인터페이스를 준수하며 최소한의 코드 변경으로 구현한다.

## 2. 구현 작업 목록
- [ ] 2.1 server/modes/time-attack.js 생성 (모드 인터페이스 구현)
- [ ] 2.2 server/modes/mode-registry.js에 time-attack 등록
- [ ] 2.3 web/ui/mode-selector.js에 Time Attack 버튼 추가
- [ ] 2.4 web/ui/hud.js에 카운트다운 타이머 UI 추가
- [ ] 2.5 server/modes/time-attack.js 타이머 동기화 로직
- [ ] 2.6 docs/architecture/code-map.md 업데이트

## 3. 수정 파일 목록
| 파일 | 변경 유형 | 변경 규모 |
|------|----------|----------|
| server/modes/time-attack.js | 신규 생성 | ~150줄 |
| server/modes/mode-registry.js | 수정 (1줄 추가) | 미미 |
| web/ui/mode-selector.js | 수정 (버튼 추가) | ~20줄 |
| web/ui/hud.js | 수정 (타이머 UI) | ~40줄 |
| docs/architecture/code-map.md | 수정 (항목 추가) | ~5줄 |

## 4. 고려사항 & 트레이드오프
- 타이머 정밀도: requestAnimationFrame 기반 vs setInterval → rAF 사용 (일관성)
- 40줄 목표: 하드코딩 vs config → config에서 읽도록 구현 (확장성)
- 서버 권위: 타이머는 서버에서 관리, 클라이언트는 표시만

## 5. 검증 방법
```bash
node --check server/modes/time-attack.js
npm run check:phase12
# 포트 4000에서 테스트 서버 실행
node server.js --port 4000 --mode time-attack
```
```

### 10.4 Phase 3: User Review (STEP 3 — 사용자 검토)

**이 단계에서 새로 참조되는 파일: 없음**

이 단계는 순수한 대화 단계. Claude는 plan.md를 사용자에게 제시하고 피드백을 받는다.

```
Claude → 사용자:
"위 계획을 검토해주세요. 특히 다음 사항을 확인해주시면 좋겠습니다:
1. 40줄/2분 목표값이 적절한지
2. 타이머를 config에서 읽는 방식이 좋은지
3. 추가로 고려할 사항이 있는지"

사용자 → Claude:
"좋아. 근데 config에서 읽는 건 나중에 하고, 일단 하드코딩으로 가자.
그리고 남은 시간이 30초 이하일 때 타이머 색상을 빨갛게 변경해줘."

Claude: plan.md 업데이트
- 2.1 태스크에 "하드코딩 (TARGET_LINES=40, TIME_LIMIT=120)" 추가
- 2.4 태스크에 "30초 이하 빨간색 타이머" 추가
```

### 10.5 Phase 4: Red Team Review (STEP 4 — 레드팀 검토)

**이 단계에서 새로 참조되는 파일들:**

```
[Phase 4에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. plan.md (수정된 최종본, 필수 참조)
   목적: 레드팀 관점에서 계획의 취약점 식별

2. .claude/skills/co-optris-tech-lead/SKILL.md (이미 로딩됨, 재참조)
   목적: 아키텍처 위험 평가 프레임워크 적용

3. .claude/skills/co-optris-netcode/SKILL.md (조건부 — 새로 로딩)
   트리거: plan.md에 "타이머 동기화"가 포함됨 → 네트워크 프로토콜 관련
   동작: ToolSearch → Skill 도구 호출
   목적: 서버-클라이언트 간 타이머 동기화의 네트워크 관점 검토
```

**STEP 4 출력물 — plan.md에 추가:**

```markdown
## 6. Red Team Review Results

### 취약점 식별
1. **[HIGH] 타이머 치팅**: 클라이언트에서 타이머를 조작할 수 있음
   → 완화: 서버에서만 타이머 관리, 클라이언트는 표시만
2. **[MED] 네트워크 지연**: 서버 타이머와 클라이언트 표시 간 지연
   → 완화: 서버 타이머를 주기적으로 클라이언트에 동기화 (매 5초)
3. **[LOW] 하드코딩 위험**: 나중에 값 변경 시 여러 파일 수정 필요
   → 수용: 사용자 결정사항. FIXME 주석으로 표시

### 조정된 작업
- 2.5에 "서버→클라이언트 타이머 동기화 메시지 추가" 반영
- 하드코딩 위치에 FIXME: "config로 추출 예정" 주석 추가
```

### 10.6 Phase 5: Implementation (STEP 5 — 구현)

**이 단계가 가장 복잡한 파일 참조 흐름을 보여준다.**

```
[Phase 5에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. plan.md (최종본, 체크리스트로 사용)
   목적: 작업 순서대로 구현

2. .claude/skills/co-optris-gameplay/SKILL.md (이미 로딩됨, 재참조)
   목적: 게임 로직 구현 가이드라인, 모드 인터페이스 스펙

3. .claude/skills/co-optris-tech-lead/SKILL.md (이미 로딩됨, 재참조)
   목적: 아키텍처 제약사항 준수 확인
```

**구현 중 동적 규칙 활성화 상세:**

```
[작업 2.1] Write("server/modes/time-attack.js")

  Write 도구 호출 전 — PreToolUse 훅 실행:
    → ownership-guard.sh 실행
    → server/modes/ 디렉토리에 대한 소유권 확인
    → 결과: PASS (현재 작업이 plan.md에 명시됨)

  Write 도구 실행:
    → 파일 생성됨

  Write 도구 호출 후 — path-scoped 규칙 확인:
    → "server/modes/time-attack.js" matches "server/**/*.js"
    → .claude/rules/server-verification.md가 이미 Phase 1에서 로딩됨 (중복 로딩 안 함)
    → 규칙 내용: "server/**/*.js 수정 후 node --check server.js 실행"
    → Claude가 자동으로 node --check 실행

  Bash("node --check server/modes/time-attack.js") 실행 후:
    → PostToolUse 훅 실행
    → quality-gate.sh 실행
    → 구문 검사 결과: PASS
```

```
[작업 2.3] Edit("web/ui/mode-selector.js")

  Edit 도구 호출 전 — PreToolUse 훅 실행:
    → ownership-guard.sh 실행
    → 결과: PASS

  Edit 도구 실행:
    → 파일 수정됨

  Edit 도구 호출 후 — path-scoped 규칙 확인:
    → "web/ui/mode-selector.js" matches "web/**/*.js"
    ★ .claude/rules/web-client.md가 새로 로딩됨! (처음으로 web/ 파일 접근)
    → 규칙 내용: "plain JavaScript + Canvas만 사용, 프레임워크 금지,
       DOM 직접 조작, CSS는 인라인 또는 style.css에서만"
    → Claude가 이 규칙을 준수하며 구현 확인

  PostToolUse 훅:
    → quality-gate.sh 실행
    → 결과: PASS
```

**전체 훅 실행 흐름 (작업 하나당):**

```
┌─────────────────────────────────────────────────────┐
│ Claude: Write("server/modes/time-attack.js")        │
├─────────────────────────────────────────────────────┤
│ PreToolUse(Write) → ownership-guard.sh              │
│   ├── 파일 경로 확인                                  │
│   ├── plan.md와 대조                                  │
│   └── 결과: allow / block                            │
├─────────────────────────────────────────────────────┤
│ [도구 실행] 파일 작성                                  │
├─────────────────────────────────────────────────────┤
│ PostToolUse(Write) → (없음, Write에 대한 Post 훅 없음) │
│                                                       │
│ Claude: Bash("node --check server/modes/time-attack.js") │
├─────────────────────────────────────────────────────┤
│ PreToolUse(Bash) → (없음 또는 기본 검사)               │
├─────────────────────────────────────────────────────┤
│ [도구 실행] node --check 실행                         │
├─────────────────────────────────────────────────────┤
│ PostToolUse(Bash) → quality-gate.sh                  │
│   ├── 구문 검사 결과 확인                              │
│   ├── 빌드 검증                                       │
│   └── 결과: 다음 메시지에 포함                          │
└─────────────────────────────────────────────────────┘
```

### 10.7 Phase 6.0: White-box QA (화이트박스 QA)

**이 단계에서 참조되는 파일들:**

```
[Phase 6.0에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. .claude/skills/co-optris-qa-whitebox/SKILL.md (새로 로딩)
   트리거: STEP 6.0 진입 시 QA 스킬 필요
   동작: ToolSearch → Skill 도구 호출
   목적: 화이트박스 QA 절차 (정적 분석, 코드 리뷰, 게이트 테스트)

2. CLAUDE.md (이미 로딩됨, 재참조)
   목적: 8개 개발 원칙과의 일치 확인 (코드 리뷰)
```

**QA 절차:**

```
1. 정적 분석 (Static Analysis)
   대상: 변경된 모든 파일
   - server/modes/time-attack.js: 구문, 미사용 변수, 타입 일관성
   - server/modes/mode-registry.js: 변경 범위 검증
   - web/ui/mode-selector.js: DOM 조작 안전성
   - web/ui/hud.js: 타이머 렌더링 로직

2. 코드 리뷰 (Code Review vs CLAUDE.md Tenets)
   - [원칙1] 코드 간결성 → ✓ 불필요한 추상화 없음
   - [원칙2] 서버 권위 → ✓ 타이머는 서버에서만 관리
   - [원칙3] 최소 의존성 → ✓ 새 의존성 없음
   - ...

3. 게이트 테스트 (Gate Test)
   실행: npm run check:phase12
   → PostToolUse 훅으로 quality-gate.sh 자동 실행

4. 임시 패치 감지 (Temp Patch Detection)
   검색: TODO, HACK, FIXME(사용자 승인된 것 제외), console.log
   결과: FIXME 1건 (사용자 승인된 하드코딩 표시) → 허용
```

**STEP 6.0 출력물 — 판정 블록:**

```
<!-- VERDICT_START -->
gate_result: PASS
static_analysis: PASS
code_review: PASS
temp_patch: NONE (FIXME 1건은 사용자 승인)
verdict: PASS
verdict_reason: 모든 검증 항목 통과. 하드코딩 FIXME는 사용자 의도적 결정.
gate_command: npm run check:phase12
<!-- VERDICT_END -->
```

### 10.8 Phase 6.1: Black-box QA (블랙박스 QA — 조건부)

**실행 조건 판단:**
- "시간 제한 게임 모드 추가" = 사용자에게 보이는 변경 (UI 변경 포함)
- → Black-box QA **실행**

```
[Phase 6.1에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. .claude/skills/co-optris-qa-blackbox/SKILL.md (새로 로딩)
   트리거: 사용자 대면 변경이므로 라이브 테스트 필요
   동작: ToolSearch → Skill 도구 호출
   목적: 블랙박스 QA 절차 (라이브 테스트, 시각적 검증)

2. .claude/rules/test-port.md (이미 로딩됨, 재참조)
   목적: 포트 4000에서 테스트, 3000은 보호
```

**QA 절차:**

```
1. 테스트 서버 시작
   Bash("node server.js --port 4000 --mode time-attack")
   → test-port.md 규칙 준수: 포트 4000 사용

2. 기능 테스트 (Feature Test)
   - 모드 선택 화면에 "Time Attack" 버튼 표시되는지
   - 모드 선택 시 게임 시작되는지
   - 타이머가 2:00에서 시작하여 카운트다운되는지
   - 줄 클리어 시 카운트 증가하는지
   - 40줄 달성 시 승리 화면 표시되는지
   - 0초 도달 시 패배 화면 표시되는지

3. 시각적 테스트 (Visual Test)
   - 타이머 UI가 HUD에 올바르게 표시되는지
   - 30초 이하에서 빨간색으로 변하는지
   - 레이아웃이 깨지지 않는지

4. 상호작용 테스트 (Interaction Test)
   - 다른 모드와 번갈아 선택해도 문제없는지
   - 게임 중 새로고침 시 정상 동작하는지
```

### 10.9 Phase 7: Commit & Memory Update (커밋 및 메모리 업데이트)

**이 단계에서 참조되는 파일들:**

```
[Phase 7에서 능동적으로 참조하는 파일]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. .claude/rules/git-safety.md — 프로젝트 레벨 (이미 로딩됨)
   목적: 커밋 정책 — QA 통과 후에만 커밋, Conventional Commits 형식

2. ~/.claude/rules/git-safety.md — 유저 레벨 (이미 로딩됨)
   목적: 전역 Git 안전 규칙 — force push 금지, main 직접 커밋 금지

3. ~/.claude/rules/korean-encoding.md (이미 로딩됨)
   목적: Windows 환경 UTF-8 인코딩 규칙 — 커밋 메시지 한글 처리
```

**커밋 프로세스:**

```bash
# Step 1: 커밋 메시지 작성 (한글이므로 임시 파일 사용)
# korean-encoding.md 규칙: Windows에서 한글 커밋 시 -m 대신 -F 사용
cat > /tmp/commit-msg.txt << 'EOF'
feat(modes): 시간 제한 게임 모드(Time Attack) 추가

- 2분 내 40줄 클리어 목표의 새 게임 모드 구현
- 서버 권위 타이머 동기화 (5초 간격)
- 30초 이하 빨간색 카운트다운 UI
- mode-registry에 time-attack 등록

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF

# Step 2: 스테이징
git add server/modes/time-attack.js
git add server/modes/mode-registry.js
git add web/ui/mode-selector.js
git add web/ui/hud.js
git add docs/architecture/code-map.md

# Step 3: 커밋
git commit -F /tmp/commit-msg.txt

# Step 4: 임시 파일 정리
rm /tmp/commit-msg.txt
```

**메모리 업데이트:**

```
세션 종료 시 Auto Memory가 다음을 업데이트:

1. memory/project_context.md 업데이트:
   추가 내용:
   - Time Attack 모드 구현 완료 (2026-04-16)
   - 하드코딩된 값: TARGET_LINES=40, TIME_LIMIT=120초
   - FIXME: 추후 config 추출 예정
   - 서버→클라이언트 타이머 동기화 주기: 5초

2. memory/feedback_workflow.md 업데이트:
   추가 내용:
   - 사용자 피드백: config 대신 하드코딩 선호 (빠른 구현 우선)
   - 사용자 피드백: 30초 이하 빨간색 타이머 요구

3. MEMORY.md 인덱스 업데이트:
   - project_context.md 설명 갱신: "... + Time Attack 모드 추가"
   - feedback_workflow.md 설명 갱신: "... + Time Attack 개발 피드백"
```

### 10.10 전체 파일 참조 타임라인 요약

```
Phase 0 (컨텍스트)    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  21개 파일 이미 로딩
Phase 1 (리서치)      ████░░░░░░░░░░░░░░░░░  +4개 로딩 (skill 2, memory 1, rule 1)
Phase 2 (계획)        ░░░░░░░░░░░░░░░░░░░░░  +0개 (이미 로딩된 것 재참조)
Phase 3 (사용자검토)   ░░░░░░░░░░░░░░░░░░░░░  +0개 (대화만)
Phase 4 (레드팀)      █░░░░░░░░░░░░░░░░░░░░  +1개 (netcode skill)
Phase 5 (구현)        █░░░░░░░░░░░░░░░░░░░░  +1개 (web-client rule 활성화)
Phase 6.0 (WB QA)    █░░░░░░░░░░░░░░░░░░░░  +1개 (qa-whitebox skill)
Phase 6.1 (BB QA)    █░░░░░░░░░░░░░░░░░░░░  +1개 (qa-blackbox skill)
Phase 7 (커밋)        ░░░░░░░░░░░░░░░░░░░░░  +0개 (이미 로딩된 것 재참조)

총 컨텍스트 파일: 세션 시작 21개 → 종료 시 29개
동적 로딩: 8개 (전체의 28%)
```

---

