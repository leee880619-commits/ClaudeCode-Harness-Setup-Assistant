# Output Quality Standards

## File Generation Rules

1. **CLAUDE.md**: MUST be under 200 lines. If content exceeds, split into .claude/rules/
2. **SKILL.md = SSoT for workflow detail** (다중 에이전트 하네스 — 에이전트 ≥ 2 또는 SKILL.md ≥ 4):
   - CLAUDE.md 범위: 리더 라우팅, 팀 구조, 파일 소유권, 공통 원칙, 세션 복구 — **매 세션 시작 시 항상 필요한 내용**
   - SKILL.md 범위: 워크플로우 정체성, 전략표, N-step 흐름, 품질 기준, anti-pattern 정의 — **스킬 호출 시점에만 필요한 내용**
   - SKILL.md 본문 상세를 CLAUDE.md에 복제 금지. 대신 한 줄 요약 + SSoT 포인터 사용 (예: "PORT anti-pattern은 `validate-port` SKILL.md에서 정의·검사")
   - 근거: SKILL.md 프론트매터(~30 토큰)만 시작 시 로드되고 본문은 호출 시 로드. 중복 시 콜드 컨텐츠 강제 항상 로드
   - 단일 에이전트·소규모 하네스(에이전트 1개)는 fragmentation 위험으로 권고만 (soft warning, BLOCK 아님)
   - **에이전트 수·SKILL.md 수 판별 공급원**: 이 항목은 always-apply 규칙이지만 판별은 정황별로 다른 공급원에 의존:
     - 빌드 시점(fresh-setup Phase 1-2): `playbooks/fresh-setup.md` Step 6.1의 "휴리스틱 사전 신호 4종"으로 추정
     - 빌드 시점(Phase 9 final-validation): 실제 `.claude/agents/*.md` 파일 수 + `.claude/skills/*/SKILL.md` 디렉터리 수를 `ls` 또는 `find`로 직접 카운트
     - 사후 감사 시점(/audit, harness-audit, ops-audit): 동일하게 실제 파일 수 카운트
     - 본 규칙 자체는 판별을 수행하지 않는다 — 위 진입점이 카운트 후 본 원칙을 적용한다
3. **settings.json**: MUST be valid JSON. No comments, no trailing commas.
4. **Rules files**: Correct YAML frontmatter for path-scoped, or NO frontmatter for always-apply
5. **SKILL.md**: MUST have `name` and `description` in YAML frontmatter
6. **All files**: UTF-8 encoding, LF line endings, no BOM
7. **참조 깊이 1단계 제한**: 생성하는 SKILL.md·playbook·rules·CLAUDE.md가 보조 파일(`references/`, 다른 playbook, `@import` 대상)을 가리킬 때 참조는 **한 단계 깊이**만 둔다. 참조 대상이 또 다른 파일을 가리키는 체인(A→B→C)을 만들지 않는다. 필요한 맥락은 직접 참조하는 파일 안에서 끝낸다 — 에이전트가 한두 번의 Read로 작업 맥락을 확보하게 하여 탐색 비용·누락 위험을 줄인다.

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
