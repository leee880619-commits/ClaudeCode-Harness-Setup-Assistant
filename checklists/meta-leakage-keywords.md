# Meta-Leakage Keyword Detection

## Purpose
Scan generated files for keywords that indicate this tool's internal instructions
have leaked into the target project's configuration files.

## Forbidden Keywords in Generated Files

### Tool Identity (must not appear)
- "Harness Setup"
- "Setup Assistant"
- "harness-architect"
- "하네스 에이전트"
- "하네스 설정 도구"
- "하네스 구축 어시스턴트"
- "구축 어시스턴트"
- "설정 도구"
- "메타 도구"

### Tool Behavioral Rules (must not appear)
- "ask everything"
- "assume nothing"
- "질문을 먼저"
- "모든 것을 먼저 질문"
- "모든 결정 전에"
- "가정하지 마세요"
- "암묵적 합의 금지"
- "no implicit assumptions"
- "question discipline"
- "질문 규율"
- "progressive disclosure"
- "점진적 공개 방식"
- "점진적 공개"
- "meta-leakage"
- "메타 누수"   <!-- 공백 삽입 변형 -->
- "메타누수"
- "meta leakage"

### Claude Code Architecture Terms (should not appear in CLAUDE.md)
- "4-Tier Scope"
- "Managed Scope"
- "composition rules"
- "settings merge"
- "deny > ask > allow"
- "context vs config"

### Plugin-internal UX Labels (must not appear in generated CLAUDE.md / rules / agents / skills)
사용자 인터뷰용 라벨이 대상 프로젝트 생성물에 복제되면 안 됨. A5 답변 원값(예: `균형형`)은 Pre-collected Answers 메타 기록에만 허용:
- "기본 성능 수준" (Phase 0 질문 라벨)
- "모델 티어" / "Model Tier"
- "Model Confirmation Gate"
- 라벨 전문 패턴: `경제형.*균형형.*고성능형` (세 단어가 한 줄/근접 위치에 동시 등장 = 이 플러그인의 UX 라벨 복제)

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

## Regex Hints (for `scripts/validate-meta-leakage.sh`)

Exact-match 방어는 변형 표현에 취약하므로, 자동 스캔 시 다음 정규식 패턴도 함께 사용한다:

| 범주 | 정규식 (grep -Ei) | 의미 |
|------|-------------------|------|
| 질문 강제 | `모든.{0,5}(결정|설정).{0,10}(먼저|반드시).{0,10}(질문|확인)` | "모든 결정 전에 먼저 질문" 계열 |
| 메타 누수 | `메타[ \-]?누수\|meta[ \-]?leak(age)?` | 공백/하이픈 변형 |
| 점진 공개 | `점진[ ]?적.{0,3}공개` | "점진적 공개 방식" 변형 |
| 질문 규율 | `질문[ ]?규율\|question[ ]?discipline` | 공백 변형 |
| 하네스 도구 | `하네스[ ]?(설정|구축|어시스턴트)` | 이 플러그인 자칭 |
| 플러그인 Phase | `Phase[ \-]?[0-9]\|Phase[ ]?Gate\|Orchestrator Pattern Decision` | 이 어시스턴트의 단계 명명 |
| 모델 티어 UX | `기본[ ]?성능[ ]?수준\|모델[ ]?티어\|Model[ ]?Tier\|Model Confirmation Gate\|경제형.{0,40}균형형.{0,40}고성능형` | Phase 0 A5 질문 및 Confirmation Gate 라벨 복제 감지 |

정규식 히트는 키워드 리스트 히트와 동일하게 `[BLOCKING]`으로 처리한다.

## Allowed Content

These ARE acceptable in generated files:
- Project-specific development principles
- Tech stack descriptions
- Build/test commands
- Git conventions
- Permission rules (but not explanations of HOW permissions work)
- @import references to project documents
