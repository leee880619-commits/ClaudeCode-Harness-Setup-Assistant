---
name: cursor-migration
description: Convert an existing Cursor IDE setup (.cursor/rules/, AGENTS.md, .cursorrules) to Claude Code harness format. Preserves all rules and workflows.
role: converter
allowed_dirs: [".", ".claude/", ".cursor/", "knowledge/"]
user-invocable: false
---

# Cursor to Claude Code Migration

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록한다. "오케스트레이터가 사용자에게
확인"이라는 구절은 서브에이전트가 해당 항목을 Escalations에 기록한다는 뜻이다.

## Goal
Faithfully convert a Cursor IDE instruction architecture to Claude Code format, preserving all rules, skills, and workflows while adapting to Claude Code's file structure.

## Prerequisites
- Target project path provided and validated
- Cursor artifacts detected (.cursor/, AGENTS.md, .cursorrules, or .agents/)
- Scan results available

## Knowledge References
Load ON-DEMAND with Read tool:
- `knowledge/07-cursor-migration.md` — Complete conversion specification
- `knowledge/03-file-reference.md` — Claude Code file format specs
- `knowledge/05-skills-system.md` — SKILL.md format (for skill conversion)

## Workflow

### Phase 1: Cursor Inventory

Scan and list ALL Cursor artifacts found:

```
[Cursor Artifact Inventory]
.cursor/rules/ (N files):
  - filename.mdc — alwaysApply: true/false, glob: pattern
AGENTS.md: found at root / docs/ / both
.agents/skills/ (N skills):
  - skill-name/SKILL.md
.cursor/mcp.json: found/not found
.cursor/hooks.json: found/not found
.cursorrules: found/not found (deprecated)
```

Read each file and present the inventory.
[Escalation] Cursor 변환 대상 확인 필요 — 전체 인벤토리를 Summary에 포함. 오케스트레이터가 "빠져야 할 항목이 있는지" 사용자에게 확인.

### Phase 2: Rule-by-Rule Conversion Plan

For each .mdc file, present the conversion:

```
[변환 계획: git-safety.mdc]
원본: alwaysApply: true
변환: .claude/rules/git-safety.md (프론트매터 없음 = 항상 적용)
내용: (핵심 규칙 요약)
```

```
[변환 계획: server-verification.mdc]
원본: alwaysApply: false, glob: "server/**/*.js"
변환: .claude/rules/server-verification.md
프론트매터:
  paths:
    - "server/**/*.js"
    - "shared/**/*.js"
내용: (핵심 규칙 요약)
```

Conversion rules:
- `alwaysApply: true` → No YAML frontmatter (always-apply in Claude Code)
- `alwaysApply: false` + `glob:` → `paths:` YAML frontmatter
- `.mdc` extension → `.md` extension
- `workflow-skill-bindings.mdc` → Absorbed into CLAUDE.md @import references
- `session-continuity.mdc` → Replaced by Auto Memory (no file needed)
- `context-mode.mdc` → Evaluate if applicable; Cursor-specific context-mode tools don't exist in Claude Code

[Escalation] 각 변환 계획을 Escalations에 기록하여 오케스트레이터가 사용자 확인을 진행.

### Phase 3: AGENTS.md Conversion

Read AGENTS.md content and present:
- What maps to CLAUDE.md (project identity, tech stack, principles)
- What maps to rules/ (specific constraints)
- What should be dropped (Cursor-specific references)
- What needs @import references

[Escalation] AGENTS.md 분배 계획 확인 필요 — 분배 매핑을 Summary에 포함하여 오케스트레이터가 사용자에게 확인.

### Phase 4: Skills Conversion

For each .agents/skills/*/SKILL.md:
- Read the content
- Add YAML frontmatter if missing (name, description)
- Replace Cursor-specific tool references
- Propose the converted SKILL.md

[Escalation] 변환된 각 스킬을 Escalations에 기록하여 오케스트레이터가 사용자 확인을 진행.

### Phase 5: Supplementary Questions

Ask ONLY questions not answerable from the Cursor configs:
- Permission policy (if no deny rules exist in Cursor setup)
- Korean encoding needs (if not addressed in existing rules)
- Anything the user wants to ADD that wasn't in the Cursor setup

### Phase 6: Generation

Follow the same generation process as /fresh-setup Phase 5-7:
- Show each file, get approval, write
- Verify, present summary

Additional: Ask whether to keep or remove original Cursor files.

## Guardrails

- Never discard Cursor rules without user approval
- Cursor-specific MCP tools (context-mode) need user decision, not silent removal
- If a .mdc file has no clear Claude Code equivalent, present it and ask
- Preserve the original intent of each rule, not just the syntax
