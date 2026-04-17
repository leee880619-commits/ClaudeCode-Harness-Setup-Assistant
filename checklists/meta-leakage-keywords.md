# Meta-Leakage Keyword Detection

## Purpose
Scan generated files for keywords that indicate this tool's internal instructions
have leaked into the target project's configuration files.

## Forbidden Keywords in Generated Files

### Tool Identity (must not appear)
- "Harness Setup"
- "Setup Assistant"
- "하네스 에이전트"
- "설정 도구"
- "메타 도구"

### Tool Behavioral Rules (must not appear)
- "ask everything"
- "assume nothing"
- "질문을 먼저"
- "가정하지 마세요"
- "no implicit assumptions"
- "question discipline"
- "progressive disclosure"
- "meta-leakage"

### Claude Code Architecture Terms (should not appear in CLAUDE.md)
- "4-Tier Scope"
- "Managed Scope"
- "composition rules"
- "settings merge"
- "deny > ask > allow"
- "context vs config"

### Runtime Internals (must not appear in generated SKILL.md or playbooks/*.md)
이 어시스턴트의 플레이북에서만 의미 있는 런타임 메커니즘 설명이 대상 프로젝트 생성 파일에 복제되면 안 된다:
- "자동 디스커버리" / "auto-discovery" (Claude Code의 `.claude/skills/` 메커니즘을 설명하는 용어)
- "BLOCKING REQUIREMENT"
- "시스템 프롬프트" / "system prompt"
- "런타임의 가시성 필터" / "runtime visibility filter"
- "Skill 도구 직접 실행 금지" (이 어시스턴트 원칙 5의 표현 그대로)
- "메인 세션 우회" / "main session bypass"
- "Orchestrator Pattern Decision" / "D-1" / "D-2" / "D-3" (이 어시스턴트의 분류 체계)
- "Phase 1-9" / "Phase Gate" (이 어시스턴트의 단계 명명)
- "user-invocable: false가 효과 없음" 같은 런타임 한계 설명

이 키워드들은 이 어시스턴트의 내부 구조를 설명하는 데 쓰인다. 대상 프로젝트 파일에는 **대상 프로젝트 고유의 용어**로 재작성되어야 한다 (예: "에이전트는 playbooks/ 파일을 Read한다" 같이 사실만 서술, 메커니즘 설명은 배제).

These terms belong in documentation, not in project instructions.

## Allowed Content

These ARE acceptable in generated files:
- Project-specific development principles
- Tech stack descriptions
- Build/test commands
- Git conventions
- Permission rules (but not explanations of HOW permissions work)
- @import references to project documents
