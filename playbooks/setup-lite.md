# Lightweight Setup (Phase L)

## Goal

경량 트랙 판별(9개 AND 조건 충족)을 통과한 프로젝트의 Phase 3-6 설계를 단일 에이전트가 경량 처리한다.
목표: 추가 LLM 호출 최소화, 30분 이내 MVP 하네스 완성.

**이 플레이북은 오케스트레이터가 9개 조건 전체를 검증한 후에만 진입한다.**
솔로·웹앱 여부만으로 경량 트랙을 가정하지 않는다 — 코드베이스 규모·배포·서비스 복잡도·사용자 발화 의도까지 모두 통과해야 한다.

Phase 3-6의 전용 플레이북(workflow-design, pipeline-design, agent-team, skill-forge)을
읽지 않는다. 이 플레이북만으로 경량 결정을 완결한다.

## Prerequisites

- `docs/{요청명}/01-discovery-answers.md` 존재 및 공통 5섹션 헤더 포함
- `00-target-path.md` frontmatter의 `track: lightweight` 확인 (오케스트레이터가 9개 조건 검증 후 기록)
- 조건 목록: 솔로, 웹앱/CLI, 비에이전트, 에이전트 신호 없음, Strict Coding 신호 없음, 소스 파일 ≤100개·깊이 ≤5, 배포 단순, 단일 서비스, 사용자 발화 의도에 대규모 마이그레이션/리라이트/멀티 서비스/에이전트 체인 신호 없음
- **프리셋 주입 파일 소유권 보호**: `01-discovery-answers.md` 의 `## Context for Next Phase` 에 `프론트엔드 프리셋 주입 여부: yes` 가 있으면, 경량 트랙도 다음 파일 집합을 **주입 완료 상태** 로 보존한다 — `.claude/agents/frontend-designer.md`, `.claude/agents/frontend-ux-reviewer.md`, `.claude/skills/frontend-design/*`. 경량 트랙의 단일 설계 패스에서 해당 파일을 재작성·덮어쓰기 금지. 필요 시 보완 에이전트·스킬을 **별도 이름** 으로 추가한다. 이 규약은 풀 트랙 Phase 5·6 의 소유권 보호 규약과 동일한 취지.

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

## Step 1-bis: code-researcher 베이스라인 + 라우팅 프로토콜 확인 (코드 프로젝트만)

이 스텝은 **Phase 1-2(fresh-setup)의 산출물을 검증**한다. setup-lite 는 파일을 직접 설치하지 않고(단일 산출물 원칙), 누락되었을 때만 Escalation 으로 보고한다.

**적용 조건**: `01-discovery-answers.md` 의 `## Context for Next Phase` 에 `코드 프로젝트 여부: yes` 가 기록된 경우만 수행. `no` 면 이 스텝 전체 스킵.

### 1-bis-A. code-researcher 에이전트 파일 존재 확인
- 경로: `{대상 프로젝트}/.claude/agents/code-researcher.md`
- 존재 시: 다음 스텝 진행
- 부재 시: Escalations 에 `[BLOCKING] code-researcher 에이전트 누락 — Phase 1-2(fresh-setup)에서 코드 프로젝트임에도 미설치. fresh-setup 재소환 또는 \`${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/agents/code-researcher.md\` → \`{대상}/.claude/agents/code-researcher.md\` 수동 복사 필요` 기록

### 1-bis-B. CLAUDE.md 라우팅 프로토콜 섹션 확인
- `{대상 프로젝트}/CLAUDE.md` 에 `## 오케스트레이터 라우팅 프로토콜` ATX 헤더 존재 확인
- 섹션 본문에 `code-researcher` 문자열 포함 여부 확인
- 미존재 시: Escalations 에 `[BLOCKING] CLAUDE.md 라우팅 프로토콜 섹션 누락 — fresh-setup 이 코드 프로젝트임에도 섹션을 삽입하지 않음. fresh-setup 재소환 필요` 기록

### 1-bis-C. 기록
- 확인 결과를 `02-lite-design.md` 의 `## Context for Next Phase` 에 `code-researcher 베이스라인: 확인됨 / 누락 (BLOCKING)` 으로 명시

## Step 1-ter: Intent Gate 베이스라인 확인 (무조건 — 코드/비코드 공통)

경량 트랙에서도 **Intent Gate 는 무조건 설치되어 있어야 한다.** fresh-setup 이 Step 3-F 에서 판별 없이 설치하므로 여기서는 그 결과만 검증한다. 이 스텝은 코드 프로젝트 여부와 무관하게 항상 수행한다.

### 1-ter-A. intent-gate 규칙 파일 존재 확인
- 경로: `{대상 프로젝트}/.claude/rules/intent-gate.md`
- 존재 + 본문에 `alwaysApply: true` 프론트매터 포함 시: 다음 스텝 진행
- 부재 시: Escalations 에 `[BLOCKING] intent-gate.md 규칙 누락 — Phase 1-2(fresh-setup)의 Step 3-F 베이스라인 설치 미실행. fresh-setup 재소환 또는 ${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/rules/intent-gate.md → {대상}/.claude/rules/intent-gate.md 수동 복사 필요` 기록

### 1-ter-B. intent-clarifier 스킬 디렉터리 존재 확인
- 경로: `{대상 프로젝트}/.claude/skills/intent-clarifier/SKILL.md`
- 존재 + `name: intent-clarifier` 프론트매터 포함 시: 다음 스텝 진행
- 부재 시: Escalations 에 `[BLOCKING] intent-clarifier 스킬 누락 — ${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/skills/intent-clarifier/ 디렉터리 전체를 {대상}/.claude/skills/intent-clarifier/ 로 수동 복사 필요` 기록

### 1-ter-C. CLAUDE.md "작업 시작 전" 섹션 확인
- `{대상 프로젝트}/CLAUDE.md` 에 `## 작업 시작 전` ATX 헤더 존재 + 본문에 `intent-gate.md` 와 `intent-clarifier` 문자열 모두 포함 확인
- 미존재 시: Escalations 에 `[BLOCKING] CLAUDE.md "작업 시작 전" 섹션 누락 — fresh-setup Step 6 이 삽입하지 않았거나 이후 제거됨. 수동 prepend 필요` 기록

### 1-ter-D. 기록
- 확인 결과를 `02-lite-design.md` 의 `## Context for Next Phase` 에 `Intent Gate 베이스라인: 확인됨 / 누락 (BLOCKING)` 으로 명시

## Step 2: 에이전트 필요성 판단 (Phase 4-5 대응)

**적용 범위**: 이 스텝은 **워크플로우 스텝을 실행하는 팀 에이전트** 판단이다. Step 1-bis 의 `code-researcher` 는 오케스트레이터 도구 에이전트로 별개 레이어이며 여기서 집계하지 않는다.

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
4. **code-researcher 베이스라인 확인** (코드 프로젝트일 때만): Step 1-bis 결과가 `확인됨` 이거나, 누락이면 `[BLOCKING]` 으로 Escalations에 기록되어 있는지 재확인. 비코드 프로젝트는 스킵.

## Output Contract

산출물 파일: `{대상 프로젝트}/docs/{요청명}/02-lite-design.md`

YAML frontmatter (경량 트랙 전용 확장 필드 포함):
```yaml
---
phase: L
completed: {ISO8601 timestamp}
status: done
advisor_status: pending
session_recovery: not_applicable    # 경량 트랙 고정값 — 단일 에이전트 단일 패스 설계
artifact_versioning: idempotent     # 경량 트랙 고정값 — docs/{요청명}/ 번호 기반 고정 경로, 재실행 시 덮어쓰기 OK
---
```

> `session_recovery: not_applicable` 과 `artifact_versioning: idempotent` 는 **경량 트랙 고정 선언**이다. 사후 `/harness-architect:ops-audit` 실행 시 Dim A(세션 연속성)와 Dim D(산출물 덮어쓰기)가 이 필드를 감지하여 RISK-LOW로 자동 분류한다. 풀 트랙과 구별되는 **공식 경량화 근거**이므로 임의 삭제 금지.

필수 섹션 (공통 5섹션):
- `## Summary` — 핵심 결정사항 (~200단어). 서두에 "**경량 트랙 — 단일 에이전트 단일 패스 설계. 세션 중단 시 처음부터 재실행 필요 (소요 25~35분).**" 한 문장 명시 필수.
- `## Files Generated` — 작성된 파일 절대경로 + 설명 (이 에이전트는 `02-lite-design.md` 1개만 생성)
- `## Context for Next Phase` — 아래 항목 전부:
  - 워크플로우 개요 (스텝 목록)
  - 에이전트 선언 (없음 또는 명세)
  - 파이프라인 리뷰 게이트 결정 (면제/필수 + 사유)
  - 스킬 목록 (없음 또는 명세)
  - 훅/MCP 후보
  - Phase 7-8 스킵 가능 여부
  - 업그레이드 경로
  - **code-researcher 베이스라인**: `확인됨` / `누락 (BLOCKING)` / `해당 없음 (비코드 프로젝트)` (Step 1-bis 결과)
  - **라우팅 프로토콜 섹션**: `확인됨` / `누락 (BLOCKING)` / `해당 없음 (비코드 프로젝트)` (Step 1-bis 결과)
  - **Intent Gate 베이스라인**: `확인됨` / `누락 (BLOCKING)` — intent-gate.md + intent-clarifier + CLAUDE.md "작업 시작 전" 섹션 3종 세트 (Step 1-ter 결과, 코드/비코드 공통)
  - **운영 가드 선언 (경량 트랙 고정)** — 아래 2줄 고정 문구 복사하여 기록:
    - `Session Recovery: not applicable — single-pass lightweight track. 세션 중단 시 처음부터 재실행.`
    - `Artifact Versioning: idempotent — docs/{요청명}/ 번호 기반 고정 경로. 재실행 시 덮어쓰기 안전.`
  - 기각된 대안 (Rejected Alternatives)
- `## Escalations` — [BLOCKING]/[ASK]/[NOTE] 태그 항목 (없으면 "없음")
- `## Next Steps` — Phase 7-8 진행 또는 스킵 권장

## Guardrails

- AskUserQuestion 사용 금지. 모든 확인은 Escalations 기록.
- 실제 `.claude/agents/*.md` 또는 SKILL.md 파일을 생성하지 않는다 — 명세만 `02-lite-design.md`에 기록
- Step 3 (파이프라인 리뷰 게이트 판단)은 경량 게이트에서도 전체 실행 (생략 금지)
- `02-lite-design.md`가 유일한 산출물이다. 추가 파일 생성 금지 (Phase 1-2가 이미 CLAUDE.md·settings.json 생성 완료)
- 에이전트·스킬이 없으면 없다고 명확히 선언한다 (미기록이 아닌 "없음 선언")
- **운영 가드 필드 고정**: YAML frontmatter의 `session_recovery: not_applicable` / `artifact_versioning: idempotent` 는 경량 트랙 공식 선언으로 수정 금지. 풀 트랙 업그레이드 시 `phase-workflow` 에이전트가 재판정하여 본격 `## Session Recovery Protocol` 섹션을 신설한다.
- **Advisor 루프 상한**: 경량 트랙에서도 Advisor 재검토 상한은 orchestrator-protocol의 2회 규약을 따른다 (풀 트랙과 동일). 경량 게이트는 BLOCK 범위만 축소될 뿐 루프 제한은 유효.
