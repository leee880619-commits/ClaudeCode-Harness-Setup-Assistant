# Strict Coding 6-Step Workflow Template

복잡한 코딩 프로젝트에 적용하는 "6단계 엄격 워크플로우"의 즉시 설치 가능한 템플릿 묶음.

## 언제 사용하는가

아래 신호 중 **2개 이상** 해당하면 이 템플릿을 제안한다:

1. 웹 앱/백엔드/멀티 모듈 구조 (Next.js/Nest/Django/Rails 등)
2. 테스트 인프라 존재 (vitest/jest/pytest/playwright)
3. DB/ORM 사용 (Prisma/TypeORM/SQLAlchemy)
4. 타입 시스템 엄격 모드 (TypeScript strict, mypy strict)
5. CI/CD 파이프라인 존재 (.github/workflows, .gitlab-ci.yml)
6. 코드베이스 규모 ≥ 5,000 LoC 또는 파일 ≥ 100개

단일 스크립트, CLI 도구, 프로토타입에는 **과잉** 적용이므로 권장하지 않는다.

## 구성 파일

이 템플릿은 **D-1 오케스트레이터 패턴**(메인 세션은 순수 라우터, 모든 실무는 서브에이전트가 수행)을 기본으로 한다. 따라서 방법론(HOW) 파일은 `.claude/skills/`가 아닌 **`playbooks/`**에 두어 메인 세션의 자동 디스커버리를 회피한다.

```
strict-coding-6step/
├── README.md                           (이 파일)
├── orchestrator-workflow.md            (규칙 본문 — 대상 .claude/rules/로 복사)
├── agents/                             (8개 에이전트 템플릿)
│   ├── researcher-agent.md
│   ├── web-researcher-agent.md
│   ├── planner-agent.md
│   ├── question-drafter-agent.md
│   ├── redteam-agent.md
│   ├── implementer-agent.md
│   ├── qa-whitebox-agent.md
│   └── qa-blackbox-agent.md
└── playbooks/                          (8개 방법론 템플릿 — flat 구조)
    ├── code-research.md
    ├── web-research.md
    ├── implementation-planning.md
    ├── question-drafting.md
    ├── design-redteam.md
    ├── code-implementation.md
    ├── qa-whitebox.md
    └── qa-blackbox.md
```

## 6단계 개요

| STEP | 내용 | Agent | Playbook |
|------|------|-------|----------|
| 0 | 작업 폴더 생성 (`docs/{task-name}/`) | (오케스트레이터) | — |
| 1 | 코드 리서치 → `research.md` | researcher-agent | code-research |
| 1-1 | 웹 리서치 (조건부) → `web_research.md` | web-researcher-agent | web-research |
| 2 | 구현 계획 초안 → `plan.md` | planner-agent | implementation-planning |
| 3 | 질문 사이클 (반복 정제) | (오케스트레이터) + question-drafter-agent 보조 | question-drafting |
| 4 | 레드팀 검토 → `plan.md` 업데이트 | redteam-agent | design-redteam |
| 5 | 구현 → 코드 변경 | implementer-agent | code-implementation |
| 6.0 | 화이트박스 QA (항상) | qa-whitebox-agent | qa-whitebox |
| 6.1 | 블랙박스 QA (조건부) | qa-blackbox-agent | qa-blackbox |

## 적용 절차 (오케스트레이터용)

1. 대상 프로젝트의 Phase 3(workflow-design)에서 "복잡 코딩 프로젝트" 판정
2. 사용자에게 "6단계 엄격 워크플로우 적용 여부" 확인 (AskUserQuestion)
3. 승인 시:
   - `orchestrator-workflow.md` → 대상 `.claude/rules/orchestrator-workflow.md` 로 복사
   - `agents/*.md` → 대상 `.claude/agents/` 로 복사 (이미 동명 파일 있으면 병합 승인)
   - `playbooks/*.md` → 대상 `playbooks/*.md` 로 복사 (대상에 `playbooks/` 디렉터리가 없으면 먼저 생성)
   - 대상 `CLAUDE.md`의 "Agent Team Structure" 섹션을 템플릿에 맞춰 갱신
4. Phase 4(파이프라인 설계)는 이 preset 스텝 시퀀스를 기반으로 진행 (추가 에이전트가 필요하지 않은 경우 자동 통과 가능)

> **절대 금지**: `playbooks/*.md`를 대상 프로젝트의 `.claude/skills/` 하위로 복사하지 않는다. 그렇게 하면 메인 세션이 자동 디스커버리하여 서브에이전트 소환을 우회하게 된다 — 이 템플릿의 전체 흐름이 무너진다.

## 절대 원칙 (이 템플릿의 정체성)

- **문제는 정면 돌파한다** — 우회·증상 억제·임시 패치 금지
- **모든 단계는 Agent Team으로 실행** — 암묵적 컨텍스트 전달 금지
- **사용자 결정이 최종** — 구현 방향은 사용자가 정한다
- **불명확하면 즉시 멈추고 질문** — 임의 판단 금지

## 커스터마이징 가이드

- 프로젝트 스택에 맞춰 각 에이전트의 `Identity` 섹션에 기술 스택 명시
- `qa-blackbox` 스킬의 "서버 기동 명령"을 실제 프로젝트 명령으로 교체
- 소유권 가드가 필요한 경우 별도 ownership-guard.sh 훅을 추가 (Phase 7-8에서 결정)

## 코드맵 통합 (선택)

이 템플릿은 `.claude/templates/common/rules/code-navigation.md` 공용 규칙과 통합된다. 이 규칙이 대상 프로젝트에 채택되면 리서치/구현 에이전트의 동작이 다음과 같이 확장된다:

- **STEP 1 (researcher-agent)**: `docs/architecture/code-map.md`가 있으면 먼저 Read하여 관련 위치를 파악한 뒤 타겟팅 탐색. 없으면 무차별 Glob 탐색으로 진행하되 `[ASK] code-map.md 부재 — 생성 제안` Escalation 기록
- **STEP 5 (implementer-agent)**: 구현 후 구조 변경이 있었으면 코드맵의 해당 부분만 업데이트. 코드맵이 없으면 생성 필요성을 Escalation으로 기록

### 채택 결정

채택 여부는 **Phase 1-3에서 사용자가 결정**한다:
- 대상 프로젝트에 이미 `docs/architecture/code-map.md` 또는 유사 파일이 있으면: Phase 1-2 스캔 시 감지 → 자동 채택 제안
- 없으면: Phase 3(workflow-design)에서 "코드맵 기반 탐색을 사용하시겠습니까?" AskUserQuestion → 채택 시 `code-navigation.md` 규칙을 대상 프로젝트에 설치 + code-map.md 신규 생성 여부를 추가 확인

채택하지 않으면 researcher/implementer는 코드맵 관련 절차 없이 평상적으로 동작한다.

## D-2 하이브리드 확장 (선택)

이 템플릿은 기본 D-1 패턴이지만, **사용자가 자연어 대신 명시적인 슬래시 명령으로 워크플로우를 시작**하고 싶다면 진입점 스킬을 하나 추가하여 D-2 하이브리드로 전환할 수 있다.

### 언제 D-2로 전환하는가
- 여러 프로젝트에서 이 워크플로우를 자주 실행하는 사용자가 `/strict-code <task>` 같은 명시적 진입점을 원할 때
- 다른 워크플로우가 같은 프로젝트에 공존하여, 어느 워크플로우로 진입하는지 사용자가 명시적으로 선택하고 싶을 때
- 자연어 요청만으로는 "작업 이름"을 메인 세션이 놓치기 쉬울 때

### 전환 절차

1. 대상 프로젝트에 `.claude/skills/strict-code-start/SKILL.md` 파일 하나만 신규 생성. 이 파일은 자동 디스커버리 대상이어야 하므로 **반드시 `.claude/skills/` 아래에 둔다**.

2. SKILL.md 최소 내용:

```markdown
---
name: strict-code-start
description: 6단계 엄격 워크플로우 진입점. task 이름을 받아 researcher-agent를 소환한다.
user-invocable: true
---

# Strict Coding Entry

## Goal
6단계 엄격 워크플로우를 시작한다. 사용자가 `/strict-code <task-name>`으로 호출한다.

## Workflow
1. task-name 파싱 (kebab-case로 정규화)
2. `docs/{task-name}/` 디렉터리 생성
3. 이전 작업 폴더 존재 여부 확인 → 있으면 재개/새로 시작 확인
4. STEP 1(researcher-agent) 소환으로 워크플로우 진입

이 스킬은 실무를 수행하지 않는다. 라우팅과 컨텍스트 준비만 담당한다.
실제 리서치·계획·구현은 playbooks/의 방법론을 따르는 에이전트가 수행한다.

## Guardrails
- 이 스킬 자체에 리서치/구현 로직을 추가하지 않는다. 그런 로직은 playbooks/에 속한다.
- task-name이 비어있으면 사용자에게 확인 요청한다.
```

3. `.claude/rules/orchestrator-workflow.md`의 진입 문구에 "`/strict-code`로도 진입 가능"을 추가. 기존 자연어 트리거도 유지.

4. 대상 `CLAUDE.md`의 "Agent Team Structure" 섹션에 "진입점: `/strict-code <task-name>` 또는 자연어 요청" 명시.

### 주의
- **진입점 스킬 외의 방법론(researcher, planner 등 8개)은 반드시 `playbooks/`에 유지**. `.claude/skills/`로 끌어올리면 메인 세션이 직접 호출하여 에이전트 체인이 무너진다.
- 여러 진입점을 추가할 수 있으나, 각 진입점은 "라우팅만" 수행하는 lean 스킬로 유지 — 실무 로직은 playbooks/ 또는 에이전트에게 위임.
