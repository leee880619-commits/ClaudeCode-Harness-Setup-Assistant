---
description: harness-architect 플러그인 사용법, 제공 커맨드, 9-Phase 흐름, 주요 옵션을 안내한다.
---

# harness-architect — 사용법

이 플러그인은 대상 프로젝트를 분석해 Claude Code 하네스(CLAUDE.md, settings, rules, agents, playbooks, hooks, MCP)를 **9-Phase 오케스트레이션**으로 구축합니다.

아래 내용을 사용자에게 **있는 그대로 출력**하세요. AskUserQuestion/Agent 소환 없이 정적 안내만 수행합니다.

---

## 🚀 빠른 시작

```
/harness-architect:harness-setup
/harness-architect:harness-setup /absolute/path/to/project
```

- 인자 없이 호출하면 Phase 0에서 대상 프로젝트 경로를 물어봅니다.
- 인자로 절대 경로를 주면 경로 질문을 생략하고 바로 인터뷰로 진입합니다.
- "빠르게" 또는 `--fast` 를 초기 발화에 포함하면 도메인 리서치(Phase 2.5)를 스킵합니다.

---

## 📋 제공 슬래시 커맨드

| 커맨드 | 역할 | 실행 시점 | 출력 등급 |
|--------|------|----------|----------|
| `/harness-architect:harness-setup [경로]` | **9-Phase 하네스 구축** (메인 진입점) | 신규 프로젝트 | BLOCK / ASK / NOTE |
| `/harness-architect:ops-audit [경로]` | **런타임 감사** — 세션 연속성·실패 복구·산출물 덮어쓰기·에이전트-스킬 이중 관리·크로스 구조 중복을 5개 Dimension으로 read-only 감사 | 기존 하네스 | RISK-HIGH / RISK-MED / RISK-LOW |
| `/harness-architect:help` | 이 사용법 안내 | — | — |

> **`ops-audit` 사용법**: `/harness-architect:harness-setup` 으로 구축한 하네스가 운영 중 실제로 문제를 일으키는지 사후 점검할 때 사용합니다. Phase 9 final-validation이 "빌드 중 구조가 올바른가"를 검증한다면, ops-audit은 "빌드 후 실제 실행 시 어디서 무너지는가"에 집중합니다. 파일을 수정하지 않고 RISK 등급 보고서만 텍스트로 제시합니다.

---

## 🔁 9-Phase 워크플로우

| Phase | 내용 | 산출물 |
|-------|------|--------|
| 0 | 경로 수집 + 요청명 생성 | `docs/{요청명}/00-target-path.md` |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | `01-discovery-answers.md`, `CLAUDE.md`, `settings.json`, `rules/` |
| 2.5 | (선택) 도메인 리서치 | `02b-domain-research.md` |
| 3 | 워크플로우 설계 | `02-workflow-design.md` |
| 4 | 파이프라인 설계 | `03-pipeline-design.md` |
| 5 | 에이전트 팀 편성 | `04-agent-team.md`, `.claude/agents/` |
| 6 | SKILL/Playbook 작성 | `05-skill-specs.md`, `.claude/skills/` |
| 7-8 | 훅/MCP 설치 | `06-hooks-mcp.md`, `.claude/hooks/` |
| 9 | 최종 검증 보고 | `07-validation-report.md` |

각 Phase 직후 **Red-team Advisor** 가 BLOCK/ASK/NOTE로 리뷰합니다.

---

## 🧭 주요 특징

- **Agent-Playbook 분리**: WHO(.claude/agents/) vs HOW(playbooks/)
- **Escalation 시스템**: 서브에이전트는 불확실성을 Escalations로 반환, 메인 세션이 AskUserQuestion으로 일괄 질문
- **Phase Gate**: 이전 Phase 산출물 없으면 다음 Phase 차단, 재개 지원
- **중단/재개**: `docs/{요청명}/` frontmatter로 언제든 재진입
- **Meta-Leakage Guard**: 생성물에 플러그인 자체 규칙이 새지 않도록 검증
- **경량 트랙 (Phase L)**: 8개 AND 조건 충족 시 Phase 3-6을 단일 에이전트가 25-35분에 처리. 단일 패스 설계이므로 세션 중단 시 재개 불가 — 처음부터 재실행
- **런타임/운영 가드** (신규): 대상 프로젝트가 에이전트 파이프라인 구조인 경우 Phase 3·4 산출물에 Session Recovery Protocol·Failure Recovery & Artifact Versioning 섹션 필수. Advisor Dim 13이 세션 연속성·실패 복구 종료 조건·에이전트-스킬 이중 관리·산출물 덮어쓰기·환경 이식성을 검증. 일반 웹앱/CLI 프로젝트는 스킵 (메타 누수 방지)
- **사후 감사** (신규): 빌드 후 운영 중 문제는 `/harness-architect:ops-audit` 이 5개 Dimension으로 read-only 점검. 경량 트랙 하네스는 `session_recovery: not_applicable` / `artifact_versioning: idempotent` 공식 선언으로 RISK-LOW 자동 분류

---

## 🔧 재개(Resume) 사용법

이미 작업 폴더(`<대상>/docs/{요청명}/`)가 있는 상태에서 `/harness-architect:harness-setup` 을 다시 실행하면:

1. 기존 작업 폴더 감지 → "계속 / 새로 시작?" 질문
2. 계속 선택 시 마지막 완료 Phase 다음부터 재개
3. 사용자가 산출물을 직접 편집한 경우 해당 Phase Advisor 재실행

---

## 📦 생성되는 대상 프로젝트 파일

```
<target>/
├─ CLAUDE.md
├─ CLAUDE.local.md
├─ .claude/
│  ├─ settings.json
│  ├─ settings.local.json
│  ├─ rules/*.md
│  ├─ agents/*.md          (에이전트 프로젝트일 때)
│  ├─ skills/*/SKILL.md
│  └─ hooks/*.sh
├─ playbooks/*.md           (에이전트 전용 방법론)
└─ docs/{요청명}/*.md       (Phase 산출물 + 상태)
```

---

## 🛟 문제 해결

- **Phase 진행이 막힘** → Advisor가 BLOCK 2회 반환 시 "무시 / 수동 개입 / 스킵" 선택지 제공
- **Phase 3·4 Dim 13 BLOCK 루프** → 에이전트 파이프라인 프로젝트에서 운영 가드 섹션(Session Recovery Protocol / Failure Recovery & Artifact Versioning) 누락 시 재실행 루프 발생. Phase당 +5~8분 추가 가능. 루프 한도 초과 시 사용자 선택지 제공
- **기존 하네스 운영 문제 점검** → `/harness-architect:ops-audit` 로 사후 감사 (read-only). 구성 진단이 필요하면 `harness-setup` 재실행
- **경로 오류** → 절대 경로 필수. 공백·한글 경로도 지원
- **플러그인 자체 수정** → `claude --plugin-dir .` 로 개발 모드 진입 (기여자 전용, `CLAUDE.md` 참조)

---

## 🔗 참고

- 레포지토리: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
- 설계 문서: `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- 라이선스: Apache-2.0
