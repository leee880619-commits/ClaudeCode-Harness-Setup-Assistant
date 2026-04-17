# harness-architect

[![ci](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/leee880619-commits/ClaudeCode-Harness-Setup-Assistant?include_prereleases&sort=semver)](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases)
[![license](https://img.shields.io/github/license/leee880619-commits/ClaudeCode-Harness-Setup-Assistant)](./LICENSE)

> 프로젝트를 분석해 완벽한 Claude Code 하네스를 9단계로 구축하는 메타-도구 플러그인.

> 🌐 소개 페이지: [harness-architect 사용 가이드](https://leee880619-commits.github.io/ClaudeCode-Harness-Setup-Assistant/) · 📖 영어 버전: [README_EN.md](./README_EN.md) · 🧭 아키텍처 상세: [ARCHITECTURE.md](./ARCHITECTURE.md) · 📜 변경 이력: [CHANGELOG.md](./CHANGELOG.md)

## 배경 (Why this exists)

저는 개발자가 아닙니다. Claude Code와 **하네스 엔지니어링(harness engineering)**
— CLAUDE.md, settings, rules, agents, hooks, MCP를 조합해 Claude를 특정
프로젝트에 최적화하는 작업 — 을 접하면서, 매 프로젝트마다 똑같은 세팅 과정을
반복하느라 낭비되는 시간과 인지 부하가 너무 크다는 것을 느꼈습니다.

"어떤 규칙이 필요하지?", "권한을 어디까지 열어야 하지?", "훅은 뭘 걸어야 하지?",
"이 프로젝트는 에이전트 팀이 필요한가, 단일 스킬로 충분한가?" 매번 동일한 질문에
다시 답하고, 공식 문서를 다시 뒤지고, 지난 프로젝트의 실수를 반복합니다.

이 플러그인은 그 비효율을 줄이기 위해 만들어졌습니다. Claude Code **공식 문서**와,
여러 프로젝트에서 **실제로 잘 작동했던 패턴들**을 바탕으로, 프로젝트를 스캔하고
필요한 질문만 던진 뒤 하네스 전체를 단계적으로 구축합니다.

## 언제 쓰면 좋은가

- **처음부터 제대로** 된 Claude Code 하네스를 구축하고 싶을 때
- **매 프로젝트 세팅**에 드는 인지 부하를 줄이고 싶을 때
- 단순한 에이전트 팀이 아닌 **풀 하네스**(CLAUDE.md + settings + rules + agents + playbooks + hooks + MCP)가 필요할 때
- 설계 중간에 **독립적 비판 리뷰**(red-team)가 필요한 복잡 프로젝트에 쓸 때

## revfactory/harness 와의 차이

| 항목 | harness-architect (본 플러그인) | [revfactory/harness](https://github.com/revfactory/harness) |
|------|---------------------------------|--------------------------|
| 범위 | 전체 하네스 (settings/rules/agents/playbooks/hooks/MCP) | 에이전트/스킬 팀 중심 |
| 입력 | 프로젝트 경로 스캔 + 대화식 인터뷰 | 사용자 서술식 요청 |
| 워크플로우 | 9-Phase 오케스트레이션 + Phase Gate + 재개 | 단일 대화 6단계 |
| 설계 리뷰 | Red-team Advisor (매 Phase 독립 비판) | 내장 없음 |
| 핵심 패턴 | Agent-Playbook 분리 (WHO/HOW), Pure Orchestrator | 사용자 주도 설계 |

**포지셔닝**: revfactory/harness는 에이전트/스킬 팀을 **빠르게** 만들고 싶을 때. harness-architect는 **한 번 제대로** 세팅해 두고 재개·검증 가능한 하네스를 원할 때.

## 설치

Claude Code 세션에서 슬래시 커맨드로 설치합니다.

```
# 1) 플러그인 마켓플레이스 등록 (한 번만)
/plugin marketplace add leee880619-commits/ClaudeCode-Harness-Setup-Assistant

# 2) 플러그인 설치
/plugin install harness-architect@harness-architect-marketplace
```

> 공식 Anthropic 마켓플레이스 제출은 진행 중입니다. 그 전까지는 위 GitHub-hosted 마켓플레이스 경로로 설치하세요.

### 개발자 설치 (이 레포에서 직접)

```bash
git clone https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
cd ClaudeCode-Harness-Setup-Assistant
claude --plugin-dir .
```

## 사용법

설치 후, 하네스를 만들 **대상 프로젝트에서** Claude Code 세션을 열고 슬래시 커맨드로 시작합니다.

```bash
cd /path/to/your/project
claude
```

세션 내에서:

```
/harness-architect:harness-setup
```

경로를 미리 정해놓았다면 **인자로 전달**할 수 있습니다. 이 경우 Phase 0의 "프로젝트 경로" 질문이 생략되어 바로 인터뷰로 진입합니다:

```
/harness-architect:harness-setup /path/to/your/project
```

오케스트레이터가 Phase 0부터 진행합니다. 필요한 의사결정(프로젝트 유형, 팀 여부, 훅 범위 등)은 `AskUserQuestion`으로 묶어 묻고, 설정 파일·에이전트·플레이북·훅을 단계별로 생성합니다.

세션이 중단되어도 `docs/{요청명}/`에 저장된 Phase 산출물로부터 자동 재개할 수 있습니다. 재개 시 이전 세션의 Advisor BLOCK·ASK 미해결 항목도 함께 복원해 묻습니다 — 상세는 [ARCHITECTURE.md §5](./ARCHITECTURE.md).

## 9-Phase 워크플로우 (요약)

| Phase | 내용 | 담당 에이전트 |
|-------|------|---------------|
| 0 | 대상 프로젝트 경로 수집 + 요청명 생성 | (Orchestrator) |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | `phase-setup` |
| 2.5 | 도메인 리서치 (옵션) | `phase-domain-research` |
| 3 | 워크플로우 설계 | `phase-workflow` |
| 4 | 파이프라인 설계 | `phase-pipeline` |
| 5 | 에이전트 팀 편성 | `phase-team` |
| 6 | SKILL/playbook 작성 | `phase-skills` |
| 7-8 | 훅/MCP 설치 | `phase-hooks` |
| 9 | 최종 검증 | `phase-validate` |
| 매 Phase | 독립 비판 리뷰 | `red-team-advisor` |

### Phase 1-2 경로 분기

- `fresh-setup`: 신규 프로젝트 하네스 구성
- `cursor-migration`: Cursor IDE 설정을 Claude Code로 변환
- `harness-audit`: 기존 Claude Code 설정 진단 및 개선

### Phase 2.5 — 도메인 리서치 (옵션)

프로젝트의 핵심 도메인(딥 리서치 / 웹사이트 제작 / 웹툰 제작 / 유튜브 콘텐츠 / 코드 리뷰 / 기술 문서 / 데이터 파이프라인 / 마케팅 캠페인 등)이 특정되면, Phase 1-2 Escalation에서 사용자가 도메인을 확인한 뒤 `phase-domain-research` 에이전트가 소환됩니다. 이 에이전트는 (1) `knowledge/domains/` 아래 **큐레이션 KB 8종**(5종 full + 3종 stub)과 (2) `WebSearch`/`WebFetch`로 도메인 업계의 표준 워크플로우·역할 분업·도구 스택·안티패턴을 수집해 `docs/{요청명}/02b-domain-research.md`에 저장합니다.

- 후속 Phase 3-6 playbook은 이 산출물이 있으면 **자동으로 Read**해 설계 시 도메인 레퍼런스를 인용합니다.
- 모든 외부 주장에 **출처 URL + 발췌일**이 강제되고, Advisor가 URL 샘플 검증까지 수행합니다.
- "해당 없음" / 공백 / `--fast` / "빠르게" 키워드면 Phase 2.5를 자동 스킵하고 Phase 3로 직행합니다.
- 라이브 검색 budget은 WebSearch 최대 6회 · WebFetch 최대 3회로 제한되며, 대상 프로젝트 식별 정보를 쿼리에 포함하지 않습니다(데이터 유출 방지).

### 복잡 코딩 프로젝트 프리셋

`.claude/templates/workflows/strict-coding-6step/`에 엄격한 6단계 코딩
워크플로우(연구 → 질문 초안 → 설계·레드팀 → 구현·계획 → 구현 → 화이트/블랙박스
QA)의 프리셋(에이전트 8 + 플레이북 8)이 포함되어 있어, 해당 유형의 프로젝트에
자동 복사됩니다.

설계 철학·구성·Escalation 프로토콜의 상세는 [ARCHITECTURE.md](./ARCHITECTURE.md)를 보세요.

## 가드레일

- **대상 프로젝트 작업 중**: 이 플러그인 자체 파일을 수정하지 않음 (`ownership-guard.sh` 훅이 `PreToolUse(Write|Edit)`로 차단)
- **보안**: `Bash(*)`, `sudo rm *` 등 위험 패턴은 플러그인 기본 설정에서 차단 권장
- **비밀값**: API 키·토큰은 `settings.local.json` (gitignored)으로 안내
- **메타 누수 방지**: 생성 파일이 이 플러그인 자체의 규칙이나 Claude Code 아키텍처 설명을 포함하지 않도록 `meta-leakage-guard` 규칙과 체크리스트로 검증

## 기여

이슈/PR 환영합니다. 시작하기 전에 [CONTRIBUTING.md](./CONTRIBUTING.md)를 읽어주세요.

## 개인정보 / 프라이버시

이 플러그인은 어떤 개인정보도 수집·전송하지 않습니다. 전문은 [PRIVACY.md](./PRIVACY.md).

## 라이선스

[Apache-2.0](./LICENSE) · Copyright © 2026 leee880619-commits

`knowledge/*.md`는 Claude Code 공식 문서(https://docs.claude.com/en/docs/claude-code)를 기반으로 한 파생 해설물입니다. 각 파일 상단의 `Source:` 주석이 원 섹션을 명시합니다.
