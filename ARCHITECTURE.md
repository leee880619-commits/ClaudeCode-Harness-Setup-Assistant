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
│   ├── agents/*.md              ← 14 — phase workers + red-team advisor + ops-auditor + security-auditor + fit-auditor + harness-auditor (WHO)
│   ├── rules/*.md               ← 4 — always-apply orchestrator rules
│   ├── hooks/
│   │   ├── hooks.json           ← plugin hook declarations (PreToolUse/PostToolUse)
│   │   ├── ownership-guard.sh   ← write-scope guard
│   │   └── syntax-check.sh      ← JSON/YAML validation
│   ├── templates/
│   │   ├── common/              ← shared rule templates
│   │   └── workflows/strict-coding-6step/
│   └── settings.json            ← developer-facing permissions/deny (not shipped to user session)
├── commands/                    ← 6 slash commands
│   ├── harness-setup.md         ← 주요 진입: /harness-architect:harness-setup (신규 하네스 구축)
│   ├── audit.md                 ← 주요 진입: /harness-architect:audit (기존 하네스 통합 감사, v0.9.0~)
│   ├── harness-audit.md         ← 개별: 구성 정합성만 (v0.9.0~)
│   ├── ops-audit.md             ← 개별: 런타임 부채만
│   ├── fit-audit.md             ← 개별: 프로젝트 적합성만 (v0.9.0~)
│   └── help.md                  ← 정적 사용법 안내
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
| **L** | **경량 통합 설계 (워크플로우·에이전트·스킬·훅 후보) — 경량 트랙 전용** | **phase-setup-lite** | **setup-lite** |
| 2.5 | 도메인 리서치 (옵션, 큐레이션 KB + 라이브 검색) | phase-domain-research | domain-research |
| 3 | 워크플로우 설계 (작업 단계 시퀀스) | phase-workflow | workflow-design |
| 4 | 파이프라인 설계 (스텝별 실행 체인) | phase-pipeline | pipeline-design |
| 5 | 에이전트 팀 편성 (Teams/Agent/SendMessage) | phase-team | agent-team |
| 6 | SKILL/playbook 작성 | phase-skills | skill-forge |
| 7-8 | 훅/MCP 설치 | phase-hooks | hooks-mcp-setup |
| 9 | 최종 검증 (문법·일관성·메타누수) | phase-validate | final-validation |
| 9 (보조) | Dim 6 패턴 매칭 전용 보조 감사 (Haiku 저비용) | security-auditor | — (에이전트 정의 내장) |
| 매 Phase | 독립 비판 리뷰 | red-team-advisor | design-review |
| 사후 감사 통합 (v0.9.0~) | 기존 하네스 통합 감사 (`/harness-architect:audit`) — harness-auditor + ops-auditor + fit-auditor 병렬 소환 후 통합 보고서 조립 | (Orchestrator) | — (커맨드 내 규약 + 3개 auditor 플레이북) |
| 사후 감사 개별 (v0.9.0~) | 구성 정합성 단독 (`/harness-architect:harness-audit`) | harness-auditor | harness-audit |
| 사후 감사 개별 | 런타임 부채 단독 (`/harness-architect:ops-audit`) | ops-auditor | ops-audit |
| 사후 감사 개별 (v0.9.0~) | 프로젝트 적합성·드리프트 단독 (`/harness-architect:fit-audit`) | fit-auditor | fit-audit |

> Phase 2.5는 Phase 1-2의 도메인 Escalation 답변이 "해당 없음"/공백/Fast Track이면 소환되지 않는다. 산출물 파일은 `docs/{요청명}/02b-domain-research.md` (기존 `02~07` 번호 체계를 보존).

### 4.2 Phase Gate

다음 Phase 시작 전 Orchestrator가 **파일 존재 + 필수 섹션 헤더의 정규식 매칭**을 함께 확인합니다. 부분 파일·섹션 누락 시 이전 Phase 에이전트를 재소환하며, 사용자 요청으로 "Phase N으로 바로 가자"를 해도 누락된 Phase를 먼저 수행합니다.

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

\* 공통 5섹션: `^## Summary$`, `^## Files Generated$`, `^## Context for Next Phase$`, `^## Escalations$`, `^## Next Steps$`
\*\* Phase 9 전용 3섹션: `^## File Inventory$`, `^## Security Audit$`, `^## Simulation Trace$`

#### CLAUDE.md 단일 소유자 원칙 (Single-Owner Rule)

대상 프로젝트의 `CLAUDE.md` **본문**은 **Phase 1-2(`phase-setup`)만 작성**합니다. 후속 Phase 3-6은 자신의 산출물 파일을 `@import docs/{요청명}/NN-*.md` 링크로 **추가**할 수 있을 뿐, 본문 재작성·섹션 덮어쓰기는 금지됩니다. 여러 Phase의 경쟁 수정으로 문체·용어가 충돌하는 문제를 구조적으로 차단합니다.

- **적용 시점**: 신규 `fresh-setup` 으로 생성되는 하네스에만 적용. 기존 배포 하네스를 `harness-audit` 로 재진입하는 경우 자동 재작성하지 않고, "단일 소유자 원칙으로 재구성할지"를 Escalation으로 확인받습니다.
- 위반 시도는 `ownership-guard` 훅 + `final-validation` Step 3 일관성 검증에서 잡힙니다.

### 4.3 Fast Track / Fast-Forward / 복잡도 게이트

- **Fast Track**: 사용자가 "빠르게"를 요청하면 phase-setup이 3개 질문 · 10분 완료 모드로 동작 (추천 기본값 사용, 고급 분기 생략).
- **Fast-Forward**: 에이전트 프로젝트 감지 시 Phase 3-5를 통합 실행 (워크플로우·파이프라인·팀을 한 번에 설계하고, 통합 후 Advisor 1회).
- **경량 트랙 (Lightweight Track)**: 8개 AND 조건 전체 충족 시에만 경량 트랙 — (1) 솔로 (2) 웹앱/CLI (3) 비에이전트 (4) 에이전트 신호 없음 (5) Strict Coding ASK 없음 (6) 소스 파일 ≤100개·최대 깊이 ≤5 (7) 배포 단순(환경 파일 1종·CI ≤1개) (8) 단일 서비스 — 조건 판별을 **Phase 1-2 완료 직후** 오케스트레이터가 스캔 결과를 기반으로 수행. 조건 충족 시 Phase 3-6을 단일 `phase-setup-lite` 에이전트(플레이북: `playbooks/setup-lite.md`)로 대체. 예상 소요 25~35분, 약 8~10회 LLM 호출. 풀 트랙(18회+, 60분+) 대비 절반 이하. 경량 트랙 완료 후 풀 트랙으로 업그레이드 가능 (`00-target-path.md`의 `track: lightweight` → Phase 3부터 재진입). 보안 가드(Dim 6)와 파이프라인 리뷰 게이트(Dim 12)는 풀 트랙과 동일하게 적용.
- **복잡도 게이트**: `track: lightweight`로 분류된 프로젝트 (8개 판별 조건 모두 충족)인 경우 Phase 1-2, 2.5, 7-8, 9에서 Advisor 경량 실행 (NOTE만 수집). 복잡 프로젝트는 전체 검토. **단, 보안 항목(Advisor Dimension 6 / `final-validation` Step 5)과 파이프라인 리뷰 게이트(Dimension 12)는 게이트와 무관하게 항상 전체 실행**합니다 — `Bash(*)`, 비밀값, 리뷰 누락 등은 단순 프로젝트·경량 트랙에서도 치명적이므로 경량화 대상이 아닙니다.

## 5. 상태 전달 (Stateful Orchestration)

Phase 간 상태는 **대상 프로젝트의 `docs/{요청명}/`에 파일로 저장**됩니다.

```
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

각 파일에는 "Context for Next Phase" 섹션이 있어, 다음 에이전트가 이 파일만 Read해도 필요한 구조화 컨텍스트를 확보합니다. Orchestrator는 각 Phase의 Summary(~200 단어)만 다음 에이전트 프롬프트에 포함시켜, 메인 세션 컨텍스트를 경량으로 유지합니다.

#### Single Source of Truth

Summary와 산출물 파일 내용이 불일치하면 **산출물 파일이 source of truth**입니다. Summary는 다음 에이전트 프롬프트용 힌트일 뿐이며 정보 손실을 전제합니다. Orchestrator는 Phase 전환 직전 파일의 `## Context for Next Phase` 섹션을 재검증하고, 모순 발견 시 해당 Phase 에이전트를 재소환해 "파일 기준 재작성"을 지시합니다.

#### 기각된 대안 (Rejected Alternatives)

200단어 Summary는 채택된 결정만 담으므로 후속 Phase가 "왜 그 경로를 안 갔는지"를 모릅니다. 모든 Phase의 `## Context for Next Phase` 에는 다음 하위 항목이 **필수**입니다:

```
### 기각된 대안 (Rejected Alternatives)
- {대안 A}: 기각 이유 — {근거}
- {대안 B}: 기각 이유 — {근거}
```

이로써 후속 Phase가 이미 기각된 대안을 다시 제안하거나 채택된 결정과 충돌하는 설계를 펼치는 것을 방지합니다.

### 중단/재개

세션 시작 시 Orchestrator가 대상 프로젝트의 `docs/` 하위에 기존 작업 폴더가 있는지 확인합니다. **여러 폴더가 있으면 AskUserQuestion으로 어느 것을 재개할지 선택**하게 합니다.

#### 산출물 frontmatter

각 Phase 완료 시 산출물 파일 최상단에 **YAML frontmatter**가 기록됩니다 (HTML 주석은 역호환 fallback):

```yaml
---
phase: 3
completed: 2026-04-17T14:32:00Z
status: done | in_progress | manual_override
advisor_status: pass | block | ask | note | manual_override
---
```

재개 시 Orchestrator는 이 필드를 재개 판단의 단일 소스로 사용합니다.

#### 수정 감지 + 하류 Phase 영향 평가

각 파일의 `mtime` > `completed` 면 "마지막 완료 이후 편집됨"으로 간주하여 해당 Phase Advisor를 재실행 대상에 포함합니다. 추가로 **편집된 Phase의 번호보다 큰 모든 하류 Phase**도 "상류 전제 변경" 상태로 표시해 사용자에게 "하류 산출물 유지 / 해당 Phase부터 재실행"을 AskUserQuestion으로 묻습니다 — 상류 편집이 하류 설계에 구조적 영향을 주는 경우를 놓치지 않기 위함입니다.

#### 비표준 파일명 처리

사용자가 실험적으로 만든 파일(예: `02-workflow-design-v2.md`)이나 에이전트가 다른 이름으로 저장한 파일은 권위 있는 산출물로 취급하지 않습니다. 정규식 `^[0-9]{2}[a-z]?-[a-z-]+\.md$` 로 엄격 매칭된 파일만 Phase 산출물로 인정하며, 비표준 파일 발견 시 "무시 / 편집본으로 간주 / 정리" 를 AskUserQuestion으로 묻습니다. frontmatter가 없는 구형 파일은 "상태 불명"으로 분류해 사용자에게 확인받습니다.

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
3. **일괄 질문**: blocking은 즉시 AskUserQuestion (최대 4개씩). non-blocking은 **다음 Phase의 Advisor 리뷰 종료 직후까지만** 묶어서 AskUserQuestion — 2개 이상 Phase를 건너뛰며 보류 금지 (맥락 손실 방지). informational은 텍스트 보고.
4. **검증 — AskUserQuestion 우회 감지**: Escalation 수가 0인데 산출물에 **사용자 확인 없는 결정 흔적**이 있으면(예: 대화 흐름에 "사용자 답변 반영"이라고 쓰여있지만 Orchestrator가 AUQ를 보낸 기록이 없음) 서브에이전트의 AUQ 직접 호출을 의심하여 `[재확인]` 으로 AUQ에 올립니다.

## 7. Red-team Advisor

매 Phase 산출물을 **사용자 목적 관점에서 비판적으로 검토**하는 독립 에이전트입니다.

- 빠진 스텝, 암묵적 가정, 정보 흐름 단절을 발견
- 결과를 **BLOCK / ASK / NOTE** 3분류로 보고 + 각 항목에 `[Dim N]` 태그
  - **BLOCK**: 다음 Phase 진행 불가, 즉시 사용자 확인 필요
  - **ASK**: Phase 전환 시 사용자에게 묶어 확인
  - **NOTE**: 텍스트 보고만 (질문 없음)

### 7.1 자문 Dimensions (10개)

| Dim | 주제 | 복잡도 게이트 |
|-----|------|--------------|
| 1 | 목적·수단 정합성 (WHY → WHAT → HOW) | 게이트 적용 |
| 2 | 정보 흐름 완전성 | 게이트 적용 |
| 3 | 암묵적 가정 식별 | 게이트 적용 |
| 4 | 실행 가능성 — 첫 실패 지점 | 게이트 적용 |
| 5 | 사용자 경험 | 게이트 적용 |
| **6** | **보안 권한 적절성** (`permissions.allow` 과잉 / 비밀값 / 필수 `deny`) | **항상 전체 실행** |
| 7 | 타깃 프로젝트 특이성 (스캔 결과와 설계 정합) | 게이트 적용 |
| 8 | 에이전트 소유권 충돌 (`allowed_dirs` 겹침, CLAUDE.md 경쟁 수정) | 게이트 적용 |
| 9 | 미기록 결정 감지 (Escalations 없음인데 결정 흔적) | 게이트 적용 |
| 10 | 도메인 리서치 정합성 (Phase 2.5 존재 시) | 게이트 적용 |
| 11 | 모델 배정 드리프트 및 복잡도 미스매치 | Model Confirmation Gate 전용 경량 Advisor에서만 활성 |
| 12 | 파이프라인 리뷰 게이트 준수 | **항상 전체 실행** (경량 트랙·단순 프로젝트 무관) |

반환 리포트의 각 항목 앞에는 Dimension 태그를 붙입니다:

```
### BLOCK
- [Dim 6] permissions.allow에 `Bash(*)` 포함 — 과잉 권한
- [Dim 8] phase-setup과 phase-workflow가 둘 다 CLAUDE.md 본문 수정 → 단일 소유자 원칙 위배

### ASK
- [Dim 3] "주요 언어: Python"을 에이전트가 임의 결정. 사용자 확인 필요
```

### 7.2 BLOCK 루프 소진 후 경로

BLOCK이 있으면 Orchestrator는 `AskUserQuestion` 으로 사용자에게 일괄 제시하고 "반영해" 응답 시 해당 Phase 에이전트를 재소환합니다 (최대 2회 루프). **2회 소진 후에도 동일 BLOCK이 반환되는 교착 상태**에서는 다음 3개 선택지를 제시합니다:

1. **무시하고 진행** — BLOCK을 수용 불가 제약으로 간주하지 않음
2. **수동 개입** — 사용자가 산출물 파일을 직접 편집 후 "편집 완료" 응답. 산출물 frontmatter의 `status`가 `manual_override` 로 갱신
3. **해당 Phase 스킵** — Phase를 건너뛰고 제한된 맥락으로 진행

선택 결과는 해당 Phase 산출물의 `## Escalations` 에 `[MANUAL OVERRIDE]` 로 기록됩니다.

### 7.3 프롬프트 슬림화

Advisor 프롬프트는 "직전 Phase Summary만" 포함합니다 (누적 제거). 필요 시 Advisor가 `docs/{요청명}/` 의 이전 산출물을 직접 Read하여 상세 컨텍스트를 확보합니다. 이전에는 Phase 9에 이를수록 8개 Phase의 Summary를 누적 수신해 Advisor 자신의 컨텍스트가 압박받는 구조였습니다.

## 8. 보안·품질 훅

### 8.1 ownership-guard.sh (PreToolUse: Write|Edit)

쓰기 범위를 제한합니다.

- 대상 프로젝트 루트(`$TARGET_PROJECT_ROOT`) 외부에 대한 Write/Edit 차단
- 플러그인 캐시 내부(`${CLAUDE_PLUGIN_ROOT}`) 수정 차단 (사용자 명시 요청 제외)
- 경로 순회(`../`) 공격 탐지
- 심볼릭 링크 탈출 방지

#### Phase 0 설정 누락 감지 (Fail-Closed 강화)

TPR(`TARGET_PROJECT_ROOT`)이 비어 있는 상태에서 `docs/{요청명}/NN-*.md` 패턴 경로에 쓰려는 시도는 **exit 1 로 차단**됩니다. 이는 Phase 0에서 환경변수 설정을 빠뜨렸거나, 서브에이전트가 잘못된 경로로 쓰려는 상황을 조용히 허용하지 않기 위함입니다.

#### Contributor Mode (TPR 미설정 + 플러그인 범위 내 Write)

TPR이 비어있지만 쓰기 대상이 **플러그인 레포 자신**이면 기여자 편집 흐름으로 간주하여 **허용하되 stderr 감사 로그**를 남깁니다 (`ℹ️ [ownership-guard] TARGET_PROJECT_ROOT 미설정 — 플러그인 자체 편집(기여자 모드)으로 간주하여 허용`). 이는 `claude --plugin-dir .` 로 레포를 직접 수정하는 기여자 흐름을 깨지 않기 위한 절충입니다.

### 8.2 syntax-check.sh (PostToolUse: Write|Edit)

생성물의 기본 유효성을 즉시 검증합니다.

- JSON 파일 (`settings.json`, `settings.local.json`, `plugin.json`, `marketplace.json`): Python `json.loads`로 parse
- `settings.json` 류: `"Bash(*)"` 같은 위험 허용 패턴 탐지
- YAML frontmatter 닫힘 검증 (`---` 짝 매칭)
- 비밀값 패턴 탐지 (`sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer `)

### 8.3 scripts/validate-settings.sh (jq 기반 정적 검증)

Phase 9 `final-validation` Step 5 에서 자동 호출되며, 기여자/사용자가 로컬에서 수동 실행할 수도 있습니다. 인자로 스캔 루트를 받습니다.

- `permissions.allow` 에 `Bash(*)` / `Bash(sudo *)` / `Bash(rm -rf *)` / `Bash(git push --force *)` 존재 여부
- 필수 `deny` 누락 경고
- 비밀값 패턴 grep (`sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer `)
- `settings.local.json` 존재 시 `.gitignore` 포함 여부 확인

사용: `bash scripts/validate-settings.sh [PROJECT_ROOT]` (미지정 시 현재 디렉터리).

### 8.4 scripts/validate-meta-leakage.sh (메타 누수 정적 스캔)

Phase 9 `final-validation` Step 5 에서 자동 호출. 대상 프로젝트의 하네스 생성 파일(`CLAUDE.md`, `.claude/rules`, `.claude/skills`, `.claude/agents`, `playbooks/`)에서 이 플러그인의 메타 용어(한국어 변형·띄어쓰기 변형 포함)와 정규식 패턴을 스캔합니다.

- **주의**: 이 스크립트를 플러그인 레포 자신에 대고 돌리면 자기참조 히트가 다수 발생 — 의도된 동작이며 regression 아님. 실제 감사는 외부 대상 프로젝트 루트에만.
- 사용: `bash scripts/validate-meta-leakage.sh [SCAN_ROOT]`

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
