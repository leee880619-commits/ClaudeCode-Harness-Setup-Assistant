
# Skill Forge

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록한다.

## Goal
Phase 5에서 편성된 각 에이전트에 대해 구체적인 SKILL.md(HOW)를 제작한다.
각 스킬은 방법론, 사용 도구, 필요 지식, 작업 워크플로우, 출력 계약, 가드레일을 포함한다.

**Agent-Skill 분리 모델(모델 D) 적용 시:** 에이전트 정의(WHO)는 Phase 5에서 이미 생성되어 있다. 이 Phase는 순수하게 스킬(HOW) 파일만 제작한다.

## Prerequisites
- Phase 5 완료: 팀 구조, 에이전트 목록, 모델/모드/범위 설정 확정
- 각 에이전트의 담당 스킬명이 Phase 4에서 매핑된 상태
- Agent-Skill 분리 모델 채택 시: 에이전트 정의(`.claude/agents/*.md`)가 Phase 5에서 생성된 상태
- **Phase 5 산출물(`04-agent-team.md`)의 "Orchestrator Pattern Decision"** — 대상 프로젝트가 오케스트레이터 패턴(메인 세션은 순수 라우터, 서브에이전트만 방법론 실행)인지 여부. 이 결정이 스킬 파일의 **저장 위치**를 바꾼다 (Step 7 참조).
- (선택) Phase 2.5 산출물 `docs/{요청명}/02b-domain-research.md` — **있으면 Read**하여 도메인 표준 도구·스킬 스택을 스킬 설계의 레퍼런스(Focus / Workflow / 사용 도구 선정)로 사용. 스킵이면 무시.
- **프리셋 스킬 소유권 보호**: Phase 1-2 산출물(`01-discovery-answers.md`)의 `## Context for Next Phase` 에 `프론트엔드 프리셋 주입 여부: yes` 가 기록돼 있으면, 대상 프로젝트 `.claude/skills/frontend-design/` 디렉터리 전체는 **이미 주입 완료** 된 상태이므로 이 Phase 에서 SKILL.md 재작성·덮어쓰기를 금지한다. Agent-Skill 매핑에는 `frontend-design` 을 포함하되 비고에 "프리셋 주입 — 재작성 제외" 기록. 보완이 필요하면 `frontend-design/references/*` 에 별도 파일로 추가한다 (본체 덮어쓰기 금지).

## Knowledge References
필요 시 Read 도구로 로딩:
- `knowledge/05-skills-system.md` — SKILL.md 포맷, frontmatter 명세, 실제 프로젝트 패턴
- `knowledge/12-teams-agents.md` — 섹션 12.7a: Agent-Skill 분리 아키텍처 패턴
- `knowledge/03-file-reference.md` — 파일 명세

## SKILL.md 구조

### Frontmatter (YAML)
```yaml
---
name: {skill-name}              # 필수. 파일명(케이스 B) 또는 디렉터리명(케이스 A)과 일치
description: {한 줄 설명}         # 필수. 트리거 매칭 및 문서화 용도
model: {opus|sonnet|haiku}       # 선택. Phase 5에서 결정
role: {role-name}                # 선택. 멀티에이전트 역할 식별
requires:                        # 선택. 사전 로딩 필요 파일
  - {file-path}
allowed_dirs:                    # 선택. 쓰기 범위 제한 (ownership-guard 훅이 참조)
  - {dir-path}/
user-invocable: {true|false}     # 선택. 문서화 메타데이터 — 런타임 가시성 차단은 못함. 실제 가시성은 파일 위치로 결정 (Step 6)
---
```

### 본체 권장 구조
```markdown
# {Skill Title}

## Goal
한 문장 미션. 모든 의사결정의 기준점.

## Focus
- 집중 영역 1: 구체적 설명
- 집중 영역 2: 구체적 설명
- 집중 영역 3: 구체적 설명

## Workflow
1. 단계 — 사용 도구, 판단 기준
2. 단계 — 분기 조건
3. 검증 단계 — 확인 방법

## Output Contract
산출물의 형식, 필수 섹션, 저장 위치.

## Guardrails
- 금지 행위 1: 이유
- 금지 행위 2: 이유
```

## Workflow

### Step 1: 에이전트 순회
Phase 5의 에이전트 목록을 순회하며 각 에이전트에 대해 Step 2-7을 반복한다.
순회 순서: 워크플로우 스텝 순서 → 파이프라인 실행 순서.

### Step 2: 역할 심층 인터뷰

**Phase 2.5 산출물이 있으면**, `## Reference Patterns > 표준 도구·스킬 스택` 의 카테고리별 도구 목록을 "이 에이전트가 주로 사용하는 도구" 후보로 참고한다. 대상 프로젝트에 실제로 설치된 도구(Phase 1-2 스캔 결과)와 교집합을 구해 현실적 스택을 도출한다.

해당 에이전트의 역할을 심층 파악하여 Escalations에 확인 사항 기록:
- 이 에이전트가 정확히 무엇을 해야 하는가?
- 어떤 파일/디렉터리를 다루는가?
- 어떤 도구를 주로 사용하는가? (Read, Write, Edit, Bash, Grep, Agent, SendMessage 등)
- 어떤 도메인 지식이 필요한가?
- 무엇을 절대 하면 안 되는가?

### Step 3: Focus 영역 정의
에이전트의 핵심 집중 영역 3-5개를 정의한다.
각 영역에 구체적 설명과 판단 기준을 포함.
확인 사항을 Escalations에 기록.

### Step 4: Workflow 단계 설계
에이전트의 작업 순서를 3-8단계로 설계한다.
각 단계: 사용 도구, 판단 기준, 분기 조건 포함.
확인 사항을 Escalations에 기록.

### Step 5: Output Contract 및 Guardrails 정의
- 산출물: 형식(코드/문서/보고서), 필수 섹션, 저장 위치
- 가드레일: 금지 행위 3-5개, 각각의 이유
확인 사항을 Escalations에 기록.

### Step 6: 스킬 저장 위치 결정 (필수)

Claude Code 런타임은 `.claude/skills/` 아래의 SKILL.md를 **자동 디스커버리**하여 메인 세션의 "사용 가능한 스킬" 목록에 노출한다. 이 노출은 `user-invocable: false` 프론트매터로 차단되지 **않는다** (프론트매터는 메타데이터일 뿐, 런타임의 가시성 필터가 아니다). 따라서 "메인 세션이 이 스킬을 직접 호출하면 안 되는" 경우에는 **파일 위치 자체를 `.claude/skills/` 밖으로** 두어야 한다.

각 스킬에 대해 다음 결정표에 따라 위치를 확정한다:

| 케이스 | 스킬의 성격 | 저장 위치 | user-invocable 프론트매터 | 에이전트의 참조 방식 |
|--------|-----------|----------|--------------------------|---------------------|
| **A. 사용자 진입점** | 사용자가 `/slash-command`로 직접 실행하거나, 메인 세션이 자동 매칭하여 호출하는 스킬 | `.claude/skills/{skill-name}/SKILL.md` | `true` | 없음 (스킬이 독립 실행) |
| **B. 에이전트 전용 (오케스트레이터 패턴)** | 메인 세션은 라우팅만 하고, 서브에이전트가 Read하여 실행하는 방법론 | `playbooks/{skill-name}.md` | 해당 필드 생략 또는 `false` (문서화 용도) | 에이전트 정의의 `Playbooks` 섹션에 경로 기재 |
| **C. 하이브리드** | 같은 프로젝트에 A, B가 공존 | 각자 해당 위치 | 각 케이스에 맞게 | 케이스별 |

#### 케이스 판별 절차
1. Phase 5 산출물 `04-agent-team.md`의 **Orchestrator Pattern Decision**을 확인한다
   - "오케스트레이터 패턴: Yes" → 기본 케이스 B
   - "오케스트레이터 패턴: No" → 기본 케이스 A
2. Phase 3 산출물 `02-workflow-design.md`에서 해당 스킬이 **워크플로우 진입점**에 연결된 스텝인지 확인
   - 진입점이면 케이스 A로 조정 (사용자가 `/skill-name`으로 직접 호출해야 함)
   - 에이전트 체인 내부 스텝이면 케이스 B 유지
3. 판별이 모호하면 `[BLOCKING]` Escalation으로 기록한다 (메인 세션 가시성 여부는 설계 정합성을 가르는 결정 — 임의로 넘어가지 않는다)

> **주의**: `.claude/skills/`에 배치된 스킬은 `user-invocable: false`를 써도 메인 세션에 노출된다. "에이전트 전용"을 실제로 강제하려면 반드시 `playbooks/`에 두어야 한다.

### Step 7: 스킬 파일 생성
Step 6에서 결정된 위치에 파일을 생성한다.

- **케이스 A (사용자 진입점)**: `대상 프로젝트/.claude/skills/{skill-name}/SKILL.md`
- **케이스 B (에이전트 전용)**: `대상 프로젝트/playbooks/{skill-name}.md`
  - 기본은 flat 구조.
  - `playbooks/` 디렉터리가 없으면 먼저 생성한다.

#### playbooks/ 구조 규모별 가이드

| 플레이북 수 | 권장 구조 | 설명 |
|------------|----------|------|
| **10개 이하** | flat | `playbooks/*.md` 직하위. 가독성 최우선, 경로 단순 |
| **11~30개** | flat + 접두사 네이밍 | 여전히 flat이지만 카테고리 접두사(`research-code.md`, `research-web.md`, `qa-whitebox.md` 등)로 그룹화 |
| **30개 초과** | 하위 디렉터리 허용 | `playbooks/{category}/{name}.md` 형태. 카테고리 디렉터리는 에이전트 역할군(research/, planning/, qa/ 등) 기준으로 나눈다 |

하위 디렉터리를 쓰더라도 `playbooks/`는 여전히 `.claude/skills/` 밖이므로 자동 디스커버리 대상이 아니다 — 메인 세션 우회 문제는 발생하지 않는다.

에이전트 정의의 `## Playbooks` 섹션에서 참조할 때는 하위 경로를 그대로 기재(예: `playbooks/research/code-research.md`). 하위 디렉터리 도입 시 기존 참조 경로를 모두 업데이트해야 한다.

플레이북 수가 10개를 넘어가기 전까지는 flat을 유지하고, 그 시점에 카테고리 분할을 **Escalations에 기록하여 사용자에게 확인**한다 — 임의로 구조를 변경하지 않는다.

전체 내용을 산출물에 포함하여 오케스트레이터가 승인 처리.

**다중 에이전트 프로젝트(오케스트레이터 패턴)일 때 각 스킬 본문에 삽입할 필수 섹션:**

```
## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. AskUserQuestion 사용 금지.
모든 확인 사항은 산출물의 Escalations 섹션에 [BLOCKING]/[ASK]/[NOTE] 태그로 기록한다.

## Output Contract
- Summary, Files Generated, Escalations, Next Steps 포함
- 다음 Phase가 필요로 하는 정보를 "Context for Next Phase" 섹션에 구조화
```

위 두 섹션은 본 어시스턴트 메타 규칙의 복사가 아니다. 대상 프로젝트의 서브에이전트 협업
규약으로서 포함한다. 단독 에이전트 프로젝트에서는 불필요하다.

### Step 8: references/ 디렉터리 (선택)
스킬에 참조 자료가 필요한 경우 (API 문서, 코드 패턴, 체크리스트 등) 위치 케이스에 따라 배치한다:

- **케이스 A (`.claude/skills/` 배치)**: `.claude/skills/{skill-name}/references/`에 참조 파일 배치. SKILL.md에서 상대 경로(`@references/guide.md`)로 임포트 또는 Read.
- **케이스 B (`playbooks/` 배치)**: flat 구조이므로 참조 자료는 `playbooks/references/{skill-name}/`에 배치한다. 스킬 본문에서 해당 경로를 절대/상대 경로로 Read.

**금지 사항 (방어적 규율 — Claude Code 런타임의 자동 디스커버리 동작이 재귀적일 가능성에 대비):**
- `references/` 하위에 **SKILL.md 파일을 절대 두지 않는다**. 재귀 디스커버리가 일어나면 그 SKILL.md가 "사용 가능한 스킬"로 노출되어 메인 세션이 직접 호출할 수 있다. 재귀 여부와 무관하게 이 규칙은 안전하다.
- references/ 하위의 파일명은 `SKILL.md`, `SKILLS.md`, `skill.md` 등 스킬 디스커버리가 매칭할 수 있는 이름을 피한다. 일반적인 문서 이름(`guide.md`, `patterns.md`, `api-spec.md`)을 사용한다.
- references/ 안에 임의의 YAML frontmatter가 달린 .md 파일을 두는 것도 피한다. 디스커버리가 frontmatter 기반으로 매칭할 수 있다.

참조 자료 필요 여부 및 배치 위치를 Escalations에 기록.

### Step 9: 전체 스킬 목록 검증
모든 스킬 파일 작성 완료 후:
1. 스킬 간 역할 중복 검사 (위치 A/B 관계없이)
2. allowed_dirs 충돌 검사 (두 에이전트가 같은 디렉터리에 쓰는 경우)
3. Agent-Skill 소유권 검증: 각 스킬이 정확히 하나의 에이전트에 소속되는지 확인
4. Agent-Skill 매핑 검증: Phase 5에서 생성된 에이전트 정의의 `Playbooks`/`Skills` 섹션이 참조하는 파일이 실제로 생성되었는지 확인 (경로가 위치 케이스와 일치하는지 포함)
5. allowed_dirs-훅 사전 검증: 각 스킬의 allowed_dirs 목록을 정리하여 Phase 7 훅 설계의 입력 데이터로 산출물에 포함
6. **가시성 일관성 검증**: 오케스트레이터 패턴(케이스 B)으로 판정된 스킬이 실수로 `.claude/skills/` 아래에 있지 않은지 확인. 있으면 `[BLOCKING]` Escalation — 메인 세션 우회 문제가 재현됨
7. **모델 필드 일관성 검증**: 각 SKILL.md frontmatter의 `model` 필드가 Phase 5 `04-agent-team.md` Agent Model Table 및 `.claude/agents/{에이전트}.md` frontmatter `model` 과 일치하는지 확인. 불일치 시 `[BLOCKING] 모델 필드 드리프트: {스킬} SKILL.md={A}, agents/*.md={B}, 04-agent-team.md={C}` Escalation (Model Confirmation Gate 재소환 시 `phase-skills` 가 SKILL.md 까지 동기화했는지 재확인 용도)
8. 전체 스킬 목록을 트리 구조로 제시 (`.claude/skills/`와 `playbooks/` 두 섹션으로 구분)
9. 최종 확인 사항을 Escalations에 기록

### Step 10: Phase 7로 전환
스킬 작성이 완료되면 Phase 7 `/hooks-mcp-setup`으로 전환한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/05-skill-specs.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Skills Created` — 생성된 각 스킬 파일 경로, 소속 에이전트, 저장 위치 케이스(A/B), 한 줄 설명
- [ ] `## allowed_dirs Consolidation` — 스킬별 `allowed_dirs` 종합 목록 (Phase 7 입력 데이터)
- [ ] `## Location Decisions` — 각 스킬의 저장 위치 케이스(A: `.claude/skills/` / B: `playbooks/`)와 판별 근거. 케이스 B가 하나라도 있으면 "오케스트레이터 패턴 준수" 표기
- [ ] `## Final Agent-Skill Mapping` — Phase 5와 일치 확인된 최종 매핑. 각 에이전트 정의가 참조하는 경로가 실제 파일 위치와 일치하는지 확인 완료 표기
- [ ] `## Context for Next Phase` — Phase 7-8이 필요한 정보:
  - `allowed_dirs` 종합 목록 (소유권 훅 설계 입력)
  - 각 스킬의 저장 위치 케이스 (훅이 검사할 경로 결정)
  - 에이전트-스킬 최종 매핑 (경로 포함)
  - 소유권 가드 필요 여부
- [ ] `## Files Generated` — 생성된 파일 목록을 두 섹션으로 구분:
  - `.claude/skills/**/SKILL.md` (케이스 A)
  - `playbooks/*.md` (케이스 B)
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 7-8: hooks-mcp-setup 에이전트 소환 권장"

### 대상 프로젝트 반영
케이스에 따라 다음 위치 중 하나 또는 둘 다에 파일을 생성한다:
- **케이스 A**: `.claude/skills/{skill-name}/SKILL.md` + 필요 시 `.claude/skills/{skill-name}/references/`
- **케이스 B**: `playbooks/{skill-name}.md` (flat) + 필요 시 `playbooks/references/{skill-name}/`
- 모든 스킬 파일은 유효한 YAML frontmatter 포함

### 병렬 생성 가이드 (선택)
스킬이 3개 이상이고 상호 독립적이면 TeamCreate로 병렬 제작을 고려:
1. TeamCreate("skill-forge-batch")
2. 스킬당 Agent 소환 (team_name 지정)
3. 각 에이전트의 산출물을 부모가 수집하여 `05-skill-specs.md`에 통합
스킬 수가 2개 이하이거나 서로 참조하는 경우 순차 제작이 안전하다.

## 스킬 크기 가이드라인
| 역할 복잡도 | 페이지 수 | 예시 |
|------------|----------|------|
| 단순 (검증, 린트) | 3-5p | qa-lint, syntax-check |
| 중간 (구현, 분석) | 7-10p | build-ui, analyze-data |
| 복잡 (설계, 아키텍처) | 10-15p | tech-lead, architect |
| 심층 전문가 | 15+p | API 테스트 (응답 예시, 트러블슈팅 포함) |

## Guardrails
- 스킬 내용을 임의로 채우지 않음. 모든 Focus/Workflow/Guardrails는 이전 Phase 산출물과 Escalations 기반.
- "일반적으로 좋은 관행"을 묻지 않고 삽입하지 않음.
- 생성된 SKILL.md에 이 도구(Project Architect)의 메타 규칙을 포함하지 않음.
- 사용자가 "모르겠어요"라고 하면 해당 섹션에 `# TODO:` 주석을 남기고 넘어감.
- **대상 프로젝트의 `.claude/skills/*/SKILL.md` 에 오케스트레이션 로직을 쓰지 않는다.**
  - 구체적으로 금지: "이 스킬은 다른 에이전트를 Agent 도구로 소환한다", "Phase 전환 지시", "서브에이전트 반환 포맷 규약", "오케스트레이터 프로토콜 복제".
  - 스킬은 **도메인 로직**(자신이 수행할 작업의 Focus / Workflow / Guardrails)만 담는다. 에이전트 간 조율은 에이전트 정의(`.claude/agents/*.md`) 또는 `playbooks/` 측 책임.
  - 이유: Claude Code는 `.claude/skills/` 아래 SKILL.md를 자동 노출한다. 오케스트레이션 로직이 포함되면 메인 세션이 직접 실행하여 에이전트 소환을 우회하고, 대상 프로젝트에서 예측 불가한 호출 체인이 발생한다.
