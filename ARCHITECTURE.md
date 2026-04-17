# Architecture

`harness-architect`의 설계 철학과 내부 구조 상세. 사용법은 [README.md](./README.md)를 보세요.

## 1. 설계 원칙 (5가지)

1. **AskUserQuestion은 Orchestrator 전용** — 서브에이전트는 불확실 사항을 산출물의 `Escalations` 섹션에 기록하고, Orchestrator(메인 세션)가 취합하여 일괄 처리합니다.
2. **암묵적 합의 금지** — 모든 설정값·설계 결정은 명시적 사용자 답변 또는 스캔 결과 확인을 거쳐야 합니다.
3. **Target Project Guardrail** — 대상 프로젝트 작업 중에는 플러그인 자체 파일을 수정하지 않습니다. `ownership-guard.sh` 훅이 `PreToolUse(Write|Edit)`에서 강제합니다.
4. **No Meta-Leakage** — 생성 파일에 이 플러그인의 행동 규칙이나 Claude Code 아키텍처 설명을 포함하지 않습니다. `meta-leakage-guard.md` + `checklists/meta-leakage-keywords.md`가 검증합니다.
5. **Playbook 직접 실행 금지** — 메인 세션은 `/slash-command`로 방법론을 직접 실행하지 않습니다. 반드시 `Agent` 도구로 서브에이전트(opus)를 소환하고, 서브에이전트가 `playbooks/*.md`를 Read하여 실행합니다.

금지 패턴:
```
Skill(skill: "fresh-setup")
```

필수 패턴:
```
Agent(
  subagent_type: "phase-setup",
  description: "Phase 1-2: scan + interview",
  prompt: "Target project: {path}, Artifacts: {path}/docs/{request-name}/"
)
```

## 2. Agent-Playbook 분리 (WHO / HOW)

에이전트 프로젝트에서는 **정체성(WHO)과 능력(HOW)을 분리**합니다.

| 분리축 | 파일 | 크기 | 역할 |
|---|---|---|---|
| WHO | `.claude/agents/*.md` | lean ~25줄 | 에이전트 페르소나·원칙 (subagent_type 자동 소환) |
| HOW | `playbooks/*.md` | detailed ~80-300줄 | 방법론·도구·템플릿 (에이전트가 Read로 로드) |

### 왜 `playbooks/`를 비표준 경로에 두는가

Claude Code는 `.claude/skills/`·`commands/` 아래 파일을 자동 디스커버리하여 메인 세션의 `Skill` 도구로 노출합니다. 방법론이 이곳에 있으면 메인 세션이 서브에이전트 소환을 **우회**하여 직접 실행할 수 있고, 이는 위 원칙 5를 깹니다.

`playbooks/`는 자동 디스커버리 대상이 아니므로 메인 세션의 도구 목록에 노출되지 않습니다. 에이전트 정의에 명시적으로 `${CLAUDE_PLUGIN_ROOT}/playbooks/{name}.md`를 Read하도록 기재해, 서브에이전트 컨텍스트에서만 방법론이 로딩됩니다.

이 분리는 "방법론이 길어져 주 오케스트레이션의 컨텍스트를 잡아먹는 문제"와 "메인 세션이 직접 실행해 의도된 가드레일(Escalation, Red-team, Phase Gate)을 건너뛰는 문제"를 동시에 방지합니다.

## 3. 플러그인 구조 (디렉터리 맵)

```
harness-architect/
├── .claude-plugin/
│   ├── plugin.json              ← manifest (name, version, component paths)
│   └── marketplace.json         ← self-hosted single-plugin marketplace
├── .claude/
│   ├── agents/*.md              ← 8 — phase workers + red-team advisor (WHO)
│   ├── rules/*.md               ← 4 — always-apply orchestrator rules
│   ├── hooks/
│   │   ├── hooks.json           ← plugin hook declarations (PreToolUse/PostToolUse)
│   │   ├── ownership-guard.sh   ← write-scope guard
│   │   └── syntax-check.sh      ← JSON/YAML validation
│   ├── templates/
│   │   ├── common/              ← shared rule templates
│   │   └── workflows/strict-coding-6step/
│   └── settings.json            ← developer-facing permissions/deny (not shipped to user session)
├── commands/
│   └── harness-setup.md         ← slash command entry (/harness-setup)
├── playbooks/*.md               ← 11 — methodology (HOW, plugin-internal only)
├── knowledge/*.md               ← 14 — Claude Code documentation commentary
├── checklists/*.md              ← 3 — validation / security-audit / meta-leakage-keywords
├── CLAUDE.md                    ← developer-facing project guide
├── README.md / README_EN.md     ← user-facing entry
├── ARCHITECTURE.md              ← this file
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE                      ← Apache-2.0
```

### `${CLAUDE_PLUGIN_ROOT}` 경로 치환

Claude Code는 플러그인 설치 시 파일을 `~/.claude/plugins/cache/…`로 복사합니다. 에이전트·커맨드·훅 내부에 하드코딩된 상대 경로는 설치 후 깨지므로, 모든 플러그인 내부 참조는 `${CLAUDE_PLUGIN_ROOT}` 변수로 작성합니다. 공식 스펙상 이 변수는 **agent content · command content · hook commands · MCP/LSP config** 안에서 inline 치환됩니다.

현 구조에서:
- 에이전트 정의: `${CLAUDE_PLUGIN_ROOT}/playbooks/*.md`, `${CLAUDE_PLUGIN_ROOT}/knowledge/`, `${CLAUDE_PLUGIN_ROOT}/checklists/`
- `hooks.json`: `bash ${CLAUDE_PLUGIN_ROOT}/.claude/hooks/ownership-guard.sh`
- `commands/harness-setup.md`: `${CLAUDE_PLUGIN_ROOT}/.claude/rules/*.md` 로드 지시

## 4. 9-Phase 오케스트레이션

### 4.1 Phase 역할

| Phase | 내용 | 담당 에이전트 | 플레이북 |
|-------|------|---------------|----------|
| 0 | 경로 수집 + 요청명 생성 + 재개 감지 | (Orchestrator) | — |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | phase-setup | fresh-setup / cursor-migration / harness-audit |
| 3 | 워크플로우 설계 (작업 단계 시퀀스) | phase-workflow | workflow-design |
| 4 | 파이프라인 설계 (스텝별 실행 체인) | phase-pipeline | pipeline-design |
| 5 | 에이전트 팀 편성 (Teams/Agent/SendMessage) | phase-team | agent-team |
| 6 | SKILL/playbook 작성 | phase-skills | skill-forge |
| 7-8 | 훅/MCP 설치 | phase-hooks | hooks-mcp-setup |
| 9 | 최종 검증 (문법·일관성·메타누수) | phase-validate | final-validation |
| 매 Phase | 독립 비판 리뷰 | red-team-advisor | design-review |

### 4.2 Phase Gate

다음 Phase 시작 전 Orchestrator가 필수 선행 산출물의 존재를 확인합니다. 누락 시 이전 Phase 에이전트를 재소환하며, 사용자 요청으로 "Phase N으로 바로 가자"를 해도 누락된 Phase를 먼저 수행합니다.

| 시작 Phase | 필수 선행 산출물 |
|-------------|------------------|
| 1-2 | `00-target-path.md` |
| 3   | `01-discovery-answers.md` |
| 4   | `02-workflow-design.md` |
| 5   | `03-pipeline-design.md` |
| 6   | `04-agent-team.md` (에이전트 프로젝트일 때) |
| 7-8 | `05-skill-specs.md` |
| 9   | `06-hooks-mcp.md` |

### 4.3 Fast Track / Fast-Forward / 복잡도 게이트

- **Fast Track**: 사용자가 "빠르게"를 요청하면 phase-setup이 3개 질문 · 10분 완료 모드로 동작 (추천 기본값 사용, 고급 분기 생략).
- **Fast-Forward**: 에이전트 프로젝트 감지 시 Phase 3-5를 통합 실행 (워크플로우·파이프라인·팀을 한 번에 설계하고, 통합 후 Advisor 1회).
- **복잡도 게이트**: 단순 프로젝트(솔로 + 표준 웹앱/CLI)는 Phase 1-2, 7-8, 9에서 Advisor 경량 실행 (NOTE만 수집). 복잡 프로젝트는 전체 검토.

## 5. 상태 전달 (Stateful Orchestration)

Phase 간 상태는 **대상 프로젝트의 `docs/{요청명}/`에 파일로 저장**됩니다.

```
target-project/
└── docs/myapp-setup/
    ├── 00-target-path.md         ← Phase 0
    ├── 01-discovery-answers.md   ← Phase 1-2
    ├── 02-workflow-design.md     ← Phase 3
    ├── 03-pipeline-design.md     ← Phase 4
    ├── 04-agent-team.md          ← Phase 5
    ├── 05-skill-specs.md         ← Phase 6
    ├── 06-hooks-mcp.md           ← Phase 7-8
    └── 07-validation-report.md   ← Phase 9
```

각 파일에는 "Context for Next Phase" 섹션이 있어, 다음 에이전트가 이 파일만 Read해도 필요한 구조화 컨텍스트를 확보합니다. Orchestrator는 각 Phase의 Summary(~200 단어)만 다음 에이전트 프롬프트에 포함시켜, 메인 세션 컨텍스트를 경량으로 유지합니다.

### 중단/재개

세션 시작 시 Orchestrator가 대상 프로젝트의 `docs/` 하위에 기존 작업 폴더가 있는지 확인하고, 있으면 "이전 작업 발견 (Phase N까지 완료). 계속 / 새로 시작?" 질문. "계속"을 선택하면 마지막 완료 Phase 다음부터 재개.

## 6. Escalation 시스템 (BLOCK / ASK / NOTE)

서브에이전트는 `AskUserQuestion`을 사용할 수 없습니다. 불확실 사항은 산출물의 `Escalations` 섹션에 구조화하여 기록하고, Orchestrator가 취합해 일괄 처리합니다.

### 6.1 에이전트 반환 5-섹션 포맷

모든 Phase 에이전트는 완료 시 다음 5개 섹션을 반환합니다.

```
## Summary
핵심 결정사항 (~200 단어)

## Files Generated
- path/to/file1.md — description
- path/to/file2.json — description

## Context for Next Phase
구조화된 메타데이터 (다음 Phase에 필요한 필수 항목)

## Escalations
- [확인 필요] 설명 — 선택지 A vs B
- (없으면 "없음")

## Next Steps
다음 Phase 제안
```

### 6.2 Escalation 병합 프로토콜

1. **분류**: blocking / non-blocking / informational
2. **중복 제거**: 동일 주제의 반복 항목 병합 (최신 Phase 내용 우선)
3. **일괄 질문**: blocking은 즉시 AskUserQuestion (최대 4개씩). non-blocking은 Phase 전환 시점에 묶어서. informational은 텍스트 보고.
4. **검증**: Escalation 수가 0이면 에이전트가 모든 결정을 자체 처리한 것 → 핵심 결정 목록 재확인.

## 7. Red-team Advisor

매 Phase 산출물을 **사용자 목적 관점에서 비판적으로 검토**하는 독립 에이전트입니다.

- 빠진 스텝, 암묵적 가정, 정보 흐름 단절을 발견
- 결과를 **BLOCK / ASK / NOTE** 3분류로 보고
  - **BLOCK**: 다음 Phase 진행 불가, 즉시 사용자 확인 필요
  - **ASK**: Phase 전환 시 사용자에게 묶어 확인
  - **NOTE**: 텍스트 보고만 (질문 없음)

Orchestrator는 BLOCK/ASK 항목을 `AskUserQuestion`으로 사용자에게 일괄 제시하고, 피드백을 바탕으로 해당 Phase 에이전트를 재소환 가능합니다 (최대 2회 루프).

## 8. 보안·품질 훅

### 8.1 ownership-guard.sh (PreToolUse: Write|Edit)

쓰기 범위를 제한합니다.

- 대상 프로젝트 루트(`$TARGET_PROJECT_ROOT`) 외부에 대한 Write/Edit 차단
- 플러그인 캐시 내부(`${CLAUDE_PLUGIN_ROOT}`) 수정 차단 (사용자 명시 요청 제외)
- 경로 순회(`../`) 공격 탐지
- 심볼릭 링크 탈출 방지

### 8.2 syntax-check.sh (PostToolUse: Write|Edit)

생성물의 기본 유효성을 즉시 검증합니다.

- JSON 파일 (`settings.json`, `settings.local.json`, `plugin.json`, `marketplace.json`): Python `json.loads`로 parse
- `settings.json` 류: `"Bash(*)"` 같은 위험 허용 패턴 탐지
- YAML frontmatter 닫힘 검증 (`---` 짝 매칭)
- 비밀값 패턴 탐지 (`sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer `)

## 9. Knowledge Base

`knowledge/00~13-*.md`는 Claude Code 공식 문서(https://docs.claude.com/en/docs/claude-code)를 기반으로 한 **파생 해설물**입니다. 각 파일 상단에 `Source:` 주석이 있어 원 섹션 매핑을 명시합니다. 서브에이전트는 필요 시 Read로 개별 파일을 온디맨드 로딩합니다.

주요 섹션:
- `00-overview` / `01-scope-hierarchy` — Context vs Config 이원 분리, 4-Tier Scope
- `02-composition-rules` / `03-file-reference` — 파일 우선순위와 합성
- `04-memory-system` — 자동 메모리 저장 구조
- `05-skills-system` / `06-hooks-system` — 스킬·훅 설계
- `07-cursor-migration` — Cursor → Claude Code 전환
- `08-session-lifecycle` / `09-reference-pipeline` — 세션·참조 흐름
- `10-agent-design` / `12-teams-agents` — 서브에이전트·팀
- `11-anti-patterns` — 피해야 할 패턴
- `13-strict-coding-workflow` — 복잡 코딩 프로젝트용 6단계 프리셋

## 10. 확장 방향 (로드맵 힌트)

- 플러그인 자체의 스모크 테스트 시나리오 및 `examples/` 확장
- Anthropic 공식 마켓플레이스 제출
- 영어 문서화 완성도 강화
- 추가 프리셋 (데이터 파이프라인, 콘텐츠 자동화 등)

상세는 [CHANGELOG.md](./CHANGELOG.md) 와 GitHub Issues/Discussions를 참조하세요.
