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

| 커맨드 | 설명 |
|--------|------|
| `/harness-architect:harness-setup [경로]` | 9-Phase 하네스 구축 시작 (메인 진입점) |
| `/harness-architect:help` | 이 사용법 안내 |

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
- **경로 오류** → 절대 경로 필수. 공백·한글 경로도 지원
- **플러그인 자체 수정** → `claude --plugin-dir .` 로 개발 모드 진입 (기여자 전용, `CLAUDE.md` 참조)

---

## 🔗 참고

- 레포지토리: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
- 설계 문서: `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- 라이선스: Apache-2.0
