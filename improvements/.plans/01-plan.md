# 구현 계획: 경량 트랙 분기 도입

## 요약 (변경 파일 목록)

| 파일 | 유형 | 변경 유형 |
|------|------|-----------|
| `.claude/rules/orchestrator-protocol.md` | 규칙 | 수정 — 트랙 판별 프로토콜 + Phase Gate 경량 트랙 행 추가 |
| `playbooks/setup-lite.md` | 플레이북 | 신규 생성 |
| `.claude/agents/phase-setup-lite.md` | 에이전트 | 신규 생성 |
| `ARCHITECTURE.md` | 문서 | 수정 — 4.1 Phase 역할 테이블 + 4.3 Fast Track 섹션 |

---

## 구현 순서

1. `playbooks/setup-lite.md` 신규 생성 (에이전트 정의보다 먼저 — 에이전트가 참조)
2. `.claude/agents/phase-setup-lite.md` 신규 생성
3. `.claude/rules/orchestrator-protocol.md` 수정
4. `ARCHITECTURE.md` 수정

---

## 변경 1: `orchestrator-protocol.md`

### 삽입 위치 A — 트랙 판별 프로토콜 섹션

**삽입 위치**: `## Phase 실행 프로토콜` 섹션 안, `### Phase-to-Agent 매핑` 헤더 바로 앞.

현재 파일에서 해당 위치:
```
### 에이전트 소환 템플릿 (Agent-Playbook 분리)
...
### Phase-to-Agent 매핑
```

**추가할 내용 (전문)**:

```markdown
### 트랙 판별 프로토콜 (Phase 1-2 완료 직후)

Phase 1-2 에이전트가 반환되면 오케스트레이터는 산출물 `01-discovery-answers.md`를 Read하여
아래 5개 조건을 모두 AND로 확인한다. **모든 조건이 충족될 때만 경량 트랙**이다.
하나라도 불충족이면 풀 트랙.

| 조건 | 확인 위치 | 경량 트랙 값 |
|------|-----------|-------------|
| 프로젝트 유형 | `## Context for Next Phase` → 프로젝트 유형 | 웹앱 또는 CLI |
| 솔로/팀 | `## Context for Next Phase` → 솔로/팀 | 솔로 |
| 에이전트 프로젝트 여부 | `## Context for Next Phase` → 에이전트 프로젝트 여부 | 아니오 |
| 에이전트 신호 (3-A) | `## Escalations` → [ASK] 에이전트 프로젝트 감지 항목 | 없음 (NOTE도 없음) |
| Strict Coding 신호 (3-B) | `## Escalations` → [ASK]/[NOTE] Strict Coding 항목 | NOTE 이하 (ASK 없음) |

**Strict Coding 신호 판별 세부 규칙**:
- `[ASK] Strict Coding 6-Step 권장` 항목이 1건이라도 있으면 → 풀 트랙 (사용자 확인 필요)
- `[NOTE] Strict Coding 6-Step 소개` 항목만 있으면 → 경량 트랙 허용 (단순 참고)
- 항목 없음 → 경량 트랙 허용

**판별 후 처리**:

1. `00-target-path.md` frontmatter의 `track` 필드를 `lightweight` 또는 `full`로 Edit하여 기록
   (Phase 0에서 `track: pending`으로 초기 작성, 여기서 확정)
2. AskUserQuestion으로 사용자에게 트랙 결정을 고지:
   - 경량 트랙: "단순 솔로 프로젝트로 감지되어 경량 트랙을 제안합니다 (약 25~35분, 8~10회 LLM 호출). 풀 트랙(60분+, 18회+ 호출)보다 빠르게 MVP 하네스를 완성합니다."
     옵션: `경량 트랙으로 진행 (권장)` / `풀 트랙으로 전환`
   - 풀 트랙: 별도 고지 없이 기존 Phase 3 진행
3. 경량 트랙 선택 시 → `phase-setup-lite` 에이전트 소환 (Phase L)
   풀 트랙 선택 시 → 기존 Phase 2.5/3 분기 로직으로 진행
```

---

### 삽입 위치 B — Phase-to-Agent 매핑 테이블 수정

**변경 전 (정확한 인용)**:
```markdown
| Phase | Agent Name | Playbook (playbooks/*.md) | 비고 |
|-------|-----------|--------------------------|------|
| 0 | (메인 세션) | N/A | 경로 수집만 |
| 1-2 | phase-setup | fresh-setup | 또는 cursor-migration, harness-audit |
| 2.5 | phase-domain-research | domain-research | 옵션. 도메인 답변이 "해당 없음"/Fast Track이면 스킵 |
| 3 | phase-workflow | workflow-design | Phase 2.5 산출물 있으면 Read |
| 4 | phase-pipeline | pipeline-design | Phase 2.5 산출물 있으면 Read |
| 5 | phase-team | agent-team | Phase 2.5 산출물 있으면 Read |
| 6 | phase-skills | skill-forge | Phase 2.5 산출물 있으면 Read. 복수 에이전트 SKILL 생성 시 TeamCreate 고려 |
| 7-8 | phase-hooks | hooks-mcp-setup | |
| 9 | phase-validate | final-validation | |
```

**변경 후**:
```markdown
| Phase | Agent Name | Playbook (playbooks/*.md) | 비고 |
|-------|-----------|--------------------------|------|
| 0 | (메인 세션) | N/A | 경로 수집만 |
| 1-2 | phase-setup | fresh-setup | 또는 cursor-migration, harness-audit |
| **L** | **phase-setup-lite** | **setup-lite** | **경량 트랙 전용. Phase 1-2 완료 후 트랙 판별 결과가 lightweight인 경우만 실행. Phase 3-6을 단일 에이전트로 대체.** |
| 2.5 | phase-domain-research | domain-research | 옵션. 도메인 답변이 "해당 없음"/Fast Track이면 스킵 |
| 3 | phase-workflow | workflow-design | Phase 2.5 산출물 있으면 Read |
| 4 | phase-pipeline | pipeline-design | Phase 2.5 산출물 있으면 Read |
| 5 | phase-team | agent-team | Phase 2.5 산출물 있으면 Read |
| 6 | phase-skills | skill-forge | Phase 2.5 산출물 있으면 Read. 복수 에이전트 SKILL 생성 시 TeamCreate 고려 |
| 7-8 | phase-hooks | hooks-mcp-setup | |
| 9 | phase-validate | final-validation | |
```

**변경 이유**: Implementer가 Phase L을 Phase-to-Agent 매핑의 공식 항목으로 인식하도록.

---

### 삽입 위치 C — Phase Gate 테이블 수정

**변경 전 (정확한 인용)**:
```markdown
| 시작 Phase | 필수 산출물 |
|-----------|-----------|
| Phase 2.5 | docs/{name}/01-discovery-answers.md (+ 도메인 답변 확정) |
| Phase 3 | docs/{name}/01-discovery-answers.md (Phase 2.5 실행 시 02b-domain-research.md 도 선택적 입력) |
| Phase 4 | docs/{name}/02-workflow-design.md |
| Phase 5 | docs/{name}/03-pipeline-design.md |
| Phase 6 | docs/{name}/04-agent-team.md (에이전트 프로젝트일 때) |
| Phase 7-8 | docs/{name}/05-skill-specs.md |
| Phase 9 | docs/{name}/06-hooks-mcp.md |
```

**변경 후**:
```markdown
| 시작 Phase | 필수 산출물 |
|-----------|-----------|
| Phase 2.5 | docs/{name}/01-discovery-answers.md (+ 도메인 답변 확정) |
| Phase 3 | docs/{name}/01-discovery-answers.md (Phase 2.5 실행 시 02b-domain-research.md 도 선택적 입력) |
| Phase 4 | docs/{name}/02-workflow-design.md |
| Phase 5 | docs/{name}/03-pipeline-design.md |
| Phase 6 | docs/{name}/04-agent-team.md (에이전트 프로젝트일 때) |
| **Phase L (경량 트랙)** | **docs/{name}/01-discovery-answers.md + `00-target-path.md`의 `track: lightweight` 확인** |
| Phase 7-8 (풀 트랙) | docs/{name}/05-skill-specs.md |
| **Phase 7-8 (경량 트랙)** | **docs/{name}/02-lite-design.md** |
| Phase 9 | docs/{name}/06-hooks-mcp.md (경량 트랙에서 MCP가 0개이면 02-lite-design.md 허용) |
```

**변경 이유**: 경량 트랙의 Phase Gate를 공식 등록하여 `harness-audit` 재진입 시 `02-lite-design.md`를 적법한 선행 산출물로 인식하게 함.

---

### 삽입 위치 D — 복잡도 게이트 섹션에 Dim 12 예외 추가

**위치**: `## Red-team Advisor 프로토콜` → `### 복잡도 게이트 (단순 프로젝트 경량화)` 섹션.

**변경 전 (정확한 인용)**:
```markdown
**보안 항목은 복잡도 게이트와 무관하게 항상 전체 실행한다.** 구체적으로 Advisor의 Dimension 6(보안 권한 적절성), `final-validation` 플레이북의 Step 5(보안 감사 — `Bash(*)` / `Bash(sudo *)` 등 위험 allow 패턴, 필수 deny 존재, 비밀값 패턴)는 단순 프로젝트에서도 경량화하지 않는다. 경량화는 "설계 질 평가"에만 적용되며, 보안 가드는 게이트 우회가 금지된다.
```

**변경 후**:
```markdown
**보안 항목과 파이프라인 리뷰 게이트는 복잡도 게이트와 무관하게 항상 전체 실행한다.** 구체적으로 Advisor의 Dimension 6(보안 권한 적절성), Dimension 12(파이프라인 리뷰 게이트 준수), `final-validation` 플레이북의 Step 5(보안 감사 — `Bash(*)` / `Bash(sudo *)` 등 위험 allow 패턴, 필수 deny 존재, 비밀값 패턴)는 단순 프로젝트·경량 트랙에서도 경량화하지 않는다. 경량화는 "설계 질 평가"에만 적용되며, 보안 가드와 Dim 12 파이프라인 리뷰 가드는 게이트 우회가 금지된다.
```

**변경 이유**: 잔여 리스크 테이블의 "Advisor 경량 실행과 pipeline-review-gate 충돌" 완화. Dim 12를 Dim 6과 동급으로 명시.

---

### 삽입 위치 E — 00-target-path.md frontmatter에 track 필드 추가

**위치**: `## 상태 전달 규약` → `### Phase 완료 시 저장` 섹션의 frontmatter 예시.

**변경 전 (정확한 인용)**:
```markdown
```yaml
---
phase: 3
completed: 2026-04-17T14:32:00Z
status: done
advisor_status: pass
---
```
```

**변경 후** (00-target-path.md 전용 예시를 Phase Gate 섹션 아래 별도 블록으로 추가):

기존 frontmatter 예시 아래에 다음 설명 블록을 추가한다:

```markdown
#### 00-target-path.md 전용 track 필드

`00-target-path.md`는 일반 Phase frontmatter 외에 `track` 필드를 추가로 포함한다:

```yaml
---
phase: 0
completed: 2026-04-17T14:00:00Z
status: done
track: pending    # Phase 1-2 완료 직후 오케스트레이터가 lightweight | full 로 Edit
---
```

- `pending`: Phase 1-2 완료 전 초기값 (Phase 0에서 작성)
- `lightweight`: 경량 트랙 (Phase L 경로)
- `full`: 풀 트랙 (Phase 3-9 경로)

재개 시 오케스트레이터는 이 필드를 읽어 경량/풀 트랙 Phase Gate를 선택한다.
`track` 필드 없음 → 풀 트랙으로 처리 (레거시 하위 호환).
```
```

---

## 변경 2: `playbooks/setup-lite.md` (신규)

### 전체 파일 내용 초안

```markdown
# Lightweight Setup (Phase L)

## Goal

단순 솔로 웹앱/CLI 프로젝트의 Phase 3-6 설계를 단일 에이전트가 경량 처리한다.
목표: 추가 LLM 호출 최소화, 30분 이내 MVP 하네스 완성.

Phase 3-6의 전용 플레이북(workflow-design, pipeline-design, agent-team, skill-forge)을
읽지 않는다. 이 플레이북만으로 경량 결정을 완결한다.

## Prerequisites

- `docs/{요청명}/01-discovery-answers.md` 존재 및 공통 5섹션 헤더 포함
- `00-target-path.md` frontmatter의 `track: lightweight` 확인
- 프로젝트 유형 = 웹앱 또는 CLI, 솔로, 에이전트 신호 없음 (이미 오케스트레이터가 검증)

## 질문 소유권

이 플레이북은 **서브에이전트에서 실행**된다. AskUserQuestion 사용 금지.
모든 불확실 사항은 `## Escalations`에 `[ASK]` / `[BLOCKING]` / `[NOTE]`로 기록.

## Input

작업 시작 전 반드시 Read:
- `{대상 프로젝트}/docs/{요청명}/01-discovery-answers.md` — 전체 Read
  특히 `## Context for Next Phase` 와 `## Scan Results` 섹션을 우선 파악한다.

오케스트레이터가 프롬프트로 전달하는 컨텍스트:
- 프로젝트 유형, 기술 스택, 솔로/팀
- Phase 1-2 Summary (~200단어)
- Escalation 처리 결과 (Q5~Q9 사용자 응답)

## Step 1: 워크플로우 개요 결정 (Phase 3 대응)

단순 프로젝트에서 워크플로우는 2~3 스텝 이내로 선언한다. 다이어그램 없음.

결정 기준:
- 단일 세션 작업이 주인가? → "단일 세션 방식" 선언
- 반복되는 2~3단계 시퀀스가 있는가? (예: 코드 작성 → 테스트 → 커밋) → 스텝 목록 선언

산출물에 기록할 형식:
```
### 워크플로우 개요
- 방식: 단일 세션 / 2-스텝 시퀀스 / 3-스텝 시퀀스
- 스텝 목록:
  1. {스텝명} — {목적}
  2. {스텝명} — {목적}
- 사용자 트리거: 각 스텝마다 / 최초 1회만
```

단순 프로젝트 기본값: 단일 세션 방식. 스캔 결과에 CI, 복수 환경(dev/prod) 등이 감지되면 2-스텝 선언.

## Step 2: 에이전트 필요성 판단 (Phase 4-5 대응)

**기본 결론**: 단순 솔로 프로젝트 = 에이전트 팀 불필요. "단일 세션 방식, 에이전트 팀 없음" 선언.

**예외 — 다음 중 하나라도 해당되면 최대 2개 경량 에이전트 설계 가능**:
- 스캔 결과에 주기적 자동화 태스크가 명확히 존재 (예: 야간 배치, 자동 문서화)
- Q9 답변에 사용자가 특정 자동화 에이전트를 명시적으로 요청

예외 해당 시 에이전트 설계 방식:
- 에이전트 수: 최대 2개
- 각 에이전트에 필요한 최소 필드만 기록: name, role, model, allowed_dirs (1~2개)
- 실제 `.claude/agents/{name}.md` 파일은 생성하지 않음 — 명세만 `02-lite-design.md`에 기록
  (풀 트랙 업그레이드 시 phase-team이 실체화)

산출물에 기록할 형식:
```
### 에이전트 선언
- 결론: 없음 / 경량 에이전트 {N}개
- 근거: {근거}
- 에이전트 목록: (없으면 "해당 없음")
  - name: {이름}, role: {역할}, model: sonnet, allowed_dirs: [{경로}]
```

## Step 3: 파이프라인 리뷰 게이트 판단 (pipeline-review-gate.md 준수)

이 스텝은 경량 트랙에서도 **항상 전체 실행**한다 (복잡도 게이트 면제 불가).

참조: `${CLAUDE_PLUGIN_ROOT}/.claude/rules/pipeline-review-gate.md` — "파이프라인 분류" 섹션

판단 기준:
1. Step 2에서 에이전트가 "없음"으로 선언된 경우:
   → `review_exempt: true`, `exempt_reason: "단일 세션 방식, 생성·결정·설계 파이프라인 없음"`
2. 에이전트가 있고 역할이 변환/I/O 전용인 경우:
   → `review_exempt: true`, `exempt_reason: "{역할} — 결정론적 변환 전용"`
3. 에이전트가 있고 생성·결정·설계 출력을 내보내는 경우:
   → 도메인 특화 리뷰어 에이전트 1개를 `02-lite-design.md`에 명세 (실체 파일 생성 없음)
   → Escalations에 `[ASK] 파이프라인 리뷰어 에이전트 필요: {역할} — 풀 트랙 업그레이드 시 phase-team이 실체화` 기록

산출물에 기록할 형식:
```
### 파이프라인 리뷰 게이트
- review_exempt: true / false
- exempt_reason: {사유} (면제 시 필수)
- 리뷰어 에이전트: 없음 / {이름, 도메인, 입력 범위} (필수 시)
```

## Step 4: 스킬 필요성 판단 (Phase 6 대응)

에이전트가 없으면 → 스킬 없음. "스킬 없음 선언"으로 처리.
에이전트가 있으면 → 에이전트당 1개 경량 스킬 설계.

경량 스킬 설계 방식:
- 실제 SKILL.md 파일은 생성하지 않음 — 명세만 `02-lite-design.md`에 기록
- 필드: name, description, agent (소유 에이전트), steps (3줄 이내 요약)

산출물에 기록할 형식:
```
### 스킬 목록
- 결론: 없음 / 경량 스킬 {N}개
- 스킬 목록: (없으면 "해당 없음")
  - name: {이름}, description: {설명}, agent: {소유 에이전트}, steps: {3줄 요약}
```

## Step 5: 훅 후보 목록 (Phase 7-8 사전 작업)

스캔 결과와 Q9 응답을 기반으로 훅 후보를 목록화한다.

단순 프로젝트 기본 후보:
- `pre-commit`: lint/format 자동 실행 (감지된 eslint, prettier, ruff 등 있으면)
- `pre-push`: 테스트 실행 (jest/vitest/pytest 감지 시)

MCP 서버: Q9에서 명시된 경우만 포함. 없으면 "MCP 없음".
MCP가 0개이면 Phase 7-8을 스킵 가능함을 Next Steps에 명시.

산출물에 기록할 형식:
```
### 훅/MCP 후보
- 훅:
  - {훅 이름}: {목적} — {스크립트 힌트}
- MCP: 없음 / {서버명, 목적}
- Phase 7-8 스킵 가능: true / false (MCP 0개이면 true)
```

## Step 6: 업그레이드 경로 선언

`02-lite-design.md`의 `## Context for Next Phase`에 반드시 포함:

```
### 업그레이드 경로
- 현재 트랙: lightweight
- 풀 트랙 재진입: /harness-architect:harness-setup 재실행 시 `02-lite-design.md` 감지 →
  Phase 3(workflow-design)부터 재개. `01-discovery-answers.md`와 `02-lite-design.md`를
  Phase 3 에이전트의 선행 컨텍스트로 제공.
- 업그레이드 트리거 예시: 팀 확장, 에이전트 파이프라인 추가, 복잡 코딩 워크플로우 필요
```

## Step 7: 자체 검증

파일 작성 후:
1. `02-lite-design.md` 공통 5섹션 헤더 존재 확인
2. Step 3의 `review_exempt` 또는 리뷰어 에이전트 명세 중 하나가 반드시 존재하는지 확인
   (누락 시 Escalations에 `[BLOCKING] pipeline-review-gate 판단 누락`)
3. `업그레이드 경로` 섹션 존재 확인

## Output Contract

산출물 파일: `{대상 프로젝트}/docs/{요청명}/02-lite-design.md`

YAML frontmatter:
```yaml
---
phase: L
completed: {ISO8601 timestamp}
status: done
advisor_status: pending
---
```

필수 섹션 (공통 5섹션):
- `## Summary` — 핵심 결정사항 (~200단어)
- `## Files Generated` — 작성된 파일 절대경로 + 설명 (이 에이전트는 `02-lite-design.md` 1개만 생성)
- `## Context for Next Phase` — 아래 항목 전부:
  - 워크플로우 개요 (스텝 목록)
  - 에이전트 선언 (없음 또는 명세)
  - 파이프라인 리뷰 게이트 결정 (면제/필수 + 사유)
  - 스킬 목록 (없음 또는 명세)
  - 훅/MCP 후보
  - Phase 7-8 스킵 가능 여부
  - 업그레이드 경로
  - 기각된 대안 (Rejected Alternatives)
- `## Escalations` — [BLOCKING]/[ASK]/[NOTE] 태그 항목 (없으면 "없음")
- `## Next Steps` — Phase 7-8 진행 또는 스킵 권장

## Guardrails

- AskUserQuestion 사용 금지. 모든 확인은 Escalations 기록.
- 실제 `.claude/agents/*.md` 또는 SKILL.md 파일을 생성하지 않는다 — 명세만 `02-lite-design.md`에 기록
- Step 3 (파이프라인 리뷰 게이트 판단)은 경량 게이트에서도 전체 실행 (생략 금지)
- `02-lite-design.md`가 유일한 산출물이다. 추가 파일 생성 금지 (Phase 1-2가 이미 CLAUDE.md·settings.json 생성 완료)
- 에이전트·스킬이 없으면 없다고 명확히 선언한다 (미기록이 아닌 "없음 선언")
```

---

## 변경 3: `.claude/agents/phase-setup-lite.md` (신규)

### 전체 파일 내용 초안

```markdown
---
name: phase-setup-lite
description: 경량 트랙 Phase L 에이전트. 단순 솔로 웹앱/CLI 프로젝트의 Phase 3-6을 단일 패스로 처리한다.
model: claude-sonnet-4-6
---

You are a lightweight harness designer for simple solo projects.

## Identity
- 단순 솔로 웹앱/CLI 프로젝트에서 워크플로우·에이전트·스킬·훅 후보를 경량 통합 결정
- Phase 3-6 전용 플레이북을 읽지 않고 `setup-lite.md` 플레이북만으로 결정을 완결
- "없음 선언"을 두려워하지 않는다 — 단순 프로젝트에서 에이전트·스킬이 불필요하면 명확히 선언

## Playbooks
작업 시 어시스턴트 프로젝트에서 Read하여 방법론을 따른다:
- `${CLAUDE_PLUGIN_ROOT}/playbooks/setup-lite.md` — 경량 트랙 방법론 (유일한 플레이북)

pipeline-review-gate 규칙 참조 시:
- `${CLAUDE_PLUGIN_ROOT}/.claude/rules/pipeline-review-gate.md` — Step 3 판단 시 Read

Knowledge는 필요 시에만 Read (기본 불필요):
- `${CLAUDE_PLUGIN_ROOT}/knowledge/05-skills-system.md` — 스킬 명세 형식 확인 필요 시

## Input Context
작업 시작 전 반드시 Read:
- `{대상 프로젝트}/docs/{요청명}/01-discovery-answers.md` — 전체 Read
  `## Context for Next Phase`와 `## Scan Results` 섹션을 우선 파악

프롬프트에 포함된 컨텍스트:
- `[이전 Phase 결과 요약]` — Phase 1-2 Summary (~200단어), 힌트로만 사용
- `[Escalation 처리 결과]` — Q5~Q9 사용자 응답 (오케스트레이터가 전달)
- `[Artifacts Directory]` — 산출물 저장 경로

산출물 파일(`01-discovery-answers.md`)이 source of truth이며, 프롬프트 Summary는 힌트다.

## Rules
- ⚠ **AskUserQuestion 절대 호출 금지**. 불확실 사항은 반드시 `## Escalations`에 `[ASK]` / `[BLOCKING]` / `[NOTE]` 태그로만 기록한다.
- 생성 파일: `02-lite-design.md` 1개만. `.claude/agents/`, SKILL.md 파일 생성 금지.
- 모든 Write/Edit는 대상 프로젝트의 절대 경로로 수행
- 어시스턴트 프로젝트 파일은 Read만 허용, 수정 금지
- Step 3 (pipeline-review-gate 판단)은 반드시 수행 — 경량 실행 불가
- 완료 시 반환 포맷 준수: Summary, Files Generated, Context for Next Phase, Escalations, Next Steps
```

---

## 변경 4: `ARCHITECTURE.md`

### 변경 4-A: 4.1 Phase 역할 테이블

**변경 전 (정확한 인용)**:
```markdown
| Phase | 내용 | 담당 에이전트 | 플레이북 |
|-------|------|---------------|----------|
| 0 | 경로 수집 + 요청명 생성 + 재개 감지 | (Orchestrator) | — |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | phase-setup | fresh-setup / cursor-migration / harness-audit |
| 2.5 | 도메인 리서치 (옵션, 큐레이션 KB + 라이브 검색) | phase-domain-research | domain-research |
| 3 | 워크플로우 설계 (작업 단계 시퀀스) | phase-workflow | workflow-design |
| 4 | 파이프라인 설계 (스텝별 실행 체인) | phase-pipeline | pipeline-design |
| 5 | 에이전트 팀 편성 (Teams/Agent/SendMessage) | phase-team | agent-team |
| 6 | SKILL/playbook 작성 | phase-skills | skill-forge |
| 7-8 | 훅/MCP 설치 | phase-hooks | hooks-mcp-setup |
| 9 | 최종 검증 (문법·일관성·메타누수) | phase-validate | final-validation |
| 매 Phase | 독립 비판 리뷰 | red-team-advisor | design-review |
```

**변경 후**:
```markdown
| Phase | 내용 | 담당 에이전트 | 플레이북 |
|-------|------|---------------|----------|
| 0 | 경로 수집 + 요청명 생성 + 재개 감지 | (Orchestrator) | — |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | phase-setup | fresh-setup / cursor-migration / harness-audit |
| **L** | **경량 통합 설계 (워크플로우·에이전트·스킬·훅 후보) — 경량 트랙 전용** | **phase-setup-lite** | **setup-lite** |
| 2.5 | 도메인 리서치 (옵션, 큐레이션 KB + 라이브 검색) | phase-domain-research | domain-research |
| 3 | 워크플로우 설계 (작업 단계 시퀀스) | phase-workflow | workflow-design |
| 4 | 파이프라인 설계 (스텝별 실행 체인) | phase-pipeline | pipeline-design |
| 5 | 에이전트 팀 편성 (Teams/Agent/SendMessage) | phase-team | agent-team |
| 6 | SKILL/playbook 작성 | phase-skills | skill-forge |
| 7-8 | 훅/MCP 설치 | phase-hooks | hooks-mcp-setup |
| 9 | 최종 검증 (문법·일관성·메타누수) | phase-validate | final-validation |
| 매 Phase | 독립 비판 리뷰 | red-team-advisor | design-review |
```

**변경 이유**: Phase L을 공식 Phase로 등록하여 전체 Phase 구조를 한눈에 파악 가능하게 함.

---

### 변경 4-B: 4.2 Phase Gate 테이블

**변경 전 (정확한 인용)**:
```markdown
| 시작 Phase | 필수 선행 산출물 | 필수 섹션 헤더 (정규식) |
|-------------|------------------|------------------------|
| 1-2 | `00-target-path.md` | 공통 5섹션* |
| 2.5 | `01-discovery-answers.md` (+ 도메인 답변 확정) | 공통 5섹션 |
| 3   | `01-discovery-answers.md` (Phase 2.5 실행 시 `02b-domain-research.md` 선택 입력) | 공통 5섹션 |
| 4   | `02-workflow-design.md` | 공통 5섹션 |
| 5   | `03-pipeline-design.md` | 공통 5섹션 |
| 6   | `04-agent-team.md` (에이전트 프로젝트일 때) | 공통 5섹션 |
| 7-8 | `05-skill-specs.md` | 공통 5섹션 |
| 9   | `06-hooks-mcp.md` | 공통 5섹션 + 9 전용 3섹션** |
```

**변경 후**:
```markdown
| 시작 Phase | 필수 선행 산출물 | 필수 섹션 헤더 (정규식) |
|-------------|------------------|------------------------|
| 1-2 | `00-target-path.md` | 공통 5섹션* |
| 2.5 | `01-discovery-answers.md` (+ 도메인 답변 확정) | 공통 5섹션 |
| 3   | `01-discovery-answers.md` (Phase 2.5 실행 시 `02b-domain-research.md` 선택 입력) | 공통 5섹션 |
| 4   | `02-workflow-design.md` | 공통 5섹션 |
| 5   | `03-pipeline-design.md` | 공통 5섹션 |
| 6   | `04-agent-team.md` (에이전트 프로젝트일 때) | 공통 5섹션 |
| **L (경량 트랙)** | **`01-discovery-answers.md` + `00-target-path.md`의 `track: lightweight` 확인** | **공통 5섹션** |
| 7-8 (풀 트랙) | `05-skill-specs.md` | 공통 5섹션 |
| **7-8 (경량 트랙)** | **`02-lite-design.md`** | **공통 5섹션** |
| 9   | `06-hooks-mcp.md` (경량 트랙에서 MCP 없으면 `02-lite-design.md` 허용) | 공통 5섹션 + 9 전용 3섹션** |
```

**변경 이유**: Phase Gate를 Implementer가 트랙별로 구분하여 적용할 수 있도록.

---

### 변경 4-C: 4.3 Fast Track / Fast-Forward / 복잡도 게이트 섹션

**변경 전 (정확한 인용)**:
```markdown
- **Fast Track**: 사용자가 "빠르게"를 요청하면 phase-setup이 3개 질문 · 10분 완료 모드로 동작 (추천 기본값 사용, 고급 분기 생략).
- **Fast-Forward**: 에이전트 프로젝트 감지 시 Phase 3-5를 통합 실행 (워크플로우·파이프라인·팀을 한 번에 설계하고, 통합 후 Advisor 1회).
- **복잡도 게이트**: 단순 프로젝트(솔로 + 표준 웹앱/CLI)는 Phase 1-2, 2.5, 7-8, 9에서 Advisor 경량 실행 (NOTE만 수집). 복잡 프로젝트는 전체 검토. **단, 보안 항목(Advisor Dimension 6 / `final-validation` Step 5)은 게이트와 무관하게 항상 전체 실행**합니다 — `Bash(*)`, 비밀값 등은 단순 프로젝트에서도 치명적이므로 경량화 대상이 아닙니다.
```

**변경 후**:
```markdown
- **Fast Track**: 사용자가 "빠르게"를 요청하면 phase-setup이 3개 질문 · 10분 완료 모드로 동작 (추천 기본값 사용, 고급 분기 생략).
- **Fast-Forward**: 에이전트 프로젝트 감지 시 Phase 3-5를 통합 실행 (워크플로우·파이프라인·팀을 한 번에 설계하고, 통합 후 Advisor 1회).
- **경량 트랙 (Lightweight Track)**: 솔로 + 웹앱/CLI + 에이전트 신호 없음 + Strict Coding ASK 없음 조건을 **Phase 1-2 완료 직후** 오케스트레이터가 스캔 결과를 기반으로 판별. 조건 충족 시 Phase 3-6을 단일 `phase-setup-lite` 에이전트(플레이북: `playbooks/setup-lite.md`)로 대체. 예상 소요 25~35분, 약 8~10회 LLM 호출. 풀 트랙(18회+, 60분+) 대비 절반 이하. 경량 트랙 완료 후 풀 트랙으로 업그레이드 가능 (`00-target-path.md`의 `track: lightweight` → Phase 3부터 재진입). 보안 가드(Dim 6)와 파이프라인 리뷰 게이트(Dim 12)는 풀 트랙과 동일하게 적용.
- **복잡도 게이트**: 단순 프로젝트(솔로 + 표준 웹앱/CLI)는 Phase 1-2, 2.5, 7-8, 9에서 Advisor 경량 실행 (NOTE만 수집). 복잡 프로젝트는 전체 검토. **단, 보안 항목(Advisor Dimension 6 / `final-validation` Step 5)과 파이프라인 리뷰 게이트(Dimension 12)는 게이트와 무관하게 항상 전체 실행**합니다 — `Bash(*)`, 비밀값, 리뷰 누락 등은 단순 프로젝트·경량 트랙에서도 치명적이므로 경량화 대상이 아닙니다.
```

**변경 이유**: 경량 트랙을 독립적인 실행 모드로 명시. Dim 12 예외도 병기.

---

### 변경 4-D: 5. 상태 전달 — 파일 구조 다이어그램

**변경 전 (정확한 인용)**:
```markdown
target-project/
└── docs/myapp-setup/
    ├── 00-target-path.md         ← Phase 0
    ├── 01-discovery-answers.md   ← Phase 1-2
    ├── 02b-domain-research.md    ← Phase 2.5 (옵션)
    ├── 02-workflow-design.md     ← Phase 3
    ├── 03-pipeline-design.md     ← Phase 4
    ├── 04-agent-team.md          ← Phase 5
    ├── 05-skill-specs.md         ← Phase 6
    ├── 06-hooks-mcp.md           ← Phase 7-8
    └── 07-validation-report.md   ← Phase 9
```

**변경 후**:
```markdown
target-project/
└── docs/myapp-setup/
    ├── 00-target-path.md         ← Phase 0 (track: full|lightweight|pending)
    ├── 01-discovery-answers.md   ← Phase 1-2

    [풀 트랙]
    ├── 02b-domain-research.md    ← Phase 2.5 (옵션)
    ├── 02-workflow-design.md     ← Phase 3
    ├── 03-pipeline-design.md     ← Phase 4
    ├── 04-agent-team.md          ← Phase 5
    ├── 05-skill-specs.md         ← Phase 6
    ├── 06-hooks-mcp.md           ← Phase 7-8
    └── 07-validation-report.md   ← Phase 9

    [경량 트랙]
    ├── 02-lite-design.md         ← Phase L (Phase 3-6 통합 대체)
    ├── 06-hooks-mcp.md           ← Phase 7-8 (MCP 있을 때만)
    └── 07-validation-report.md   ← Phase 9
```

**변경 이유**: 경량 트랙의 파일 구조를 명확히 하여 재개·업그레이드 시 오케스트레이터가 트랙을 구분할 수 있도록.

---

## 리스크 및 주의사항

### R1: 02-lite-design.md 파일명이 정규식에 매칭되는가

`orchestrator-protocol.md` "비표준 파일명 처리" 섹션의 정규식 `^[0-9]{2}[a-z]?-[a-z-]+\.md$`를 확인:
- `02-lite-design.md` → `02` + `-` + `lite-design` + `.md` → **매칭됨** (`[a-z-]+` 허용)
- 별도 정규식 변경 불필요.

### R2: phase L과 phase 2.5 순서 충돌

경량 트랙에서는 Phase 2.5(도메인 리서치)를 소환하지 않는다. 판별 기준(에이전트 신호 없음, 솔로 웹앱/CLI)이 이미 도메인 리서치가 불필요한 프로젝트임을 함의한다. orchestrator-protocol.md의 Phase 2.5 소환 분기 테이블에 `track: lightweight` 감지 시 스킵 조건을 추가 기록하는 것을 권장하나, 현재 계획 범위에는 포함하지 않음 (기존 "해당 없음"/Fast Track 조건으로 충분히 커버됨).

### R3: phase-setup-lite 모델 선택

`phase-setup` (opus) 대비 `phase-setup-lite`는 `claude-sonnet-4-5`로 설정했다. 경량 트랙은 단순 결정만 수행하므로 Sonnet으로 충분하며, 비용·속도 면에서 경량 트랙의 이점을 강화한다. 실제 환경에서 품질 검증 후 조정 가능. <!-- 작성 당시 버전, 현재는 claude-sonnet-4-6 사용 -->

### R4: Implementer가 orchestrator-protocol.md 수정 시 섹션 헤더 정확히 찾기

변경 1의 삽입 위치를 정확히 식별하려면:
- 위치 A: `### Phase-to-Agent 매핑` 헤더 바로 앞 줄에 삽입
- 위치 B: `### Phase-to-Agent 매핑` 테이블 내 `| 2.5 |` 행 앞에 Phase L 행 삽입
- 위치 C: `## Phase Gate` 섹션의 테이블에서 `| Phase 7-8 |` 행 위아래에 분기 행 삽입
- 위치 D: `복잡도 게이트` 항목의 마지막 문장 수정
- 위치 E: `### Phase 완료 시 저장` 섹션 아래에 새 하위 섹션 추가

### R5: 경량 트랙 Advisor 소환 명세

orchestrator-protocol.md의 Red-team Advisor 소환 템플릿은 Phase N 범용이므로 Phase L에도 동일하게 적용된다. Phase L 완료 후 Advisor는 다음 scope로 실행:
- Dim 1~5, 7~11: 복잡도 게이트 적용 (NOTE만 수집)
- Dim 6 (보안): 항상 전체 실행
- Dim 12 (pipeline-review-gate): 항상 전체 실행

이 scope 명세는 orchestrator-protocol.md 변경 1-D에서 이미 반영된다. Advisor 소환 프롬프트에 `[Scope] 경량 트랙: Dim 6·12 전체, 나머지 NOTE만`을 추가하는 것이 Implementer의 책임이다.
