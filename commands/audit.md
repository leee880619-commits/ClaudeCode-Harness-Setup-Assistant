---
description: Unified audit entry — runs harness-audit (configuration integrity), ops-audit (runtime debt), and fit-audit (project-fit drift) in parallel and assembles a single consolidated report. Recommended for most users. For focused single-axis audits, use /harness-architect:harness-audit, /harness-architect:ops-audit, or /harness-architect:fit-audit directly.
---

# Harness Unified Audit

기존 Claude Code 하네스에 대해 **3개 감사를 병렬 실행**하고 **단일 통합 보고서**를 제공합니다. 시나리오 B(기존 환경 점검) 의 표준 엔트리입니다.

## 통합 감사 구성

| 감사 | 근본 질문 | 출력 등급 |
|------|----------|----------|
| `harness-auditor` | "파일 구조가 올바른가" | CRITICAL / HIGH / MEDIUM / LOW |
| `ops-auditor` | "실행할 때 실패하는가" | RISK-HIGH / RISK-MED / RISK-LOW |
| `fit-auditor` | "이 프로젝트에 여전히 맞는가" | MAJOR-DRIFT-CRITICAL / MAJOR-DRIFT-MED / MINOR-DRIFT / ALIGN |

**세 감사는 모두 read-only** 이며 파일을 수정하지 않습니다. 감사 결과를 대상 프로젝트에 쓰지 않습니다.

## 언제 개별 커맨드를 쓸까

- **대부분**: 이 커맨드(`/harness-architect:audit`) 한 번이면 충분
- **특정 축만 깊게 보고 싶을 때**: `/harness-architect:harness-audit` (구성만), `/harness-architect:ops-audit` (런타임만), `/harness-architect:fit-audit` (적합성만)
- **대규모 하네스** (에이전트 30+ 개, CLAUDE.md 여러 파일 @import): 각 auditor 보고서가 누적되면 메인 세션 컨텍스트가 폭증할 수 있음. 이 경우 **개별 커맨드 순차 실행 권장**

## Pre-flight Gate

커맨드 진입 시 사용자에게 먼저 안내 (AskUserQuestion 없이 텍스트):

> 이 커맨드는 **진단 전용**입니다. 3개 감사가 발견한 문제를 자동으로 수정하지 않습니다. 개선은 통합 보고서의 **Recommendation** 섹션 안내를 따라 `/harness-architect:harness-setup` 재실행 또는 수동 편집으로 수행합니다.

이후:

1. `$ARGUMENTS` 또는 AskUserQuestion 으로 대상 프로젝트 절대 경로 수집. 경로 유효성 검증 (`test -d`).
2. **하네스 최소 존재 검증** — 다음 중 **하나라도** 존재해야 감사 진행:
   - `{대상}/CLAUDE.md`
   - `{대상}/.claude/settings.json`
   - `{대상}/.claude/agents/` (파일 1개 이상)
   - `{대상}/playbooks/` (파일 1개 이상)
3. **모두 미존재** 시 AskUserQuestion 분기:
   - `먼저 harness-setup 실행` — `/harness-architect:harness-setup` 안내 후 종료
   - `취소` — 종료
4. **fit-audit baseline 모드 자동 결정** (fit-audit 에만 필요):
   - `{대상}/docs/*/01-discovery-answers.md` 존재 → `baseline-mode`
   - 부재 → `heuristic-only-mode`

## 3개 Auditor 병렬 소환

Pre-flight 통과 후 **한 응답에 3개 Agent 를 동시 호출** (independent read-only 이므로 병렬 안전):

```
Agent(
  subagent_type: "harness-auditor",
  description: "Unified Audit — Configuration",
  prompt: "[Target Project Root] {대상 절대 경로}
    [Assistant Project Root] ${CLAUDE_PLUGIN_ROOT}
    [Invocation Context] /harness-architect:audit 통합 감사의 일부.
    [Scope] playbooks/harness-audit.md Phase 1-3 수행. CRITICAL/HIGH/MEDIUM/LOW 등급 보고서 반환.
    AskUserQuestion 금지, 파일 생성·수정 금지.",
  mode: "auto"
)

Agent(
  subagent_type: "ops-auditor",
  description: "Unified Audit — Runtime",
  prompt: "[Target Project Root] {대상 절대 경로}
    [Assistant Project Root] ${CLAUDE_PLUGIN_ROOT}
    [Invocation Context] /harness-architect:audit 통합 감사의 일부.
    [Scope] playbooks/ops-audit.md 6개 Dimension 수행. RISK-HIGH/RISK-MED/RISK-LOW 등급 보고서 반환.
    AskUserQuestion 금지, 파일 생성·수정 금지.",
  mode: "auto"
)

Agent(
  subagent_type: "fit-auditor",
  description: "Unified Audit — Project Fit",
  prompt: "[Target Project Root] {대상 절대 경로}
    [Assistant Project Root] ${CLAUDE_PLUGIN_ROOT}
    [Invocation Context] /harness-architect:audit 통합 감사의 일부.
    [Audit Mode] baseline-mode | heuristic-only-mode
    [Scope] playbooks/fit-audit.md 7개 Dimension 수행. MAJOR-DRIFT-CRITICAL/MAJOR-DRIFT-MED/MINOR-DRIFT/ALIGN 등급 보고서 반환.
    AskUserQuestion 금지, 파일 생성·수정 금지.",
  mode: "auto"
)
```

## 통합 보고서 조립

3개 auditor 반환을 수신한 뒤 **오케스트레이터가 단일 Markdown 보고서를 조립**합니다. 파일에 쓰지 않고 텍스트로 사용자에게 제시합니다.

### 통합 severity 매핑

| 통합 버킷 | harness-audit | ops-audit | fit-audit |
|-----------|---------------|-----------|-----------|
| `Critical` (즉시 조치) | CRITICAL | RISK-HIGH | MAJOR-DRIFT-CRITICAL |
| `High` (조속 수정) | HIGH | — | — |
| `Medium` (개선 권장) | MEDIUM | RISK-MED | MAJOR-DRIFT-MED |
| `Low` (정보성) | LOW | RISK-LOW | MINOR-DRIFT |
| `Aligned` (참고) | — | — | ALIGN |

> **fit-audit 의 MAJOR-DRIFT 서브등급**: fit-auditor 는 MAJOR-DRIFT 를 발행할 때 `MAJOR-DRIFT-CRITICAL` (하네스가 프로젝트를 방해·오도하는 수준) 또는 `MAJOR-DRIFT-MED` (재구축 권장이나 당장 운영에 지장 없음) 로 서브분류해 반환합니다. 상세 판정 기준: `playbooks/fit-audit.md` "MAJOR-DRIFT 서브등급 판정" 섹션.

### SSoT 공유 항목 충돌 처리

harness-audit 과 ops-audit 은 **W4 (산출물 절대 경로)** 와 **W16 (크로스 워크플로우 Jaccard 구조 중복)** 두 항목을 공유 검사합니다. 판정 충돌 시 **ops-audit 결과 우선** (더 최신 상태를 반영).

**동일 항목 식별 알고리즘** (구현 모호성 제거):

- **W4 (절대 경로 산출물)**: 항목 키는 `(검사 유형="W4", 파일 경로 문자열)` 2튜플. 두 보고서에서 동일 `파일 경로` 로 보고된 항목을 동일 항목으로 간주.
- **W16 (Jaccard 중복)**: 항목 키는 `(검사 유형="W16", 파일쌍 튜플)` — 정렬된 `(file_A, file_B)` 페어. 두 보고서에서 동일 페어를 참조하면 동일 항목.
- **그 외 우연한 중복** (같은 anti-pattern 을 harness-audit 과 fit-audit 이 다른 등급으로 발행): 항목 제목 Jaccard 유사도 ≥70% + 동일 파일 경로 참조 → 중복 후보. 동일 항목 병합 시 "(harness-audit·fit-audit 중복)" 주석으로 원본 출처 병기하되, 등급 차이는 **각 auditor 의 등급 중 높은 쪽 채택** (보수적 상승).

**절차**:
1. 3개 auditor 반환을 받은 뒤 각 항목에 위 식별 키 부여
2. 키 충돌 시 W4/W16 은 ops-audit, 그 외는 "높은 등급 우선" 규칙 적용
3. 통합 보고서 본문에는 병합된 단일 항목만 표시하고, 각 항목에 원본 auditor 태그 (`[harness]` / `[ops]` / `[fit]`) 병기
4. 충돌 병합 건수를 `## Summary` 의 "SSoT 충돌 병합 건수: {M}" 에 계상

### 원본 등급 병기 원칙

통합 보고서의 각 발견 항목은 **원본 auditor 등급 + 통합 버킷** 을 모두 표기합니다. 사용자가 통합 버킷 이름(예: `Critical`) 을 보고 "원래 어느 감사에서 어떤 등급이었나" 를 역추적할 수 있어야 합니다.

표기 형식: `[ops / RISK-HIGH → Critical] 발견 제목 ...`, `[fit / MAJOR-DRIFT-CRITICAL → Critical] ...`

이는 통합 severity 표 자체의 매핑 투명성을 보장할 뿐 아니라, 동일 "Critical" 버킷 안에서도 이슈 성격 (파일 구조 파손 vs 런타임 실패 vs 프로젝트 오도) 이 다름을 보고서 소비자가 바로 인지할 수 있게 합니다.

### 부분 실패 처리

3개 auditor 중 **일부가 실패** (타임아웃·에이전트 미로딩·반환 누락·반환 빈 텍스트) 해도 나머지 auditor 결과로 통합 보고서를 **부분 조립** 합니다.

**절차**:
1. 각 Agent 호출의 반환을 수집. 반환이 없거나 빈 문자열이면 "실패" 로 간주
2. 실패 auditor 의 Source Details 섹션은 보고서에 포함하되 다음 형태로 명시:
   ```markdown
   ### {auditor 이름} 원본 리포트 — ❌ 실행 실패
   사유: {타임아웃 / 에이전트 미로딩 / 반환 빈 텍스트 / 기타}
   영향: 이 축의 발견 사항은 이 보고서에 포함되지 않음. 별도 실행 권장 — `/harness-architect:{auditor 이름}` 커맨드 직접 호출.
   ```
3. `## Summary` 섹션 상단에 "⚠️ 부분 감사: {N}/3 auditor 실패" 경고 배너 추가
4. 3개 전부 실패 → 통합 보고서 조립 중단, 사용자에게 "3개 auditor 모두 실행 실패 — 개별 커맨드로 각각 실행해 로그를 확인하세요" 안내 후 종료
5. `## Recommendation` 섹션에 "누락된 축은 개별 커맨드로 재실행 필요" 명시

### 보고서 크기 관리 (대규모 하네스 대응)

3개 auditor 가 각자 수십 KB 의 상세 보고서를 반환하면 통합 결과가 메인 세션 컨텍스트를 과도하게 점유할 수 있습니다. 다음 상한 정책을 적용합니다:

- **통합 보고서 총 라인 수 상한**: 300 라인
- **초과 시 자동 축약 규칙**:
  - `Critical` / `High` 버킷: 전체 inline 표시 (우선 보존)
  - `Medium` / `Low` 버킷: 각 항목 제목 한 줄로 요약, 본문 생략 후 "(상세: `/harness-architect:{auditor}` 직접 실행)" 안내
  - `Aligned` 버킷: 건수만 표시, 개별 항목 생략
  - `Source Details` 섹션: 각 auditor 보고서 앞 30줄만 inline, 나머지는 "(이하 생략 — 개별 커맨드로 전체 보고 확인)" 로 절단
- **축약이 발생한 경우**: `## Summary` 에 "보고서 축약됨: {원본 총 라인} → {축약 후 라인}" 명시

사용자가 전체 보고서가 필요하면 개별 커맨드(`harness-audit`·`ops-audit`·`fit-audit`) 를 직접 호출하도록 안내합니다.

### heuristic-only-mode 주의 문구

fit-audit 이 `heuristic-only-mode` 로 실행된 경우(대상 프로젝트에 `docs/*/01-discovery-answers.md` 부재), fit-auditor 는 `MAJOR-DRIFT-CRITICAL` 승격이 불가합니다. Critical 버킷에 fit 기여분이 없다고 해서 "프로젝트가 안전" 이라는 결론을 내릴 수 없으므로 다음 문구를 `## Summary` 와 `## Coverage Gaps` 양쪽에 조건부 삽입:

> ⚠️ **heuristic-only-mode**: fit-audit 이 baseline 부재로 추정 모드 실행 → MAJOR-DRIFT-CRITICAL 판정이 구조적으로 유보됨. Critical 버킷에 fit 기여분 0건이라도 실제 적합성 문제가 없음을 보장하지 않음. baseline 복원 또는 `/harness-architect:harness-setup` 재실행으로 정식 baseline 생성 권장.

### 보고서 템플릿

```markdown
# Harness Audit — Unified Report

**대상**: {대상 절대 경로}
**감사 시각**: {ISO8601}
**fit-audit 모드**: baseline-mode | heuristic-only-mode

## Summary

- 통합 버킷별 건수: Critical={N}, High={N}, Medium={N}, Low={N}, Aligned={N}
- 감사 소스별 건수: harness-audit={X}, ops-audit={Y}, fit-audit={Z}
- SSoT 충돌 병합 건수: {M}

## Critical (즉시 조치)
(CRITICAL / RISK-HIGH / MAJOR-DRIFT-CRITICAL 통합. 각 항목에 원본 소스 태그 `[harness]` `[ops]` `[fit]` 표기)

## High (조속 수정)
(HIGH)

## Medium (개선 권장)
(MEDIUM / RISK-MED / MAJOR-DRIFT-MED)

## Low (정보성 / 선택적 개선)
(LOW / RISK-LOW / MINOR-DRIFT)

## Aligned (참고 — 드리프트 없음)
(fit-audit ALIGN 만. 건수만 요약, 상세는 source detail 에)

## Recommendation

- Critical 있으면: "즉시 `/harness-architect:harness-setup` 재실행 또는 수동 편집 필요"
- Critical 0 & High 2+ 있으면: "가까운 시점에 `/harness-architect:harness-setup` 재실행 권장"
- Medium 만 있으면: "settings.json 권한 범위 갱신·agent 모델 티어 조정 등 국소 리팩터 권장"
- 전부 Aligned/Low: "하네스가 현재 프로젝트와 정합. 유지"

## Coverage Gaps

- harness-audit: {auditor 가 명시한 한계}
- ops-audit: {auditor 가 명시한 한계}
- fit-audit: {auditor 가 명시한 한계 — heuristic-only-mode 인 경우 특히 중요}

## Source Details

### harness-audit 원본 리포트
{전체 텍스트}

### ops-audit 원본 리포트
{전체 텍스트}

### fit-audit 원본 리포트
{전체 텍스트}
```

## 오케스트레이터 역할

- Pre-flight 게이트 수행 (유일한 AskUserQuestion 지점)
- 3개 auditor 병렬 소환
- 반환 수신 → severity 매핑 → SSoT 충돌 병합 → 통합 보고서 조립 → 텍스트로 사용자에게 제시
- 통합 보고서를 대상 프로젝트에 **쓰지 않음** (기존 하네스 무변경 원칙)
- Critical 이 있으면 `/harness-architect:harness-setup` 재실행 권장 안내

## 파이프라인 분류

이 커맨드는 "리서치" 분류이나, 3개 auditor 자체가 각자 리뷰어 역할을 수행하므로 `.claude/rules/pipeline-review-gate.md` 의 **"리뷰의 리뷰" 재귀 금지 원칙**에 따라 추가 리뷰어 스텝을 두지 않습니다. 오케스트레이터의 보고서 조립은 병합·재분류 결정론적 변환이므로 면제 가능 (`review_exempt: true` / `exempt_reason: "deterministic transformation of reviewer outputs"`).

## 인자 처리

- `$ARGUMENTS` 에 경로가 있으면 Pre-flight 게이트에서 바로 검증
- 비어있으면 AskUserQuestion 으로 수집
- 경로에 공백·한글 포함 가능 — 절대 경로로 정규화

## Language

한국어로 응답. 코드/파일명은 영어.
