---
name: workflow-design
description: 프로젝트 목적에 맞는 작업 단계 시퀀스(워크플로우)를 설계한다. Phase 3에서 사용.
role: designer
allowed_dirs: [".", ".claude/", "knowledge/"]
user-invocable: false
---

# Workflow Design

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 사용자 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그와 함께 기록하여 오케스트레이터가
취합 후 사용자에게 일괄 질문하도록 한다. 직접 "질문"이라는 단어가 나오는 문장도
"Escalations에 기록"의 뜻이다.

## Goal
프로젝트의 목적과 사용자 인터뷰 결과를 바탕으로, 프로젝트에 최적화된 작업 단계 시퀀스(워크플로우)를 설계한다.

## Prerequisites
- Phase 1 완료: 프로젝트 스캔 및 인터뷰 결과 확보
- Phase 2 완료: 기본 하네스(CLAUDE.md, settings.json, rules) 생성 완료
- 사용자가 프로젝트에서 하고 싶은 일이 명확히 파악된 상태

## Knowledge References
필요 시 Read 도구로 로딩:
- `knowledge/05-skills-system.md` — 스킬 설계 패턴 (워크플로우-스킬 바인딩)
- `knowledge/10-agent-design.md` — 에이전트 워크플로우 패턴

## Workflow

### Step 0: Strict Coding 6-Step Preset 감지

Phase 1-2의 산출물(`docs/{요청명}/01-discovery-answers.md`)과 기술 스택 스캔 결과를 토대로,
**복잡 코딩 프로젝트** 신호를 점검한다. 아래 신호 중 **2개 이상** 해당하면 "Strict Coding 6-Step"
템플릿을 preset으로 제안하도록 Escalations에 `[ASK]`로 기록한다.

**감지 신호**:
1. 웹 앱/백엔드 프레임워크 감지 (Next.js, Nest, Django, Rails, Spring 등)
2. 테스트 인프라 존재 (vitest/jest/pytest/playwright/cypress 설정 파일)
3. DB/ORM 사용 (Prisma/TypeORM/SQLAlchemy/Sequelize/ActiveRecord)
4. 타입 시스템 엄격 모드 (TypeScript strict, mypy strict, ruff strict)
5. CI/CD 파이프라인 (.github/workflows, .gitlab-ci.yml, circle.yml)
6. 코드베이스 규모 ≥ 5,000 LoC 또는 파일 ≥ 100개
7. 사용자가 "엄격", "정석", "프로덕션 품질" 같은 강한 품질 요구를 명시

**제외 조건** (아래면 제안하지 않음):
- 프로토타입/POC/학습 프로젝트
- 단일 스크립트 또는 소규모 CLI
- 콘텐츠 자동화/데이터 파이프라인 (별도 패턴 사용)

**Escalation 포맷 예시**:
```
- [ASK] Strict Coding 6-Step 워크플로우 적용 여부
  - 감지 신호: Next.js + TypeScript strict + Prisma + vitest (4/7)
  - 적용 시: `.claude/templates/workflows/strict-coding-6step/`의 규칙·에이전트·스킬을 대상 프로젝트에 설치
  - 기본값: 적용 권장 (복잡 코딩 프로젝트로 판정)
  - 선택지: (A) 적용 (B) 커스텀 워크플로우 설계 (C) 단순 워크플로우만 사용
```

**사용자가 적용을 승인한 경우** (오케스트레이터가 다음 Phase 전달 시):
- Phase 3의 워크플로우 스텝은 템플릿의 6단계를 그대로 채택
- Phase 4(pipeline-design)는 템플릿의 에이전트-플레이북 매핑을 기본값으로 채택. 메인 세션 역할은 D-1(라우터 only) 고정
- Phase 5(agent-team)는 템플릿의 `agents/*.md`를 대상 `.claude/agents/`로, `playbooks/*.md`를 대상 `playbooks/`로 복사
- 프로젝트 스택에 맞춘 커스터마이징(예: qa-blackbox의 서버 기동 명령, allowed_dirs)만 수행

템플릿 위치: `.claude/templates/workflows/strict-coding-6step/` (이 어시스턴트 프로젝트).

### Step 0-B: Code Navigation 규칙 채택 판별

strict-coding-6step를 채택했거나, 중~대형 코드베이스(LoC ≥ 5,000, 파일 ≥ 100)에 해당하면 `code-navigation` 공용 규칙 채택을 고려한다. 이 규칙은 `docs/architecture/code-map.md`를 활용한 타겟팅 탐색과 구현 후 자동 유지를 제공한다.

Phase 1-2의 스캔 결과에서 이 주제에 대한 Escalation이 이미 있는지 확인:
- **Phase 1-2가 이미 `[ASK] code-navigation 규칙 채택 ...`을 기록함**: 이 Step에서는 중복 기록하지 않는다. 오케스트레이터가 이미 그 Escalation을 사용자에게 질문했을 것이므로, 답변 결과에 따라 진행
- **Phase 1-2에서 기록되지 않았고 strict-coding-6step 채택**: Escalations에 `[ASK] code-navigation 규칙 채택 — strict-coding-6step의 research/implement 효율을 높임. 기존 code-map.md가 없으면 규칙만 설치하고, 실제 사용 시점에 생성 여부를 다시 확인함` 기록
- **Phase 1-2에서 기록되지 않았고 strict-coding-6step 미채택 + 대형 코드베이스**: Escalations에 `[NOTE] code-navigation 규칙 채택 고려 — 대형 코드베이스이므로 탐색 효율 향상 가능. 사용자가 원하면 Phase 7에서 훅/규칙 설치 가능` 기록

**사용자가 채택을 승인한 경우**:
- Phase 5(agent-team)는 `.claude/templates/common/rules/code-navigation.md`를 대상 `.claude/rules/code-navigation.md`로 복사 (경로 조정 필요 시 수정)
- 대상 프로젝트의 researcher/implementer(있는 경우, strict-coding-6step 템플릿 포함)가 이 규칙을 자동으로 따르게 됨

### Step 1: 프로젝트 유형 판별

Phase 1 인터뷰 결과를 기반으로 프로젝트 유형을 판별한다.
참고용 워크플로우 패턴 (강제 아님):

| 유형 | 워크플로우 패턴 예시 |
|------|---------------------|
| 웹 앱 / SPA | Research → Design → Implement → Test → Deploy |
| 게임 | Research → Design → Vertical Slice → QA → Polish |
| CLI 도구 | Spec → Implement → Test → Document → Publish |
| 라이브러리 | API Design → Implement → Test → Document → Release |
| 데이터/ML | Explore → Preprocess → Model → Evaluate → Deploy |
| 모노레포 | Analyze → Design → Package Implement → Integration → Test |
| 에이전트 파이프라인 | Input → Research → Plan → Execute → QA → Deliver |
| 콘텐츠 자동화 | Topic → Research → Draft → Design → Render → QA → Publish |

판별 결과를 Escalations에 기록하여 오케스트레이터가 사용자에게 확인한다.
사용자가 위 유형에 맞지 않는 고유한 워크플로우를 원하면 그것을 우선한다.

### Step 2: 워크플로우 스텝 정의

각 스텝에 대해 다음을 정의한다:

```
스텝 N: [스텝 이름]
├── 목적: 이 스텝이 달성하는 것
├── 입력: 이전 스텝의 출력 또는 외부 입력
├── 출력: 이 스텝이 생산하는 산출물
├── 완료 조건: 다음 스텝으로 넘어가기 위한 조건
├── 관련 도메인: 이 스텝에 필요한 전문 영역
└── 사용자 트리거 여부: 사용자가 이 스텝을 `/slash-command`로 직접 시작하는가? (yes/no)
```

**사용자 트리거 여부** 판별 기준:
- **yes**: 사용자가 워크플로우의 진입점으로 이 스텝을 직접 호출 (예: `/plan-and-implement`, `/generate-card`)
- **no**: 이전 스텝의 완료 또는 다른 에이전트의 소환에 의해서만 실행되는 내부 스텝

이 값은 Phase 6(skill-forge)의 스킬 저장 위치 판별에 사용된다 (yes면 케이스 A `.claude/skills/`, no면 케이스 B `playbooks/`).

스텝 정의 초안을 산출물에 포함하고, 확인이 필요한 사항은 Escalations에 기록한다.

### Step 3: 스텝 간 의존성 매핑

- 순차 실행 필수: A → B (A 완료 후 B 시작)
- 병렬 실행 가능: A ∥ B (동시 진행 가능)
- 반복 루프: A ↔ B (조건 충족까지 반복)
- 게이트: A → [Gate] → B (검증 통과 시만 진행)

의존성 구조에 대한 확인 사항을 Escalations에 기록한다.

### Step 4: 워크플로우 다이어그램 생성

텍스트 기반 다이어그램으로 워크플로우를 시각화:

```
[Research] → [Design] → [Implement] → [QA] → [Deploy]
                            │
                    ┌───────┼───────┐
                    ▼       ▼       ▼
                [Frontend] [Backend] [Infra]
                    │       │       │
                    └───────┼───────┘
                            ▼
                     [Integration]
```

### Step 5: 워크플로우를 대상 프로젝트 CLAUDE.md에 기록

워크플로우를 대상 프로젝트의 docs/{요청명}/02-workflow-design.md에 저장한다.
오케스트레이터가 Advisor 리뷰와 사용자 승인을 거친 후 CLAUDE.md에 반영한다.

### Step 6: 완료 및 반환

워크플로우 설계가 완료되면 반환 포맷(Summary, Files Generated, Escalations, Next Steps)에 따라 오케스트레이터에 반환한다.
Next Steps에 "Phase 4: pipeline-design 에이전트 소환 권장"을 기록한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/02-workflow-design.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Workflow Steps` — 각 스텝: 이름, 목적, 입력, 출력, 완료 조건, 관련 도메인
- [ ] `## Dependencies` — 순차/병렬/반복/게이트 의존성 다이어그램
- [ ] `## Context for Next Phase` — Phase 4가 필요한 정보:
  - 스텝 목록 (이름, 사용자 트리거 여부)
  - 스텝 간 의존성 맵
  - 각 스텝의 완료 조건
  - 사용자 승인 게이트 위치 (해당 시)
- [ ] `## Files Generated`
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 4: pipeline-design 에이전트 소환 권장"

### 대상 프로젝트 반영 (오케스트레이터 승인 후)
- 대상 프로젝트 CLAUDE.md에 `## 작업 워크플로우` 섹션 추가

## Guardrails
- 워크플로우 스텝 수는 3~8개. 너무 세분화하면 관리 부담 증가.
- 프로젝트 유형을 임의로 판단하지 않음. Escalations에 기록하여 오케스트레이터가 확인.
- 사용자가 원하지 않는 스텝을 강제하지 않음 (모든 프로젝트에 Deploy가 필요한 것은 아님).
- 파이프라인(Phase 4)의 내용을 미리 결정하지 않음. 워크플로우는 "무엇을" 정의, 파이프라인은 "누가/어떻게"를 정의.
