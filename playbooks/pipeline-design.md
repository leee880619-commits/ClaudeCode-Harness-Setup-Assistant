---
name: pipeline-design
description: 각 워크플로우 스텝에 대해 에이전트 실행 체인(파이프라인)을 설계한다. Phase 4에서 사용.
role: pipeline-designer
allowed_dirs: [".", ".claude/", "knowledge/"]
user-invocable: false
---

# Pipeline Design

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그와 함께 기록하여 오케스트레이터가
사용자에게 일괄 질문하도록 한다.

## Goal
Phase 3에서 정의된 워크플로우의 각 스텝에 대해, 어떤 에이전트들을 소환하고 어떤 순서와 의존성으로 실행하며 각 에이전트가 어떤 스킬을 사용할지를 설계한다.

## Prerequisites
- Phase 3 완료: 워크플로우 스텝 정의, 의존성 매핑 완료
- 각 스텝의 목적, 입출력, 완료 조건이 명확한 상태

## Knowledge References
**Step 1에서 반드시 Read:**
- `knowledge/12-teams-agents.md` — 에이전트 규모 가이드라인, Teams/Agent/SendMessage 기능, **섹션 12.7a: Agent-Skill 분리 아키텍처**
- `knowledge/10-agent-design.md` — 에이전트 워크플로우 패턴

필요 시 추가 Read:
- `knowledge/05-skills-system.md` — 스킬 설계 패턴 (Co-optris, GUI2WEBAPP, PIA 패턴)

## Workflow

### Step 1: 스텝별 에이전트 후보 식별

각 워크플로우 스텝에 필요한 전문 역할을 식별한다:

```
워크플로우 스텝: [Implement]
├── 필요 역할:
│   ├── frontend-agent: UI/UX 구현
│   ├── backend-agent: API/서버 구현
│   └── integration-agent: 통합 검증
├── 판단 근거: Phase 1 스캔 (src/client/, src/server/ 존재)
```

각 스텝의 에이전트 후보를 Escalations에 기록하여 오케스트레이터가 사용자에게 확인한다.
프로젝트 규모에 맞지 않는 과도한 에이전트를 제안하지 않는다.

### Step 2: 실행 순서 및 의존성 설계

각 스텝 내에서 에이전트들의 실행 흐름을 설계한다.

**실행 패턴 유형:**

| 패턴 | 설명 | 표기 |
|------|------|------|
| 순차 | A 완료 후 B 시작 | A → B |
| 병렬 | A와 B 동시 실행 | A ∥ B |
| 팬아웃/팬인 | 분기 후 합류 | A → (B ∥ C) → D |
| 반복 | 조건 충족까지 반복 | A ↔ B (until condition) |
| 게이트 | 검증 통과 시만 진행 | A → [Gate] → B |

각 스텝의 실행 패턴 선택을 Escalations에 기록한다.

### Step 3: 에이전트-스킬 소유권 매핑

각 에이전트가 보유할 스킬을 매핑한다. **각 스킬은 정확히 하나의 에이전트에 소속**된다 (스킬 공유 없음). 한 에이전트가 복수의 스킬을 보유할 수 있다 (1:N 관계).

```
[Implement 스텝 파이프라인]
frontend-agent:
  ├── 스킬: build-ui
  ├── 모델 권장: sonnet (구현 작업)
  └── 쓰기 범위: src/client/, src/styles/

backend-agent:
  ├── 스킬: build-api
  ├── 모델 권장: sonnet
  └── 쓰기 범위: src/server/, src/routes/

qa-agent:
  ├── 스킬: validate-integration, ui-validation, api-validation
  ├── 모델 권장: sonnet
  └── 쓰기 범위: tests/integration/
```

동일 기준을 다른 목적으로 사용해야 하는 경우 (예: 생성 vs 검증), 별도 스킬을 만든다.
스킬명, 모델 선택, 쓰기 범위를 Escalations에 기록하여 오케스트레이터가 확인한다.
모델 선택 시 비용/성능 트레이드오프를 Escalations에 포함한다:
- opus: 복잡한 설계/분석, 가장 비용 높음
- sonnet: 구현/일반 작업, 균형
- haiku: 단순 검증/반복 작업, 가장 저렴

### Step 4: 에이전트 간 소통 포인트 식별

에이전트 간 정보 전달이 필요한 지점을 식별한다:

| 소통 유형 | 구현 방식 | 용도 |
|-----------|----------|------|
| 동기 메시지 | SendMessage | 즉시 응답이 필요한 질문/요청 |
| 비동기 공유 | 공유 파일 (docs/shared/) | 설계 문서, 상태 보고서 |
| 게이트 | 훅 (PostToolUse) | 품질 검증 통과 여부 |
| 핸드오프 | 상태 파일 (_state.json) | 이전 에이전트 결과를 다음에 전달 |

소통 패턴 선택을 Escalations에 기록한다.

### Step 5: 전체 파이프라인 다이어그램

모든 워크플로우 스텝의 파이프라인을 통합 다이어그램으로 제시:

```
Step 1: Research
  └── tech-lead-agent (단독)

Step 2: Design
  └── tech-lead-agent → [사용자 승인 게이트]

Step 3: Implement
  └── tech-lead-agent → (frontend-agent ∥ backend-agent) → integration-agent

Step 4: QA
  └── qa-whitebox-agent → qa-blackbox-agent → [품질 게이트]
```

전체 파이프라인 승인 여부를 Escalations에 기록한다.

### Step 6: 파이프라인 문서화 및 완료 반환

승인된 파이프라인을 대상 프로젝트에 기록한다:
- CLAUDE.md의 워크플로우 섹션에 파이프라인 정보 추가
- 또는 별도 `docs/pipeline-design.md`로 분리 (CLAUDE.md 200줄 초과 시)

완료 시 반환 포맷에 따라 오케스트레이터에 반환한다.
Next Steps에 "Phase 5: agent-team 에이전트 소환 권장"을 기록한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/03-pipeline-design.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Per-Step Pipelines` — 스텝별 에이전트 목록, 실행 순서, 패턴(순차/병렬 등)
- [ ] `## Agent-Skill Mapping` — 에이전트별 모델/쓰기 범위/스킬명 (스킬 1:N)
- [ ] `## Communication Points` — SendMessage/공유파일/훅/핸드오프 사용 위치
- [ ] `## Main Session Role` — 메인 세션이 이 파이프라인에서 수행하는 역할:
  - **라우터 only**: 메인 세션은 사용자 요청을 받아 에이전트 체인을 소환·조율만 함. 방법론 직접 실행 없음. → Phase 5에서 D-1 기본값
  - **직접 실행 가능**: 메인 세션이 간단한 스킬을 직접 실행하기도 함 (에이전트 1-2개의 단순 구조) → Phase 5에서 D-3 기본값
  - **하이브리드**: 일부 진입점 스킬은 메인 세션 직접 실행, 내부는 에이전트 체인 → Phase 5에서 D-2 기본값
  - 판별 신호: 에이전트 수, 체인 깊이, 사용자 진입점 존재 여부
- [ ] `## Context for Next Phase` — Phase 5가 필요한 정보:
  - 에이전트 목록 (이름, 역할, 모델, 쓰기 범위)
  - 에이전트별 담당 스킬명 (Phase 6에서 제작할 대상)
  - 실행 순서/패턴
  - 소통 포인트 목록
  - **메인 세션 역할** (라우터 only / 직접 실행 가능 / 하이브리드) — Phase 5의 Orchestrator Pattern Decision 입력
- [ ] `## Files Generated`
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 5: agent-team 에이전트 소환 권장"

### 대상 프로젝트 반영 (오케스트레이터 승인 후)
- 대상 프로젝트 CLAUDE.md 또는 `docs/pipeline-design.md`에 파이프라인 다이어그램 기록

## Guardrails
- 에이전트 수를 프로젝트 규모에 맞춘다 (솔로: 1-3, 중규모: 3-6, 대규모: 6-15).
- 모든 에이전트 결정은 Escalations에 기록. 자동 추가 금지.
- 스킬 내용 자체는 작성하지 않음 — 스킬명과 매핑만 정의. 실제 SKILL.md는 Phase 6.
- "일반적으로 필요한" 에이전트를 묻지 않고 추가하지 않음.
