
# Agent Team Formation

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록한다.

## Goal
Phase 4에서 설계된 파이프라인을 바탕으로, Claude Code의 팀 기능(TeamCreate, Agent, SendMessage)을 활용하여 실제 에이전트 팀을 편성하고 소통 패턴을 설계한다.

## Prerequisites
- Phase 4 완료: 파이프라인 설계 (에이전트 목록, 실행 순서, 스킬 매핑)
- 에이전트 간 소통 포인트가 식별된 상태
- (선택) Phase 2.5 산출물 `docs/{요청명}/02b-domain-research.md` — **있으면 Read**하여 도메인 표준 팀 구조(전형적 인원수, 역할별 책임)를 팀 편성의 레퍼런스로 사용. 스킵이면 무시.

## Knowledge References
**Step 1에서 반드시 Read:**
- `knowledge/12-teams-agents.md` — Teams/Agent/SendMessage 완전 명세, 규모별 에이전트 수 권장, **섹션 12.7a: Agent-Skill 분리 아키텍처**
- `knowledge/05-skills-system.md` — SKILL.md frontmatter (role, allowed_dirs)

필요 시 추가 Read:
- `knowledge/06-hooks-system.md` — 소유권 가드 등 팀 연동 훅

## 팀 편성 모델

### 모델 A: Claude Code Teams (TeamCreate 기반)
팀을 공식 생성하고, 팀 소속 에이전트가 SendMessage로 소통하는 구조.

```
TeamCreate("impl-team")
├── Agent(name: "frontend", team_name: "impl-team", ...)
├── Agent(name: "backend", team_name: "impl-team", ...)
└── SendMessage(to: "frontend", content: "API 변경사항 공유")
```

적합: 에이전트 간 빈번한 소통, 장시간 복합 작업, 팀 단위 관리 필요

### 모델 B: 서브에이전트 소환 (Agent 도구 기반)
필요할 때 서브에이전트를 소환하여 독립 작업 수행 후 결과를 받는 구조.

```
Agent(name: "qa-check", prompt: "코드 품질 검증...", mode: "auto")
→ 결과 반환 → 다음 작업 진행
```

적합: 독립적 일회성 작업, 에이전트 간 소통 불필요, 빠른 결과 필요

### 모델 C: 하이브리드
팀 내에서는 SendMessage로 소통, 팀 간에는 독립 서브에이전트 소환.

프로젝트에 적합한 모델 선택을 Escalations에 기록하여 오케스트레이터가 사용자에게 확인한다.

### 모델 D: Agent-Skill 분리 (WHO vs HOW)
에이전트 프로젝트에서 정체성과 능력을 분리하는 구조.

WHO 위치는 항상 `.claude/agents/`이지만, **HOW 위치는 "오케스트레이터 패턴 여부"에 따라 분기한다**:

#### D-1. 오케스트레이터 패턴 (메인 세션은 순수 라우터)

```
.claude/agents/         ── WHO: 페르소나 + 규칙 (lean, ~25줄) ──
  ├── designer-agent.md   "나는 카드 디자이너다. 브랜드 가이드를 준수한다."
  └── qa-agent.md         "나는 QA 검증자다. 렌더링 결과를 검증한다."

playbooks/              ── HOW: 방법론 + 코드 (detailed, ~80줄) ──
  ├── html-card-design.md  카드 생성 방법론 (designer 전용)
  ├── image-qa.md          이미지 QA 방법론 (qa 전용)
  └── card-validation.md   카드 검증 기준 (qa 전용)
```

이 구조를 쓰는 이유: Claude Code는 `.claude/skills/` 아래 SKILL.md를 자동 디스커버리하여 메인 세션에 **사용 가능한 스킬로 노출**한다. 오케스트레이터 패턴에서는 메인 세션이 방법론을 직접 호출하면 안 되므로, HOW 파일을 `playbooks/`에 두어 자동 디스커버리를 회피한다. 이 위치 선택은 `user-invocable: false` 프론트매터로 대체할 수 없다 — 프론트매터는 가시성 필터가 아니다.

#### D-2. 하이브리드 (사용자 진입점 스킬 + 내부 스킬 공존)

```
.claude/agents/
  └── orchestrator-agent.md  (사용자 진입점을 받는 에이전트)

.claude/skills/         ── 사용자가 /slash-command로 직접 호출하는 스킬 ──
  └── card-generate/SKILL.md   진입점 (user-invocable: true)

playbooks/              ── 에이전트 체인 내부에서만 쓰는 스킬 ──
  ├── html-card-design.md
  ├── image-qa.md
  └── card-validation.md
```

#### D-3. 단일 진입점 (메인 세션이 스킬을 직접 실행해도 되는 간단한 프로젝트)

```
.claude/agents/          (에이전트 1-2개, 주로 독립 소환)
  └── some-agent.md

.claude/skills/          모든 HOW를 여기 배치
  ├── skill-a/SKILL.md
  └── skill-b/SKILL.md
```

**판별 기준:**

| 신호 | 권장 구조 |
|------|----------|
| 3개 이상 에이전트가 체인으로 협업, 메인 세션은 라우터 역할 | **D-1** |
| 사용자가 `/command`로 진입점을 호출하고, 내부에서 에이전트 체인 실행 | **D-2** |
| 에이전트 1-2개, 사용자가 스킬을 직접 호출해도 무방 | **D-3** |

**소유권 원칙:** 각 스킬은 정확히 하나의 에이전트에 소속된다. 스킬 공유는 없다.
한 에이전트가 복수의 스킬을 보유할 수 있다 (1:N 관계).
**장점:** 소유권 명확, 스킬 수정 시 영향 범위 예측 가능, lean 에이전트로 소환 비용 최소화.
**적합:** 에이전트 3개 이상의 프로젝트.
**상세:** `knowledge/12-teams-agents.md` 섹션 12.7a 참조.

에이전트 프로젝트 감지 시 위 신호에 따라 D-1/D-2/D-3 중 하나를 기본 제안하고, Escalations에 판별 근거와 함께 기록한다. **이 결정은 Phase 6(skill-forge)의 스킬 파일 저장 위치를 좌우하므로 반드시 산출물(`04-agent-team.md`)의 "Orchestrator Pattern Decision" 섹션에 명시한다.**

## Workflow

### Step 1: 팀 구조 설계

**먼저 Phase 2.5 산출물 확인**: `docs/{요청명}/02b-domain-research.md` 가 있고 스킵이 아니면, `## Reference Patterns > 표준 역할/팀 분업` 의 역할별 "전형적 인원수"를 팀 단위 후보로 참고한다. 그러나 최종 팀 수는 항상 Phase 4 파이프라인과 프로젝트 규모(솔로/중/대)에 맞춰 조정한다 — 도메인 표준을 맹종하지 않는다.

파이프라인 설계를 기반으로 팀 단위를 결정한다:

```
[팀 구조 예시]
Team: architecture
  └── Agent: tech-lead (model: opus)

Team: implementation
  ├── Agent: frontend (model: sonnet)
  └── Agent: backend (model: sonnet)

Team: quality
  ├── Agent: qa-whitebox (model: sonnet)
  └── Agent: qa-blackbox (model: sonnet)

독립 에이전트 (팀 없음):
  └── Agent: deploy (model: haiku, 일회성)
```

팀 구분과 소속 에이전트를 Escalations에 기록한다.

### Step 2: 에이전트 간 소통 패턴 설계

팀 내/팀 간 소통 방식을 구체적으로 설계한다:

| 소통 유형 | 구현 방식 | 용도 |
|-----------|----------|------|
| 동기 메시지 | SendMessage(to: "agent-name") | 즉시 응답 필요 |
| 비동기 공유 | 공유 파일 (docs/shared/) | 설계 문서, 보고서 |
| 게이트 | PostToolUse 훅 | 품질 검증 통과 여부 |
| 핸드오프 | 상태 파일 | 다음 에이전트에 결과 전달 |

소통 패턴 선택을 Escalations에 기록한다.

### Step 3: 에이전트별 설정 결정

오케스트레이터 프롬프트의 `[Model Tier]` 필드(A5 값 — `경제형` / `균형형` / `고성능형` 중 하나, 누락 시 `균형형`)를 입력으로 받아 **역할 복잡도 매트릭스**로 기본 모델을 배정한다. 그 외 설정은 기존대로 결정하여 Escalations에 기록한다:

#### 모델 배정 매트릭스

| 역할 복잡도 | 경제형 | 균형형 (권장) | 고성능형 |
|-------------|--------|---------------|----------|
| 복잡 설계 / 아키텍처 / 리서치 / 오케스트레이션 | sonnet | opus | opus |
| 구현 / 리뷰 / 리팩터 / QA-whitebox | haiku | sonnet | opus |
| 단순 검증 / 린트 / 포매팅 / QA-blackbox | haiku | haiku | sonnet |

**단일 에이전트(팀 없음)** 일 때는 위 표를 무시하고 `경제형=haiku / 균형형=sonnet / 고성능형=opus` 로 단일 배정.

매트릭스를 벗어나는 개별 조정이 필요하면(예: 도메인 특수성으로 검증 에이전트도 opus 필요) Escalations에 `[ASK] {에이전트} 모델 {tier default} → {제안} 조정 제안 — {근거}` 로 기록.

#### 재소환 시 (Model Confirmation Gate에서 `[Model Overrides]` 또는 새 `[Model Tier]` 전달)
- 프롬프트의 `[Model Overrides]` 가 있으면 해당 에이전트만 지정 모델로 교체. 그 외는 유지
- 새 `[Model Tier]` 가 있으면 매트릭스 전체 재배정
- **의무**: `04-agent-team.md` 의 `### 기각된 대안 (Rejected Alternatives)` 섹션에 이전 배정을 기각 이유와 함께 이관하고 새 배정을 본문으로 이동. `.claude/agents/*.md` frontmatter `model` 필드도 Edit
- **누적 상한**: Rejected Alternatives 는 **최근 1개(직전 배정)만 유지**한다. 재소환이 반복되면 더 오래된 이관 항목은 한 줄 압축 주석(`<!-- 이전 이력 N회, 최초 배정: {요약} -->`)으로 교체하여 파일 비대화를 막는다

#### 기타 결정 항목

- **모드**: auto, plan, bypassPermissions, default
- **격리**: worktree (독립 git 워크트리) 여부
- **쓰기 범위**: allowed_dirs (SKILL.md frontmatter에 반영)
- **백그라운드**: run_in_background 여부

### Step 4: 소유권 가드 설계 (멀티 에이전트 시)

여러 에이전트가 같은 프로젝트에서 작업할 때 파일 충돌 방지:

1. **SKILL.md의 `allowed_dirs`**: 에이전트가 쓸 수 있는 디렉터리 선언
2. **PreToolUse 훅**: Write/Edit 실행 전 소유권 검증으로 차단
3. **공유 영역**: 모든 에이전트가 접근 가능한 디렉터리 (docs/, .claude/ 등)

소유권 가드 필요 여부와 영역 구분을 Escalations에 기록한다.
솔로 프로젝트나 단독 에이전트에는 불필요 — 제안하지 않는다.

### Step 5: 에이전트 정의(WHO) 파일 생성 (Agent-Skill 분리 모델 적용 시)

모델 D가 채택된 경우, 각 에이전트에 대해 `.claude/agents/{agent-name}.md`를 생성한다.

**품질 기준: 서비스 가능 수준(Production-Ready)**
이 Phase에서 생성하는 에이전트 파일은 즉시 서비스 가능한 수준이어야 한다.
설정 과정 중에 이 에이전트들이 소환되지는 않지만, Phase 완료 후 사용자가 바로 사용할 수 있어야 한다.

```yaml
---
name: {agent-name}
description: {한 줄 역할 설명}
model: {opus|sonnet|haiku}
---
```

본문은 lean하되 완전하게 (20-30줄):
- Identity: 이 에이전트가 누구인지, 핵심 가치/원칙 (구체적이고 프로젝트 맥락에 맞게)
- Playbooks / Skills: 이 에이전트가 참조하는 방법론 파일 경로 목록 (1개 이상). 섹션 이름은 위치에 따라:
  - D-1(오케스트레이터 패턴)이면 `## Playbooks` 섹션에 `playbooks/{skill-name}.md` 경로 나열
  - D-3이면 `## Skills` 섹션에 `.claude/skills/{skill-name}/SKILL.md` 경로 나열
  - D-2(하이브리드)이면 해당 에이전트가 사용하는 실제 위치에 맞춰 섹션명/경로 혼용
- Rules: 판단 기준, 금지 행위 (3-5줄)

**스킬 소유권 원칙**: 각 스킬은 정확히 하나의 에이전트에 소속된다. 스킬 공유는 없다.
한 에이전트가 복수의 스킬을 보유할 수 있다 (1:N 관계).
동일 기준을 다른 목적으로 사용해야 하는 경우 (예: 생성 vs 검증), 별도 스킬을 만든다.

**필수 Rules 문구 (다중 에이전트 프로젝트일 때 모든 에이전트에 삽입):**
```
- AskUserQuestion을 직접 사용하지 않는다. 불확실 사항은 Escalations 섹션에 기록
- 완료 시 반환 포맷 준수: Summary, Files Generated, Escalations, Next Steps
- 쓰기 범위({해당 에이전트의 allowed_dirs})를 벗어난 Write/Edit 금지
```

위 세 문구는 본 어시스턴트 메타 규칙의 복제가 아니라 **대상 프로젝트의 협업 규약**으로서 포함한다.
오케스트레이터 패턴을 채택한 대상 프로젝트가 여러 에이전트 간 충돌 없이 작동하려면 필수적.

에이전트 정의 내용을 Escalations에 기록하여 오케스트레이터가 확인.

### Step 6: 팀 설정 문서화 및 진입점 규칙 파일 생성

승인된 팀 구조를 대상 프로젝트에 기록:
- CLAUDE.md에 `## 에이전트 팀 구조` 섹션 **추가**. 단 본문 상세는 **산출물 @import 만 기재** (예: `상세: @docs/{요청명}/04-agent-team.md` 한 줄). CLAUDE.md 본문에 에이전트별 모델을 직접 적지 않음 — 모델의 단일 진실(source of truth)은 `.claude/agents/{이름}.md` frontmatter의 `model` 필드. 이 원칙은 CLAUDE.md 단일 소유자(phase-setup) 규약과도 정합하며, Model Confirmation Gate 재조정 시 CLAUDE.md 본문을 다시 건드리지 않아 드리프트가 발생하지 않게 한다
- 에이전트-스킬 소유권 매핑 테이블 (1 에이전트 : N 스킬, 각 스킬의 예상 저장 위치 포함)은 `04-agent-team.md` 산출물에만 기록
- 소통 패턴 다이어그램은 `04-agent-team.md` 에만 기록
- 소유권 맵 포함 (해당 시, `04-agent-team.md` 에만)

**D-1 패턴(순수 오케스트레이터)일 때 진입점 규칙 파일 생성 (필수):**

D-1 프로젝트에서는 사용자가 `/slash-command`로 시작하지 않고 자연어 요청으로 메인 세션에 진입한다. 이때 메인 세션이 "어느 에이전트를 첫 번째로 소환할지"를 결정할 수 있도록 **오케스트레이터 규칙 파일**을 생성한다:

- 위치: `대상 프로젝트/.claude/rules/orchestrator-workflow.md` (또는 프로젝트에 맞는 이름)
- 내용: 메인 세션의 역할 선언(순수 라우터), 첫 에이전트 소환 조건, 에이전트 체인 순서, AskUserQuestion 소유권 규칙
- 참고 구조: `어시스턴트 프로젝트/.claude/templates/workflows/strict-coding-6step/orchestrator-workflow.md` — 이 템플릿을 대상 프로젝트 맥락으로 재작성 (직접 복사 금지, 메타 누수 방지)

**D-2 패턴(하이브리드)**: 사용자 진입점 스킬이 있으므로 orchestrator-workflow.md는 선택적. 진입점 스킬 내부에 에이전트 체인 소환 로직을 기술해도 충분.

**D-3 패턴(단일 진입점)**: orchestrator-workflow.md 불필요. 사용자가 `/slash-command`로 직접 스킬을 호출.

산출물을 docs/{요청명}/04-agent-team.md에 저장하고 오케스트레이터가 승인 처리.

### Step 7: 완료 및 반환

반환 포맷에 따라 오케스트레이터에 반환한다.
Next Steps에 "Phase 6: skill-forge 에이전트 소환 권장 (HOW 파일만 제작)"을 기록한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/04-agent-team.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Team Structure` — 팀 단위 + 소속 에이전트 + 독립 에이전트
- [ ] `## Orchestrator Pattern Decision` — D-1/D-2/D-3 중 하나로 확정된 모델, 판별 근거. Phase 6이 스킬 파일 저장 위치를 결정할 때 반드시 참조하는 필드
- [ ] `## Agent-Skill Ownership Table` — 각 에이전트 : 담당 스킬 목록 (1:N). **각 스킬의 예상 저장 위치(`.claude/skills/` 또는 `playbooks/`) 포함**
- [ ] `## Agent Identities` — 각 에이전트의 Identity 초안 요약 (페르소나, 원칙)
- [ ] `## Communication Patterns` — SendMessage/공유파일/훅/핸드오프 사용 위치
- [ ] `## Ownership Guard Scope` — 소유권 가드 적용 범위 (해당 시)
- [ ] `## Context for Next Phase` — Phase 6이 필요한 정보:
  - **Orchestrator Pattern Decision (D-1/D-2/D-3)** — Phase 6 Step 6의 위치 결정에 사용
  - 에이전트-스킬 소유권 테이블 (확정본, 예상 저장 위치 포함)
  - 각 에이전트의 Identity/원칙 (스킬 작성 시 참조)
  - 팀 구조와 소유권 가드 범위
  - Phase 6에서 제작할 스킬 목록 확정
  - **Model Tier Applied** — 프롬프트로 받은 `[Model Tier]` 원값 (예: `균형형`). Confirmation Gate가 재조정 시 비교 기준으로 사용
  - **Agent Model Table** — `| 에이전트 | 역할 | 복잡도(복잡설계/구현/단순검증) | 모델 | 근거 |` 형식의 표. Confirmation Gate가 Read하여 사용자에게 제시
- [ ] `## Files Generated` — 생성된 `.claude/agents/*.md` 목록 (모델 D 채택 시)
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 6: skill-forge 에이전트 소환 권장"

### 대상 프로젝트 반영
- 대상 프로젝트 CLAUDE.md에 `## 에이전트 팀 구조` 섹션 추가
- 모델 D 채택 시: `.claude/agents/*.md` 생성

## Guardrails
- 팀 수를 프로젝트 규모에 맞춤 (솔로: 팀 없음, 중규모: 1-2팀, 대규모: 2-4팀).
- 모든 결정은 Escalations에 기록. 임의로 팀/에이전트 추가 금지.
- 모델은 반드시 Step 3 매트릭스를 기본 배정으로 사용. 매트릭스를 벗어난 조정은 Escalations에 근거와 함께 기록.
- CLAUDE.md 본문에 에이전트별 모델을 직접 기재하지 않음 — 단일 진실은 `.claude/agents/*.md` frontmatter.
- 소유권 가드는 멀티 에이전트에만 제안. 단독 에이전트에는 불필요.
