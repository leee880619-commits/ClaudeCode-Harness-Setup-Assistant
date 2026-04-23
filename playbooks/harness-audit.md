
# Harness Audit

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록하여 오케스트레이터에 반환한다.

## Goal
Diagnose the health of an existing Claude Code harness and propose targeted improvements.

## Prerequisites
- Target project path provided and validated
- Existing `.claude/` or `CLAUDE.md` detected in the target

## Knowledge References
Load ON-DEMAND with Read tool:
- `knowledge/01-scope-hierarchy.md` — Expected structure for each scope
- `knowledge/02-composition-rules.md` — Merge rules to detect conflicts
- `knowledge/03-file-reference.md` — Correct file formats
- `knowledge/11-anti-patterns.md` — Known mistakes to detect

## Workflow

### Phase 1: Full 4-Scope Scan

Scan all 4 scopes automatically:

**Managed**: `/etc/claude-code/` (usually empty for personal use)
**User**: `~/.claude/` — CLAUDE.md, settings.json, rules/, skills/
**Project**: `<target>/.claude/`, `<target>/CLAUDE.md`, `<target>/playbooks/` (에이전트 전용 방법론 디렉터리가 있는 경우)
**Local**: `<target>/CLAUDE.local.md`, `<target>/.claude/settings.local.json`

For each file found, collect:
- Exists? (yes/no)
- Size (bytes, lines)
- JSON valid? (for .json files)
- Line count (for .md files)

추가 감지: 프로젝트에 `playbooks/` 디렉터리가 있으면 에이전트 프로젝트(D-1/D-2 오케스트레이터 패턴)로 간주하고, 각 파일의 frontmatter 및 에이전트 정의와의 매핑을 기록한다.

### Phase 2: Anti-Pattern Detection

Check for these issues:

| Check | Severity | Condition |
|-------|----------|-----------|
| CLAUDE.md too long | HIGH | Over 200 lines |
| Wildcard permissions | CRITICAL | `Bash(*)` or `Bash(sudo *)` in allow |
| Dangerous allows | HIGH | `sudo rm`, `rm -rf`, `git push --force` in allow |
| settings.local.json bloat | MEDIUM | Over 10KB |
| Missing User CLAUDE.md | MEDIUM | `~/.claude/CLAUDE.md` does not exist |
| Missing .gitignore entries | MEDIUM | CLAUDE.local.md or settings.local.json not in .gitignore |
| No rules/ directory | LOW | `.claude/rules/` does not exist |
| Empty skills/ | LOW | `.claude/skills/` exists but no SKILL.md files AND `playbooks/`도 비어있거나 없음 |
| **Main session bypass risk (D-1 violation)** | **HIGH** | `.claude/agents/`에 에이전트 정의가 2개 이상 있고 체인 패턴이 감지되는데, 에이전트 전용 스킬이 `.claude/skills/` 아래에 배치되어 있다. 메인 세션이 Skill 도구로 자동 호출하여 서브에이전트 소환을 우회할 위험. |
| **Playbook reference mismatch** | HIGH | `.claude/agents/*.md`의 `## Playbooks` 섹션이 참조하는 `playbooks/{name}.md` 파일이 존재하지 않음 |
| **Orphan playbook** | MEDIUM | `playbooks/*.md` 파일이 어느 에이전트 정의에서도 참조되지 않음 |
| **Mixed location without hybrid intent** | MEDIUM | `.claude/skills/`와 `playbooks/` 모두 내용이 있으나 CLAUDE.md에 D-2 하이브리드 패턴 선언이 없음 — 의도를 재확인해야 함 |
| Invalid JSON | HIGH | settings.json parse failure |
| Path pattern mismatch | MEDIUM | paths: patterns that match zero files |
| settings.local.json at user level | MEDIUM | `~/.claude/settings.local.json` exists (non-standard) |
| No deny list | HIGH | settings.json has no permissions.deny |
| **Missing Ask-first directive** | LOW | 프로젝트 CLAUDE.md 에 "모호하면 먼저 질문" 취지의 규약(키워드: `AskUserQuestion`, "먼저 확인", "가정하지", "ask first", "when uncertain" 등)이 감지되지 않음. 자동 수정하지 않고 제안만 기록. |
| **Missing Intent Gate baseline** | **HIGH** | 아래 3개 요소 중 **하나라도 누락** 시 단일 복합 HIGH 항목으로 발행: (1) `.claude/rules/intent-gate.md` 파일 존재 + `alwaysApply: true` 프론트매터, (2) `.claude/skills/intent-clarifier/SKILL.md` 파일 존재 + `name: intent-clarifier` 프론트매터, (3) `CLAUDE.md` 에 `## 작업 시작 전` 섹션 + 본문에 `intent-gate.md` / `intent-clarifier` 문자열 모두 포함. 이 3종은 상호 의존적 단일 시스템 — 하나만 빠져도 첫 턴 의도 확인 강제가 무력화되므로 부분 등급 차등을 두지 않는다. 보고 시 **누락 하위 요소 목록**(예: "rule OK / skill MISSING / CLAUDE.md section MISSING") 을 함께 제시. |

### Phase 3: Diagnostic Report

Present results as a structured report:

```
[하네스 진단 보고서]
대상: {path}

[Scope Status]
  Managed:  N/A (개인 사용)
  User:     ✅ settings.json / ❌ CLAUDE.md / ❌ rules/
  Project:  ✅ CLAUDE.md (185줄) / ✅ settings.json / ✅ rules/ (3개) / ✅ agents/ (N개) / ⊙ skills/ (M개 또는 N/A) / ⊙ playbooks/ (K개 또는 N/A)
  Local:    ❌ CLAUDE.local.md / ❌ settings.local.json

[Orchestrator Pattern]
  추정: D-1 (오케스트레이터) / D-2 (하이브리드) / D-3 (단일 진입점) / 비에이전트 프로젝트
  근거: 에이전트 N개, skills/ M개, playbooks/ K개 → 패턴 판정

[Issues Found]
  🔴 CRITICAL (0)
  🟠 HIGH (2)
    - settings.json에 deny 목록 없음
    - ~/.claude/CLAUDE.md 없음
  🟡 MEDIUM (1)
    - .gitignore에 CLAUDE.local.md 미포함
  🔵 LOW (1)
    - skills/ 디렉터리 비어있음

[Recommendations]
  1. settings.json에 최소 deny 목록 추가 (우선순위: 높음)
  2. ~/.claude/CLAUDE.md 생성 → /user-scope-init 실행 (우선순위: 중간)
  3. .gitignore 업데이트 (우선순위: 중간)
  4. 빈 skills/ 디렉터리 제거 또는 스킬 추가 (우선순위: 낮음)
```

### Phase 4: User Decision

[Escalation] 수정 대상 선택 필요 — 발견된 항목 번호 목록을 Escalations에 기록하여 오케스트레이터가 사용자에게 선택을 요청.

**"Missing Ask-first directive" 특례**: 이 LOW 항목은 `orchestrator-protocol.md` "CLAUDE.md 단일 소유자 원칙"의 audit 재진입 조항에 따라 **자동 재작성 금지**. 대신 Escalations에 다음 형식으로 기록:
`[ASK] Ask-first 지침 미감지 — 기존 CLAUDE.md 끝부분에 "모호하면 AskUserQuestion으로 먼저 확인" 규약 1~2줄을 append할까요? (권장: Yes)`
사용자가 Yes 응답 시 Phase 5에서 CLAUDE.md 본문 재작성 없이 **append-only** 수정으로 반영.

**"Missing Intent Gate baseline" 특례**: 이 복합 HIGH 항목은 **자동 패치 가능**. 단일 Escalation 으로 사용자에게 확인:
`[ASK] Intent Gate 베이스라인 누락 — (1) .claude/rules/intent-gate.md (2) .claude/skills/intent-clarifier/ (3) CLAUDE.md "작업 시작 전" 섹션 중 {누락 목록}. 이 도구가 소스 템플릿을 그대로 복사하여 자동 패치할까요? (권장: Yes)`

**CLAUDE.md 단일 소유자 원칙의 명시적 예외**: `orchestrator-protocol.md` 의 "CLAUDE.md 단일 소유자 원칙" 은 audit 재진입 시 본문 재작성·덮어쓰기 금지를 원칙으로 하되, **Intent Gate 베이스라인은 이 원칙의 명시적 예외**로 허용한다. 이유: Intent Gate 는 모든 하네스의 최상위 지침이며, 기존 본문과 의미적으로 독립된 선행 섹션이기에 구조적 충돌이 없다. 단, 아래 안전장치를 따른다:
- 이미 `## 작업 시작 전` 섹션이 존재하면 prepend 하지 않고 **본문만 갱신** (중복 방지)
- prepend 대상은 최상위 `# {title}` 바로 아래만 — 다른 섹션 사이 삽입 금지
- 적용 전 기존 CLAUDE.md 사본을 `.claude/backup/CLAUDE.md.{timestamp}.bak` 으로 저장 (롤백 대비)

사용자가 Yes 응답 시 Phase 5에서 다음을 수행:
- (1) 누락 시: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/rules/intent-gate.md` → `{대상}/.claude/rules/intent-gate.md` Read→Write 복사
- (2) 누락 시: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/skills/intent-clarifier/` 디렉터리 전체 → `{대상}/.claude/skills/intent-clarifier/` 복사
- (3) 누락 시: 위 안전장치에 따라 CLAUDE.md 최상단에 `## 작업 시작 전` 섹션 prepend (템플릿은 fresh-setup Step 6 의 동일 본문)
- 적용 후 재스캔하여 복합 HIGH 항목이 해소되었는지 확인, 산출물에 기록.

### Phase 5: Execute Remediation

For each selected item:
1. Show the proposed change (new file content or edit)
2. Get approval
3. Apply the change
4. Verify the fix

### Phase 6: Re-Scan & Report

After all changes:
1. Re-scan all 4 scopes
2. Compare before vs after
3. Present improvement summary

## Guardrails

- Scope is DIAGNOSIS and TARGETED FIXES only
- Do not redesign the entire harness unless user asks
- Do not modify application code
- Do not remove existing configurations without explicit approval
- **스코프 경계 — 런타임/운영 부채 위임**: 본 플레이북은 **설계·구성 중심 진단** (파일 존재 여부, 권한, anti-pattern, scope 분포, 에이전트-플레이북 매핑)에 집중한다. 다음은 본 플레이북의 스코프가 **아니다**:
  - 세션 연속성·체크포인트 메커니즘·재개 프로토콜 (→ Dim A)
  - 실패 복구 종료 조건 (`max_retries`·timeout·무한 루프 방지) (→ Dim B)
  - 에이전트-스킬 이중 관리 부채 drift (→ Dim C)
  - 산출물 덮어쓰기·버저닝 전략 (→ Dim D)
  - 크로스 워크플로우 구조 중복 (Jaccard 유사도) (→ Dim E)
  
  위 5개 런타임/운영 부채는 `/harness-architect:ops-audit` 에 위임한다. harness-audit 완료 후 사용자에게 "구성 진단은 완료되었습니다. 런타임/운영 부채 감사를 원하면 `/harness-architect:ops-audit` 을 실행하세요." 를 Phase 3 진단 리포트의 Recommendations 말미에 1줄로 안내할 것.
