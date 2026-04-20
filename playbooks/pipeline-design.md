
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
- (선택) Phase 2.5 산출물 `docs/{요청명}/02b-domain-research.md` — **있으면 Read**하여 도메인 표준 역할 분업을 파이프라인 역할 후보로 우선 적용. Summary가 "스킵됨"이면 무시.

## Authoritative References
- `.claude/rules/pipeline-review-gate.md` — **필수 참조**. 각 파이프라인의 리뷰어 포함 의무·면제 기준·에스컬레이션 래더를 정의하는 권위 규칙. 이 플레이북의 Step 4.5는 해당 규칙의 **적용 지침**이며, 규칙 본문과 충돌 시 규칙이 우선.

## Knowledge References
**Step 1에서 반드시 Read:**
- `knowledge/12-teams-agents.md` — 에이전트 규모 가이드라인, Teams/Agent/SendMessage 기능, **섹션 12.7a: Agent-Skill 분리 아키텍처**
- `knowledge/10-agent-design.md` — 에이전트 워크플로우 패턴

필요 시 추가 Read:
- `knowledge/05-skills-system.md` — 스킬 설계 패턴 (Co-optris, GUI2WEBAPP, PIA 패턴)

## Workflow

### Step 1: 스텝별 에이전트 후보 식별

**먼저 Phase 2.5 산출물 확인**: `docs/{요청명}/02b-domain-research.md` 가 존재하고 스킵이 아니면, `## Reference Patterns > 표준 역할/팀 분업` 테이블의 역할명을 에이전트 후보의 **1차 시드**로 사용한다. 프로젝트 규모(솔로/팀)에 맞춰 축소·통합한 후 Escalations에 `(출처: 02b-domain-research.md 역할 {역할명})` 인용을 남긴다.

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

### Step 2.5: Complexity Gate 경로별 파이프라인 계약 (에이전트 파이프라인 / 멀티 에이전트 프로젝트)

Phase 3(workflow-design)가 Step 4-B로 대상 프로젝트에 Complexity Gate(S/M/L)를 포함시킨 경우, Phase 4는 각 등급별로 **에이전트 호출 체인과 산출물 계약**을 명시한다. 이 계약이 없으면 게이트가 선언뿐이고 실제 경로 분기가 동작하지 않는다.

**S 등급 계약** (메인 세션 직접 구현):
- 에이전트 소환: 0회
- 전제: `ORCHESTRATOR_DIRECT=1` 환경변수로 ownership-guard 우회 (hooks-mcp-setup Step 2의 early-exit 블록과 짝)
- 산출물: 변경된 소스 파일 + 커밋 메시지에 `[S-grade]` 태그
- 예상 비용 프로파일: 에이전트 소환 없음, 메인 세션 직접 Read/Edit

**M 등급 계약** (단축 파이프라인):
- 에이전트 소환: 3회 이하 (researcher+planner 병합 → implementer → QA)
- **핵심: researcher와 planner를 단일 에이전트 `planner-agent`로 병합**. 이 에이전트가 `research.md` 와 `plan.md` 를 한 번의 실행으로 **동시 산출**한다. 두 에이전트 분리 시 cache write가 2회 발생해 약 10~15% 비용이 가산됨 (실측 근거).
- `planner-agent` 계약:
  - 입력: 사용자 요청, 관련 파일 경로 목록(5~15개)
  - 산출물: `docs/{task}/research.md`(조사 결과) + `docs/{task}/plan.md`(구현 계획) 동시 생성
  - 단일 소환으로 두 파일을 Write (순차 호출 금지)
- 다음: `implementer-agent` → `qa-whitebox-agent`
- Specialist Review(design/ux/security)는 이 경로에서 **소환 금지**
- 예상 비용 프로파일: 3회 에이전트 소환, L 대비 ~40~50%

**L 등급 계약** (전체 파이프라인):
- 에이전트 소환: 전체 체인 (researcher → planner → refinement → redteam → implementer → specialist? → QA)
- Specialist Review 트리거는 workflow-design Step 4-C의 3조건 AND (L + UI 디렉터리 변경 + 명시 플래그)
- 예상 비용 프로파일: 기존 풀 파이프라인

이 세 경로 계약을 `docs/{요청명}/03-pipeline-design.md` 에 `## Complexity Gate Pipeline Contracts` 섹션으로 명시하고, Phase 5(agent-team)가 `planner-agent` (M 등급 병합형) 를 프로비저닝하도록 Context for Next Phase 에 전달한다.

**Advisor Dim 12 추가 검사 항목**: M 등급 경로에 researcher와 planner가 분리되어 있거나, planner-agent가 research.md·plan.md 중 하나만 산출하는 경우 BLOCK.

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

### Step 4.5: 파이프라인 리뷰 게이트 분류 및 리뷰어 배치

**권위 문서**: `.claude/rules/pipeline-review-gate.md` 를 이 단계 시작 전에 Read. 분류 기준·리뷰어 요구사항·에스컬레이션 래더는 해당 규칙에 정의되어 있으며 여기서 재정의하지 않는다.

각 파이프라인에 대해 다음을 수행:

1. **분류**: 파이프라인을 `mandatory_review` 또는 `exempt_eligible` 로 분류
   - 생성/결정/설계/계획/리서치 → `mandatory_review`
   - 결정론적 변환/단순 I/O/검증 실행/조회 → `exempt_eligible`
   - 애매한 경우 **면제하지 않는다** (mandatory_review로 분류)
2. **면제 처리 (exempt_eligible일 때)**: 산출물에 `review_exempt: true` + `exempt_reason: "..."` 를 명시. 사유가 없으면 면제 불가.
3. **리뷰어 스텝 배치 (mandatory_review일 때)**:
   - 파이프라인의 **마지막 스텝**으로 도메인 리뷰어를 추가
   - 리뷰어 에이전트 이름은 `{domain}-redteam` 컨벤션 (예: `research-redteam`, `plan-redteam`, `content-redteam`, `design-redteam`)
   - 리뷰어는 **파이프라인별로 분리 프로비저닝** (범용 Advisor 1명으로 통합 금지)
   - 리뷰어의 `allowed_dirs`: **비움 또는 read-only 경로만** (리뷰는 파일 수정하지 않음)
   - 모델 권장: `sonnet` (일반) 또는 `opus` (전략/보안 파이프라인). `haiku` 는 피할 것 — 반례 탐색이 약해짐
4. **리뷰어 도메인 스코프 초안**: 각 리뷰어가 검사할 도메인 Dimension 2~5개 초안을 기록 (Phase 6 skill-forge가 확장)
   - 예(research-redteam): 출처 최신성, 반대 주장 누락, 편향, 인용 정확성
   - 예(plan-redteam): 기술 부채, 의존성 누락, 보안 리스크, 테스트 전략
5. **에스컬레이션 래더 참조 문구 포함**: 산출물의 해당 파이프라인 항목에 다음 한 줄을 포함 — `"리뷰 BLOCK 처리: .claude/rules/pipeline-review-gate.md '에스컬레이션 래더' 규약을 따른다 (1회=오케스트레이터 자동 승인, 2회=사용자 결정, 3회=중단)"`. 래더 본문을 복붙하지 않는다.
6. **재귀 차단 확인**: 리뷰어 스텝의 출력은 다시 리뷰받지 않는지 확인 (리뷰의 리뷰 금지).

분류 결과와 리뷰어 배치를 Escalations에 `[ASK]` 로 기록하여 오케스트레이터가 사용자 확인을 받는다. 면제 결정은 Advisor Dim 12가 재검증한다.

**Phase 5 전달 필드 (Context for Next Phase 에 반드시 포함)**:
```
### Pipeline Review Gate Decisions
| 파이프라인 | 분류 | 리뷰어 에이전트 | 면제 사유 |
|-----------|------|-----------------|----------|
| research | mandatory_review | research-redteam | - |
| plan | mandatory_review | plan-redteam | - |
| format-code | exempt | - | 결정론적 포맷팅 스크립트 실행 |
```

### Step 4.6: 실패 복구 종료 조건 & 산출물 버저닝 전략

각 파이프라인 설계 시 런타임 운영 부채를 예방하기 위해 다음 두 항목을 명시한다:

**1. 실패 복구 종료 조건**

파이프라인 내 재시도 루프·에러 핸들링·재설계 요청 흐름은 반드시 **종료 조건**을 포함한다:

- **재시도 상한**: `max_retries: N` 형태의 정수 상한. "재시도"만 적고 상한 없는 설계는 BLOCK 대상
- **에스컬레이션 분기**: 상한 도달 시 어느 에이전트·사용자에게 넘기는지 명시 (예: `max_retries: 3 → orchestrator_ask`)
- **금지 패턴**: "Builder에게 재설계 요청", "QA가 다시 검증" 등 **행위자·조건·종료 없는 개방형 서술**은 잠재적 무한 루프 → BLOCK
- **timeout 수용**: 외부 호출이 있으면 timeout 값 명시 (예: `timeout: 60s`)

**2. 산출물 경로 버저닝 전략**

파이프라인이 생성하는 산출물(분석 리포트·결정서·설계 문서)의 출력 경로는 재실행 시 덮어쓰기·오염 리스크가 있다. 다음 중 하나를 명시:

- **덮어쓰기 허용 (idempotent)**: 동일 입력→동일 출력이 보장되는 결정론적 파이프라인만 가능. `versioning: overwrite_ok + idempotency_guarantee: "..."`
- **타임스탬프 suffix**: `output_path: docs/analysis/{YYYY-MM-DD-HHmm}-report.md`
- **버전 넘버링**: `output_path: docs/analysis/v{N}/report.md` + 버전 증가 규칙
- **히스토리 디렉터리**: 최신 파일은 `current/`, 이전 실행본은 `archive/{timestamp}/`로 이동

미명시 시 Escalation `[ASK] 파이프라인 {이름}의 산출물 버저닝 전략 미정의 — 재실행 시 이전 결과 오염 가능성. 어느 전략을 적용할지 확인 필요`.

**기록 위치**: 위 두 항목을 `## Pipeline Review Gate` 표 바로 아래 또는 각 파이프라인 항목 내부에 기록한다.

### Step 5: 전체 파이프라인 다이어그램

모든 워크플로우 스텝의 파이프라인을 통합 다이어그램으로 제시. **mandatory_review 파이프라인은 말단에 리뷰어 스텝을 명시**한다:

```
Step 1: Research  (mandatory_review)
  └── tech-lead-agent → [research-redteam 리뷰]

Step 2: Design  (mandatory_review)
  └── tech-lead-agent → [design-redteam 리뷰] → [사용자 승인 게이트]

Step 3: Implement  (mandatory_review)
  └── tech-lead-agent → (frontend-agent ∥ backend-agent) → integration-agent → [plan-redteam 리뷰]

Step 4: QA  (exempt — 기존 테스트 스위트 실행, review_exempt_reason: "결정론적 테스트 실행")
  └── qa-whitebox-agent → qa-blackbox-agent → [품질 게이트]
```

각 리뷰 스텝 옆에는 `.claude/rules/pipeline-review-gate.md` 의 에스컬레이션 래더(1회=자동 승인, 2회=사용자 결정, 3회=중단) 를 따른다는 주석을 산출물 본문에 포함한다(다이어그램 자체는 간결히 유지).

전체 파이프라인 승인 여부 및 리뷰 게이트 분류 결과를 Escalations에 기록한다.

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
- [ ] `## Per-Step Pipelines` — 스텝별 에이전트 목록, 실행 순서, 패턴(순차/병렬 등). **mandatory_review 파이프라인은 말단 리뷰어 스텝 포함 필수**
- [ ] `## Pipeline Review Gate` — 파이프라인별 분류 표 (mandatory_review / exempt), 리뷰어 에이전트명, 면제 사유. 에스컬레이션 래더는 `.claude/rules/pipeline-review-gate.md` 참조 명시 (래더 본문 복붙 금지)
- [ ] `## Failure Recovery & Artifact Versioning` — Step 4.6 결과. 각 파이프라인: `max_retries`, 에스컬레이션 분기, timeout, 산출물 버저닝 전략 (overwrite_ok / timestamp / version / archive). 미정의 항목은 Escalation으로 연결
- [ ] `## Agent-Skill Mapping` — 에이전트별 모델/쓰기 범위/스킬명 (스킬 1:N). 리뷰어 에이전트는 `allowed_dirs` 를 비우거나 read-only 경로로 제한
- [ ] `## Communication Points` — SendMessage/공유파일/훅/핸드오프 사용 위치
- [ ] `## Main Session Role` — 메인 세션이 이 파이프라인에서 수행하는 역할:
  - **라우터 only**: 메인 세션은 사용자 요청을 받아 에이전트 체인을 소환·조율만 함. 방법론 직접 실행 없음. → Phase 5에서 D-1 기본값
  - **직접 실행 가능**: 메인 세션이 간단한 스킬을 직접 실행하기도 함 (에이전트 1-2개의 단순 구조) → Phase 5에서 D-3 기본값
  - **하이브리드**: 일부 진입점 스킬은 메인 세션 직접 실행, 내부는 에이전트 체인 → Phase 5에서 D-2 기본값
  - 판별 신호: 에이전트 수, 체인 깊이, 사용자 진입점 존재 여부
- [ ] `## Context for Next Phase` — Phase 5가 필요한 정보:
  - 에이전트 목록 (이름, 역할, 모델, 쓰기 범위) — **도메인 리뷰어 에이전트 포함**
  - 에이전트별 담당 스킬명 (Phase 6에서 제작할 대상) — 리뷰어의 도메인 Dimension 초안 포함
  - 실행 순서/패턴
  - 소통 포인트 목록
  - **메인 세션 역할** (라우터 only / 직접 실행 가능 / 하이브리드) — Phase 5의 Orchestrator Pattern Decision 입력
  - **Pipeline Review Gate Decisions 표** (Step 4.5의 분류 결과) — Phase 5가 리뷰어 에이전트 프로비저닝 시 사용
- [ ] `## Files Generated`
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 5: agent-team 에이전트 소환 권장"

### 대상 프로젝트 반영 (오케스트레이터 승인 후)
- 대상 프로젝트 CLAUDE.md 또는 `docs/pipeline-design.md`에 파이프라인 다이어그램 기록

## Guardrails
- 에이전트 수를 프로젝트 규모에 맞춘다 (솔로: 1-3, 중규모: 3-6, 대규모: 6-15). **도메인 리뷰어는 이 카운트에서 별도로 취급** — 프로젝트 규모 상한 때문에 리뷰어를 생략하지 않는다.
- 모든 에이전트 결정은 Escalations에 기록. 자동 추가 금지.
- 스킬 내용 자체는 작성하지 않음 — 스킬명과 매핑만 정의. 실제 SKILL.md는 Phase 6.
- "일반적으로 필요한" 에이전트를 묻지 않고 추가하지 않음.
- **리뷰어 관련 금지 사항**:
  - `mandatory_review` 파이프라인에서 리뷰어 스텝 누락 금지
  - 복수 파이프라인을 단일 "범용 Advisor" 하나로 공유 커버 금지 (도메인 특화 원칙)
  - 리뷰어에게 파일 쓰기 권한 부여 금지
  - 리뷰어 자체 출력에 다시 리뷰를 연결 금지 (재귀 차단)
  - 에스컬레이션 래더를 파이프라인별로 자체 정의 금지 — 반드시 `.claude/rules/pipeline-review-gate.md` 를 참조
  - 단순 프로젝트라는 이유로 리뷰어 스킵 금지 (복잡도 게이트로 우회 불가)
