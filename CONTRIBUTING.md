# Contributing to harness-architect

기여해 주셔서 감사합니다. 이 플러그인은 비개발자를 포함해 Claude Code 하네스 엔지니어링의 반복 세팅을 줄이기 위한 메타-도구입니다. 작은 기여도 환영합니다.

## 시작 전에

이슈를 먼저 만들어 주세요. 특히 아키텍처에 영향을 주는 변경(Phase 구조, Agent-Playbook 분리, Escalation 포맷, 훅 스펙)은 사전 논의 후 PR이 안전합니다.

## 개발 환경

```bash
git clone https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
cd ClaudeCode-Harness-Setup-Assistant
claude --plugin-dir .
```

`--plugin-dir` 플래그로 현재 디렉터리를 플러그인 루트로 로드하면 `${CLAUDE_PLUGIN_ROOT}`가 실제 경로로 치환되어 에이전트·훅·커맨드가 동작합니다.

## 변경 원칙

- **Agent-Playbook 분리 준수**: 새 방법론은 `playbooks/`에 두고 `.claude/skills/`·`commands/`에 자동 노출되지 않도록 합니다. 에이전트 정의(`.claude/agents/*.md`)에서 `${CLAUDE_PLUGIN_ROOT}/playbooks/...`로 Read를 지시하세요.
- **경로 변수 사용**: 플러그인 내부 참조는 반드시 `${CLAUDE_PLUGIN_ROOT}`를 사용하세요. 하드코딩 금지.
- **메타 누수 금지**: 플러그인이 생성하는 산출물(CLAUDE.md, rules 등)에 이 플러그인의 행동 규칙·Claude Code 아키텍처 설명을 포함시키지 마세요. `.claude/rules/meta-leakage-guard.md`와 `checklists/meta-leakage-keywords.md`를 확인하세요.
- **Phase 5-섹션 반환 포맷 유지**: 에이전트 반환은 Summary / Files Generated / Context for Next Phase / Escalations / Next Steps 순서를 유지합니다.
- **AskUserQuestion 소유권**: 서브에이전트는 AskUserQuestion을 직접 호출하지 않습니다. 불확실 사항은 Escalations로만 기록하세요.

## 파일별 스타일

| 파일 유형 | 체크포인트 |
|---|---|
| `.claude/agents/*.md` | frontmatter에 `name`, `description`, `model: opus` 필수. 본문 ~25줄 lean. |
| `playbooks/*.md` | frontmatter 없음 (자동 디스커버리 방지). 상단에 Purpose·Prerequisites·Steps 섹션 권장. |
| `.claude/rules/*.md` | 항상 적용되는 짧은 규칙만. 조건부 적용이 필요하면 에이전트 정의에 임베드하세요. |
| `knowledge/*.md` | 상단 `<!-- File: ... | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: N -->` 주석 유지. |
| `checklists/*.md` | 체크박스 리스트 형태. 각 항목은 에이전트가 기계적으로 확인 가능해야 함. |
| 훅 스크립트 (`.sh`) | shebang `#!/bin/bash`, `set -euo pipefail`, LF 개행. shellcheck 통과 권장. |
| JSON 파일 | 주석 금지, trailing comma 금지, UTF-8 (BOM 없음). |

## 테스트

CI가 준비되기 전까지는 로컬에서 다음을 확인해 주세요.

```bash
# 1) 훅 스크립트 문법
bash -n .claude/hooks/ownership-guard.sh
bash -n .claude/hooks/syntax-check.sh

# 2) JSON parse
python3 -c "import json; [json.load(open(p)) for p in ['.claude-plugin/plugin.json', '.claude-plugin/marketplace.json', '.claude/hooks/hooks.json', '.claude/settings.json']]"

# 3) YAML frontmatter 닫힘 (agents/, playbooks/ 선택)
for f in .claude/agents/*.md; do
  head -n 20 "$f" | awk '/^---$/{c++} END{exit c!=2}'
done
```

## 커밋 / PR

- Conventional Commits 권장: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
- 변경이 사용자 가시 영역에 영향을 주면 `CHANGELOG.md`의 `[Unreleased]` 섹션에 항목을 추가하세요.
- PR 설명에 다음을 포함하세요:
  1. 변경 이유 (어떤 문제/시나리오를 해결하는지)
  2. 영향 범위 (수정 파일, Phase 흐름 변화 여부)
  3. 수동 테스트 결과 또는 재현 절차

## 라이선스

기여한 코드는 프로젝트 라이선스인 [Apache-2.0](./LICENSE) 하에 배포됩니다.
