<!-- File: 12-teams-agents.md | Source: architecture-report Section 12 -->
## SECTION 12: Teams 및 Agent 시스템

### 12.1 개요

Claude Code는 멀티 에이전트 작업을 위한 세 가지 핵심 도구를 제공한다:

| 도구 | 용도 | 핵심 파라미터 |
|------|------|-------------|
| `TeamCreate` | 에이전트 팀 생성 | team_name |
| `Agent` | 에이전트 소환 | name, team_name, model, mode, isolation, prompt |
| `SendMessage` | 에이전트 간 메시지 전달 | to, content |

### 12.2 Agent 도구 상세

Agent 도구는 서브에이전트를 소환하여 독립적인 작업을 수행하게 한다.

**핵심 파라미터:**

| 파라미터 | 필수 | 설명 |
|---------|------|------|
| `prompt` | 필수 | 에이전트에게 부여할 작업 지시 |
| `description` | 필수 | 3-5단어 작업 설명 |
| `name` | 선택 | 에이전트 이름. SendMessage의 `to`로 주소 지정 가능 |
| `team_name` | 선택 | 소속 팀. TeamCreate로 생성된 팀에 연결 |
| `model` | 선택 | opus, sonnet, haiku 중 선택 |
| `mode` | 선택 | auto, plan, bypassPermissions, default 등 |
| `isolation` | 선택 | "worktree" — 독립 git 워크트리에서 실행 |
| `subagent_type` | 선택 | 전문 에이전트 유형: general-purpose, Explore, Plan 등 |
| `run_in_background` | 선택 | true면 백그라운드 실행, 완료 시 알림 |

**에이전트 소환 패턴:**

```
# 단독 서브에이전트
Agent(name: "qa", prompt: "코드 품질 검증...", model: "sonnet")

# 팀 소속 에이전트
Agent(name: "frontend", team_name: "impl-team", prompt: "...", model: "sonnet")

# 백그라운드 실행
Agent(name: "lint", prompt: "린트 검사...", run_in_background: true)

# 독립 워크트리 (변경사항 격리)
Agent(name: "experiment", prompt: "실험적 변경...", isolation: "worktree")

# 병렬 소환 (한 메시지에 여러 Agent 호출)
Agent(name: "frontend", prompt: "...") + Agent(name: "backend", prompt: "...")
```

### 12.3 TeamCreate 도구 상세

팀을 생성하여 여러 에이전트를 그룹으로 관리한다.

```
TeamCreate(team_name: "implementation")
→ Agent(name: "frontend", team_name: "implementation", ...)
→ Agent(name: "backend", team_name: "implementation", ...)
```

**팀의 장점:**
- 에이전트 간 소통 채널 제공 (SendMessage)
- 논리적 그룹핑으로 작업 관리
- 팀 단위 정리 (TeamDelete)

### 12.4 SendMessage 도구 상세

실행 중인 에이전트 간 메시지를 전달한다.

```
SendMessage(to: "frontend", content: "API 엔드포인트 변경: /api/v2/users")
```

**용도:**
- 에이전트 간 작업 결과 공유
- 의존성 해결: A 완료 후 B에 알림
- 상태 업데이트: 진행 상황 공유

### 12.5 멀티 에이전트 아키텍처 패턴

#### 패턴 1: 순차 파이프라인
```
Agent A → Agent B → Agent C
각 에이전트가 이전의 결과를 받아 작업
```

#### 패턴 2: 팬아웃/팬인
```
                  Agent B
Agent A → fork →  Agent C  → join → Agent D
                  Agent E
B, C, E는 병렬 실행, 모두 완료 후 D 실행
```

#### 패턴 3: 지휘자(Orchestrator)
```
Orchestrator Agent
├── SendMessage → Worker A
├── SendMessage → Worker B
├── 결과 수집
└── 최종 통합
```

#### 패턴 4: 피어 커뮤니케이션
```
Agent A ←→ Agent B
  ↕            ↕
Agent C ←→ Agent D
팀 내 에이전트가 자유롭게 소통
```

### 12.6 소유권 가드와 팀 연동

멀티 에이전트 환경에서 파일 충돌 방지:

1. **SKILL.md `allowed_dirs`**: 에이전트 쓰기 범위 선언 (정보 제공용)
2. **PreToolUse 훅**: 실제 쓰기 차단 런타임 가드
3. **공유 영역**: 모든 에이전트 접근 가능 디렉터리 (docs/shared/ 등)

소유권 가드 훅 패턴은 `knowledge/06-hooks-system.md`의 ownership-guard.sh 참조.

### 12.7 `.claude/agents/` 서브에이전트 정의 파일

`Agent` 도구의 `subagent_type` 파라미터는 built-in 타입(`Explore`, `Plan`, `general-purpose`) 외에 **프로젝트/유저 정의 커스텀 에이전트**를 참조할 수 있다.

#### 커스텀 에이전트 정의

`.claude/agents/<name>.md` 또는 `~/.claude/agents/<name>.md`에 배치한다.

```markdown
---
name: code-reviewer
description: Specialized agent for reviewing code quality, security, and style. Use when reviewing PRs or checking implementation.
model: claude-sonnet-4-6
---

You are a strict code reviewer. Focus on:
1. Security vulnerabilities (OWASP Top 10)
2. Performance bottlenecks
3. Naming conventions and readability

Always provide specific line references and concrete improvement suggestions.
```

#### 호출 방식

```
# subagent_type으로 커스텀 에이전트 호출
Agent(
  subagent_type: "code-reviewer",
  description: "PR security review",
  prompt: "Review the changes in src/auth/ for security issues"
)
```

#### 에이전트 정의 vs SKILL.md 선택 기준

| 기준 | `.claude/agents/*.md` 선택 | `.claude/skills/*/SKILL.md` 선택 |
|------|--------------------------|--------------------------------|
| 실행 격리 필요 | ✅ 독립 컨텍스트 필요 시 | ❌ 메인 세션 공유 |
| 재사용 패턴 | 여러 프로젝트/팀 공유 에이전트 | 이 프로젝트 전용 워크플로우 |
| 모델 분리 | 전용 모델 지정 필요 시 | 메인 모델로 충분할 때 |
| 슬래시 명령 | 없음 (도구로만 호출) | `/skill-name` 슬래시 명령 지원 |

#### 내장 에이전트와의 우선순위

프로젝트의 `.claude/agents/explore.md`를 정의하면 built-in `Explore` 에이전트를 **프로젝트 수준에서 오버라이드**한다. User 에이전트와 Project 에이전트가 동일 `name`이면 **Project가 우선**이다.

### 12.7a Agent-Skill 분리 아키텍처 (WHO vs HOW)

에이전트 프로젝트에서 WHO(정체성)와 HOW(능력)를 **관심사 분리** 원칙으로 설계하는 패턴.

#### 핵심 개념

| 계층 | 위치 | 정의하는 것 | 크기 |
|------|------|-----------|------|
| **WHO** (정체성) | `.claude/agents/*.md` | 페르소나, 목적, 준수 규칙, 판단 기준 | 20-30줄 (lean) |
| **HOW** (능력) | `.claude/skills/*/SKILL.md` 또는 `playbooks/*.md` (아래 위치 결정 참조) | 방법론, 도구 사용법, 코드 템플릿, 워크플로우 | 50-120줄 (detailed) |

- 에이전트(WHO)는 **무엇을 해야 하는지**와 **어떤 원칙을 따르는지**를 정의
- 방법론(HOW)은 **구체적으로 어떻게 수행하는지**를 정의
- 에이전트가 소환되면, 정의된 방법론 중 적합한 것을 선택하여 작업 수행

#### HOW의 저장 위치 결정 (중요)

Claude Code 런타임은 `.claude/skills/` 아래의 SKILL.md를 **자동 디스커버리**하여 메인 세션에 "사용 가능한 스킬"로 노출한다. 시스템 프롬프트에는 "When a skill matches the user's request, this is a BLOCKING REQUIREMENT: invoke the relevant Skill tool" 지시가 있어, 메인 세션이 서브에이전트 소환을 우회하고 스킬을 직접 실행하게 만든다. 이 노출은 `user-invocable: false` 프론트매터로 차단되지 **않는다** — 프론트매터는 메타데이터일 뿐, 런타임의 가시성 필터가 아니다.

따라서 HOW 파일의 저장 위치는 **메인 세션 가시성을 제어하는 실질적 수단**이다:

| 케이스 | HOW 위치 | 용도 | 메인 세션 노출 |
|--------|---------|------|---------------|
| **D-1: 오케스트레이터 패턴** | `playbooks/*.md` (flat) | 메인 세션은 순수 라우터. 서브에이전트가 Read해서 실행 | ❌ 차단 (자동 디스커버리 안 됨) |
| **D-2: 하이브리드** | 혼용 — 진입점은 `.claude/skills/`, 내부는 `playbooks/` | 사용자가 `/command`로 진입 + 내부 에이전트 체인 | 진입점만 노출 |
| **D-3: 단일 진입점** | `.claude/skills/*/SKILL.md` | 에이전트 1-2개, 메인 세션이 스킬 직접 실행 가능 | ✅ 의도된 노출 |

**판별**: 에이전트 3개 이상이고 메인 세션이 라우터 역할만 한다면 D-1. 사용자 `/command` 진입점이 있고 내부에 에이전트 체인이 있으면 D-2. 단순하면 D-3.

#### 장점

1. **관심사 분리**: 정체성(WHO)과 능력(HOW)이 독립적으로 관리됨
2. **소유권 명확**: 각 스킬은 정확히 하나의 에이전트에 소속 (1:N — 스킬 공유 없음, 한 에이전트가 복수 스킬 보유 가능)
3. **독립 업데이트**: 스킬 수정 시 영향 범위가 단일 에이전트로 한정되어 예측 가능
4. **lean 에이전트**: 에이전트 정의가 20-30줄로 경량화되어 소환 시 컨텍스트 부담 최소

#### 에이전트 정의 패턴 (lean)

**D-1 오케스트레이터 패턴의 예:**

```markdown
---
name: designer-agent
description: 카드 디자이너. HTML/CSS 기반 시각 콘텐츠를 제작한다.
model: claude-sonnet-4-6
---

You are a visual content designer specializing in card-based layouts.

## Identity
- 시각적 균형과 가독성을 최우선시
- 인스타그램 규격(1080×1350px)을 준수

## Playbooks
작업 시 다음 방법론을 Read하여 따른다:
- `playbooks/html-card-design.md` — HTML/CSS 카드 생성

## Rules
- 모든 텍스트는 한국어 기본
- 색상은 브랜드 가이드를 준수
- 생성한 HTML은 templates/{topic}/ 에 저장
```

**D-3 단일 진입점 패턴의 예**: `## Playbooks` 섹션 대신 `## Skills` 섹션에 `.claude/skills/html-card-design/SKILL.md` 경로를 기재한다.

#### 스킬 정의 패턴 (detailed)

```markdown
---
name: html-card-design
description: HTML/CSS 기반 인스타그램 카드 생성 방법론. 템플릿, 코드 패턴, 검증 기준 포함.
user-invocable: false
---

# HTML Card Design

## Goal
브랜드 가이드에 맞는 인스타그램 카드 HTML/CSS를 생성한다.

## Workflow
1. 콘텐츠 구조 분석 — 카드 수, 흐름 결정
2. HTML 스켈레톤 생성 — 템플릿 기반
3. CSS 스타일링 — 브랜드 색상, 타이포그래피
4. 반응형 검증 — 1080×1350px 기준

## Code Templates
(구체적인 HTML/CSS 코드 패턴...)

## Guardrails
- 인라인 스타일만 사용 (외부 CSS 링크 금지)
- 이미지 경로는 assets/ 상대경로로
```

#### 실제 프로젝트 구조 예시 (D-2 하이브리드)

5개 에이전트가 체인으로 협업하며, 사용자가 `/card-generate`로 진입하는 구조:

```
instagram-card/
├── CLAUDE.md                          프로젝트 정체성, 워크플로우, 에이전트 팀 구조
├── .claude/
│   ├── settings.json                  권한 + MCP 설정
│   ├── rules/                         ── 항상 적용 규칙 ──
│   │   ├── card-generation.md         에이전트 팀 소환 프로토콜
│   │   └── instagram-format.md        인스타 규격/디자인 기준
│   ├── agents/                        ── WHO: 페르소나 + 규칙 (lean) ──
│   │   ├── reference-agent.md         레퍼런스 리서처
│   │   ├── planner-agent.md           콘텐츠 기획자
│   │   ├── designer-agent.md          카드 디자이너
│   │   ├── renderer-agent.md          렌더러
│   │   └── qa-agent.md               QA 검증자
│   └── skills/                        ── 사용자 진입점 스킬 (메인 세션 노출 OK) ──
│       └── card-orchestrator/SKILL.md  진입점. `/card-generate` 슬래시 명령
├── playbooks/                         ── 에이전트 전용 방법론 (메인 세션에 노출 안 됨) ──
│   ├── instagram-reference.md         검색 방법론
│   ├── html-card-design.md            HTML/CSS 카드 생성 (designer 전용)
│   ├── playwright-render.md           렌더링 스크립트
│   ├── image-qa.md                    이미지 QA 검증
│   └── card-validation.md             카드 검증 기준 (qa 전용)
├── templates/{topic}/                 카드 HTML (에이전트 생성)
├── output/{topic}/                    생성된 PNG (gitignored)
└── docs/state/                        에이전트 간 상태 전달
```

`card-orchestrator`만 `.claude/skills/`에 있어서 사용자가 `/card-generate`로 시작할 수 있고, 나머지 5개 내부 방법론은 `playbooks/`에 있어서 메인 세션에 노출되지 않는다. 진입점 스킬이 호출되면 내부적으로 각 에이전트를 소환하고, 에이전트는 `playbooks/*.md`를 Read하여 방법론대로 실행한다.

순수 D-1 패턴이면 `.claude/skills/` 디렉터리 자체가 없어도 된다. D-3 패턴이면 `playbooks/`가 없고 모든 HOW가 `.claude/skills/`에 있다.

#### 에이전트→스킬 소유권 매핑 테이블

위 프로젝트의 에이전트-스킬 매핑 예시 (1 에이전트 : N 스킬, 공유 없음):

| Agent (WHO) | Skills (HOW) |
|-------------|-------------|
| reference-agent | instagram-reference |
| planner-agent | content-planning |
| designer-agent | html-card-design |
| renderer-agent | playwright-render |
| qa-agent | image-qa, card-validation |

qa-agent가 검증 전용 스킬(`card-validation`)을 별도 보유하는 것에 주목.
동일 기준을 다른 목적(생성 vs 검증)으로 사용해야 하면, 스킬을 공유하지 않고 별도 스킬을 만든다.

#### 이 패턴의 적용 시점

- **적합**: 에이전트 파이프라인, 콘텐츠 자동화, 3개 이상의 에이전트가 협업하는 프로젝트
- **과도**: 솔로 CLI 도구, 단순 웹앱 (에이전트 1-2개면 스킬과 에이전트를 분리할 필요 없음)
- **스킬 소유권**: 각 스킬은 정확히 하나의 에이전트 소속. 한 에이전트가 복수 스킬 보유 가능 (1:N)

---

### 12.8 이 도구 자체의 서브에이전트 모델 정책

이 도구(Harness Setup Assistant)의 모든 Phase 서브에이전트와 Red-team Advisor는 **opus**로 실행한다.
하네스 세팅은 프로젝트 당 1회이며, 각 Phase의 설계 품질이 대상 프로젝트의 전체 수명에 영향을 미치므로 최고 품질의 추론이 필요하다.

**대상 프로젝트용 에이전트의 모델 선택은 별도** — 사용자에게 비용/성능 트레이드오프를 설명하고 선택받아야 한다.

### 12.9 하네스 설계 시 규모별 권장 구성

| 프로젝트 규모 | 권장 에이전트 수 | 팀 구성 |
|-------------|----------------|---------|
| 솔로/소규모 | 1-3 | 팀 없음, 서브에이전트만 |
| 중규모 | 3-6 | 1-2 팀 |
| 대규모/모노레포 | 6-15 | 2-4 팀, 역할별 분리 |
| 연구/실험 | 가변적 | 주제별 임시 팀 |

**과도한 에이전트의 위험:**
- 컨텍스트 스위칭 비용 증가
- 소통 오버헤드
- 소유권 충돌 빈도 증가
- 비용 증가 (각 에이전트가 별도 API 호출)

---
