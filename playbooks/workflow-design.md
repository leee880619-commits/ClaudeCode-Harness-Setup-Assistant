
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
- (선택) Phase 2.5 산출물 `docs/{요청명}/02b-domain-research.md` — **있으면 Read**하여 도메인 표준 워크플로우를 우선 적용. 없으면 기존 Step 1 매핑 테이블만 사용.

## Knowledge References
필요 시 Read 도구로 로딩:
- `knowledge/05-skills-system.md` — 스킬 설계 패턴 (워크플로우-스킬 바인딩)
- `knowledge/10-agent-design.md` — 에이전트 워크플로우 패턴

## Workflow

### Step 0: Strict Coding 6-Step Preset 감지

Phase 1-2의 산출물(`docs/{요청명}/01-discovery-answers.md`)과 기술 스택 스캔 결과를 토대로,
**복잡 코딩 프로젝트** 신호를 점검하고 감지 개수에 따라 이원화하여 기록한다:
- **2개 이상** → Escalations에 `[ASK]` 로 기록 (의사결정 요청, preset 채택 제안)
- **정확히 1개** → Escalations에 `[NOTE]` 로 기록 (정보 전달만, 사용자가 원하면 채택 가능하다는 안내)
- **0개** → 기록하지 않음
- **예외 — 단일 신호가 신호 #7(사용자 의지 발화)인 경우** → `[ASK]`로 승격 (사용자가 명시적 품질 의지를 표명했으므로 질문 누락 방지)

**Step 0 범위 — `[NOTE]` 케이스만 재검토**: Phase 1-2(`fresh-setup` Step 3-B)가 이미 `[ASK]`로 기록하여 오케스트레이터가 AskUserQuestion으로 사용자 답변(A/B/C)을 받은 경우는 **의사결정이 종료된 상태**로 간주하고 Step 0에서 재검토하지 않는다. Step 0가 다루는 것은 Phase 1-2가 `[NOTE]`로 기록한 **단일 신호 케이스**이며, Phase 3 설계 직전 사용자가 명시적으로 "preset을 적용해보자"를 요청할 경우 채택 플로우로 진입한다. 그 외에는 Step 0에서 추가 기록 없이 통과.

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

신호 2개 이상:
```
- [ASK] Strict Coding 6-Step 워크플로우 적용 여부
  - 감지 신호: Next.js + TypeScript strict + Prisma + vitest (4/7)
  - 적용 시: `.claude/templates/workflows/strict-coding-6step/`의 규칙·에이전트·스킬을 대상 프로젝트에 설치
  - 기본값: 적용 권장 (복잡 코딩 프로젝트로 판정)
  - 선택지: (A) 적용 (B) 커스텀 워크플로우 설계 (C) 단순 워크플로우만 사용
```

신호 정확히 1개:
```
- [NOTE] Strict Coding 6-Step 워크플로우 소개 — 감지 신호 1/7: TypeScript strict
  - 단일 신호이므로 자동 제안은 보류. 사용자가 원하면 Phase 3 설계에서 채택 가능
  - 템플릿 경로: `.claude/templates/workflows/strict-coding-6step/`
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

**먼저 Phase 2.5 산출물 확인**: `docs/{요청명}/02b-domain-research.md` 가 존재하고 Summary에 "스킵됨"이 아니면:
1. Read하여 `## Reference Patterns > 표준 워크플로우` 섹션의 스텝 시퀀스를 **1차 후보**로 채택
2. Phase 1 인터뷰의 A1·A2와 도메인 패턴이 충돌하면 Escalations에 `[ASK] 도메인 패턴 vs 프로젝트 유형 — 어느 것을 우선?` 기록
3. 도메인 패턴을 채택할 경우, 산출물의 `## Context for Next Phase > Phase 3이 쓸 워크플로우 스텝` 목록을 Step 2 스텝 정의의 출발점으로 사용
4. 각 채택된 스텝 옆에 `(출처: 02b-domain-research.md)` 인용 표시 — 다음 Advisor가 검증

Phase 2.5 산출물이 없거나 스킵된 경우에만 아래 기본 매핑 테이블 사용:

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

### Step 4-B: Complexity Gate 필수 포함 (멀티 에이전트 / strict-coding-6step / 대규모 코드베이스)

**적용 대상 확대 기준 (OR — 하나라도 충족 시 필수)**:
- 멀티 에이전트 / 에이전트 파이프라인 / 오케스트레이터 패턴 채택 (프로젝트 유형이 "에이전트 파이프라인")
- Step 0에서 strict-coding-6step 채택 (웹앱이더라도 복잡 코딩 6단계 워크플로우면 해당)
- 코드베이스 규모 LoC ≥ 5,000 또는 파일 ≥ 100개

실측으로 비용 $18.29 오버런이 발생한 세션이 바로 "복잡 웹앱의 보안 패치 4줄" 이었다 — 웹앱 타입이라고 Complexity Gate에서 제외하면 목적을 달성하지 못한다. 초기 설계 시 "에이전트 파이프라인 한정" 으로 좁혔던 것을 이번 단계에서 수정.

위 OR 조건 중 하나라도 해당되면 **반드시** 워크플로우 최상단에 "STEP -1: Complexity Gate (태스크 크기 분류)" 를 추가한다. 이 게이트 누락은 작은 작업에도 풀 파이프라인이 강제되어 단순 패치 비용이 수십 배로 증가하는 구조적 결함이다.

**판정 주체 (보안 Dim 6 순환 고리 방지)**:
- 메인 세션은 "S/M/L 등급 추정"만 수행하고 **자가 확정 금지**.
- 등급 확정은 반드시 AskUserQuestion으로 사용자 명시 승인을 받는다 (`header: 작업 등급`, 옵션: `S (직접 구현)` / `M (단축 파이프라인)` / `L (전체 파이프라인)` / `메인이 제안한 등급 유지`).
- S 등급 승인 시점에 오케스트레이터가 per-task 토큰(`ORCHESTRATOR_DIRECT_TOKEN`)을 발급하고 `docs/complexity-gate.lock` 에 sha256 해시를 기록. 작업 완료 시 락 파일 삭제. (상세: hooks-mcp-setup.md Step 2)
- **판정 기본값**: 메인 세션이 확신 못 하면 **M**. 절대 자가 S등급 선언 금지.

**Complexity Gate 스펙** (대상 프로젝트의 `orchestrator-workflow.md` 또는 해당하는 워크플로우 규칙 파일 최상단에 그대로 삽입):

```
## STEP -1: Complexity Gate (태스크 크기 분류)

작업 시작 전 다음 기준으로 경로를 선택한다.

| 등급 | 기준 | 경로 |
|------|------|------|
| S (소형) | 파일 5개 이하 + 해법 자명 + 외부 API/신규 의존성 없음 | 메인 세션 직접 구현 허용 (ORCHESTRATOR_DIRECT=1) |
| M (중형) | 파일 5~15개 또는 설계 결정 1~2개 | 단축 파이프라인 (planner 병합 → implementer → QA) |
| L (대형) | 신규 기능, 외부 라이브러리 도입, 복잡 의존성, UI 재구성 | 전체 파이프라인 |

S 등급은 ownership-guard 우회를 자동 허용 (ORCHESTRATOR_DIRECT=1 환경변수).
등급 판단이 애매하면 상향(M→L, S→M) 기본. 다운그레이드는 사용자 명시 요청 시에만.
```

Escalations에 `[ASK] Complexity Gate 기본 임계값 확정 — 기본 제안 유지 / 사용자 커스텀` 기록하여 오케스트레이터가 사용자에게 임계값을 재확인한다.

Phase 4(pipeline-design)에는 "S 등급 경로 = 에이전트 소환 0, M 등급 경로 = 에이전트 소환 3회 이하, L 등급 경로 = 전체 파이프라인"을 제약으로 전달한다.

### Step 4-C: Specialist Review 트리거 조건 강화 (풀 파이프라인 설계 시)

풀 파이프라인(L 등급) 안에 Specialist Review(design/ux/security) 가 포함되는 경우, 무조건 병렬 호출을 지양한다. 다음 **AND 조건을 모두 충족할 때만** 트리거되도록 Phase 4에 제약을 전달:

1. 등급 L (Complexity Gate에서 L로 분류됨)
2. `src/components/` 또는 `src/app/` (또는 대상 프로젝트의 UI 디렉터리 equivalent) 파일이 변경 범위에 포함됨
3. plan.md / research.md 등의 상위 설계 산출물에 `[design-review]` / `[security-review]` / `[ux-review]` 플래그가 명시됨

S/M 등급 작업에는 Specialist 소환 없이 QA(whitebox/blackbox) 단독으로 진행. 보안 패치·config 변경·타입 수정은 QA 단독으로 충분(실측으로 Specialist 3종이 loop-back 포함 전체 비용의 ~30% 차지).

### Step 4-D: Handoff 문서 분리 원칙 (세션 간 컨텍스트 유지가 필요한 프로젝트)

대상 프로젝트가 세션 간 상태를 handoff 문서로 전달하는 경우(예: `docs/product/next-session-handoff.md`), CLAUDE.md 또는 해당 규칙 파일에 다음 원칙을 명시한다:

1. **현재 상태 파일 (`next-session-handoff.md`)**: 최신 상태 + 직전 1개 세션 요약만 보관. 목표 10KB 이내
2. **히스토리 아카이브 (`session-history.md`)**: 오래된 세션 요약을 누적. CLAUDE.md @import 대상이 **아니며**, 필요 시에만 명시적으로 Read
3. **N 세션 경과 시 이관 규칙**: handoff의 prev 항목이 2개를 초과하면 가장 오래된 항목을 `session-history.md` 로 이동

이 원칙 누락 시 handoff 파일이 누적 증가하여 매 세션 cache write 비용이 지속 상승한다(실측: 60KB handoff → 세션당 cache write 추가 비용 ~$2~3).

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
