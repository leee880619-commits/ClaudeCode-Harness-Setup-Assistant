
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
