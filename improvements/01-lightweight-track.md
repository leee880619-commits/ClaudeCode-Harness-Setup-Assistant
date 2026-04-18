# 개선 사항 1: 경량 트랙 분기 도입

## 문제 정의

단순 프로젝트(솔로 개발자 + 표준 웹앱/CLI)에서 현재 9-Phase × (에이전트 + Advisor) 구조는 최소 18회 LLM 호출이 발생한다. 예상 소요 시간 60분 이상. 실제로 필요한 산출물은 `CLAUDE.md`, `.claude/settings.json`, `.claude/rules/` 수준인데, 이를 위해 파이프라인 설계(Phase 4), 에이전트 팀 편성(Phase 5), 스킬 명세(Phase 6)까지 강제 통과해야 한다. 결과적으로 단순 프로젝트 사용자 이탈률이 높다.

현행 복잡도 게이트(`orchestrator-protocol.md` "복잡도 게이트" 섹션, `ARCHITECTURE.md` 4.3)는 Advisor 실행을 경량화할 뿐, Phase 수 자체를 줄이지는 않는다.

---

## 도메인 전문가 제안 (Product Architect 김민준)

### 핵심 주장: "Phase를 줄이는 것이 아니라 트랙을 분기한다"

단순히 Phase를 건너뛰는 것은 기존 Phase Gate(`ARCHITECTURE.md` 4.2)를 우회하게 되어 의도치 않은 부작용이 발생한다. 대신 처음부터 **두 개의 독립된 실행 트랙**으로 분기한다.

### 트랙 판별 기준

Phase 0에서 오케스트레이터가 다음 신호를 종합하여 판별한다:

| 신호 | 경량 트랙 | 풀 트랙 |
|------|-----------|---------|
| A2 프로젝트 유형 | 웹 앱 / CLI | 에이전트 파이프라인 / 데이터 / 콘텐츠 자동화 |
| A3 솔로/팀 | 솔로 | 팀 (2인 이상) |
| fresh-setup Step 3-A 에이전트 신호 | 감지 없음 | 감지됨 |
| fresh-setup Step 3-B Strict Coding 신호 | 0~1개 | 2개 이상 |
| fast-forward 사용자 발화 | "--fast" / "빠르게" | (해당 없음) |

**경량 트랙 조건**: A2 = 웹앱/CLI **AND** A3 = 솔로 **AND** 에이전트 신호 없음 **AND** Strict Coding 신호 1개 이하.
모든 조건이 AND로 충족되어야 한다. 하나라도 불충족이면 풀 트랙.

### 경량 트랙에서 Phase 병합/스킵

```
경량 트랙:
Phase 0 (경로 수집)
  ↓
Phase 1-2 (스캔 + 인터뷰 + 기본 하네스) — 그대로
  ↓ [Advisor 경량 실행 — NOTE만]
Phase L (경량 통합 설계) — Phase 3+4+5+6을 단일 에이전트로 통합
  ↓ [Advisor 전체 실행]
Phase 7-8 (훅/MCP) — 그대로, 단 MCP 0개이면 스킵 가능
  ↓ [Advisor 경량 실행 — NOTE만, 보안은 항상 전체]
Phase 9 (최종 검증) — 그대로
```

풀 트랙 대비 LLM 호출 수:
- 풀 트랙: 18회 이상 (Phase × 에이전트 + Advisor)
- 경량 트랙: 8~10회 (Phase 0, 1-2+Advisor, L+Advisor, 7-8+Advisor, 9+Advisor)

### Phase L (경량 통합 설계)의 산출물

Phase L은 단일 `phase-setup-lite` 에이전트가 실행하며 `playbooks/setup-lite.md`를 Read한다.
산출물은 `docs/{요청명}/02-lite-design.md` 단일 파일에 통합한다.

포함 내용:
- 워크플로우 개요 (Phase 3 대응) — 2~3 스텝 수준, 다이어그램 없음
- 에이전트 없음 선언 (Phase 4-5 대응) — "단일 세션 방식, 에이전트 팀 불필요"
- 스킬 목록 (Phase 6 대응) — 1~3개 경량 스킬 또는 없음 선언
- 훅 후보 (Phase 7-8 사전 작업)

### 경량 트랙 MVP 하네스 (최소 유효 하네스)

```
대상 프로젝트/
├── CLAUDE.md                      ← Phase 1-2가 작성 (기존과 동일)
├── .claude/
│   ├── settings.json              ← Phase 1-2가 작성 (기존과 동일)
│   ├── rules/                     ← Phase 1-2가 작성 (기존과 동일)
│   └── hooks/ (있으면)            ← Phase 7-8이 작성
├── CLAUDE.local.md (템플릿)
└── docs/{요청명}/
    ├── 00-target-path.md
    ├── 01-discovery-answers.md
    ├── 02-lite-design.md          ← Phase L 통합 산출물 (신규)
    └── 07-validation-report.md
```

Phase 4-5-6 산출물(`03-pipeline-design.md`, `04-agent-team.md`, `05-skill-specs.md`)은 생성되지 않는다. Phase Gate는 경량 트랙에서 `02-lite-design.md`의 존재와 공통 5섹션 헤더를 검증하는 것으로 대체한다.

### 생략된 산출물 보완 방안

Phase 3-6 산출물이 없더라도 사용자가 나중에 풀 트랙으로 업그레이드할 수 있어야 한다.

- `02-lite-design.md`의 `## Context for Next Phase`에 "업그레이드 경로" 항목을 포함한다.
- 오케스트레이터는 Phase 9 직후 "나중에 에이전트 파이프라인이 필요하게 되면 `/harness-architect:harness-setup`을 재실행하세요. `02-lite-design.md`가 존재하므로 Phase 3부터 재개됩니다."를 텍스트로 안내한다.
- `00-target-path.md`에 `track: lightweight`를 YAML frontmatter로 기록하여, 재개 시 오케스트레이터가 어느 트랙이었는지 감지한다.

---

## 레드팀 비판 (Systems Critic 이서연)

### 비판 1: 판별 기준 신뢰성 — AND 조건이 너무 좁거나 너무 넓다

AND 조건은 모든 조건이 충족되어야 경량 트랙인데, 현실에서는 애매한 케이스가 많다.

- **너무 좁은 경우**: 솔로 개발자가 FastAPI 백엔드를 짜는데 `--fast`를 붙이지 않았다면 Strict Coding 신호가 0개여도 풀 트랙으로 가야 하나? 단순한 REST API인데 과잉이다.
- **너무 넓은 경우**: 솔로 개발자가 "간단한 에이전트 챗봇"을 만들 때 에이전트 신호가 감지되면 풀 트랙으로 가는데, 이 경우 Phase 5-6의 복잡한 팀 편성은 오히려 오버킬이다.
- **판별 시점 문제**: 판별은 Phase 0에서 이루어지는데, Phase 1-2의 fresh-setup Step 3-A/3-B 신호는 스캔 후에야 확정된다. Phase 0에서 스캔이 아직 실행되지 않았으므로, 판별을 Phase 0에서 확정하는 것은 정보 부족 상태의 결정이다.

현재 `orchestrator-protocol.md` "Phase 0 상세 프로토콜"에는 트랙 판별 로직이 없다. 이를 Phase 0에 욱여넣으면 Phase 0이 지금보다 훨씬 복잡해진다.

### 비판 2: Phase L 통합 에이전트의 품질 저하 위험

Phase 3, 4, 5, 6은 각각 독립된 에이전트가 150~300줄의 전용 플레이북을 Read하며 실행한다. 이를 단일 에이전트가 통합 처리하면:

- 플레이북(`workflow-design.md`, `pipeline-design.md`, `agent-team.md`, `skill-forge.md`)을 모두 Read해야 하는데 컨텍스트 압박이 크다.
- 각 Phase에서 발생하는 Escalation을 통합 에이전트가 정리해야 하므로 Escalation 품질이 떨어질 수 있다.
- Red-team Advisor가 1회만 실행되므로, Phase 4(파이프라인)에서만 발생하는 문제(예: 리뷰어 에이전트 누락 — `pipeline-review-gate.md` 규칙)를 Phase L 통합 Advisor가 놓칠 수 있다.

`pipeline-review-gate.md`의 "리뷰 필수 (mandatory review)" 기준은 "생성·결정·설계 출력을 내보내는 파이프라인"에 적용된다. 단순 프로젝트라도 코드 생성 워크플로우가 있으면 이 규칙이 적용되어야 하는데, Phase L 통합 에이전트가 이를 누락할 가능성이 있다.

### 비판 3: 단순이 복잡으로 바뀌는 케이스 처리 부재

솔로 웹앱으로 시작했다가 6개월 후 팀으로 확장하거나 에이전트 파이프라인을 추가하는 케이스가 흔하다.

- 경량 트랙으로 생성된 하네스에는 `04-agent-team.md`가 없다.
- `harness-audit` 플레이북(`orchestrator-protocol.md` "CLAUDE.md 단일 소유자 원칙 적용 시점" 참조)이 재진입 시 경량 트랙 산출물 구조를 인식할 수 있는가? `02-lite-design.md`는 현행 Phase Gate 테이블(`orchestrator-protocol.md` "Phase Gate" 섹션)에 없는 비표준 번호다.
- `00-target-path.md`에 `track: lightweight`를 기록한다고 했지만, 이것이 재개 프로토콜(`orchestrator-protocol.md` "중단/재개 프로토콜" → "비표준 파일명 처리")에서 올바르게 인식되는지 검증이 없다.

### 비판 4: Advisor 경량 실행과 보안의 충돌

김민준의 제안에서 Phase 1-2 Advisor는 경량 실행(NOTE만)이지만, `orchestrator-protocol.md` "복잡도 게이트" 항목과 `ARCHITECTURE.md` 7.1 표의 Dim 6(보안 권한 적절성)은 "항상 전체 실행"이 명시되어 있다. 경량 트랙 Advisor도 Dim 6은 예외 없이 전체 실행해야 하는데, 이 예외를 Phase L 통합 Advisor에도 명시하지 않으면 보안 가드가 형해화될 수 있다.

---

## 수렴: 김민준의 반론과 조정

이서연의 비판을 수용하여 다음과 같이 제안을 수정한다.

### 조정 1: 판별 시점을 Phase 1-2 완료 후로 이동

트랙 판별은 Phase 0이 아닌 **Phase 1-2(`phase-setup`) 완료 직후**에 오케스트레이터가 수행한다. `01-discovery-answers.md`의 스캔 결과와 Escalation을 읽은 후 판별하므로 정보 완전성이 보장된다.

Phase 0에서는 트랙 판별 없이 기존과 동일하게 경로 수집 + 사전 인터뷰만 수행한다. "빠르게" 발화(`--fast`)는 Phase 1-2에 Fast Track 힌트로 전달되어 인터뷰를 단축시키는 현행 메커니즘을 그대로 유지한다.

판별 기준은 Phase 1-2 산출물의 다음 항목으로 확정한다:
- `01-discovery-answers.md` → `## Context for Next Phase` → 에이전트 프로젝트 여부 필드
- `## Escalations` → 에이전트 신호(3-A), Strict Coding 신호(3-B) 항목

### 조정 2: Phase L은 통합이 아닌 "압축 실행"

단일 에이전트에 4개 플레이북을 모두 읽히는 대신, Phase L 에이전트는 전용 플레이북 `playbooks/setup-lite.md`(신규 생성)만 읽는다. 이 플레이북은 Phase 3-6의 핵심 의사결정 항목만 추출한 경량 버전으로, 단순 프로젝트에서 필요한 워크플로우/에이전트/스킬 수준의 결정을 100줄 이내로 처리한다.

플레이북 책임:
- 워크플로우: "단일 세션인가, 2~3 스텝 시퀀스인가"만 결정
- 에이전트: "필요한가? 있다면 최대 1~2개 경량 에이전트"
- 스킬: "필요한가? 있다면 각 에이전트당 1개"
- 훅: "commit hook 정도만"

`pipeline-review-gate.md` 의무(`mandatory review`)는 Phase L에서도 적용한다. 단, 단순 프로젝트 특성상 "생성·결정 파이프라인"이 없는 경우 면제(`review_exempt: true + exempt_reason: "단순 웹앱, 생성/결정 파이프라인 없음"`)가 가능하며, Phase L 에이전트가 이를 `02-lite-design.md`에 명시한다. Advisor가 이 면제 사유를 Dim 12로 검증한다.

Phase L Advisor는 Dim 6(보안)을 항상 전체 실행하며 나머지 Dimension은 복잡도 게이트 기준(NOTE만)을 적용한다. 이는 `orchestrator-protocol.md` "복잡도 게이트" 조항 문구와 일치한다.

### 조정 3: 업그레이드 경로를 Phase Gate에 통합

`02-lite-design.md`를 비표준 파일명이 아닌, Phase Gate 테이블에 공식 항목으로 등록한다. 번호 체계: `02-lite-design.md`는 경량 트랙 전용이며 풀 트랙의 `02-workflow-design.md`와 번호 공간을 공유하지 않는다. `00-target-path.md`의 `track: lightweight` frontmatter를 Phase Gate 검증 로직이 확인하여 해당 트랙에 맞는 Gate를 적용한다.

재개 시 오케스트레이터 처리:
- `track: lightweight` 감지 → 경량 트랙 Phase Gate 적용
- `track` 필드 없음 → 풀 트랙 Phase Gate 적용 (하위 호환)
- 경량 트랙 재개 시 `02-lite-design.md`가 있으면 Phase L 완료로 인정, `07-validation-report.md`가 없으면 Phase 9에서 재개

---

## 최종 합의된 개선 방향성

두 전문가가 합의한 경량 트랙은 다음 원칙을 따른다:

1. **Phase 수를 줄이지 않고 트랙을 분기한다** — 기존 Phase Gate, Advisor, Escalation 시스템의 보장을 유지하면서 단순 프로젝트에 맞는 실행 경로를 제공한다.
2. **판별은 스캔 후에 한다** — Phase 1-2 완료 직후, `01-discovery-answers.md`를 근거로 오케스트레이터가 트랙을 결정한다.
3. **경량 트랙도 보안 가드는 동일하게 적용한다** — Dim 6, `final-validation` Step 5, `pipeline-review-gate.md` 의무는 트랙과 무관하게 동일하게 적용한다.
4. **업그레이드 가능성을 설계에 포함한다** — 경량 트랙 완료 후에도 풀 트랙으로 재진입할 수 있도록 `00-target-path.md`에 트랙 정보를 기록하고, Phase Gate가 이를 인식한다.
5. **전용 플레이북으로 품질을 보장한다** — Phase L 에이전트는 Phase 3-6 플레이북을 모두 읽는 대신 `playbooks/setup-lite.md` 전용 경량 플레이북을 사용한다.

---

## 구현 방법론 (단계별 + 구체적 파일 변경 포함)

### Step 1: 트랙 판별 로직 — `orchestrator-protocol.md` 수정

**파일**: `.claude/rules/orchestrator-protocol.md`

**변경 위치**: "Phase 실행 프로토콜" → "Phase-to-Agent 매핑" 테이블 앞에 "트랙 판별 프로토콜" 섹션 추가.

추가 내용:
```
### 트랙 판별 프로토콜 (Phase 1-2 완료 직후)

오케스트레이터는 `01-discovery-answers.md`의 다음 항목을 읽어 트랙을 결정한다:

경량 트랙(lightweight) 조건 — 모두 AND:
- `## Context for Next Phase` → 에이전트 프로젝트 여부: **아니오**
- `## Context for Next Phase` → 프로젝트 유형: **웹앱 또는 CLI**
- `## Context for Next Phase` → 솔로/팀: **솔로**
- `## Escalations` → 에이전트 신호(3-A): **없음 또는 NOTE**
- `## Escalations` → Strict Coding 신호(3-B): **0~1개 신호 (NOTE 수준)**

위 조건 모두 충족 → 경량 트랙
하나라도 불충족 → 풀 트랙

트랙 결정 후 `00-target-path.md` frontmatter에 `track: lightweight | full` 기록.
AskUserQuestion으로 사용자에게 트랙 결정을 고지하고 계속 여부 확인:
"단순 프로젝트로 감지되어 경량 트랙으로 진행합니다 (~30분, 약 8회 LLM 호출). 계속 / 풀 트랙으로 전환"
```

**변경 위치**: "Phase-to-Agent 매핑" 테이블에 Phase L 행 추가:

```
| L | phase-setup-lite | setup-lite | 경량 트랙 전용. Phase 1-2 완료 후 판별 결과가 lightweight인 경우만 실행. Phase 3-6 대체. |
```

**변경 위치**: "Phase Gate" 테이블에 경량 트랙 조건 추가:

```
| Phase L (경량) | docs/{name}/01-discovery-answers.md + track: lightweight 확인 |
| Phase 7-8 (경량) | docs/{name}/02-lite-design.md |
| Phase 9 (경량) | docs/{name}/06-hooks-mcp.md 또는 MCP 없으면 02-lite-design.md |
```

### Step 2: 경량 트랙 플레이북 신규 생성

**파일**: `playbooks/setup-lite.md` (신규)

내용 구조:
```
# Lightweight Setup (Phase L)

## Goal
단순 웹앱/CLI 솔로 프로젝트의 Phase 3-6을 단일 에이전트가 경량 처리한다.
목표: 30분 이내, 추가 LLM 호출 최소화.

## Input
- docs/{요청명}/01-discovery-answers.md (필수 Read)

## Step 1: 워크플로우 개요 결정 (Phase 3 대응)
2~3줄 수준. 다이어그램 없음. "코딩 → 테스트 → 커밋" 수준의 선언만.

## Step 2: 에이전트 필요성 판단 (Phase 4-5 대응)
단순 프로젝트 기본: "에이전트 팀 불필요, 단일 세션으로 처리"
예외: 반복 코드 리뷰, 자동 문서화 등 명확한 자동화 니즈가 있으면 최대 1~2개 경량 에이전트 설계.

## Step 3: 파이프라인 리뷰 게이트 판단 (pipeline-review-gate.md 준수)
에이전트가 없거나 변환/I/O 전용이면: review_exempt: true + exempt_reason 기록 (의무)
생성/결정 파이프라인이 있으면: 도메인 리뷰어 에이전트 1개 설계

## Step 4: 스킬 필요성 판단 (Phase 6 대응)
에이전트 없음 → 스킬 없음
에이전트 있음 → 에이전트당 1개 경량 스킬 설계

## Step 5: 훅 후보 목록 (Phase 7-8 사전 작업)
commit hook, lint hook 정도. Phase 7-8에 전달.

## Output Contract
산출물: docs/{요청명}/02-lite-design.md
필수 섹션: Summary, Files Generated, Context for Next Phase, Escalations, Next Steps
Context for Next Phase 필수 항목:
- 워크플로우 스텝 목록 (이름, 목적)
- 에이전트 목록 (없으면 "없음 선언")
- pipeline-review-gate 결정 (면제/필수 + 사유)
- 스킬 목록 (없으면 "없음 선언")
- 훅 후보
- 업그레이드 경로: "Phase 3부터 풀 트랙으로 재진입 가능"
```

### Step 3: phase-setup-lite 에이전트 정의 신규 생성

**파일**: `.claude/agents/phase-setup-lite.md` (신규)

내용 구조 (기존 `phase-workflow.md` 등 참조하여 lean ~25줄):
```yaml
---
name: phase-setup-lite
description: Lightweight track agent for simple solo web/CLI projects. Handles Phase 3-6 in a single pass.
model: claude-sonnet-4-6  # 경량 트랙이므로 Sonnet (풀 트랙 phase-workflow의 Opus 대신)
---

# Phase-Setup-Lite Agent

당신은 단순 솔로 프로젝트의 Phase 3-6을 경량 통합 처리하는 에이전트다.

## Playbooks
반드시 이 플레이북을 Read하여 실행한다:
${CLAUDE_PLUGIN_ROOT}/playbooks/setup-lite.md

## Rules
- AskUserQuestion 사용 금지 — 불확실 사항은 Escalations에 기록
- 쓰기 대상: 대상 프로젝트 내부만
- 반환 포맷: 5-섹션 (Summary, Files Generated, Context for Next Phase, Escalations, Next Steps)
- pipeline-review-gate.md 의무 준수: 생성/결정 파이프라인에는 리뷰어 필수
```

### Step 4: ARCHITECTURE.md 업데이트

**파일**: `ARCHITECTURE.md`

**변경 위치**: "4.3 Fast Track / Fast-Forward / 복잡도 게이트" 섹션에 "경량 트랙(Lightweight Track)" 항목 추가:

```
- **경량 트랙(Lightweight Track)**: 솔로 + 웹앱/CLI + 에이전트 신호 없음 조건에서 
  Phase 1-2 완료 직후 자동 판별. Phase 3-6을 단일 `phase-setup-lite` 에이전트(플레이북: 
  `playbooks/setup-lite.md`)로 통합 처리. 총 8~10회 LLM 호출, 예상 소요 30분. 
  보안 가드(Dim 6, pipeline-review-gate)는 풀 트랙과 동일하게 적용.
```

**변경 위치**: "4.1 Phase 역할" 테이블에 Phase L 행 추가:

```
| L | 경량 통합 설계 (워크플로우/에이전트/스킬/훅 후보) | phase-setup-lite | setup-lite |
```

### Step 5: 00-target-path.md 템플릿 업데이트

오케스트레이터가 Phase 0에서 생성하는 `00-target-path.md`에 `track` 필드를 예약한다. Phase 1-2 완료 직후 트랙이 결정되면 오케스트레이터가 이 파일을 Edit하여 `track` 값을 채운다.

```yaml
---
phase: 0
completed: {timestamp}
status: done
track: lightweight | full   # Phase 1-2 완료 후 오케스트레이터가 채움. 초기값: pending
---
```

---

## 예상 효과 및 성공 지표

| 지표 | 현재 (풀 트랙만) | 경량 트랙 도입 후 |
|------|-----------------|-----------------|
| 단순 프로젝트 예상 소요 시간 | 60분+ | 25~35분 |
| 단순 프로젝트 LLM 호출 수 | 18회+ | 8~10회 |
| 생성 산출물 완성도 | Phase 9개 × 파일 8개 | Phase 5개 × 파일 5개 |
| 업그레이드 가능성 | 해당 없음 | `track: lightweight` → Phase 3부터 풀 트랙 재진입 |
| 보안 커버리지 | Dim 6 항상 전체 | Dim 6 항상 전체 (변경 없음) |

**성공 지표**:
- 경량 트랙 완료율(Phase 9까지) ≥ 풀 트랙 완료율의 1.5배
- 경량 트랙 후 "업그레이드 요청" 비율 ≥ 10% (트랙이 가치를 증명한 후 확장)
- Advisor Dim 6 BLOCK 발생률: 경량 ↔ 풀 트랙 간 차이 5% 이내 (보안 동등성)

---

## 잔여 리스크 및 완화 방안

| 리스크 | 설명 | 완화 방안 |
|--------|------|-----------|
| 오탐(False Light) | 단순해 보이지만 실제로는 복잡한 프로젝트를 경량 트랙으로 판별 | 경량 트랙 AskUserQuestion에 "풀 트랙으로 전환" 선택지 제공. 언제든 탈출 가능 |
| 업그레이드 단절 | 경량 트랙 완료 후 풀 트랙 재진입 시 `01-discovery-answers.md`만 있고 `02-workflow-design.md`가 없어 Phase Gate 실패 | Phase Gate가 `track: lightweight` 감지 시 `02-lite-design.md`를 Phase 3 선행 산출물로 인정하도록 조건 분기 |
| setup-lite 플레이북 부실 | `playbooks/setup-lite.md`가 `pipeline-review-gate.md` 의무를 충분히 반영하지 못함 | 플레이북 Step 3을 `pipeline-review-gate.md`의 "파이프라인 분류" 섹션을 직접 참조(Read)하도록 지시 |
| 트랙 판별 타이밍 오류 | Phase 1-2 에이전트가 Escalations에 에이전트 신호를 기록했지만 오케스트레이터가 NOTE로 오독하여 경량 트랙 판별 | 트랙 판별 로직에 "Escalations에 3-A [ASK] 항목이 하나라도 있으면 풀 트랙" 조건 명시. NOTE는 경량 허용, ASK는 풀 트랙 |
| Advisor 경량 실행과 pipeline-review-gate 충돌 | Phase L Advisor가 NOTE만 수집하다가 Dim 12(파이프라인 리뷰 게이트)를 누락 | `orchestrator-protocol.md` 복잡도 게이트 조항에 "Dim 12(파이프라인 리뷰 게이트 준수)는 Dim 6(보안)과 동일하게 경량 게이트에서도 항상 전체 실행" 추가 |
