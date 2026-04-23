
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
- docs/{요청명}/02b-domain-research.md (선택) — Phase 2.5 산출물. 존재하면 Summary에 "스킵됨"이 아닌지 확인, Sources 섹션 유무 체크
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
12. **Phase 2.5 도메인 리서치 반영 검증** (02b 존재하고 스킵이 아닐 때):
    - Phase 3-6 산출물(`02-workflow-design.md` ~ `05-skill-specs.md`)에서 "02b-domain-research.md" 인용 흔적이 최소 1회 이상 존재하는지 grep으로 확인
    - 없으면 `[NOTE] 도메인 리서치 산출물이 후속 Phase 설계에 반영되지 않음 — 의도인지 확인 필요`
13. **산출물 필수 섹션 스키마 검증** — 각 Phase 산출물(`docs/{요청명}/NN-*.md`)에 대해:
    - 모든 산출물: `^## Summary$`, `^## Files Generated$`, `^## Context for Next Phase$`, `^## Escalations$`, `^## Next Steps$` 5개 헤더 정규식 매칭
    - Phase 9 자체 보고서(`07-validation-report.md`): 추가로 `^## File Inventory$`, `^## Security Audit$`, `^## Simulation Trace$` 요구
    - **Phase 3 산출물 (`02-workflow-design.md`)** — 대상 프로젝트가 에이전트 파이프라인·오케스트레이터 구조인 경우: `^## Session Recovery Protocol$` 헤더 요구 (헤더 아래 "단일 세션 완결 — 복구 프로토콜 미필요" 한 줄 도피는 Advisor Dim 13이 품질 검증)
    - **Phase 4 산출물 (`03-pipeline-design.md`)**: `^## Failure Recovery & Artifact Versioning$` 헤더 요구 (각 파이프라인별 max_retries·timeout·버저닝 전략 품질 검증은 Advisor Dim 13)
    - **경량 트랙 산출물 (`02-lite-design.md`)**은 위 Phase 3·4 추가 요구에서 제외 — 단일 패스 설계상 Session Recovery Protocol은 `setup-lite.md` Output Contract의 `session_recovery: not_applicable` 필드로 명시 대체
    - 매칭 실패 시 `[BLOCKING] 산출물 {파일명} 필수 섹션 {누락 헤더} 없음` 으로 기록. 오케스트레이터가 해당 Phase 에이전트 재소환 트리거.
14. **`@import` 중복 로드 검증 (비용 절감 가드)** — CLAUDE.md의 모든 `@import` 지시자에 대해:
    - `@import path/to/file.md` 지정 파일이 실존하는지 (3번에서 이미 검사됨)
    - **신규**: @import 대상 파일의 ATX 헤더 목록과 본문 CLAUDE.md의 ATX 헤더 목록을 추출해 교집합을 계산. 교집합 비율이 **50% 이상**이면 `[NOTE] @import {대상 경로} 내용이 CLAUDE.md 본문과 상당 부분({N}%) 중복 가능성. 매 세션 cache write 누적 → 제거·축약 검토 권장`
    - @import 대상 파일 크기(byte)도 기록. **20KB 초과** 대상은 `[NOTE] @import {대상 경로} {N}KB 대형 파일 — 매 세션 로드됨. 최신 요약만 남기고 아카이브 분리 검토` 추가
    - Phase 5~9 산출물(`04-agent-team.md`, `05-skill-specs.md` 등)이 CLAUDE.md에 @import 되어 있으면서 해당 산출물의 "Agent Model Table" / "Final Agent-Skill Mapping" 같은 섹션 이름이 CLAUDE.md 본문 섹션 이름과 겹치면 BLOCK 후보로 승격 (Phase 설계 단계에서 @import 의무가 아님에도 과잉 @import한 정황).
    - 이 검증은 `[BLOCKING]`이 아닌 `[NOTE]`/`[ASK]` 수준으로 기록 — 사용자 결정 대상이지 자동 제거 대상이 아니다.

15. **절대 경로 하드코딩 감지** — 생성된 CLAUDE.md, 스킬·에이전트·플레이북 파일에서:
    - **Scan 범위 제한**: 대상 프로젝트 하네스 파일만 (`{대상}/CLAUDE.md`, `{대상}/.claude/**`, `{대상}/playbooks/**`). 플러그인 자체(`${CLAUDE_PLUGIN_ROOT}`)나 프로젝트 소스 코드는 제외.
    - `/Users/`, `/home/`, `/mnt/c/Users/`, `C:\Users\`, `C:/Users/` 패턴을 grep으로 탐지 (`grep -rn "\/Users\/\|\/home\/\|\/mnt\/c\/Users\|C:\\\\Users\|C:/Users" {대상}/.claude {대상}/CLAUDE.md {대상}/playbooks`)
    - **제외 패턴**: `${CLAUDE_PLUGIN_ROOT}`, `${TARGET_PROJECT_ROOT}` 환경변수 참조, **코드 예시 블록 내 경로**(fenced code 블록 내부의 WSL/Unix 경로는 설명용 샘플이므로 제외)
    - 발견 시 `[ASK] 머신 특정 절대 경로 발견: {파일명}:{줄번호} "{경로}". 범용 하네스로 설계된 경우 환경변수·상대 경로로 교체 권장 — 다른 머신 또는 다른 사용자 환경에서 하네스가 작동하지 않을 수 있음.`
    - 이 검사는 `[BLOCK]`이 아닌 `[ASK]` 수준 — 의도적으로 특정 환경 전용으로 설계된 경우 허용

17. **Intent Gate 베이스라인 설치 검증** (모든 대상 프로젝트 공통, 복잡도·도메인·에이전트 여부 무관):
    - `.claude/rules/intent-gate.md` 존재 + 프론트매터에 `alwaysApply: true` 포함 확인. 누락 시 `[BLOCKING] Intent Gate 규칙 누락 — fresh-setup Step 3-F 베이스라인 미설치 또는 이후 삭제됨`.
    - `.claude/skills/intent-clarifier/SKILL.md` 존재 + 프론트매터 `name: intent-clarifier` 확인. 누락 시 `[BLOCKING] Intent Clarifier 스킬 누락`.
    - `CLAUDE.md` 에 `^## 작업 시작 전$` 헤더 존재 + 섹션 본문에 `intent-gate.md` 와 `intent-clarifier` 문자열 모두 포함 확인. 누락 시 `[BLOCKING] CLAUDE.md Intent Gate 참조 섹션 누락`.
    - 위 3개 중 하나라도 BLOCKING 이면 오케스트레이터에게 `phase-setup` 재소환 또는 `/harness-architect:audit` 자동 패치 경로 안내. 산출물 `## Intent Gate` 섹션에 결과 명시.

16. **워크플로우 간 스킬·플레이북 구조 중복 감지** — 복수의 스킬·플레이북 파일이 존재할 때:
    - 각 파일의 ATX 헤더(`^## ` 또는 `^### `) 목록을 추출하여 쌍별 비교
    - 헤더 이름의 집합 기준 Jaccard 유사도가 **70% 이상**인 파일 쌍 탐지 (`grep -n "^##" {파일}` 로 추출 후 비교)
    - 발견 시 `[NOTE] 스킬/플레이북 {파일A}와 {파일B}의 섹션 구조 유사도 {N}% — 공통 로직 추출 또는 기반 템플릿화 검토. (유사도는 섹션 이름 기준 추정치이며 내용 중복 여부는 별도 판단 필요)`
    - 이 검사는 정보성 `[NOTE]` 수준이며 자동 제거·BLOCK 대상이 아님
    - **SSoT — 양방향 교차 참조**: 이 검사의 70% Jaccard 임계값과 비교 로직은 `playbooks/ops-audit.md` Dim E와 **동일 기준**이다 (양방향 SSoT). 값 변경 시 양쪽 동시 수정 필수. `ops-audit` 커맨드(사후 감사)와 Phase 9(빌드 중 검증) 결과가 상이하면 실행 시점 차이로 간주하고 최신 ops-audit 결과를 우선. 반대로 ops-audit Dim E 변경 시 본 항목도 동반 갱신.

### Step 4: 메타 누수 검사
checklists/meta-leakage-keywords.md의 금지 키워드를 대상 프로젝트의 생성 파일에서 검색:
- "질문을 먼저", "가정하지 마세요", "하네스 에이전트"
- "Harness Setup Assistant", "setup agent"
- 이 도구의 행동 규칙이 생성 파일에 포함되지 않았는지

### Step 5: 보안 감사 (복잡도 게이트 무관 — 항상 전체 실행)

이 Step은 `orchestrator-protocol.md` 의 "복잡도 게이트" 경량화 조건과 **무관하게 모든 프로젝트에서 전체 실행**한다. 단순 프로젝트에서도 Secret 노출·권한 과잉은 치명적이다.

> **권위 게이트**: 이 Step은 Dim 6 위반의 **최종 권위 판정 지점**이다. Phase 3-6 Advisor 에서 `[NOTE]` 로 기록된 설계 레벨 보안 관심사(Advisor Dim 6 매트릭스에 따른 서술적 언급)는 여기서 실제 파일 기준으로 [BLOCK]/[ASK]/PASS 판정된다. `.claude/rules/orchestrator-protocol.md` 의 "Dim 6 전체 실행" 원칙은 "시행 시점 localization" 이며 이 Step이 그 localization 의 종착점이다.
>
> **설계 결함이 여기서 처음 발견되는 경우**: Phase 3-6 에서 서술 단계 [NOTE] 에 머물렀던 권한 요구가 `phase-hooks` 산출물에 `Bash(*)` 와일드카드로 반영된 상황이 있을 수 있다. 이 경우 `phase-hooks` 재소환 1회로 localized fix 가능.

`checklists/security-audit.md` 기반으로 수동 확인 + 자동 도구 + (선택적) Haiku `security-auditor` 소환을 함께 사용한다:

**Step 5-A: `security-auditor` 소환 (선택적, 비용 절감 경로)**
- 오케스트레이터가 이 Step 직전 `Agent(subagent_type: "security-auditor", ...)` 를 호출했다면, phase-validate 는 Haiku 패턴 매칭 결과를 받아 `## Security Audit` 섹션에 통합한다.
- security-auditor 결과에 `[ASK]` 가 포함되면 phase-validate 는 이를 `[BLOCKING]` 대신 `[ASK]` 로 유지 (Haiku 판단 단독 의존 금지 — 판정 애매 항목은 사용자·Sonnet Advisor 에스컬레이션).
- security-auditor 결과에 `[BLOCK]` 이 있고 해당 패턴이 **명백한 위반**(실제 `Bash(*)` allow 항목, 난수 토큰 등)이면 phase-validate 는 `[BLOCKING]` 으로 승격.

**Step 5-B: 수동 체크 (항상 수행 — security-auditor 소환 여부 무관)**
1. `Bash(*)` 가 allow에 없는지
2. `Bash(sudo *)` 가 allow에 없는지
3. 필수 deny 목록 포함 여부: rm -rf /, sudo rm *, git push --force *
4. 비밀값이 settings.json(git 공유)에 없는지

security-auditor 소환이 실패(타임아웃·에러·미소환) 했으면 이 수동 체크가 1차 게이트. 성공 했어도 수동 체크는 **병렬 확증**으로 실행 — Haiku 단독 의존 금지.

**Step 5-C: 자동 도구** (가능하면 반드시 실행):
- `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-settings.sh {대상 프로젝트 루트}` — jq 기반 정적 검증. 결과(stdout/stderr)를 산출물 `## Security Audit` 섹션에 **첨부**한다. non-zero exit면 `[BLOCKING]` 자동 추가.
- `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-meta-leakage.sh {대상 프로젝트 루트}` — 메타 누수 정적 스캔. 히트 시 `[BLOCKING]`.

jq 미설치·도구 실행 실패 시에도 수동 체크(5-B) 는 반드시 수행하고 Escalations에 "자동 도구 미실행 — 수동 확인만 수행" 로 기록.

**Fallback 우선순위 요약**: security-auditor (Haiku, 저비용) → 수동 체크 (phase-validate 직접) → 자동 도구 (validate-settings.sh). 이 중 **최소 2개 경로가 실행 성공**해야 Dim 6 게이트 통과로 인정. 1개 경로만 성공한 경우 Escalations 에 `[NOTE] Dim 6 게이트 단일 경로만 실행됨 — 이중 확인 권장` 기록.

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

### Step 7: Runtime Spot Check (시나리오 A 자기완결 게이트)

> **설계 근거**: 시나리오 A(완전 신규 설치)의 사용자는 `/harness-architect:harness-setup` 만으로 완결을 기대한다. Phase 9 가 기존에 커버하던 파일 구조·보안·일관성 외에, `ops-audit` Dim B(실패 복구) 와 Dim F(라우팅 프로토콜) 의 핵심 체크를 이식하여 "빌드 직후 운영 중 치명적으로 무너질 구조" 를 차단한다. `fit-audit` 은 드리프트 감사라 빌드 직후엔 구조적으로 드리프트가 0 → 편입 불필요 (통합 감사 `/harness-architect:audit` 참조).

본 스팟 체크는 **ops-audit 의 대체가 아닌 최소 경계**다. 섹션 내용 완결성·라우팅 규약 세부 준수 여부 심층 검증은 여전히 `/harness-architect:ops-audit` 담당.

#### Step 7-A: Failure Recovery 섹션 존재 확인 (ops-audit Dim B 스팟)

`.claude/agents/*.md` 및 `playbooks/*.md` 에 대해 다음을 grep:

- 허용 헤더: `^##\s+Failure Recovery`, `^##\s+실패 복구`, `^##\s+Error Handling`, `^##\s+재시도`
- **Pass 조건**: 헤더가 존재 + 해당 헤더 아래 **비어있지 않은 본문 2줄 이상** (빈 줄·주석만 있는 경우 실패)
- **에이전트·플레이북 전체에서 헤더 0건** → `[ASK] 운영 중 실패 시 종료 조건이 어디에도 명시되지 않음. 루프 탈출 구조 미비 위험 — /harness-architect:ops-audit 실행하여 Dim B 상세 점검 권장`
- **헤더는 있으나 본문 2줄 미만** (placeholder 섹션) → `[ASK] Failure Recovery 섹션이 비어 있거나 placeholder 임 — 의도인지 확인`

> **한계 명시**: 내용의 **완결성**(종료 조건·재시도 상한·에스컬레이션 경로) 까지는 검증하지 않는다. 완결성 심층 검증은 `ops-auditor` Dim B 담당.

#### Step 7-B: 개방형 루프 금지 문구 탐지 (ops-audit Dim B 스팟)

`.claude/agents/`, `.claude/skills/`, `playbooks/`, `CLAUDE.md` 전체에 대해 다음 grep:

- `재설계 요청`, `다시 검증`, `Builder에게 넘김`, `무한 반복`, `지속 시도`
- **매치 1건이라도** → `[BLOCKING] 종료 조건 없는 개방형 루프 지시어 감지 — 운영 중 무한 루프 위험. 해당 섹션을 "max_retries N회 + 초과 시 사용자에게 확인 요청" 패턴으로 수정 필요`

#### Step 7-C: 메인 세션 Skill 직접 호출 위험 패턴 (ops-audit Dim F 스팟)

오케스트레이터가 서브에이전트 소환 대신 `Skill` 도구로 방법론을 직접 실행하면 메인 세션이 서브에이전트 우회로 방법론을 떠맡아 질문 소유권·Target Guardrail 규약이 붕괴한다. 다음 범위에 대해 **구조 패턴 grep** 을 수행한다 (스킬명 문자열 열거가 아닌, `Skill` 도구 호출 구문 자체를 탐지):

- 범위: `{대상}/commands/*.md`, `{대상}/playbooks/*.md`, `{대상}/.claude/agents/*.md`, `{대상}/CLAUDE.md`
- **권위 패턴** (매치 시 즉시 `[BLOCKING]`):
  - `Skill\(skill\s*:` — `Skill(skill: "...")` Tool 호출 구문의 표준 형태. 플러그인 내부 규칙 서술(예: "`Skill(skill: ...)` 사용 금지" 와 같은 메타 코멘트) 와 구분하려면 매치 라인 ±3줄 내에 부정어(`금지`, `NEVER`, `not`, `❌`) 가 있는지 확인 — 부정 문맥이면 제외.
- **False positive 차단**: `Skill` 문자열이 일반 산문(예: "skill" 을 소문자로 언급) 에 등장하는 경우는 패턴에 `\(skill\s*:` 로 엄격히 제한하여 제외. 또한 이 플레이북 파일(`final-validation.md`) 자신·`orchestrator-protocol.md`·플러그인 레포의 메타 규칙 문서는 **대상 프로젝트 범위 밖**이므로 검사 대상이 아님 — 오케스트레이터가 실행 시 `{대상}` 변수를 대상 프로젝트 루트로 엄격히 한정.
- **판정**:
  - 매치 1건 이상 + 부정 문맥 아님 → `[BLOCKING] 메인 세션 Skill 도구 직접 호출 패턴 감지 — 서브에이전트 소환 우회 위험. 해당 지점을 Agent(subagent_type: "...") 패턴으로 수정 필요`
  - 매치 있으나 부정 문맥 (금지 안내) 이면 → PASS 처리하되 `## Runtime Spot Check` 섹션에 "`Skill(skill:` 언급 N건 감지 — 전부 금지 안내 문맥" 로 기록

> **패턴 설계 근거**: 초기 설계는 금지 스킬명을 열거하는 keyword-based 접근이었으나, `harness-audit`·`fit-audit`·`ops-audit` 같은 이름이 대상 프로젝트의 playbook 파일명으로 존재하거나 (contributor 환경) 산문 언급으로 등장하면 false positive 가 구조적으로 발생. 구조 패턴(`Skill(skill:`) 기반으로 재설계하여 "도구 호출 구문" 만 엄격 매치.

#### Step 7-D: docs 체인 frontmatter 무결성 (ops-audit Dim A 스팟)

대상 프로젝트에 `docs/{요청명}/` 이 존재할 때(재개 프로토콜 작동 전제):

- `00-target-path.md` frontmatter 에 `phase`, `completed`, `status`, `track` 4개 필드 모두 존재 확인
- 누락 → `[ASK] docs 체인 재개 프로토콜이 작동하지 않을 수 있음 (frontmatter 필드 누락). 자동 보완 / 수동 편집 / 무시 선택`

#### Step 7 요약

Runtime Spot Check 는 **4개 하위 체크(7-A ~ 7-D)** 를 수행하며 결과를 `## Runtime Spot Check` 섹션에 PASS/FAIL + 상세로 기록한다. `[BLOCKING]` 은 Step 9 Escalations 로 승격.

### Step 8: 최종 보고서 생성
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
- 런타임 스팟 체크: PASS/FAIL (7-A Failure Recovery, 7-B 개방형 루프, 7-C Skill 직접 호출, 7-D docs frontmatter)
- 시뮬레이션: PASS/FAIL (상세)

## 이 설정의 효과 요약
"이 설정으로 Claude는 X를 자동 실행하고, Y는 매번 확인합니다.
Z 규칙에 따라 코드를 작성하며, W 스킬로 전문 작업을 수행합니다."

## 다음 단계 안내
1. CLAUDE.local.md를 개인 취향에 맞게 편집하세요
2. 첫 세션에서 Claude에게 "현재 하네스 구성을 확인해줘"라고 요청하세요
3. 필요 시 `/harness-architect:audit` 로 정기 점검하세요 (구성·런타임·적합성 3축 병렬 감사)
4. `/memory` 슬래시 커맨드로 세션 메모리 상태를 확인하세요 — Claude Code 는 세션 중 학습한 사용자 프로필·피드백·프로젝트 맥락을 `~/.claude/projects/{cwd-encoded}/memory/MEMORY.md` 에 자동 기록합니다 (사용자 홈 영역, 레포 외부). 비어 있어도 정상이며, 초기 맥락을 수동 시딩하려면 `/memory` 로 열어 편집할 수 있고, 그대로 두어도 세션 중 자연 축적됩니다.
```

### Step 9: Escalations 기록 (사용자 확인은 오케스트레이터가 처리)
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
- [ ] `## Runtime Spot Check` — Step 7 결과 (7-A Failure Recovery, 7-B 개방형 루프, 7-C Skill 직접 호출, 7-D docs frontmatter). 시나리오 A 자기완결 게이트.
- [ ] `## Intent Gate` — Step 3의 17번(Intent Gate 베이스라인 설치 검증) 결과. 3개 체크(규칙/스킬/CLAUDE.md 섹션)의 PASS/FAIL 나열.
- [ ] `## Simulation Trace` — 2~3개 시나리오 참조 체인 추적
- [ ] `## Escalations` — `[BLOCKING]`으로 실패 항목 분류
- [ ] `## Effect Summary` — 자연어 효과 요약 ("이 설정으로 Claude는 X...")
- [ ] `## Next Steps` — 성공 시 "하네스 구축 완료", 실패 시 재소환할 Phase 에이전트

## Guardrails
- 이 스킬은 새 **하네스** 파일을 생성하거나 수정하지 않는다 (하네스는 읽기 + 검증만).
  단, 검증 보고서 파일(`07-validation-report.md`)은 생성한다.
- 검증 실패 시 자동 수정하지 않고 Escalations에 기록만 한다.
