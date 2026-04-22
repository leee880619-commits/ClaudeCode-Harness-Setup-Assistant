
# Design Review

## Goal
Phase 에이전트의 산출물이 사용자 목적에 부합하는지, 빠진 것은 없는지,
암묵적 가정이 있는지를 비판적으로 검토한다.

## Review Dimensions

### Dimension 1: 목적-수단 정합성 (WHY → WHAT → HOW)
- 사용자의 최종 목적이 무엇인가? (Phase 0에서 수집한 정보 기반)
- 이 Phase의 산출물이 그 목적에 기여하는가?
- 목적 달성에 필요하지만 아직 설계되지 않은 것이 있는가?

### Dimension 2: 정보 흐름 완전성
- 각 워크플로우 스텝의 입력(input)은 어디서 오는가?
- "허공에서" 나타나는 입력이 있는가? (예: 카드 메시지를 리서치 없이 작성)
- 에이전트가 작업에 필요한 지식을 어떻게 획득하는가?

### Dimension 3: 암묵적 가정 식별
- 사용자에게 확인하지 않고 에이전트가 결정한 사항은?
- "상식적으로 당연한" 것으로 넘어간 결정이 있는가?
- 사용자가 다른 선호를 가질 수 있는 결정인가?

### Dimension 4: 실행 가능성
- 이 설계를 실제로 실행하면 첫 번째로 실패할 지점은?
- 외부 의존성(API, 패키지, 서비스)이 빠져있진 않은가?
- 에러 시나리오가 고려되었는가?

### Dimension 5: 사용자 경험
- 사용자가 이 설정을 받아서 바로 사용할 수 있는가?
- 설명이 필요한 부분이 문서화되지 않은 것은 없는가?

### Dimension 6: 보안 권한 적절성

**검사 원칙**: 실제 하드 텍스트에 위반 패턴이 존재할 때만 [BLOCK]. 설계 스펙의 **서술적 언급**("이 에이전트는 쉘 실행 필요")은 Phase 7-8 에서 실제 파일(`settings.json`, `hooks.json`)로 시행되는 단계에서 시행됨 — 조기 Phase 에서는 [NOTE] 로 기록하고 Phase 7-8 에 시행 책임을 위임한다.

> **참고**: 이 매트릭스는 **경량화가 아닌 시행 시점 localization**. 모든 위반 패턴은 최소 1회 [BLOCK] 으로 승격되며(Phase 7-8 또는 Phase 9 에서), Phase 3-6 에서 [NOTE] 처리된 항목은 이후 실제 파일 레벨에서 시행된다. `.claude/rules/orchestrator-protocol.md` 의 "Dim 6 복잡도 게이트 무관 전체 실행" 원칙은 그대로 유지된다.

**Phase별 Dim 6 등급 매트릭스**:

| Phase | 산출물 유형 | 실제 JSON/settings 패턴 위반 | 서술적 언급 | 실제 비밀값 | 더미/플레이스홀더 비밀값 |
|-------|-----------|---------------------------|-----------|-----------|-----------|
| 3-6 | 설계 마크다운 | [BLOCK] | [NOTE] Phase 7-8 에서 시행됨 | [BLOCK] (어디서든 즉시) | [ASK] — 교육용 예시 의도 확인 |
| 7-8 | 실제 `settings.json` / `hooks.json` | [BLOCK] (최종 시행) | N/A | [BLOCK] | [BLOCK] — 실제 파일은 주석 예시로만 허용 |
| 9 | final-validation 보고서 | Step 5 자체 판정 | Step 5 자체 판정 | Step 5 자체 판정 | Step 5 자체 판정 |

**패턴 정의**:
- 와일드카드 위반 패턴: `Bash(*)`, `Bash(sudo *)`, `Bash(rm -rf *)`, `Bash(git push --force *)`
- 비밀값 패턴: `sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer `
- 필수 `deny` 항목: `Bash(rm -rf /)`, `Bash(sudo rm *)`, `Bash(git push --force *)`

**실제 비밀값 vs 더미 판정**:
- **실제 비밀값**: 난수성 높은 토큰 문자열, 문서 맥락이 교육적이지 않음 → [BLOCK]
- **더미/플레이스홀더**: `sk-XXXXXX`, `ghp_<YOUR_TOKEN>`, `<YOUR_API_KEY>`, `AKIA-EXAMPLE-KEY`, 반복 문자(`ghp_0000...`), 명시적 `YOUR`/`EXAMPLE`/`<...>` 마커 포함 → Phase 3-6 [ASK], Phase 7-8 [BLOCK]
- **판정 애매 시**: [BLOCK] 금지, [ASK] 로 에스컬레이션 (사용자 또는 맥락 판단 가능한 상위 권위에 위임)

**필수 `deny` 누락**: Phase 7-8 에서 [BLOCK] (settings.json 최종 확정 시점), Phase 3-6 에서는 [NOTE] (미확정 파일은 보류).

**Phase 7-8 리뷰에서는 엄격**: Phase 3-6 에서 [NOTE] 로 기록된 모든 서술적 보안 관심사가 실제 `settings.json`·`hooks.json` 에 반영되었는지 확인. 예: Phase 5 에서 "이 에이전트는 쉘 실행 필요" [NOTE] 가 있었다면, Phase 7-8 산출물에 이 에이전트의 `allowed_tools` 가 `Bash(*)` 가 아닌 구체 패턴으로 제한되었는지 확인. 미흡 시 [BLOCK].

이 Dimension은 **복잡도 게이트와 무관하게 항상 전체 실행**한다 — 위 매트릭스의 Phase별 등급은 경량화가 아닌 **시행 시점 명확화** 이며, 모든 위반은 결국 [BLOCK] 으로 시행된다.

### Dimension 7: 타깃 프로젝트 특이성

- Phase 1-2의 스캔 결과(실제 파일 구조, 실존하는 기술 스택, 테스트 도구)와 Phase 3-6의 설계가 정합하는가?
- 예: 스캔에 Python/Django가 잡혔는데 설계에 Node/Express 도구가 등장하거나, 모노레포인데 단일 루트 CLAUDE.md만 설계되면 `[BLOCK]`.
- 사용자가 명시한 프로젝트 유형(웹앱/CLI/에이전트/데이터/콘텐츠)과 설계가 어긋나면 `[BLOCK]`.

### Dimension 8: 에이전트 소유권 충돌

- Phase 5 팀 편성·Phase 6 스킬 명세의 `allowed_dirs` 가 두 개 이상의 에이전트에서 겹치는가?
- 겹치는 디렉터리가 **의도된 공유 영역**(docs/ 같은 공용 산출물)이 아니면 `[BLOCK]`.
- 같은 파일을 두 Phase가 모두 수정하도록 설계되지 않았는가 (예: CLAUDE.md 본문을 Phase 1-2와 Phase 3 둘 다 재작성) → `[BLOCK]`.

### Dimension 9: 미기록 결정 감지

- 에이전트 반환의 `## Escalations` 가 "없음"인데, Summary·`## Context for Next Phase`·산출물 본문에 **사용자 확인 없이 에이전트가 스스로 내린 결정**이 포함되어 있는가?
- 예: 사용자가 "에이전트 수 미정"이라고 했는데 Phase 5가 "3개 에이전트"로 확정했고 Escalations는 "없음". 이는 AskUserQuestion 독점을 우회한 조용한 결정 → `[ASK]` 또는 사안 중대성에 따라 `[BLOCK]`.
- 서브에이전트가 오케스트레이터 몰래 AskUserQuestion을 호출했을 가능성(대화 흐름에 "사용자 답변 반영"이라는 문구가 등장하지만 Escalations 기록이 없음)도 이 항목으로 감지.

### Dimension 10: 도메인 리서치 정합성 (Phase 2.5 존재 시)

Phase 2.5 산출물(`docs/{요청명}/02b-domain-research.md`) 이 존재하는 경우, 이후 Phase 3-6 리뷰 시 추가 확인:

- **Phase 3-6 산출물이 02b의 도메인 패턴을 실제로 반영했는가?** 워크플로우 스텝명·역할명·도구명에 02b의 인용(`출처: 02b-domain-research.md`) 흔적이 있는지 확인. 없으면 `[NOTE] 도메인 리서치가 설계에 반영되지 않음 — 의도인가?` 또는 `[ASK]`.
- **02b 산출물 자체의 검증** (Phase 2.5 리뷰 시):
  - 모든 외부 주장에 출처 URL + 발췌일이 명시되어 있는가? 누락 시 `[BLOCK] 출처 없는 주장: "{발췌}"`.
  - Sources 섹션의 URL 중 1~2개를 샘플로 WebFetch 시도. 404 / 도메인 변조 / 내용 불일치면 `[BLOCK] 위조 또는 변경된 출처`.
  - 큐레이션 KB가 `quality: stub`이었다면 Summary에 그 사실이 명시되었는가? 누락 시 `[ASK]`.
  - Project Fit Analysis가 존재하고 Escalations에 실제 ASK로 연결되었는가?
- **메타 누수 체크**: 02b 본문에 Phase / Orchestrator / Escalation / Playbook 같은 이 플러그인의 메타 용어가 들어갔는가? 있으면 `[BLOCK]` — 대상 프로젝트 사용자에게 혼란.

### Dimension 11: 모델-복잡도 미스매치 (Phase 5·6 에만 적용)

Phase 5(`04-agent-team.md`) / Phase 6(`05-skill-specs.md`) 산출물 리뷰 시에만 실행. 다른 Phase에서는 스킵.

- **복잡도 분류와 모델 어긋남**:
  - 복잡 설계 / 아키텍처 / 리서치 / 오케스트레이션 역할에 `haiku` 배정 → `[BLOCK]` (경제형 티어에서 의도된 경우라도 사용자 확인 필요)
  - 단순 검증 / 린트 / 포매팅 역할에 `opus` 배정 → `[ASK]` (고성능형 티어에서 의도된 경우에만 허용)
  - 구현 / 리뷰 역할에 매트릭스 기본값 외 모델 → `[NOTE]`
- **드리프트 감지 (Phase 6 리뷰 시)**:
  - `04-agent-team.md` Agent Model Table ↔ `.claude/agents/{이름}.md` frontmatter `model` ↔ 해당 에이전트 소유 SKILL.md `model` 세 곳이 일치하지 않으면 `[BLOCK] 모델 드리프트` (Model Confirmation Gate 재조정 후 동기화 누락 가능성)
- **티어 정합성**:
  - `04-agent-team.md` 의 `Model Tier Applied` 필드 값과 Agent Model Table이 Step 3 매트릭스 규칙에서 벗어나 있는데 기각된 대안·Escalation에 근거가 없으면 `[ASK] 매트릭스 이탈 근거 누락`

이 Dimension은 **복잡도 게이트와 무관하게 항상 실행**한다 — 모델 미스매치는 설계 품질 이슈이면서 비용·성능에 즉시 영향을 주므로 경량화하지 않는다.

### Dimension 12: 파이프라인 리뷰 게이트 준수 (Phase 4 에 필수, Phase 5·9 에 확장 적용)

> **SSoT**: 본 Dimension은 `.claude/rules/pipeline-review-gate.md` 규약을 **참조**한다. 본문(분류 기준·에스컬레이션 래더·면제 범주 정의)은 규약 파일이 권위 원천이므로 여기에 복붙하지 않는다. Advisor는 아래 **검사 체크리스트**만 인라인으로 확인한다.

**Phase 4 산출물 (`03-pipeline-design.md`) 검사 체크리스트**:
- `## Pipeline Review Gate` 섹션 존재 여부, 모든 파이프라인의 분류(`mandatory_review`/`exempt`) 명시 여부
- 생성·결정·설계·계획·리서치 파이프라인이 `exempt` 로 오분류되진 않았는가 (면제 범주는 pipeline-review-gate.md의 "리뷰 면제 가능" 절에 명시된 결정론적 변환/단순 I/O/조회/실행에 한정)
- `exempt` 에 `exempt_reason` 이 구체적인가 ("표준 관례"처럼 공허한 사유는 `[BLOCK]`)
- `mandatory_review` 파이프라인 각각에 말단 리뷰어 스텝이 배치됐는가
- 리뷰어가 **도메인 특화 분리**인가 — 1개의 범용 Advisor 로 복수 파이프라인을 공유 커버하진 않는가 (단수 원칙)
- 리뷰어 스텝 출력이 다시 리뷰받는 재귀 구조는 없는가 (재귀 금지 원칙)
- 산출물에 에스컬레이션 래더 **참조 문구**가 있고, 래더 본문을 복붙하지 않았는가 (복붙은 SSoT 붕괴 위험 — `[BLOCK]`)
- 리뷰어의 예상 `allowed_dirs` 가 쓰기 권한을 갖는가 (있으면 `[BLOCK]` — 리뷰 전용 원칙 위배)

**Phase 5 산출물 (`04-agent-team.md`) 확장 검사**:
- Phase 4가 지정한 도메인 리뷰어 각각에 대해 `.claude/agents/{name}-redteam.md` 프로비저닝 계획이 있는가
- 해당 리뷰어의 `allowed_dirs` 가 비어있거나 read-only 경로에만 한정되는가

**Phase 9 산출물 (`07-validation-report.md`) 확장 검사**:
- 리뷰 스텝 누락·`exempt_reason` 공백·래더 본문 복붙을 `[BLOCK]`으로 감지했는가

**Complexity Gate 경로 계약 검증** (Phase 4 산출물에 `## Complexity Gate Pipeline Contracts` 섹션이 존재할 때만):
- S 등급 경로가 "에이전트 소환 0회 + `ORCHESTRATOR_DIRECT` 기반 우회" 로 명시됐는가
- M 등급 경로에 `planner-agent` 가 단일 소환으로 `research.md` + `plan.md` 를 **동시 산출** 하는 계약이 있는가 — researcher와 planner가 별도 소환으로 분리되어 있으면 `[BLOCK]` (cache write 2회 가산 → 비용 최적화 무효화)
- M 등급 경로에 Specialist Review(design/ux/security) 소환이 포함되어 있으면 `[BLOCK]` (M 등급에서는 금지)
- L 등급 Specialist Review 트리거가 workflow-design Step 4-C의 3조건 AND(L등급 + UI 디렉터리 변경 + 명시 플래그)를 모두 명시했는가
- S/M/L 등급의 **판정 주체**가 명시됐는가 — 메인 세션 자가 판정 금지, "사용자 명시 승인" 경유 필수 (Dim 6 보안 순환 고리 방지)

이 Dimension은 **복잡도 게이트와 무관하게 항상 전체 실행**한다 (Phase 4·5·9 각각에서) — 보안·리뷰 가드는 경량 트랙에서도 우회 금지.

### Dimension 13: 상태 지속성 & 실패 복구 & 운영 부채 (대상 프로젝트가 에이전트 파이프라인/오케스트레이터 구조일 때 Phase 3·4·5·6 산출물에 적용)

> **적용 범위 제한 (Meta-Leakage Guard)**: 이 Dimension은 **대상 프로젝트 자체가 에이전트 파이프라인·오케스트레이터 구조를 채택한 경우**에만 Phase 3·4·5·6 산출물에 대해 실행한다. 일반 웹앱/CLI/데이터 프로젝트의 하네스 설계 산출물에는 스킵하여 플러그인 메타 용어(Session Recovery Protocol, Failure Recovery 등)가 대상 프로젝트 방법론 문서에 누수되는 것을 막는다. 대상 프로젝트 유형 판정은 Phase 1-2 산출물(`01-discovery-answers.md`)의 "에이전트 프로젝트 여부" 필드를 근거로 한다.

**상태 지속성 (Phase 3 리뷰 시)**:
- 워크플로우 실행 중 세션 리셋(/clear·프로세스 종료)이 발생해도 복구 가능한가? Phase 3 산출물에 `## Session Recovery Protocol` 섹션이 있고 4개 소항목(체크포인트 위치·재개 감지 로직·리더 교체 프로토콜·실패 시나리오)이 채워졌는가? 없으면 `[ASK] 세션 재시작 시 복구 방법이 미정의 — 체크포인트 전략 필요 여부 확인 권장`
- 스크립트(`validate-phase-artifact.sh`)는 헤더 존재만 확인하므로 **Advisor가 1차 품질 게이트** — "단일 세션 완결 — 복구 프로토콜 미필요" 한 줄 도피 여부를 직접 판정

**실패 복구 종료 조건 (Phase 4 리뷰 시)**:
- Phase 4 산출물에 `## Failure Recovery & Artifact Versioning` 섹션이 있고 각 파이프라인에 `max_retries`·에스컬레이션 분기·timeout 이 명시됐는가? "재설계 요청", "Builder에게 넘김" 등 행위자·조건·종료 없는 개방형 서술은 잠재적 무한 루프다 → `[BLOCK] 실패 복구 경로의 종료 조건 미정의 — {경로명}: 재시도 상한·에스컬레이션 분기 추가 필요`

**리더 연속성 가정 (Phase 3·4 리뷰 시)**:
- "리더 = 메인 세션"이라는 가정이 있으면 세션 교체 시 컨텍스트 재구성 방법(상태 파일 재로드, 재개 프로토콜)이 문서화됐는가? 없으면 `[ASK] 메인 세션이 리더인데 세션 재시작 시 재개 프로토콜이 정의되지 않음`

**환경 이식성 (전 Phase 공통)**:
- 절대 경로(예: `/Users/lee/`, `/mnt/c/Users/`, `C:\Users\`)가 설계 문서·CLAUDE.md에 하드코딩됐는가? 있으면 `[ASK] 머신 특정 절대 경로 발견 — 환경변수 또는 상대 경로로 교체 검토`

**W5 — 에이전트-스킬 이중 관리 부채 (Phase 5·6 리뷰 시)**:
- 각 에이전트 파일(`.claude/agents/*.md`)에 스킬 방법론이 인라인 포함되어 있는가? 스킬 파일(`playbooks/*.md` 또는 `.claude/skills/*/SKILL.md`)에 에이전트 정체성 섹션(Identity/Persona)이 중복 존재하는가? 이중 관리는 drift 발생 주범이다 → `[ASK] 방법론이 에이전트 파일과 스킬 파일 두 곳에 중복 정의됨 — 소유권 분리 원칙 위반 가능성`

**W6 — 산출물 덮어쓰기 위험 (Phase 4 리뷰 시)**:
- Phase 4 산출물의 각 파이프라인에 버저닝 전략(overwrite_ok / timestamp / version / archive)이 명시됐는가? `overwrite_ok` 로 명시된 경우 idempotency 보장 사유가 있는가? 없으면 `[ASK] {파이프라인명} 산출물 덮어쓰기 전략 미명시 — 재실행 시 이전 결과 오염 가능`

**경량화 조건**:
- 경량 트랙 단순 프로젝트에서는 상태 지속성·리더 연속성·W5 검사를 NOTE 수준으로 완화
- W6(산출물 덮어쓰기)는 데이터 손실 리스크이므로 **경량화 금지** (항상 전체 실행)
- 경량 트랙 면제 조건은 본 조항과 `playbooks/setup-lite.md` Output Contract의 `session_recovery: not_applicable` 명시가 **양방향 SSoT** — 한쪽 변경 시 다른 쪽 동반 갱신

## Review Output Format

다음 구조로 반환한다:

```
## Red-team Review: Phase {N}

### BLOCK — 진행 전 반드시 해결
(다음 Phase로 넘어가면 안 되는 설계 결함)
- {문제}: {왜 문제인지}
  → 제안: {해결 방향}
  → 사용자에게 물어야 할 질문: "{질문}"

### ASK — 사용자 확인 권장
(암묵적 가정이나, 사용자가 다른 선호를 가질 수 있는 결정)
- {가정/결정}: {왜 확인이 필요한지}
  → 제안 질문: "{질문}"

### NOTE — 참고
(현재는 문제 아니지만 인지해야 할 사항)
- {사항}: {맥락}

### Overall Assessment
이 Phase의 산출물이 사용자 목적에 부합하는 정도: {상/중/하}
다음 Phase 진행 권장 여부: {예/조건부/아니오}
```

## Guardrails
- 파일을 생성하거나 수정하지 않는다 (읽기 + 리뷰만)
- 기술적 세부사항보다 "사용자 목적 달성 여부"에 집중한다
- 모든 BLOCK에는 반드시 구체적인 해결 방향과 사용자 질문을 포함한다
- 과도한 지적을 하지 않는다 — 실제로 문제가 되는 것만 BLOCK/ASK로 분류
