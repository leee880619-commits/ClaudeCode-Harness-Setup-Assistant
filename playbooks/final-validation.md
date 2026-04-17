
# Final Validation

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록하여 오케스트레이터에 반환한다.

## Goal
대상 프로젝트에 생성된 전체 하네스의 정확성, 일관성, 완전성을 검증하고 최종 보고서를 생성한다.

## Prerequisites
- Phase 1~8이 완료되어 하네스 파일이 대상 프로젝트에 생성된 상태
- 대상 프로젝트 경로가 제공된 상태

## Knowledge References
필요 시 Read 도구로 개별 로딩:
- `knowledge/03-file-reference.md` — 18개 파일 명세 (검증 기준)
- `knowledge/11-anti-patterns.md` — 안티패턴 체크리스트
- `checklists/validation-checklist.md` — 검증 항목
- `checklists/security-audit.md` — 보안 검사
- `checklists/meta-leakage-keywords.md` — 메타 누수 감지 키워드

## Workflow

### Step 1: 파일 인벤토리
대상 프로젝트의 하네스 파일을 모두 수집하고 목록화한다:
```
[확인 대상]
- CLAUDE.md (존재, 줄 수, @import 참조 유효성)
- .claude/settings.json (존재, JSON 유효성)
- .claude/settings.local.json (존재, JSON 유효성)
- .claude/rules/*.md (각 파일: frontmatter 유무, 줄 수)
- .claude/skills/*/SKILL.md (각 파일: name/description 프론트매터) ← 사용자 진입점 스킬
- playbooks/*.md (각 파일: name/description 프론트매터) ← 에이전트 전용 스킬 (오케스트레이터 패턴일 때)
- .claude/agents/*.md (각 파일: name/description/model 프론트매터, 줄 수, 스킬/플레이북 참조 경로 유효성)
- .claude/hooks/*.sh (존재, 실행 권한)
- CLAUDE.local.md (존재)
- .gitignore (CLAUDE.local.md, settings.local.json 포함 여부)
```

Phase 5 산출물(`04-agent-team.md`)의 **Orchestrator Pattern Decision**을 먼저 확인하여 기대되는 스킬 위치를 판단한다:
- D-1 (오케스트레이터 패턴) → 모든 에이전트 전용 스킬이 `playbooks/`에 있어야 함. `.claude/skills/`에 있으면 `[BLOCKING]`
- D-3 (단일 진입점) → 모든 스킬이 `.claude/skills/`에 있어야 함. `playbooks/` 있으면 `[ASK]`
- D-2 (하이브리드) → 두 위치 혼재 정상. 각 스킬이 기대 위치에 있는지 매핑 검증

### Step 2: 구문 검증
1. JSON 파일: jq로 파싱 가능 여부 확인
2. YAML 프론트매터: `---` 구분자 쌍, paths 배열 형식
3. Markdown: 비어있는 파일 없는지
4. Shell 스크립트: 실행 권한(chmod +x)

### Step 3: 일관성 검증
1. permissions.deny가 allow를 무의미하게 만들지 않는지
2. rules의 path 패턴이 실제 프로젝트 구조와 매칭되는지
3. @import 참조가 실존 파일을 가리키는지
4. `.claude/skills/*/SKILL.md`와 `playbooks/*.md`가 모두 유효한 frontmatter를 갖는지
5. `.claude/agents/*.md`가 참조하는 스킬/플레이북 파일이 실제로 존재하는지 (Playbooks 섹션은 `playbooks/*.md`, Skills 섹션은 `.claude/skills/*/SKILL.md` 경로 검증)
6. Agent-Skill 매핑 완전성: 에이전트 없는 스킬, 스킬 없는 에이전트 확인 (두 위치 통합 검사)
7. **가시성 일관성**: Phase 5의 Orchestrator Pattern Decision이 D-1(오케스트레이터)인데 `.claude/skills/` 아래 에이전트 전용 스킬이 놓여있으면 실패 — 메인 세션 우회 문제 재현됨 → `[BLOCKING]`
8. hooks의 matcher 패턴이 의미있는지
9. env 환경변수에 비밀값이 없는지 (sk-, ghp_, AKIA, xoxb- 패턴 검사)
10. **다중 에이전트 프로젝트 규율 검증** (해당 시):
    - 각 에이전트의 Rules 섹션에 "AskUserQuestion 직접 사용 금지, Escalations 기록" 문구 포함 여부
    - 각 스킬의 "질문 소유권" 섹션 존재 여부 (`.claude/skills/`, `playbooks/` 둘 다 검사)
    - 각 스킬의 "Output Contract"에 Summary/Files Generated/Escalations/Next Steps/Context for Next Phase 항목이 명시되어 있는지
11. **Phase Gate / docs 체인 검증** (에이전트 프로젝트일 때):
    - 대상 프로젝트에 `docs/{요청명}/` 디렉터리와 번호 순서 산출물이 존재하는지

### Step 4: 메타 누수 검사
checklists/meta-leakage-keywords.md의 금지 키워드를 대상 프로젝트의 생성 파일에서 검색:
- "질문을 먼저", "가정하지 마세요", "하네스 에이전트"
- "Harness Setup Assistant", "setup agent"
- 이 도구의 행동 규칙이 생성 파일에 포함되지 않았는지

### Step 5: 보안 감사
checklists/security-audit.md 기반:
1. `Bash(*)` 가 allow에 없는지
2. `Bash(sudo *)` 가 allow에 없는지
3. 필수 deny 목록 포함 여부: rm -rf /, sudo rm *, git push --force *
4. 비밀값이 settings.json(git 공유)에 없는지

### Step 6: 시뮬레이션 검증
2~3개 대표 시나리오로 파일 참조 체인을 추적:
- "사용자가 프로젝트 루트에서 Claude Code를 시작하면?"
  → CLAUDE.md → settings.json → rules(always-apply) → 순서대로 로딩되는지
- "사용자가 특정 파일을 편집하면?"
  → path-scoped rules가 올바르게 매칭되는지
- "사용자가 슬래시 명령을 호출하면?" (케이스 A/D-3 스킬이 있을 때)
  → `.claude/skills/`에서 올바른 SKILL.md가 로딩되는지
- "메인 세션이 요청을 받으면 서브에이전트를 소환하는가?" (D-1 오케스트레이터 패턴일 때)
  → CLAUDE.md의 프로토콜대로 Agent 도구 호출 경로가 유효한지
  → `playbooks/`의 방법론 파일이 에이전트 정의의 Playbooks 섹션 경로와 일치하는지
  → `.claude/skills/` 아래 에이전트 전용 스킬이 잘못 노출되지 않는지

### Step 7: 최종 보고서 생성
텍스트로 최종 보고서를 출력한다 (파일 생성하지 않음):

```
# 하네스 환경 검증 보고서

## 생성된 파일 목록
| 파일 | 크기 | 줄 수 | 유효성 |
|------|------|------|--------|
| ... | ... | ... | ✓/✗ |

## 검증 결과
- 구문 검증: PASS/FAIL (상세)
- 일관성 검증: PASS/FAIL (상세)
- 메타 누수 검사: PASS/FAIL (상세)
- 보안 감사: PASS/FAIL (상세)
- 시뮬레이션: PASS/FAIL (상세)

## 이 설정의 효과 요약
"이 설정으로 Claude는 X를 자동 실행하고, Y는 매번 확인합니다.
Z 규칙에 따라 코드를 작성하며, W 스킬로 전문 작업을 수행합니다."

## 다음 단계 안내
1. CLAUDE.local.md를 개인 취향에 맞게 편집하세요
2. 첫 세션에서 Claude에게 "현재 하네스 구성을 확인해줘"라고 요청하세요
3. 필요 시 /harness-audit로 정기 점검하세요
```

### Step 8: Escalations 기록 (사용자 확인은 오케스트레이터가 처리)
최종 확인 사항을 Escalations 섹션에 기록:
- 검증 실패 항목 → `[BLOCKING]`으로 기록
- 수정 필요 시 → Next Steps에 "해당 Phase 에이전트 재소환" 제안
- 확인 완료 시 → Summary에 "프로젝트 하네스 구축 완료" 선언
AskUserQuestion을 직접 호출하지 않는다 (스킬은 서브에이전트에서 실행됨).

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/07-validation-report.md`에는 다음을 **반드시** 포함한다.
보고서 자체도 **파일로 저장**한다 (이전 관행 수정: 후속 재검증과 재개를 위해 필요).

### 필수 섹션
- [ ] `## Summary` — 전체 PASS/FAIL 요약
- [ ] `## File Inventory` — 생성된 모든 하네스 파일 목록 + 크기 + 유효성
- [ ] `## Syntax Check` — JSON, YAML frontmatter, Markdown, 쉘 스크립트 권한
- [ ] `## Consistency Check` — 8개 항목 (위 Step 3)
- [ ] `## Meta-Leakage Check` — 키워드 감지 결과
- [ ] `## Security Audit` — 권한/비밀값 검사 결과
- [ ] `## Simulation Trace` — 2~3개 시나리오 참조 체인 추적
- [ ] `## Escalations` — `[BLOCKING]`으로 실패 항목 분류
- [ ] `## Effect Summary` — 자연어 효과 요약 ("이 설정으로 Claude는 X...")
- [ ] `## Next Steps` — 성공 시 "하네스 구축 완료", 실패 시 재소환할 Phase 에이전트

## Guardrails
- 이 스킬은 새 **하네스** 파일을 생성하거나 수정하지 않는다 (하네스는 읽기 + 검증만).
  단, 검증 보고서 파일(`07-validation-report.md`)은 생성한다.
- 검증 실패 시 자동 수정하지 않고 Escalations에 기록만 한다.
