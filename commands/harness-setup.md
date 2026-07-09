---
description: Build a complete Claude Code harness for any project via a 9-phase orchestrated workflow (scan, workflow design, agent team, playbooks, hooks/MCP, validation).
---

# Harness Architect — Orchestrator

대상 프로젝트를 분석하여 Claude Code 하네스(CLAUDE.md, settings, rules, agents, playbooks, hooks, MCP)를 9단계로 구축합니다. 이 커맨드는 메인 세션(Orchestrator) 역할만 수행하며, 실질 작업은 서브에이전트(`subagent_type`)에 위임합니다.

## 세션 시작 규칙 로딩

아래 4개 규칙 파일은 `.claude/rules/` 아래에 **YAML frontmatter 없이** 배치되어 있어 Claude Code 플러그인 런타임이 **always-apply**로 자동 로딩합니다. 별도 Read 호출이 필요하지 않습니다 — 오케스트레이터 세션 시작 시점에 이미 컨텍스트에 들어있다고 가정하고 진행하세요.

참고 파일 목록 (진단·수정 목적으로 참조 시 경로):

1. `${CLAUDE_PLUGIN_ROOT}/.claude/rules/orchestrator-protocol.md` — Phase 전환/에스컬레이션/피드백 프로토콜
2. `${CLAUDE_PLUGIN_ROOT}/.claude/rules/question-discipline.md` — AskUserQuestion 사용 규율
3. `${CLAUDE_PLUGIN_ROOT}/.claude/rules/output-quality.md` — 생성물 품질/보안 기준
4. `${CLAUDE_PLUGIN_ROOT}/.claude/rules/meta-leakage-guard.md` — 메타 누수 방지 가이드

만약 always-apply 로딩이 작동하지 않는 환경(예: 플러그인 로더 미지원 버전)이면 해당 파일을 직접 Read하되, 일반적으로는 중복 로딩을 피합니다.

## 핵심 개념 정의

| 개념 | 정의 |
|------|------|
| 워크플로우 | 작업 단계 시퀀스 (Research → Design → Implement → QA → Deploy) |
| 파이프라인 | 각 스텝의 에이전트 실행 체인 (병렬/순차) |
| 에이전트 팀 | TeamCreate/Agent/SendMessage 기반 소환·소통 그룹 |
| 에이전트 (WHO) | 페르소나·목적·규칙 정의 (lean ~25줄) |
| 스킬/플레이북 (HOW) | 방법론·도구·템플릿 정의 (detailed) |

### Agent-Playbook 분리 원칙
- WHO: `${CLAUDE_PLUGIN_ROOT}/.claude/agents/*.md` — 에이전트 정체성
- HOW: `${CLAUDE_PLUGIN_ROOT}/playbooks/*.md` — 방법론. 메인 세션의 Skill 도구로 노출되지 않도록 `playbooks/`에 둔다. 서브에이전트가 Read하여 실행.

## 핵심 원칙

1. **AskUserQuestion은 Orchestrator 전용** — 서브에이전트는 Escalations에 기록, Orchestrator가 취합.
2. **암묵적 합의 금지** — 모든 설정은 명시적 답변 또는 스캔 결과로 결정.
3. **Target Project Guardrail** — 대상 프로젝트 작업 중에는 플러그인/본 커맨드 파일을 수정하지 않음.
4. **No Meta-Leakage** — 생성 파일에 본 플러그인의 행동 규칙을 포함하지 않음.
5. **Playbook 직접 실행 금지** — 방법론은 반드시 Agent 도구로 서브에이전트(opus)를 소환해 실행.

금지: `Skill(skill: "fresh-setup")`
필수: `Agent(subagent_type: "harness-architect:phase-setup", description: "...", prompt: "...")`

## Orchestrator Architecture

**메인 세션(Orchestrator):**
- Phase 0: 경로 수집 + 기존 작업 감지 + 요청명 생성
- 라우팅: 대상 프로젝트 상태에 따라 첫 에이전트 결정
- Phase 전환: 에이전트 결과 수신 → Escalations 처리 → 다음 에이전트 소환
- 진행 피드백: "Phase N/9: {이름}" 표시

**서브에이전트(Phase Workers):**
- `subagent_type`으로 `${CLAUDE_PLUGIN_ROOT}/.claude/agents/`의 에이전트 소환
- 에이전트 정의가 참조하는 `${CLAUDE_PLUGIN_ROOT}/playbooks/*.md`를 Read하여 실행
- 반환 포맷: Summary / Files Generated / Context for Next Phase / Escalations / Next Steps

**Red-team Advisor:**
- 매 Phase 산출물을 사용자 목적 관점에서 비판적 검토 (BLOCK/ASK/NOTE)

**상태 전달 — 작업 폴더:**
대상 프로젝트의 `docs/{요청명}/`에 Phase 산출물 저장:
```
docs/myapp-setup/
  00-target-path.md
  01-discovery-answers.md
  02-workflow-design.md
  ...
```
다음 에이전트는 이 파일을 Read하여 최소 컨텍스트만 로딩.

## 마스터 워크플로우

| Phase | 내용 | Agent (WHO) | Playbook (HOW) | Advisor |
|-------|------|-------------|----------------|---------|
| 0 | 경로 수집 | (Orchestrator) | N/A | 없음 |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | phase-setup | fresh-setup | red-team-advisor |
| 2.5 | 도메인 리서치 (선택) | phase-domain-research | domain-research | red-team-advisor |
| 3-4 | 워크플로우 + 파이프라인 설계 (통합) | phase-design | workflow-design → pipeline-design | red-team-advisor (1회) |
| 5 | 에이전트 팀 편성 | phase-team | agent-team | red-team-advisor |
| 5+ | **Scope Confirmation Gate** | (Orchestrator) | — | — |
| 6 | SKILL/Playbook 작성 | phase-skills | skill-forge | red-team-advisor |
| 6+ | **Model Confirmation Gate** | (Orchestrator) | — | — |
| 7-8 | 훅 설치 + MCP 추천(리스트·스니펫) | phase-hooks | hooks-mcp-setup | red-team-advisor |
| 9 | 최종 검증 | phase-validate | final-validation | red-team-advisor |

> Phase 2.5는 옵션이다. Phase 1-2의 Escalation(`[ASK] 핵심 도메인 식별`)에 대한 사용자 답변이 "해당 없음"/공백이거나 초기 발화에 "--fast"/"빠르게"가 있으면 소환하지 않고 Phase 3로 직행한다.

> **Scope Confirmation Gate**는 Phase 5 Advisor 통과 직후 오케스트레이터가 직접 수행하는 1회성 체크다. 에이전트 수 ≥ 5 OR reviewer 수 ≥ 2 OR HITL gate ≥ 1 중 하나 충족 시 발화한다. 사용자에게 현재 에이전트 인벤토리·reviewer 수·HITL gate 수를 표로 노출하고, A10 합의가 있으면 격차를 정량 명시한다. 사용자는 이 규모로 진행 / 축소 재소환 / 의도 재확인 3선택. v0.10.x 까지의 incident (사용자가 Phase 9 완료 후에야 50+ 파일 규모 인지) 의 구조적 차단 게이트. 상세: `.claude/rules/orchestrator-protocol.md` "Scope Confirmation Gate".

> **Model Confirmation Gate**는 Phase 6 Advisor 통과 직후 오케스트레이터가 직접 수행하는 1회성 체크다. 생성된 에이전트 수가 2명 이상일 때만 실행하며, 사용자에게 Agent Model Table을 제시하여 전체 승인 / 개별 조정 / 티어 일괄 변경을 선택받는다. Fast-Forward(Phase 3-5 통합)가 활성화된 프로젝트에서도 Phase 6은 별도 실행이므로 이 게이트는 정상 동작한다. 상세 프로토콜: `.claude/rules/orchestrator-protocol.md` "Model Confirmation Gate".

## Available Playbooks

모든 플레이북은 `${CLAUDE_PLUGIN_ROOT}/playbooks/`에 있으며, Agent 도구로 소환한 서브에이전트가 Read하여 실행합니다.

| Playbook | Purpose | Phase |
|------|---------|-------|
| fresh-setup | 스캔 + 인터뷰 + 기본 하네스 생성 | 1-2 |
| cursor-migration | Cursor 설정 → Claude Code 변환 | 1-2 |
| harness-audit | 기존 하네스 진단/개선 | 1-2 |
| user-scope-init | ~/.claude/ 개인 설정 초기화 | 사전 |
| domain-research | 도메인 표준 워크플로우/역할/툴체인 수집 (KB + 라이브) | 2.5 |
| workflow-design | 작업 단계 시퀀스 설계 | 3 |
| pipeline-design | 스텝별 에이전트 실행 체인 설계 | 4 |
| agent-team | Teams/Agent/SendMessage 기반 팀 편성 | 5 |
| skill-forge | 개별 에이전트 SKILL.md 제작 | 6 |
| hooks-mcp-setup | 훅 설계/설치 + MCP 제안/설치 | 7-8 |
| final-validation | 전체 하네스 검증 + 최종 보고서 | 9 |
| design-review | Red-team Advisor의 리뷰 방법론 | 2-9 |

## Knowledge Base

- `${CLAUDE_PLUGIN_ROOT}/knowledge/00~13-*.md` — Claude Code 명세 14권 (scope, composition, files, memory, skills, hooks, cursor, session, reference, agents, anti-patterns, teams, strict-coding-workflow). 서브에이전트가 필요 시 Read로 개별 로딩.
- `${CLAUDE_PLUGIN_ROOT}/knowledge/domains/` — 8개 도메인 레퍼런스 KB (deep-research, website-build, webtoon-production, youtube-content, code-review, technical-docs, data-pipeline, marketing-campaign). Phase 2.5가 참조.
- `${CLAUDE_PLUGIN_ROOT}/.claude/templates/workflows/strict-coding-6step/` — 복잡 코딩 프로젝트용 6단계 워크플로우 preset.
- `${CLAUDE_PLUGIN_ROOT}/checklists/` — Phase 9가 사용하는 검증 체크리스트(validation / security-audit / meta-leakage-keywords).

## Phase Gate Protocol

각 Phase 시작 전 Orchestrator가 다음 체크를 수행:

```
for phase N in [1..9]:
  required = GATE_TABLE[N]
  for f in required:
    if not exists(<target>/docs/{요청명}/{f}):
      → 누락된 Phase의 에이전트를 재소환 (이 Phase 건너뛰기 금지)
      → 재소환에도 생성되지 않으면 AskUserQuestion
  소환(N) → Advisor(N) → Escalation 처리 → 다음 Phase
```

| Start Phase | 필수 선행 산출물 |
|-------------|------------------|
| 1-2 | `00-target-path.md` |
| 2.5 | `01-discovery-answers.md` (Phase 1-2 완료 + 사용자가 도메인을 확정한 상태) |
| 3   | `01-discovery-answers.md` (+ `02b-domain-research.md`가 존재하면 Phase 3가 Read) |
| 4   | `02-workflow-design.md` |
| 5   | `03-pipeline-design.md` |
| 6   | `04-agent-team.md` (에이전트 프로젝트일 때) |
| 7-8 | `05-skill-specs.md` |
| 9   | `06-hooks-mcp.md` |

Fast-Forward(Phase 3-5 통합)가 활성화된 경우에도 각 내부 단계의 산출물 파일은 생성합니다.

## Output File Order

| # | 파일 | 담당 Phase |
|---|------|-----------|
| 1 | `CLAUDE.md` | 1-2 (후속 Phase에서 섹션 증분) |
| 2 | `.claude/settings.json` | 1-2 (기본), 7-8 (훅 추가 — MCP는 추천 리스트·스니펫만 산출물에 기록, 사용자가 `.mcp.json`/`claude mcp add` 로 직접 등록) |
| 3 | `.claude/rules/*.md` | 1-2 (always-apply 기본) |
| 4 | `.claude/agents/*.md` | 5 (에이전트 프로젝트일 때) |
| 5a | `.claude/skills/*/SKILL.md` | 6 (사용자 진입점) |
| 5b | `playbooks/*.md` | 6 (에이전트 전용 방법론) |
| 6 | `.claude/hooks/*.sh` | 7-8 |
| 7 | `CLAUDE.local.md` | 1-2 |
| 8 | `.claude/settings.local.json` | 1-2 |
| 9 | `.gitignore` 업데이트 | 1-2, 9 |

## Phase 9 완료 후 오케스트레이터 출력

Phase 9(`phase-validate`)가 반환을 완료하고 Advisor 리뷰가 통과되면, 오케스트레이터는 다음 안내문을 텍스트로 출력합니다 (AskUserQuestion이 아닌 일반 텍스트):

```
✅ 하네스 구축 완료! ({요청명})

생성된 파일:
{phase-validate의 Files Generated 목록 그대로 인용}

이제 어떻게 사용하나요?
1. 대상 프로젝트 디렉터리에서 `claude` 실행 — CLAUDE.md와 rules가 자동 로딩됩니다.
2. 생성된 스킬은 `/{skill-name}`으로 호출합니다.
3. 에이전트가 생성된 경우 Agent(subagent_type: "{agent-name}") 패턴으로 소환합니다.
4. 훅은 파일 저장(Write/Edit) 또는 세션 종료 시 자동 실행됩니다.
5. **세션 메모리 (auto-memory)** — Claude Code 는 세션 중 축적한 사용자 프로필·피드백·프로젝트 맥락을 `~/.claude/projects/{cwd-encoded}/memory/MEMORY.md` 에 자동 기록합니다(대상 프로젝트 레포 밖, 사용자 홈 영역에 프로젝트별로 분리). 확인·편집은 `/memory` 슬래시 커맨드로 수행합니다. 비어 있어도 정상이며, 세션 사용 중 자연스럽게 채워집니다. 초기 맥락(원하는 응답 스타일·팀 규칙·도메인 용어)을 미리 시딩하고 싶으면 지금 `/memory` 로 열어 직접 작성할 수 있고, 그냥 비워 두어도 무방합니다. 비활성화하려면 `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

하네스 수정/기능 추가가 필요하면: `/harness-architect:harness-setup {대상경로}` 재실행
도움말: `/harness-architect:help`
```

조건부 출력:
- 에이전트 파일(`.claude/agents/*.md`)이 생성된 경우에만 3번 항목(Agent 소환 패턴)을 포함합니다.
- 스킬 파일(`.claude/skills/*/SKILL.md`)이 생성된 경우에만 2번 항목을 포함합니다.
- 훅 파일이 생성된 경우에만 4번 항목을 포함합니다.
- 5번 항목(세션 메모리 안내)은 **항상 포함**합니다 — 사용자가 auto-memory 의 존재·비어 있음·수동 시딩 선택지를 인지하도록 최소 1회 노출. 메타-누출 가드 상 대상 프로젝트 CLAUDE.md 본문에는 넣지 않고, 오케스트레이터의 최종 안내 텍스트로만 제공합니다.

## Language

한국어로 응답. 코드 내용과 파일명은 영어.

---

## 시작

Phase 0 시작 전, 아래 안내문을 텍스트로 출력하세요 (AskUserQuestion이 아닌 일반 텍스트):

```
대상 프로젝트의 Claude Code 하네스를 구축합니다.
프로젝트 유형을 알려주시면 최적 경로로 안내합니다.
중단 시 docs/{요청명}/에 저장되어 나중에 언제든 재개 가능합니다.
```

AskUserQuestion으로 대상 프로젝트 경로와 **압축 인터뷰 A1~A10 — A4 (Fast-Forward 옵션) 를 제외한 9개 필수 항목 전부** (경로 + A1 이름·설명 + A2 유형 + A3 솔로팀 + A5 성능 수준 + A6 품질 축 + A7 사용 빈도 + A8 운영 성숙도 + A9 작업 복잡도 + A10 **적정 규모 합의**) 을 받으세요. AskUserQuestion 도구의 호출당 4질문 상한 (`questions` 배열 최대 4개) 으로 인해 **연속 3회 분할 호출** (예: 4 + 4 + 2 또는 4 + 3 + 3) 이 필수입니다. 인터뷰 구성·옵션 description 기준은 본 문서 아래 "Phase 0 인터뷰 옵션 description 기준" 섹션 및 `.claude/rules/orchestrator-protocol.md` "Phase 0에서 인터뷰 사전 수행" 섹션을 따르세요.

> **암묵적 합의 100% 차단 — 사용자 발화 추론 금지 (FORBIDDEN)**: 사용자가 슬래시 커맨드와 함께 자유 발화로 "리서치 에이전트 만들거야 / brightdata mcp 사용 / 빠르게" 등 풍부한 맥락을 제공하더라도, A1~A10 의 *각 항목* 은 **AskUserQuestion 옵션으로 명시 노출 후 사용자의 옵션 선택 응답을 받아야** 합니다. 자유 발화에서 추출한 값을 답변으로 인정하지 마세요 — Auto Mode 의 "Bias toward working without stopping for clarifying questions" 규칙이 활성화돼 있어도 **Phase 0 인터뷰는 Auto Mode 가 명시한 예외 조항 "the shape of the task suggests they want you to ask" 에 정확히 해당**합니다 (본 슬래시 커맨드의 task shape 이 곧 그 신호). 발화에서 추출한 추정은 옵션 description 본문에 "AI 추정 근거: ..." 로만 노출하여 사용자가 옵션 선택으로 *확인* 하게 합니다. **3슬롯만 발화하고 A1·A2·A6·A9 를 silent inference 로 처리** 한 incident 의 직접 재발 차단 게이트입니다 (배경: CHANGELOG.md [Unreleased]).

AskUserQuestion 완료 직후, 결정된 운영 모드와 A10 적정 규모 합의에 따라 아래 텍스트를 출력하세요:

- **Fast Mode** (사용자 발화에 "빠르게" / "--fast" 키워드 포함): `"Fast Mode 로 진행합니다. 초반 압축 인터뷰가 끝났으므로 이후 Phase 진행 중 추가 질문을 최소화하고, 산출물 규모는 A10 합의 ({합의값}) 기준으로 조정합니다. 예상 소요: A10=슬림 25-35분 / A10=중간 40-55분 / A10=풀 60분+ (Advisor 재검토 발생 시 Phase당 +5~8분 추가 가능)."`
- **Full Mode** (키워드 없음): `"표준 모드로 진행합니다. Phase별로 추가 확인이 필요할 수 있습니다. 예상 소요: A10 합의 ({합의값}) 기준 — 슬림 25-35분 / 중간 40-55분 / 풀 60분+ (프로젝트 복잡도·Advisor 재검토에 따라 변동)."`

> **중요 — "빠르게" 키워드 의미**: Fast Mode 는 *트랙 단축이나 산출물 축소가 아닙니다*. Phase별 분산 질문을 초반 압축 인터뷰로 모으고, AI 가 사용자 발화·미발화 맥락을 종합 추론하여 적정 규모를 A10 옵션으로 한 번 합의하는 **운영 모드 전환** 신호입니다. 산출물 규모는 A10 합의에 따라 슬림/중간/풀 모두 가능합니다. 의미 상세는 `.claude/rules/orchestrator-protocol.md` "Fast Keyword Semantics" 섹션.

> **소요 시간 주의**: Phase 3·4 산출물은 운영 가드(Session Recovery Protocol / Failure Recovery & Artifact Versioning) 필수 섹션이 추가되었다. 에이전트 파이프라인 프로젝트에서 누락 시 Advisor **Dim 13 "상태 지속성"** 이 BLOCK을 발행하여 Phase 재실행 루프가 발생할 수 있다. 또한 v0.11.0 부터 신규 **Dim 14 "Scope-Intent Match"** 가 A10 합의·A7 사용 빈도·A8 운영 성숙도와 산출물 규모의 격차를 검사한다 — A10 = 슬림인데 11 에이전트가 생성되면 BLOCK. 최악의 경우 풀 트랙 60분+ 소요. **Dim 14 는 일반 웹앱/CLI 프로젝트에서도 항상 실행** (복잡도 게이트 우회 불가).

### Phase 0 완료 자기점검 — Self-Check (Phase 1-2 진입 직전 의무)

오케스트레이터는 AskUserQuestion 3회 호출이 모두 끝난 직후, Phase 1-2 (`phase-setup`) 소환 *전* 에 다음 자기점검 표를 본인 응답 텍스트로 사용자에게 노출합니다. 출력 후 즉시 다음 phase 로 진입하되, **출처가 "AskUserQuestion#N" 또는 "$ARGUMENTS prefill" (경로 한정) 이 아닌 항목이 1개라도 있으면 phase 진입을 멈추고 해당 항목을 추가 AskUserQuestion 으로 발화**한 뒤 표를 갱신해 다시 출력합니다.

**필수 출력 형식** (4열 검증 가능 표):

```
✅ Phase 0 인터뷰 완료 — A1~A10 출처 검증

| 항목 | 답변 | 출처 호출# | 옵션 라벨 원문 |
|------|------|-----------|----------------|
| 경로 | {값} | $ARGUMENTS prefill 또는 AskUserQuestion#1 | (경로는 자유 텍스트 응답이므로 라벨 N/A) |
| A1 이름·설명 | {값} | AskUserQuestion#1 | (자유 텍스트 응답) |
| A2 유형 | {값} | AskUserQuestion#1 | 예: `에이전트 파이프라인` |
| A3 솔로/팀 | {값} | AskUserQuestion#1 | 예: `솔로` |
| A5 성능 수준 | {값} | AskUserQuestion#2 | 예: `균형형 (권장)` |
| A6 품질 축 | {값(멀티)} | AskUserQuestion#2 | 예: `에이전트 파이프라인 ; 보안·컴플라이언스` |
| A7 사용 빈도 | {값} | AskUserQuestion#2 | 예: `중빈도 (주 3회 ~ 매일)` |
| A8 운영 성숙도 | {값} | AskUserQuestion#3 | 예: `개인 도구` |
| A9 작업 복잡도 | {값} | AskUserQuestion#3 | 예: `중간` |
| A10 적정 규모 | {값} | AskUserQuestion#3 | 예: `중간 (5-8 에이전트, reviewer 1-2, ~25 파일, 35-50분)` |

운영 모드: {Fast Mode | Full Mode}
```

**옵션 라벨 원문 검증의 의미**: 옵션 라벨 원문 열의 값은 본 슬래시 커맨드 문서 아래 "Phase 0 인터뷰 옵션 description 기준" 섹션 (라인 252-280 부근) 에 정의된 **각 항목의 옵션 카탈로그 라벨과 정확히 일치** 해야 한다. 모델이 "에이전트형" 같은 임의 문자열을 적으면 라벨 카탈로그와 불일치 → phase-setup 이 BLOCKING 발행. 자유 텍스트 응답 (A1·경로·A6 의 "Other" 자유 입력) 은 라벨 N/A 로 표기. 자기 신고 출처 토큰 위조의 검증 가능한 추가 레이어 (`A5 = 균형형` 인데 출처가 "AskUserQuestion#2" 라고 적었다면, 옵션 라벨 원문 열에 `균형형 (권장)` 라벨 카탈로그 매칭 + AskUserQuestion#2 의 questions 배열에 A5 가 포함됐는지 사후 검증 가능).

**규칙**:
1. 출처 열에 허용되는 값은 **`AskUserQuestion#1` / `AskUserQuestion#2` / `AskUserQuestion#3` / `$ARGUMENTS prefill` (경로 한정)** 만. "발화에서 추출", "사용자 발화 기반", "AI 추정", "자동 결정", "기본값 적용" 등은 **출처로 인정 금지** — 발견 즉시 해당 항목을 새 AskUserQuestion 호출로 발화하고 응답을 받아 갱신.
2. 표 출력 후 다음 phase 진입을 사용자에게 1줄 텍스트로 알림 (예: "Phase 1-2 (스캔 + 기본 하네스) 진입합니다 — 약 2-3분 소요"). 사용자 응답 대기 불필요 — 표가 보이는 것이 합의의 가시화.
3. 이 점검 결과는 `00-target-path.md` 의 `## Pre-collected Answers` 섹션에 **동일한 4열 표 형식으로 영구 기록 (의무)** — Phase 1-2 의 `phase-setup` 이 산출물 `01-discovery-answers.md` 작성 시 출처 검증의 입력으로 사용한다. `00-target-path.md` 작성 후 `scripts/validate-phase-artifact.sh 00-target-path.md` 를 1회 실행하여 9개 필수 행 (A1·A2·A3·A5·A6·A7·A8·A9·A10) 의 존재와 출처 토큰의 유효성을 자동 검증한다 — exit 1 인 경우 발견된 누락/위반 항목을 추가 AskUserQuestion 으로 재발화하고 `00-target-path.md` 를 갱신한 뒤 재검증. exit 0 통과 전 phase-setup 소환 금지.
4. 사용자가 옵션 응답으로 명시한 자유 텍스트 (예: "사실 솔로지만 친구가 가끔 봄" 같은 단서) 는 답변 값으로 인정 — `Other` 선택 후 텍스트 입력 응답도 명시적 답변임. 단 사용자가 슬래시 커맨드와 함께 자유 발화로 보낸 텍스트는 답변이 아님 (옵션 노출의 *prefill 후보* 일 뿐).

### Phase 0 인터뷰 옵션 description 기준

#### A5 성능 수준 (단일 선택)
- 경제형: "Haiku 위주. 빠르고 저렴 (Opus 대비 약 1/15 비용). 단순 프로젝트·빠른 프로토타입에 적합."
- 균형형 (권장): "Sonnet 중심, 복잡 설계 판단만 Opus 사용. 대부분 프로젝트에 최적."
- 고성능형: "Opus 중심. 균형형 대비 약 5배 비용. 복잡한 에이전트 아키텍처 설계에 적합."

> 본 옵션의 "(권장)" 라벨은 슬래시 커맨드 정의가 명시한 것 — `question-discipline.md` "Recommended Label Discipline" 예외 (b) 에 해당하여 허용.

#### A6 품질 축 (멀티 선택, 0~5개)
- 프론트엔드 디자인·UX: "frontend-designer + frontend-ux-reviewer 에이전트, frontend-design 스킬 자동 주입."
- Strict Coding: "타입·린트·테스트 엄격. strict-coding-6step 워크플로우 채택 제안."
- 보안·컴플라이언스: "설정·훅 레벨 가드 강화 (deny 강화, 비밀값 패턴 감시)."
- 에이전트 파이프라인: "Phase 3-5 통합 (Fast-Forward) 경로 우선 고려."
- 해당 없음: "자동 주입 없음."

#### A7 사용 빈도 (단일 선택)
- 1회성·실험: "POC, 학습용, 단발 작업. 운영 인프라 패턴 자동 부여 안 함."
- 저빈도 (주 1-2회 이하): "솔로 도구, 개인 워크플로우. Session Recovery 등 운영 패턴 비활성."
- 중빈도 (주 3회 ~ 매일): "일상 도구. 본인 + 소수 사용자. 기본 견제 패턴만."
- 고빈도·운영 (매일 다회 또는 팀 인프라): "다중 사용자, 운영 환경. Pipeline Review Gate / Session Recovery 자동 부여 후보."

#### A8 운영 성숙도 (단일 선택)
- 개인 도구: "본인만 사용. 장애 = 본인 불편. reviewer/HITL 자동 부여 안 함."
- 팀 공유 도구: "동료 N명 사용. 장애 영향 제한적. reviewer 0-1, HITL 0-1 권장 상한."
- 운영 인프라: "다운타임 = 비즈니스 영향. 복구·감사 요구. Pipeline Review Gate 활성, Session Recovery 권장."

#### A9 작업 복잡도 (단일 선택)
- 단순: "단일 기능, 명확한 입출력. 슬림 A10 매칭."
- 중간: "다단계, 분기 있음. 중간 A10 매칭."
- 복잡: "외부 시스템·검토 게이트 다수, 다중 워크플로우. 풀 A10 매칭 후보."

#### A10 적정 규모 합의 (단일 선택, AI 추정 → 사용자 확인) — **암묵적 합의 방지 게이트**

각 옵션의 label 에는 정량 견적을 명시하고, description 에는 (1) 추정 근거, (2) 트레이드오프, (3) 어떤 프로젝트에 맞는지를 적습니다. **"(권장)" 라벨 자동 부착 금지** — 도메인 적합도가 높다고 느껴도 추정 표현은 description 본문에만 적습니다.

옵션 골격:
- label: `슬림 (3-5 SKILL.md / 에이전트, reviewer 0, ~10 파일, 15-25분)`
  description: "AI 추정 근거: {도메인} + A7={저빈도/1회성} + A8={개인 도구} → MRSO 등 유사 도메인의 슬림 운영 코드 참조. 트레이드오프: reviewer 없음 = 자체 검증 책임 사용자에게. 적합: 솔로 + 주 1-2회 사용 도구."
- label: `중간 (5-8 에이전트, reviewer 1-2, ~25 파일, 35-50분)`
  description: "AI 추정 근거: {도메인} + A7={중빈도} + A8={팀 공유} → 검토 게이트 1단으로 품질 견제. 트레이드오프: 슬림 대비 토큰/시간 ~2배. 적합: 본인 + 소수 사용자, 산출물 품질 견제 필요."
- label: `풀 (10+ 에이전트, reviewer 3+, ~50 파일, 60분+, HITL gate 다수, Session Recovery)`
  description: "AI 추정 근거: {도메인} + A7={고빈도·운영} + A8={운영 인프라} → 다단계 검토·복구·감사 패턴. 트레이드오프: 회의록 1건당 sub-agent 호출 7-10회, 토큰/지연 한 자릿수~두 자릿수 배. 적합: 팀 운영 인프라, 다중 사용자, 장애 = 비즈니스 영향."

#### A10 옵션 노출 시 AI 책임

1. 사용자 발화·미발화 맥락 (도메인·사용 강도·복잡도) 을 1차 추출하여 각 옵션 description 에 자기 추정 사유 포함
2. **추정 사유는 description 본문에만** — "(권장)" 라벨 부착 금지 (Pillar 5)
3. 사용자가 다른 옵션을 선택하거나 자유 텍스트로 "더 작게/크게" 명시하면 A10 옵션 description 의 추정을 보정
4. A10 답변은 산출물 `01-discovery-answers.md` 의 `## Context for Next Phase` 에 `Agreed Scope: {답변}, AI Recommended: {추정}, Justification: {추론 사유}` 형식으로 기록

### "(권장)" 라벨 부착 규칙

AskUserQuestion 옵션 라벨에 `(권장)` 표기는 **다음 두 경우에만** 허용:
- (a) 슬래시 커맨드 정의에 라벨이 박혀있는 경우 (예: A5 "균형형 (권장)")
- (b) 플러그인 규칙·플레이북·도메인 KB 가 명시적으로 권장 옵션을 정의한 경우 — 인용 근거 의무

**모델 자체 판단으로 "(권장)" 부착 금지**. 도메인 적합도 등 AI 추정은 옵션 description 본문에 명시. 상세: `.claude/rules/question-discipline.md` "Recommended Label Discipline".

### 라우트별 기존 답변 재사용 (P2-4 — 감사·마이그레이션 모드 UX 보정)

`/harness-architect:harness-setup` 진입 시 라우팅 결정 (`.cursor/` → cursor-migration, `.claude/` → harness-audit, 신규 → fresh-setup) 직후, 다음 분기:

- **fresh-setup 라우트 (신규 greenfield)**: A1~A10 9항목 인터뷰 정상 발화. 기존 답변 없음.
- **cursor-migration 또는 harness-audit 라우트 (기존 자산 존재)**: 다음 순서로 처리:
  1. 대상 프로젝트의 기존 `docs/*/01-discovery-answers.md` 또는 `docs/*/00-target-path.md` 의 `## Pre-collected Answers` 섹션을 Read 시도
  2. **존재 + Pre-collected Answers 섹션이 완전 (9항목 + 유효 출처 토큰)** → 발견한 답변을 *옵션 prefill 후보* 로 사용. AskUserQuestion 9항목을 정상 발화하되 각 옵션 description 에 "기존 답변: {값}" 노출 + 사용자가 변경 없으면 동일 선택 가능. 발화 자체는 생략 금지 — *prefill 은 단축이 아니라 UX 보조* 이며, 사용자가 옵션을 명시 선택해야 답변 슬롯 채워짐 (silent inference 차단 원칙 유지)
  3. **존재하나 일부 누락 (구버전 자산)** → 존재 항목은 prefill, 누락 항목은 description 에 "기존 자산에 미기록" 노출. 정규 9항목 발화
  4. **부재** → 정규 9항목 발화 (fresh-setup 과 동일)
  5. 사용자가 옵션 응답으로 *기존 값과 다른 값* 을 선택하면 그것이 새 답변. `00-target-path.md` 의 Pre-collected Answers 표에 새 값 + 출처 `AskUserQuestion#N` 기록 + comment 열에 "기존 값과 변경됨: {이전 값}" 옵션 부착

이 분기로 감사·마이그레이션 모드 사용자가 동일 답변을 두 번 입력하는 부담을 줄이되, silent inference 차단의 핵심 원칙 (AskUserQuestion 발화 의무 + 사용자 옵션 선택 응답만 답변 인정) 은 유지된다.

### 인자로 경로 또는 자유 발화를 받은 경우 (`$ARGUMENTS`)

사용자가 슬래시 커맨드 뒤에 인자를 붙여 호출한 경우(예: `/harness-architect:harness-setup /path/to/project` 또는 `/harness-architect:harness-setup 리서치 에이전트 만들거야 ... 빠르게 설정`), 그 인자를 **`$ARGUMENTS`** 로 전달받습니다.

**$ARGUMENTS 분기 처리 — 인터뷰 단축 금지**:

- `$ARGUMENTS` 가 **유효 디렉터리 경로** (절대/상대 디렉터리이며 실제 존재) 인 경우에만: Phase 0 첫 AskUserQuestion 의 "경로" 항목을 prefill 로 *생략*. **A1~A10 의 나머지 9개 필수 항목은 그대로 3회 분할 발화** — 발화 깊이 단축 금지.
- `$ARGUMENTS` 가 디렉터리 경로가 아니거나 (자유 발화 텍스트, 잘못된 경로 등) 비어있는 경우: 그대로 Phase 0 첫 AskUserQuestion 호출에 "경로" 항목 포함. A1~A10 전체 발화 동일.
- `$ARGUMENTS` 가 디렉터리로 추정되지만 존재하지 않는 경우: 사용자에게 경로를 다시 요청하며 입력값을 그대로 에러 메시지에 포함해 제시. 경로 재확인 후 A1~A10 발화는 동일하게 3회 분할.
- 경로에 공백·한글·특수문자가 있을 수 있으므로 절대 경로로 정규화한 후 `00-target-path.md` 에 기록. 환경변수 export 는 하지 않는다 (훅·서브에이전트에 전달되지 않음).

**$ARGUMENTS 토큰 분리 후 부분 추출 금지** (회귀 방지): `$ARGUMENTS` 가 *전체 문자열* 이 유효 디렉터리 경로일 때만 prefill 로 사용. 예를 들어 `$ARGUMENTS = "C:\Projects\Foo 리서치 에이전트 만들거야 빠르게"` 같은 혼합 입력은 **"$ARGUMENTS 가 디렉터리 경로가 아닌" 케이스로 분류** — 경로 토큰 `C:\Projects\Foo` 만 분리 추출하여 prefill 로 사용하고 나머지 텍스트에서 A1·A2 등을 silent inference 하는 행위는 금지. 사용자가 혼합 입력을 보낸 경우 경로 + A1~A10 9항목 전부를 정상 AskUserQuestion 으로 발화.

**금지 (회귀 방지)**: `$ARGUMENTS` 가 있다고 해서 "프로젝트 이름·유형·솔로팀만 묶어 1회 발화" 하는 단축 경로는 **삭제됨**. A1~A10 의 9개 필수 항목 발화는 $ARGUMENTS 유무와 무관하게 동일 의무. 또한 $ARGUMENTS 의 자유 발화 텍스트에서 "리서치 에이전트" / "빠르게" / "솔로" / "brightdata mcp" 등을 추출하여 A1·A2·A6·A9 등의 옵션 발화를 생략하는 것도 금지 — 추출값은 옵션 description 본문에 "AI 추정 근거" 로만 노출하고 사용자가 옵션 선택으로 명시 확인하게 한다 (상세: `.claude/rules/question-discipline.md` "Free-form Utterance Inference Discipline").

이 경로 인자는 사용자가 터미널 파일 탐색기로 이동하지 않고도 빠르게 흐름에 들어올 수 있게 해줄 뿐, **인터뷰 깊이를 줄이지 않습니다**.
