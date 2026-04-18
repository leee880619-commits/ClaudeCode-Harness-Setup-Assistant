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
필수: `Agent(subagent_type: "phase-setup", description: "...", prompt: "...")`

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
| 3 | 워크플로우 설계 | phase-workflow | workflow-design | red-team-advisor |
| 4 | 파이프라인 설계 | phase-pipeline | pipeline-design | red-team-advisor |
| 5 | 에이전트 팀 편성 | phase-team | agent-team | red-team-advisor |
| 6 | SKILL/Playbook 작성 | phase-skills | skill-forge | red-team-advisor |
| 6+ | **Model Confirmation Gate** | (Orchestrator) | — | — |
| 7-8 | 훅/MCP 설치 | phase-hooks | hooks-mcp-setup | red-team-advisor |
| 9 | 최종 검증 | phase-validate | final-validation | red-team-advisor |

> Phase 2.5는 옵션이다. Phase 1-2의 Escalation(`[ASK] 핵심 도메인 식별`)에 대한 사용자 답변이 "해당 없음"/공백이거나 초기 발화에 "--fast"/"빠르게"가 있으면 소환하지 않고 Phase 3로 직행한다.

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
| 2 | `.claude/settings.json` | 1-2 (기본), 7-8 (훅/MCP 추가) |
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

하네스 수정/기능 추가가 필요하면: `/harness-architect:harness-setup {대상경로}` 재실행
도움말: `/harness-architect:help`
```

조건부 출력:
- 에이전트 파일(`.claude/agents/*.md`)이 생성된 경우에만 3번 항목(Agent 소환 패턴)을 포함합니다.
- 스킬 파일(`.claude/skills/*/SKILL.md`)이 생성된 경우에만 2번 항목을 포함합니다.
- 훅 파일이 생성된 경우에만 4번 항목을 포함합니다.

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

AskUserQuestion으로 대상 프로젝트 경로와 핵심 인터뷰 질문(이름/유형/팀 규모)을 묶어 받으세요.
AskUserQuestion 완료 직후, 결정된 트랙에 따라 아래 텍스트를 출력하세요:

- Fast Track 선택 또는 "빠르게"/"--fast" 키워드: `"Fast Track으로 진행합니다. 예상 소요: 10–15분."`
- 에이전트 파이프라인 프로젝트: `"에이전트 파이프라인 경로로 진행합니다. 예상 소요: 30–40분."`
- 그 외 표준 경로: `"표준 경로로 진행합니다. 예상 소요: 20–45분 (프로젝트 복잡도에 따라)."`

### Phase 0 성능 수준 옵션 description 기준

AskUserQuestion으로 성능 수준을 물을 때 options의 description 필드:
- 경제형: "Haiku 위주. 빠르고 저렴 (Opus 대비 약 1/15 비용). 단순 프로젝트·빠른 프로토타입에 적합."
- 균형형 (권장): "Sonnet 중심, 복잡 설계 판단만 Opus 사용. 대부분 프로젝트에 최적."
- 고성능형: "Opus 중심. 균형형 대비 약 5배 비용. 복잡한 에이전트 아키텍처 설계에 적합."

### 인자로 경로를 받은 경우 (`$ARGUMENTS`)

사용자가 슬래시 커맨드 뒤에 경로를 붙여 호출한 경우(예: `/harness-architect:harness-setup /path/to/project`), 그 인자를 **`$ARGUMENTS`** 로 전달받습니다. 이때는 Phase 0 AskUserQuestion 중 "경로" 항목을 **생략**하고, 나머지 인터뷰 질문(프로젝트 이름·유형·솔로/팀)만 묶어 1회 AskUserQuestion으로 받습니다.

- `$ARGUMENTS` 가 비어있는 경우: 기존 방식대로 경로를 AskUserQuestion 한 질문에 포함.
- `$ARGUMENTS` 가 유효 디렉터리가 아닌 경우: 사용자에게 경로를 다시 요청하며 입력값을 그대로 에러 메시지에 포함해 제시.
- 경로에 공백·한글·특수문자가 있을 수 있으므로 절대 경로로 정규화한 후 `TARGET_PROJECT_ROOT` 환경변수로 export.

이 경로는 사용자가 터미널 파일 탐색기로 이동하지 않고도 빠르게 흐름에 들어올 수 있게 해줍니다.
