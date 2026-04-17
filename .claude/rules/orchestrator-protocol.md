# Orchestrator Protocol — Full Agent Team Model

## 원칙
메인 세션은 순수 오케스트레이터다. 직접 스킬/knowledge 파일을 로드하거나, 직접 대상 프로젝트를 분석하지 않는다.
모든 실질 작업은 Agent 도구로 소환한 서브에이전트에 위임한다.

## 메인 세션이 하는 일
1. Phase 0: 프로젝트 경로 수집 + 기존 작업 감지 + 요청명 생성 (AskUserQuestion 직접 사용)
2. 라우팅: 대상 프로젝트 상태에 따라 첫 스킬 결정 (.cursor/ → cursor-migration, .claude/ → harness-audit, 신규 → fresh-setup)
3. Phase 전환: 이전 에이전트 결과 수신 → 요약 추출 → 다음 에이전트 소환
4. Escalation 처리: 에이전트가 반환한 Escalations를 취합하여 AskUserQuestion으로 사용자에게 일괄 질문
5. 사용자 확인: Phase 간 계속 진행 여부 (AskUserQuestion)

### Phase 0 상세 프로토콜 (최대 1~2회 AskUserQuestion)

1. AskUserQuestion으로 대상 프로젝트 경로 수집
   - 사용자가 초기 요청에 경로를 포함했으면 이 질문 생략
2. 경로 존재 여부 검증 (Bash ls)
3. 기존 작업 감지: 대상 프로젝트의 docs/ 아래에 기존 작업 폴더가 있는지 확인
   - 있으면: AskUserQuestion "이전 작업 발견. 계속 진행 / 새로 시작?"
   - 없으면: 자동으로 새 작업 시작
4. 요청명 자동 생성: 프로젝트 폴더 이름 + 날짜 (별도 질문 없음)
5. 작업 폴더 생성: `docs/{요청명}/` + 쓰기 권한 테스트
6. 00-target-path.md 작성: 대상 경로, 요청명, 시작 시간 기록
7. $TARGET_PROJECT_ROOT 환경변수 설정 (ownership-guard 훅이 참조)

### Phase 0에서 인터뷰 사전 수행

서브에이전트는 AskUserQuestion을 사용할 수 없으므로, fresh-setup의 핵심 질문(Q1~Q4)은
오케스트레이터가 Phase 0에서 사전 수행하고, 답변을 서브에이전트 프롬프트에 전달한다.

**사전 인터뷰 질문** (Phase 0의 AskUserQuestion에 포함):
- 프로젝트 이름 + 한 줄 설명
- 프로젝트 유형 (웹 앱 / CLI / 에이전트 파이프라인 / 데이터 / 콘텐츠 자동화 / 기타)
- 솔로 / 팀 여부

나머지 질문(Q5~Q9 + 도메인 후보)은 서브에이전트가 스캔 결과를 기반으로 Escalations에 기록하고,
오케스트레이터가 Phase 1-2 완료 후 일괄 처리한다.

**도메인 식별은 Phase 0 질문에 포함하지 않는다.** Phase 1-2의 phase-setup 에이전트가
A1(설명) + 스캔 결과로 도메인 후보 1~3개를 추정해 Escalations에 `[ASK] 핵심 도메인 식별 — 후보 ... (자유 입력/"해당 없음" 가능)` 로 기록하면, 오케스트레이터가 Phase 1-2 Escalation 처리 시 AskUserQuestion으로 확인한다. 이 답변이 Phase 2.5 소환 여부와 `[Domain Hint]` 프롬프트 값이 된다.

### Fast-Forward 경로 처리 (에이전트 프로젝트)

fresh-setup이 Escalation에 "에이전트 프로젝트 감지: Fast-Forward 경로 권장"을 반환하면:
1. 오케스트레이터가 사용자에게 확인: "에이전트 프로젝트로 감지됨. Phase 3-5 통합 진행?"
2. 승인 시: (Phase 2.5가 실행되는 경우 먼저 완료한 뒤) Phase 3(workflow) → Phase 4(pipeline) → Phase 5(team)를 순차 실행하되,
   각 Phase 에이전트에 "에이전트 프로젝트" 맥락과 Phase 2.5 산출물(있으면) 경로를 전달하여 설계 방향을 사전 안내
3. Advisor는 Phase 3-5 통합 완료 후 1회만 실행 (매 Phase가 아닌 통합 리뷰)

### Phase 2.5 도메인 리서치 소환 분기

Phase 1-2 Escalation 처리 후 오케스트레이터는 도메인 답변을 검사하여 Phase 2.5 소환 여부를 결정한다:

| 도메인 답변 / 컨텍스트 | Phase 2.5 소환 | 비고 |
|-----------------------|----------------|------|
| 유효한 도메인명 (예: "딥 리서치", "webtoon") | 소환 | `[Domain Hint]` 프롬프트로 전달 |
| "해당 없음" / 공백 / 사용자가 스킵 선택 | 소환 안 함 | Phase 3로 직행 |
| Phase 0 초기 발화 또는 사전 답변에 "--fast" / "빠르게" | 소환 안 함 | Fast Track |
| 도메인명에 URL/비밀키/내부경로 포함 (sanitization 실패) | 소환 안 함 | Escalation으로 재확인 요청 |

Phase 2.5 소환 시 다음 프롬프트 템플릿을 사용:

```
Agent(
  subagent_type: "phase-domain-research",
  description: "Phase 2.5: 도메인 리서치",
  prompt: "[Two Project Paths]
    어시스턴트 프로젝트: {어시스턴트 경로}
    대상 프로젝트: {대상 경로}

    [Phase] 2.5 — 도메인 리서치
    [Domain Hint] {사용자가 확인한 도메인명}
    [이전 Phase 결과 요약] {Phase 1-2 Summary ~200단어}
    [Artifacts Directory] {대상 경로}/docs/{요청명}/02b-domain-research.md",
  mode: "auto"
)
```

## AskUserQuestion 소유권

**AskUserQuestion은 오케스트레이터만 사용한다.**

- 서브에이전트는 AskUserQuestion을 직접 호출하지 않는다
- 서브에이전트가 불확실한 사항을 만나면 반환 산출물의 **Escalations** 섹션에 기록한다
- 오케스트레이터는 에이전트 완료 후 Escalations를 취합하여 AskUserQuestion으로 사용자에게 일괄 질문한다
- 사용자 응답을 받은 후, 필요 시 동일 에이전트를 재소환하여 해결된 사항을 전달한다

## 메인 세션이 하지 않는 일
- 플레이북 파일(playbooks/*.md) 직접 로드 (→ 에이전트 prompt에 "해당 플레이북을 Read하여 따라라" 지시)
- knowledge/ 파일 직접 Read (→ 에이전트에 위임)
- 대상 프로젝트 파일 직접 Write/Edit (→ 에이전트에 위임)
- 파일 스캔, 인터뷰, 설계 등 실질 작업

## Phase 실행 프로토콜

### 에이전트 소환 템플릿 (Agent-Playbook 분리)

이 프로젝트는 Agent-Playbook 분리 패턴을 따른다:
- **WHO**: `.claude/agents/phase-*.md` — 에이전트 정체성, 규칙 (소환 시 자동 로딩)
- **HOW**: `playbooks/*.md` — 방법론 (에이전트가 Read하여 실행)

> **경로가 `.claude/skills/`가 아닌 이유**: `.claude/skills/` 아래 파일은 Claude Code가 자동 디스커버리하여 메인 세션에 "사용 가능한 스킬"로 노출시킨다. 메인 세션이 이를 Skill 도구로 직접 호출하면 서브에이전트 소환을 우회하게 되므로, 방법론 파일을 `playbooks/`에 둔다.

각 Phase 에이전트는 `subagent_type`으로 정의된 에이전트를 소환한다:

```
Agent(
  subagent_type: "phase-setup",
  description: "Phase 1-2: 스캔 + 인터뷰",
  prompt: 아래 프롬프트 템플릿,
  mode: "auto"
)
```

프롬프트 템플릿 (동적 컨텍스트만 전달 — 정체성/규칙은 에이전트 정의에 포함):
---
[Two Project Paths — 반드시 구분]
- 어시스턴트 프로젝트: {어시스턴트 절대 경로} (스킬/knowledge 읽기 전용)
- 대상 프로젝트: {대상 프로젝트 절대 경로} (산출물/하네스 파일 쓰기 대상)

[Phase] {N} — {phase 이름}

[이전 Phase 결과 요약]
{이전 에이전트가 반환한 핵심 결정사항, ~200단어 이내}

[Artifacts Directory]
Phase 산출물을 대상 프로젝트에 저장 (절대 경로 사용):
{대상 프로젝트 절대 경로}/docs/{요청명}/{NN}-{phase-name}.md
---

에이전트 정의(`.claude/agents/phase-*.md`)에 이미 포함된 내용은 프롬프트에서 생략:
- Playbook 참조 (에이전트 정의의 Playbooks 섹션)
- Knowledge 참조 (에이전트 정의의 Playbooks 섹션)
- 공통 Rules (AskUserQuestion 금지, 쓰기 범위, 반환 포맷)

### Phase-to-Agent 매핑

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

## Red-team Advisor 프로토콜

### 실행 시점
Phase 1-2 에이전트 완료 직후부터 Phase 9까지, 매 Phase 에이전트 완료 직후 실행한다.
Phase 2.5가 실행된 경우에도 산출물 직후 Advisor 리뷰를 수행 (단순 프로젝트는 경량 게이트).
Phase 0은 오케스트레이터 직접 처리이므로 Advisor 불필요.

### 복잡도 게이트 (단순 프로젝트 경량화)
프로젝트 유형이 단순(솔로 + 표준 웹앱/CLI)인 경우:
- Phase 1-2, 2.5, 7-8, 9: Advisor 경량 실행 (NOTE만 수집, BLOCK/ASK 없으면 자동 통과)
- Phase 3-6: Advisor 전체 실행 (설계 품질이 중요)
- Fast-Forward 통합 실행 시: 통합 완료 후 1회만 전체 실행

### 실행 흐름

```
[Phase N Agent]
      ↓ 산출물
[Red-team Advisor] ← 산출물 + 이전 Phase 맥락 + 원래 사용자 요구사항
      ↓ 리뷰 리포트
[Orchestrator]
      ↓
  BLOCK 항목 있으면 → AskUserQuestion → Phase N 재실행 가능
  ASK 항목만 있으면 → AskUserQuestion → 답변 기록 → 다음 Phase
  NOTE만 있으면 → 텍스트 보고 → 다음 Phase
```

### 소환 템플릿

```
Agent(
  subagent_type: "red-team-advisor",
  description: "Red-team Review: Phase {N}",
  prompt: "[Review Target]
    Phase {N} 산출물: docs/{요청명}/{NN}-{phase-name}.md

    [Paths]
    어시스턴트 프로젝트: {어시스턴트 절대 경로}
    대상 프로젝트: {대상 프로젝트 절대 경로}

    [User's Original Request]
    {Phase 0에서 수집한 사용자 요구사항 원문}

    [Previous Phases Summary]
    {이전 Phase들의 핵심 결정사항}

    [Output]
    Red-team review report (BLOCK/ASK/NOTE 구분)"
)
```

### Advisor 결과 처리

1. BLOCK 항목이 1건 이상:
   a. 오케스트레이터가 사용자에게 BLOCK + ASK 항목을 AskUserQuestion으로 일괄 제시
   b. 사용자 응답에 따라:
      - "반영해" → Phase N 에이전트를 피드백과 함께 재소환
      - "괜찮아, 넘어가" → 다음 Phase 진행
   c. 재소환 후 Advisor도 다시 실행 (최대 2회 루프)

2. ASK 항목만 존재:
   a. AskUserQuestion으로 확인
   b. 사용자 답변을 다음 Phase 에이전트 프롬프트에 포함

3. NOTE만 존재:
   a. 텍스트로 간략 보고 후 다음 Phase 진행

## Phase Gate

다음 Phase 시작 전 이전 Phase 산출물 존재를 확인한다:

| 시작 Phase | 필수 산출물 |
|-----------|-----------|
| Phase 2.5 | docs/{name}/01-discovery-answers.md (+ 도메인 답변 확정) |
| Phase 3 | docs/{name}/01-discovery-answers.md (Phase 2.5 실행 시 02b-domain-research.md 도 선택적 입력) |
| Phase 4 | docs/{name}/02-workflow-design.md |
| Phase 5 | docs/{name}/03-pipeline-design.md |
| Phase 6 | docs/{name}/04-agent-team.md (에이전트 프로젝트일 때) |
| Phase 7-8 | docs/{name}/05-skill-specs.md |
| Phase 9 | docs/{name}/06-hooks-mcp.md |

산출물 미존재 시: 이전 Phase 에이전트를 재소환한다.
사용자가 "Phase N으로 바로 가자" 요청 시 → 누락된 Phase를 안내하고 순서대로 진행.

## 에이전트 반환 포맷

각 에이전트는 완료 시 반드시 다음 5개 섹션으로 구조화하여 반환한다:

```
## Summary
핵심 결정사항 (~200단어)

## Files Generated
- path/to/file1.md — 설명
- path/to/file2.json — 설명

## Context for Next Phase
다음 Phase가 작업을 시작하기 위해 반드시 알아야 하는 정보를 구조화하여 기록.
이 섹션은 산출물 파일(docs/{요청명}/NN-*.md)에도 동일하게 포함된다.

## Escalations
- [확인 필요] {불확실 사항 설명} — 선택지 A vs B
- (없으면 "없음")

## Next Steps
다음 Phase에 대한 제안
```

- **Summary**: 이 Phase에서 내린 핵심 결정사항. 오케스트레이터가 다음 에이전트 프롬프트에 포함
- **Files Generated**: 생성 또는 수정된 모든 파일의 절대 경로와 한 줄 설명
- **Context for Next Phase**: 다음 Phase가 필요로 하는 구조화된 컨텍스트 (아래 Phase별 명세 참조)
- **Escalations**: 에이전트가 자체 판단하지 못한 불확실 사항. 오케스트레이터가 AskUserQuestion으로 사용자에게 확인
- **Next Steps**: 다음 Phase에서 수행할 작업 제안

### Phase별 Context for Next Phase 필수 항목

각 Phase는 산출물 파일과 반환의 Context for Next Phase에 다음 정보를 **반드시** 포함한다:

| Phase | Context for Next Phase 필수 항목 |
|-------|-------------------------------|
| 1-2 | 프로젝트 유형, 기술 스택, 솔로/팀, 에이전트 프로젝트 여부, 디렉터리 구조 요약, 기존 설정 존재 여부, **도메인 후보 추정 (Escalation에 포함)** |
| 2.5 | 도메인 ID(slug), 신뢰도(high/medium/low), 표준 워크플로우 스텝 목록, 표준 역할 분업, 표준 도구 스택, 안티패턴, 프로젝트 정합성 갭, KB 사용 여부(full/stub/none) |
| 3 | 워크플로우 스텝 목록 (이름, 목적, 사용자 트리거 여부), 스텝 간 의존성, 완료 조건 |
| 4 | 에이전트 목록 (이름, 역할, 모델, 쓰기 범위), 에이전트별 스킬 매핑, 실행 순서/패턴, 소통 포인트, **메인 세션 역할 (라우터 only / 직접 실행 가능)** |
| 5 | 에이전트-스킬 소유권 테이블 (각 스킬의 예상 저장 위치 포함), 각 에이전트의 Identity/원칙 요약, 팀 구조, 소유권 가드 범위, **Orchestrator Pattern Decision (D-1/D-2/D-3)** |
| 6 | 스킬별 allowed_dirs 종합 목록, **저장 위치 결정 (케이스 A `.claude/skills/` / 케이스 B `playbooks/`)**, 에이전트-스킬 최종 매핑 (경로 포함) |
| 7-8 | 설치된 훅 목록, MCP 서버 목록, 검증 대상 파일 목록 |

이 명세를 통해 다음 Phase 에이전트가 이전 Phase 산출물을 Read하면 필요한 모든 컨텍스트를 확보할 수 있다.

## 상태 전달 규약

### 작업 폴더 관례

Phase 간 산출물은 `docs/{요청명}/` 디렉터리에 번호 순서로 저장한다:

```
docs/myapp-setup/
  00-target-path.md          ← Phase 0: 오케스트레이터가 작성
  01-discovery-answers.md    ← Phase 1-2: 스캔/인터뷰 결과
  02b-domain-research.md     ← Phase 2.5 (선택): 도메인 레퍼런스 패턴
  02-workflow-design.md      ← Phase 3: 워크플로우 설계
  03-pipeline-design.md      ← Phase 4: 파이프라인 설계
  04-agent-team.md           ← Phase 5: 팀 편성
  05-skill-specs.md          ← Phase 6: 스킬 명세
  06-hooks-mcp.md            ← Phase 7-8: 훅/MCP 설계
  07-validation-report.md    ← Phase 9: 최종 검증
```

### 전달 흐름

1. 각 에이전트는 완료 시 산출물을 `docs/{요청명}/` 에 파일로 저장하고, **반환 포맷**에 맞춰 결과를 반환한다
2. 산출물 파일에는 **Context for Next Phase** 섹션이 포함되어, 다음 Phase가 필요한 모든 구조화된 컨텍스트를 담는다
3. 오케스트레이터는 반환의 Summary (~200단어)를 다음 에이전트의 `[이전 Phase 결과 요약]`에 포함
4. 다음 에이전트는 `docs/{요청명}/` 의 이전 파일을 Read하여 **Context for Next Phase** 섹션에서 상세 컨텍스트를 확보한다
5. 이렇게 하면 프롬프트에는 요약만, 상세는 산출물 파일의 구조화된 섹션에서 온디맨드 로딩 — 컨텍스트 효율 극대화 + 누락 방지

## TeamCreate 사용 기준

- 기본: 각 Phase는 단일 Agent로 실행 (오버헤드 최소화)
- TeamCreate 사용 시점:
  - Phase 6에서 다수 에이전트의 SKILL.md를 병렬 생성할 때
  - Phase 내에서 독립적인 하위 작업이 3개 이상일 때
  - 에이전트 간 실시간 소통이 필요할 때

## Escalations 병합 프로토콜

에이전트 반환의 Escalations를 처리하는 절차:

### 1. 분류
각 Escalation을 카테고리별로 분류:
- **blocking**: 다음 Phase 진행 불가, 즉시 사용자 확인 필요
- **non-blocking**: 기본값으로 진행했으나, 사용자 검토 권장
- **informational**: 참고 사항 (질문 불필요, 텍스트로 보고)

### 2. 중복 제거
동일 주제의 Escalation이 여러 Phase에서 반복되면 병합:
- 최신 Phase의 내용을 우선
- 이전 Phase에서 이미 해결된 항목은 제거

### 3. 일괄 질문 (AskUserQuestion)
- blocking 항목: 즉시 AskUserQuestion (최대 4개씩)
- non-blocking 항목: Phase 전환 시점에 묶어서 AskUserQuestion
- informational: 텍스트로 보고만

### 4. 검증
Escalations와 생성된 파일의 일관성 확인:
- Escalation에서 "미결정"이라고 했는데 파일에 이미 값이 있으면 → 재확인
- Escalation 수가 0이면 → 에이전트가 모든 결정을 자체 처리한 것 → 핵심 결정 목록 확인

## 에이전트 실패 처리

- 불완전 결과: 피드백과 함께 동일 Phase 에이전트 재소환
- 사용자 중단: 현재까지 생성된 파일 목록 정리, 재개 가능 상태 안내
- 충돌: 이전 Phase 결정과 모순 발견 시 → AskUserQuestion으로 사용자에게 해결 요청

## 진행 상황 피드백

각 Phase 전환 시 오케스트레이터가 표시:

Phase 시작:
"📍 Phase {N}/9: {phase 이름}"

Phase 완료:
"✅ Phase {N} 완료. Advisor 리뷰 중..."

Advisor 완료:
- BLOCK 있으면: "⚠️ Advisor가 {건수}건 BLOCK 발견. 확인이 필요합니다."
- ASK 있으면:  "💬 Advisor가 {건수}건 추가 확인을 제안합니다."
- NOTE만:      "✅ Advisor 리뷰 통과. 다음 Phase로 진행합니다."

## 컨텍스트 예산 관리

오케스트레이터의 컨텍스트에 누적되는 것은:
- Phase별 결과 요약 (~200단어 × 최대 9 = ~1,800단어)
- 사용자 응답 (Phase 전환 확인)
- 에이전트 소환 기록

이렇게 하면 메인 세션의 컨텍스트는 항상 경량 상태를 유지한다.

## 중단/재개 프로토콜

### 세션 시작 시 감지
오케스트레이터가 대상 프로젝트 경로를 받으면:
1. `docs/` 디렉터리에 기존 작업 폴더가 있는지 확인
2. 있으면 최신 산출물 파일의 번호로 마지막 완료 Phase 판별
3. AskUserQuestion: "이전 작업 발견 (Phase {N}까지 완료). 계속 / 새로 시작?"
4. 계속 선택 시: 마지막 완료 Phase 다음부터 재개

### Phase 완료 시 저장
각 Phase 완료 시 산출물 파일에 메타데이터 포함:
```
<!-- phase: {N}, completed: {timestamp}, status: done -->
```
