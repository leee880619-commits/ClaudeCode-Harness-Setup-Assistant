# Claude Code Project Architect

사용자의 프로젝트를 분석하여 완벽한 Claude Code 개발 인프라(하네스)를 구축하는 메타-도구.

## 배경 (Why this exists)

저는 개발자가 아닙니다. Claude Code와 **하네스 엔지니어링(harness engineering)**
— CLAUDE.md, settings, rules, agents, hooks, MCP를 조합해 Claude를 특정
프로젝트에 최적화하는 작업 — 을 접하면서, 매 프로젝트마다 똑같은 세팅 과정을
반복하느라 낭비되는 시간과 인지 부하가 너무 크다는 것을 느꼈습니다.

"어떤 규칙이 필요하지?", "권한을 어디까지 열어야 하지?", "훅은 뭘 걸어야 하지?",
"이 프로젝트는 에이전트 팀이 필요한가, 단일 스킬로 충분한가?" 매번 동일한 질문에
다시 답하고, 공식 문서를 다시 뒤지고, 지난 프로젝트의 실수를 반복합니다.

이 도구는 그 비효율을 줄이기 위해 만들어졌습니다. Claude Code **공식 문서**와,
개인적으로 여러 프로젝트에서 **실제로 잘 작동했던 패턴들**을 바탕으로,
프로젝트를 스캔하고 필요한 질문만 던진 뒤 하네스 전체를 단계적으로 구축합니다.

- **대상 사용자**: 비개발자를 포함해, 매 프로젝트 세팅에 드는 인지 부하를
  줄이고 Claude Code를 "제대로" 쓰고 싶은 사용자
- **기반**: Claude Code 공식 명세 + 개인적으로 검증된 패턴의 체계화
- **목표**: 프로젝트 유형을 감지하고, 꼭 필요한 의사결정만 사용자에게 묻고,
  나머지는 자동으로 하네스 파일을 생성

---

## 운영 모델: Orchestrator + Agent Team

이 도구는 **Pure Orchestrator + 풀 에이전트 팀** 모델로 작동합니다.

```
┌─────────────────────────────────────────────┐
│  Main Session (Orchestrator)                │
│  - Phase 전환 관리                           │
│  - AskUserQuestion 전담                      │
│  - 에이전트 결과 수신 + Escalations 처리      │
│  - 컨텍스트 경량 유지                         │
├─────────────────────────────────────────────┤
│  Agent(phase-setup)    → Phase 1-2          │
│  Agent(phase-workflow) → Phase 3            │
│  Agent(phase-pipeline) → Phase 4            │
│  Agent(phase-team)     → Phase 5            │
│  Agent(phase-skills)   → Phase 6            │
│  Agent(phase-hooks)    → Phase 7-8          │
│  Agent(phase-validate) → Phase 9            │
│  Agent(red-team-advisor) → 매 Phase 리뷰    │
└─────────────────────────────────────────────┘
```

**핵심 규칙:**
- AskUserQuestion은 Orchestrator(메인 세션)만 사용
- 서브에이전트가 불확실한 사항이 있으면 산출물의 `Escalations` 섹션에 기록
- Orchestrator가 Escalations를 취합하여 사용자에게 일괄 확인

### Agent-Playbook 분리 (WHO/HOW)

- **WHO** (`.claude/agents/*.md`): 에이전트 정체성·규칙 (lean ~25줄)
- **HOW** (`playbooks/*.md`): 방법론·절차 (에이전트가 Read하여 실행)

방법론을 `.claude/skills/`가 아닌 `playbooks/`에 두는 이유는 명확합니다.
Claude Code는 `.claude/skills/` 아래 파일을 자동 디스커버리하여 메인 세션의
Skill 도구로 노출시킵니다. 메인 세션이 이를 직접 실행하면 서브에이전트 소환을
우회하게 되므로, 자동 디스커버리가 되지 않는 `playbooks/`에 방법론을 둡니다.

## 작업 폴더 (State Passing)

Phase 간 산출물은 대상 프로젝트의 `docs/{요청명}/`에 파일로 저장됩니다.
다음 Phase의 에이전트는 이 파일을 Read하여 최소 컨텍스트만 로딩합니다.

```
대상 프로젝트/
└── docs/myapp-setup/
    ├── 00-target-path.md          ← Phase 0 산출물
    ├── 01-discovery-answers.md    ← Phase 1-2 산출물
    ├── 02-workflow-design.md      ← Phase 3 산출물
    ├── 03-pipeline-design.md      ← Phase 4 산출물
    └── ...
```

세션이 중단되어도 `docs/{요청명}/` 파일로부터 재개할 수 있습니다.

## 사용 방법

### 1. 이 폴더에서 Claude Code 실행

```bash
cd "ClaudeCode-Harness-Setup-Assistant"
claude
```

### 2. 대상 프로젝트 경로 입력

Orchestrator가 대상 프로젝트 경로를 물어봅니다:

```
/home/alice/projects/my-new-project
```

### 3. 자동 진행

Orchestrator가 Phase별 에이전트를 `Agent` 도구로 순차 소환하며, 필요한 질문만
사용자에게 `AskUserQuestion`으로 전달합니다. 사용자는 `/slash-command`를 직접
입력할 필요가 없습니다.

## 9-Phase 워크플로우

| Phase | 내용 | 담당 에이전트 | 플레이북 |
|-------|------|---------------|----------|
| 0 | 프로젝트 경로 수집 + 요청명 생성 | (Orchestrator) | — |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 생성 | `phase-setup` | `fresh-setup` / `cursor-migration` / `harness-audit` |
| 3 | 워크플로우 설계 | `phase-workflow` | `workflow-design` |
| 4 | 파이프라인 설계 | `phase-pipeline` | `pipeline-design` |
| 5 | 에이전트 팀 편성 | `phase-team` | `agent-team` |
| 6 | SKILL.md/플레이북 작성 | `phase-skills` | `skill-forge` |
| 7-8 | 훅 설계/설치 + MCP 제안 | `phase-hooks` | `hooks-mcp-setup` |
| 9 | 최종 검증 | `phase-validate` | `final-validation` |
| 매 Phase | 독립 비판 리뷰 | `red-team-advisor` | `design-review` |

### 지원 경로 (Phase 1-2 분기)

- **`fresh-setup`**: 신규 프로젝트 하네스 구성
- **`cursor-migration`**: Cursor IDE 설정을 Claude Code로 변환
- **`harness-audit`**: 기존 Claude Code 설정 진단 및 개선
- **`user-scope-init`**: `~/.claude/` 개인 전역 설정 초기화 (선택)

### 복잡 코딩 프로젝트 프리셋

`.claude/templates/workflows/strict-coding-6step/`에 엄격한 6단계 코딩
워크플로우(연구 → 질문 초안 → 설계·레드팀 → 구현·계획 → 구현 → 화이트/블랙박스
QA)의 프리셋(에이전트 8 + 플레이북 8)이 포함되어 있어, 해당 유형의 프로젝트에
자동 복사됩니다.

## 프로젝트 구조

```
.
├── CLAUDE.md                    ← 메타-도구 정체성 + 오케스트레이터 지침
├── README.md
├── .claude/
│   ├── settings.json            ← 권한, 환경변수, 훅
│   ├── agents/                  ← Phase 에이전트 정의 (WHO, 8개)
│   │   ├── phase-setup.md
│   │   ├── phase-workflow.md
│   │   ├── phase-pipeline.md
│   │   ├── phase-team.md
│   │   ├── phase-skills.md
│   │   ├── phase-hooks.md
│   │   ├── phase-validate.md
│   │   └── red-team-advisor.md
│   ├── rules/                   ← 항상 적용 규칙 (4개)
│   │   ├── meta-leakage-guard.md
│   │   ├── orchestrator-protocol.md
│   │   ├── output-quality.md
│   │   └── question-discipline.md
│   ├── hooks/                   ← 훅 스크립트
│   │   ├── ownership-guard.sh   ← 쓰기 범위 가드
│   │   └── syntax-check.sh      ← JSON/YAML 검증
│   └── templates/               ← 프리셋 템플릿
│       ├── common/rules/
│       └── workflows/strict-coding-6step/   ← 6단계 코딩 워크플로우 프리셋
├── playbooks/                   ← 방법론 (HOW, 11개, 에이전트 전용)
│   ├── fresh-setup.md
│   ├── cursor-migration.md
│   ├── harness-audit.md
│   ├── user-scope-init.md
│   ├── workflow-design.md
│   ├── pipeline-design.md
│   ├── agent-team.md
│   ├── skill-forge.md
│   ├── hooks-mcp-setup.md
│   ├── final-validation.md
│   └── design-review.md
├── knowledge/                   ← Claude Code 명세 (15개, ~6,300줄)
└── checklists/                  ← 검증 체크리스트 (3개)
```

## 가드레일

- **대상 프로젝트 작업 중**: 본 어시스턴트 워크스페이스 파일을 수정하지 않음
  (`ownership-guard.sh` 훅이 `PreToolUse(Write|Edit)`로 차단)
- **자기 개선 요청 시**: 사용자가 명시적으로 요청한 경우에만 본 레포 파일 수정 허용
- **보안**: `Bash(*)`, `sudo rm *` 등 위험 패턴은 자동 차단
- **비밀값**: API 키, 토큰은 `settings.local.json` (gitignored)으로 안내
- **메타 누수 방지**: 생성 파일이 이 도구 자체의 규칙이나 Claude Code 아키텍처
  설명을 포함하지 않도록 `meta-leakage-guard` 규칙과 체크리스트로 검증
