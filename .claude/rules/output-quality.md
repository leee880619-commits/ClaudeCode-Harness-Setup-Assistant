# Output Quality Standards

## File Generation Rules

1. **CLAUDE.md**: MUST be under 200 lines. If content exceeds, split into .claude/rules/
2. **settings.json**: MUST be valid JSON. No comments, no trailing commas.
3. **Rules files**: Correct YAML frontmatter for path-scoped, or NO frontmatter for always-apply
4. **SKILL.md**: MUST have `name` and `description` in YAML frontmatter
5. **All files**: UTF-8 encoding, LF line endings, no BOM

## Security Constraints (NEVER violate)

These patterns are FORBIDDEN in generated permissions.allow:
- `Bash(*)` — allows all commands without confirmation
- `Bash(sudo *)` — allows all sudo commands
- `Bash(rm -rf *)` — allows recursive deletion of anything
- `Bash(git push --force *)` — allows force push

Every generated settings.json MUST include this minimum deny list:
```json
"deny": [
  "Bash(rm -rf /)",
  "Bash(sudo rm *)",
  "Bash(git push --force *)"
]
```

## Secret Detection

If user mentions API keys, tokens, or passwords during questions:
- NEVER put them in settings.json (git-committed)
- Guide user to put them in .claude/settings.local.json (gitignored)
- Detect patterns: `sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer `

## Validation Before Writing

After generating each file, before writing to disk:
1. JSON files: verify parseable (mentally or via jq)
2. CLAUDE.md: count lines, ensure under 200
3. Rules with `paths:`: verify patterns match actual project structure
4. Verify no duplicate filenames
5. Verify .gitignore will include CLAUDE.local.md and settings.local.json

## Presentation Rules

### 서브에이전트 실행 모드 (기본)
- 서브에이전트는 대상 프로젝트에 파일을 직접 Write한다
- 단, 핵심 파일(CLAUDE.md, settings.json)의 초안은 산출물 Summary에 포함하여 반환
- 오케스트레이터가 Advisor 리뷰 후 사용자에게 핵심 파일을 제시
- AskUserQuestion으로 승인/수정 요청
- 수정 필요 시 서브에이전트를 피드백과 함께 재소환
- 서브에이전트는 AskUserQuestion을 사용할 수 없으므로, 승인 절차는 오케스트레이터가 대행한다

### 파일 제시 규칙
- 파일을 FULL로 제시. 한 번에 하나씩.
- 승인 후 작성
- 모든 파일 생성 완료 후 전체 트리 구조 제시
- 자연어 요약: "이 설정으로 Claude는 X를 자동 실행하고, Y는 매번 확인합니다."
