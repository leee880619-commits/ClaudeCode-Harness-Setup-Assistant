# Knowledge Base Version

- **Version**: 1.3.0
- **Date**: 2026-04-16
- **Claude Code baseline**: Opus 4.6 (1M context)
- **Source**: claude-code-harness-architecture-report.md (6,034 lines, 249KB)
- **Sections**: 13 files (00 ~ 12)
- **Total**: ~6,000 lines across all files

## Changelog

### v1.3.0 (2026-04-16)
- **Agent-Skill 분리 아키텍처 (WHO vs HOW)**: `12-teams-agents.md` 섹션 12.7a 신규 — 에이전트(정체성)와 스킬(능력) 분리 패턴, 실제 프로젝트 구조 예시
- CLAUDE.md: Agent-Skill 분리 원칙 추가, checklists/ 참조 추가, knowledge 파일 번호 매핑 설명
- agent-team/SKILL.md: 모델 D (Agent-Skill 분리) 추가, knowledge 12.7a 참조
- skill-forge/SKILL.md: Agent-Skill 분리 모델 적용 시 에이전트 정의 파일 생성 단계(Step 7a) 추가
- pipeline-design/SKILL.md: knowledge 12.7a 참조 추가
- 스킬 Ask 패턴 일괄 제거: fresh-setup, harness-audit, cursor-migration의 "Ask:" → [Escalation] 패턴으로 전환
- 스킬 자체 전환 지시 제거: fresh-setup, workflow-design, pipeline-design의 "자동으로 Phase N 전환" → "Next Steps에 기록"
- syntax-check.sh: 경로 내 작은따옴표 주입 취약점 수정 — `open('$TARGET_FILE')` → `open(sys.argv[1])`
- design-review/SKILL.md: role, allowed_dirs frontmatter 추가
- MEMORY.md: 존재하지 않는 예시 파일 링크 제거
- settings.json: Bash(jq *) 허용 제거 (미사용)
- docs/ → dev-notes/ 이름 변경 (대상 프로젝트 docs/와 충돌 방지)
- 전체 knowledge 파일(00~12): 파일-섹션 번호 매핑 주석 추가

### v1.2.0 (2026-04-16)
- Red-team Advisor 도입: `.claude/agents/red-team-advisor.md`, `.claude/skills/design-review/SKILL.md` 신규
- 오케스트레이터 프로토콜: Advisor 프로토콜, Phase Gate, 절대경로 템플릿 추가
- CLAUDE.md: 원칙 5 (Skill 직접 실행 금지), Advisor 역할, 마스터 워크플로우 Advisor 컬럼
- 모든 Phase 스킬: `user-invocable: false`, `model` 필드 제거, AskUserQuestion→Escalations 전환
- 서브에이전트 모델 정책: 모든 Phase 에이전트 opus 통일
- fresh-setup: 프로젝트 아키타입 감지, 키워드 자동 감지, Fast-Forward 경로, 내부 Phase→Step 이름 변경
- workflow-design: 에이전트 파이프라인/콘텐츠 자동화 유형 추가
- pipeline-design, agent-team: knowledge 필수 로딩
- ownership-guard.sh: $CLAUDE_TOOL_INPUT 기반 + 대상 프로젝트 경로 허용 + python3 JSON 파싱 + 심볼릭 링크 탈출 방어
- syntax-check.sh: $CLAUDE_TOOL_INPUT 기반 + python3 JSON 파싱 + settings.local.json 제외 + 위험 패턴 4종 검사
- `11-anti-patterns.md`: 잘못된 내용(진단 보고서) → 올바른 안티패턴 문서로 교체
- `10-agent-design.md`, `12-teams-agents.md`: 서브에이전트 opus 정책 명시
- settings.json: dead env vars 제거, 불필요 Bash allow 제거, matcher 정리
- output-quality.md: 서브에이전트 실행 모드의 초안/승인 흐름 추가

### v1.1.0 (2026-04-16)
- `03-file-reference.md`: `.claude/agents/*.md` (User/Project 서브에이전트 정의) 추가 — 섹션 4.14a, 4.14b
- `03-file-reference.md`: 요약표 16→18개 항목으로 확장 (User agents #8, Project agents #15)
- `12-teams-agents.md`: 섹션 12.7 추가 — 커스텀 에이전트 정의 파일 명세 및 SKILL.md 선택 기준
- `10-agent-design.md`: 스캔 체크리스트에 `.claude/agents/` 항목 추가

## Update Protocol

1. Update `docs/claude-code-harness-architecture-report.md` (canonical source)
2. Re-split into `knowledge/` files using the section boundaries
3. Update this VERSION.md with new date and version
4. Commit and push for team to `git pull`
