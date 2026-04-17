# Post-Generation Validation Checklist

Run through these checks after generating every harness file set.

## File Existence
- [ ] CLAUDE.md exists at project root
- [ ] .claude/ directory created
- [ ] .claude/settings.json exists and is valid JSON
- [ ] .claude/rules/ directory exists (if rules were generated)
- [ ] Each generated rule file exists
- [ ] Each generated skill directory has SKILL.md
- [ ] CLAUDE.local.md template exists
- [ ] .claude/settings.local.json template exists

## CLAUDE.md Quality
- [ ] Under 200 lines
- [ ] Contains project name and purpose
- [ ] Contains tech stack
- [ ] Contains at least one development principle
- [ ] @import paths reference files that actually exist
- [ ] No Claude Code architecture explanations (meta-leakage)
- [ ] No references to "Harness Setup Assistant"

## settings.json Quality
- [ ] Valid JSON (no comments, no trailing commas)
- [ ] Has permissions.deny with at least: rm -rf /, sudo rm, git push --force
- [ ] No `Bash(*)` in permissions.allow
- [ ] No `Bash(sudo *)` in permissions.allow
- [ ] No secrets, API keys, or tokens in env
- [ ] allow patterns match actual project scripts/tools

## Rules Quality
- [ ] Always-apply rules have NO YAML frontmatter
- [ ] Path-scoped rules have correct `paths:` YAML frontmatter
- [ ] Path patterns match at least one file in the project (verify with find/glob)
- [ ] No duplicate rules across files
- [ ] Rules contain project-specific content, not generic advice

## Skills Quality (if generated)
- [ ] Each SKILL.md has `name` and `description` in YAML frontmatter
- [ ] Each skill has Goal, Workflow, and Guardrails sections
- [ ] No Cursor-specific tool references in skills

## Multi-Agent Discipline (에이전트 프로젝트일 때)
- [ ] 각 .claude/agents/*.md의 Rules 섹션에 "AskUserQuestion 직접 사용 금지, Escalations 기록" 문구 포함
- [ ] 각 스킬/플레이북 파일(`.claude/skills/*/SKILL.md` 및 `playbooks/*.md`)에 "질문 소유권" 섹션 존재
- [ ] 각 스킬의 Output Contract에 Summary / Files Generated / Escalations / Next Steps / Context for Next Phase 명시
- [ ] Phase 5 Orchestrator Pattern Decision이 D-1인데 에이전트 전용 스킬이 `.claude/skills/`에 있지 않은지 확인 (메인 세션 우회 방지)
- [ ] ownership-guard.sh (또는 동등) 훅 존재 — 멀티 에이전트 쓰기 범위 강제
- [ ] 에이전트가 2개 이상이면 각 스킬의 allowed_dirs가 충돌 없이 분리됨
- [ ] `docs/{요청명}/` 산출물 번호 체인(00~07)이 완비

## Git Integration
- [ ] .gitignore contains `CLAUDE.local.md`
- [ ] .gitignore contains `.claude/settings.local.json`

## Security
- [ ] Run checklists/security-audit.md checks
- [ ] Run checklists/meta-leakage-keywords.md checks
