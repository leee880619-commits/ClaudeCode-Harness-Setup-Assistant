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
bash -n scripts/validate-settings.sh
bash -n scripts/validate-meta-leakage.sh

# 2) JSON parse
python3 -c "import json; [json.load(open(p)) for p in ['.claude-plugin/plugin.json', '.claude-plugin/marketplace.json', '.claude/hooks/hooks.json', '.claude/settings.json']]"

# 3) YAML frontmatter 닫힘 (agents/, playbooks/ 선택)
for f in .claude/agents/*.md; do
  head -n 20 "$f" | awk '/^---$/{c++} END{exit c!=2}'
done

# 4) agents 파일명 ↔ frontmatter name 일치 (명명 규약)
for f in .claude/agents/phase-*.md .claude/agents/red-team-advisor.md; do
  stem=$(basename "$f" .md)
  declared=$(awk -F': *' '/^name:/{print $2; exit}' "$f" | tr -d '\r')
  [[ "$stem" == "$declared" ]] || { echo "명명 위반: $f → name=$declared"; exit 1; }
done

# 5) 정적 보안/메타누수 검증 (jq 필요)
bash scripts/validate-settings.sh .          # 이 레포 자신
bash scripts/validate-meta-leakage.sh .      # 이 레포 자신
```

`validate-settings.sh`, `validate-meta-leakage.sh` 는 기여자가 수동으로 실행하거나 대상 프로젝트에 설치된 하네스를 사후 감사할 때 사용합니다. 인자로 스캔 루트를 받을 수 있습니다 (`bash scripts/validate-meta-leakage.sh /path/to/target`).

> ⚠ `validate-meta-leakage.sh` 를 **이 레포 루트** 에 대고 돌리면 플러그인 내부 설명이 허용 문맥임에도 자기참조 히트가 다수 발생합니다. 이는 스크립트 동작 확인용이지 regression 이 아닙니다. 실제 감사는 **외부 대상 프로젝트 루트** 에 대해서만 수행하세요.

## Phase / 규칙 변경 체크리스트

Phase를 추가·제거하거나 오케스트레이터 규칙을 바꿀 때 아래 파일들이 **묶음으로 변경**되어야 합니다. 누락 시 런타임(`orchestrator-protocol.md`)과 기여자용 요약(`CLAUDE.md`) 간 드리프트가 발생합니다.

| 변경 유형 | 함께 수정해야 하는 파일 |
|-----------|-----------------------|
| Phase 추가/제거 | `.claude/agents/phase-{name}.md` / `playbooks/{name}.md` / `.claude/rules/orchestrator-protocol.md` (Phase-to-Agent 매핑 + Phase Gate + Context for Next Phase 테이블) / `commands/harness-setup.md` (마스터 워크플로우 테이블) / `CHANGELOG.md` / 필요 시 `CLAUDE.md` 요약 |
| 규칙 추가/제거 (`.claude/rules/*.md`) | `CLAUDE.md` 요약 섹션 / `commands/harness-setup.md` 참고 목록 / `CONTRIBUTING.md` 파일 유형 체크포인트 |
| 에이전트 Rules 변경 | 해당 `.claude/agents/phase-*.md` / `orchestrator-protocol.md` AskUserQuestion 섹션 일관성 확인 |
| 체크리스트 변경 | `checklists/*.md` / `playbooks/final-validation.md` Step 4-5 / `scripts/validate-*.sh` |

각 변경 PR에는 위 파일 중 **어느 것이 함께 변경됐는지** 본문에 명시하세요.

## 명명 규약

- `.claude/agents/{stem}.md` 파일의 frontmatter `name:` 필드는 파일명 stem과 **반드시 일치**해야 합니다. 오케스트레이터가 `Agent(subagent_type: "{name}")` 로 소환할 때 이 `name` 이 그대로 `subagent_type` 값으로 쓰입니다.
- 예: `phase-setup.md` → `name: phase-setup` → `subagent_type: "phase-setup"`.
- 이 규약은 위 "테스트" 섹션의 check #4 로 자동 검증됩니다.

## 외부 의존성 리스크 (읽어두세요)

이 플러그인의 **Agent-Playbook 분리**는 Claude Code 런타임의 자동 디스커버리 동작("`.claude/skills/` 및 `commands/` 아래 파일만 스킬/커맨드로 노출")에 의존합니다. 방법론 파일을 `playbooks/`에 두는 이유는 이 디스커버리 범위 밖이기 때문입니다.

Claude Code 버전 업데이트로 디스커버리 경로가 확장되면(예: `playbooks/` 자동 로딩) 이 분리 원칙이 무력화되고, 메인 세션이 서브에이전트 소환을 우회할 수 있습니다. 버전 업데이트 시 다음 테스트를 수행해 주세요:

1. `playbooks/*.md` 가 메인 세션의 "사용 가능한 스킬" 목록에 노출되는지 확인
2. 노출되면 즉시 이슈 등록 + 설계 대안 논의 (예: `playbooks/` 파일에 frontmatter `visibility: hidden` 같은 방어 메타 추가)

## knowledge 수정 시

`knowledge/*.md` 는 Claude Code 공식 문서에서 파생된 derivative commentary 입니다. 수정 시:

1. `knowledge/VERSION.md` 의 버전을 semver 규칙에 따라 범프 (문구 수정은 PATCH, 섹션 추가는 MINOR, 스키마 변경은 MAJOR)
2. `CHANGELOG.md` 의 `[Unreleased]` 섹션에 `knowledge: ...` 항목 추가
3. 공식 문서와의 매핑(파일 상단 `Source: ... Original section mapping: N`)이 여전히 유효한지 확인

## 커밋 / PR

- Conventional Commits 권장: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
- 변경이 사용자 가시 영역에 영향을 주면 `CHANGELOG.md`의 `[Unreleased]` 섹션에 항목을 추가하세요.
- PR 설명에 다음을 포함하세요:
  1. 변경 이유 (어떤 문제/시나리오를 해결하는지)
  2. 영향 범위 (수정 파일, Phase 흐름 변화 여부)
  3. 수동 테스트 결과 또는 재현 절차

## 라이선스

기여한 코드는 프로젝트 라이선스인 [Apache-2.0](./LICENSE) 하에 배포됩니다.
