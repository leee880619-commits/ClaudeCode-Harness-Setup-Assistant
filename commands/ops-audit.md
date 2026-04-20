---
description: Audit an existing Claude Code harness for runtime assumptions, operational debt, and failure recovery gaps (session continuity, retry termination, dual-maintenance, artifact overwrite, cross-workflow duplication). Complementary to /harness-architect:harness-setup Phase 9 (build-time validation) and /harness-architect:harness-audit (configuration diagnosis).
---

# Harness Ops Audit

기존 Claude Code 하네스의 **런타임 가정·운영 부채·실패 복구 미비**를 분석합니다. `/harness-architect:harness-setup` Phase 9가 "구조가 올바른가"를 검증하는 정적 구조 린터라면, 이 커맨드는 "실제 실행할 때 어디서 문제가 생기는가"에 집중한 사후 감사입니다.

## 범위 비교

| 측면 | Phase 9 final-validation | ops-audit |
|------|--------------------------|-----------|
| 실행 시점 | 신규 harness-setup 플로우 내부 (빌드 중) | 기존 하네스에 독립 실행 (빌드 후, 언제든) |
| 주 관심사 | 파일 존재·스키마 준수·보안 | 런타임 가정·운영 부채 |
| 대상 프로젝트 | harness-architect가 방금 생성한 하네스 | 과거에 생성된 하네스 (타 도구 생성 하네스 포함) |
| 출력 등급 | BLOCK/ASK/NOTE | RISK-HIGH/RISK-MED/RISK-LOW |

중복 항목(W4 절대 경로, W7 크로스 구조 중복)은 두 곳 모두에서 검사하되, 판정 충돌 시 ops-audit가 더 최신 상태이므로 우선합니다. (`playbooks/final-validation.md` #15·#16에 SSoT 주석 명시)

### 관련 커맨드 (See also)

| 커맨드 | 역할 | 실행 시점 | 출력 등급 |
|--------|------|----------|----------|
| `/harness-architect:harness-setup` | 신규 하네스 구축 (9-Phase) | 빌드 | BLOCK/ASK/NOTE |
| `/harness-architect:harness-audit` | **구성 진단** (파일·권한·anti-pattern·에이전트-플레이북 매핑) | 기존 하네스 | CRITICAL/HIGH/MEDIUM/LOW |
| `/harness-architect:ops-audit` (본 커맨드) | **런타임 감사** (세션 연속성·실패 복구·덮어쓰기·중복) | 기존 하네스 | RISK-HIGH/MED/LOW |

**harness-audit와 ops-audit의 관계**: 두 커맨드는 상호 보완적이다. harness-audit은 설계·구성 중심, ops-audit은 런타임·운영 중심. 사용자는 기존 하네스 점검 시 **harness-audit → ops-audit 순서로 실행** 권장 — 구성 문제를 먼저 해소한 후 운영 부채를 감사해야 RISK 판정의 정확도가 높아진다.

### 등급 체계 매핑 (RISK ↔ BLOCK)

RISK 등급은 red-team-advisor의 BLOCK/ASK/NOTE와 **직접 대응되지 않는다**. 의도된 차이:
- `RISK-HIGH` ≈ **시급 권장** (프로덕션 운영 시 실패·데이터 손실 가능) — 진행 중단은 아님. 이미 배포된 하네스를 BLOCK으로 멈출 수 없기 때문.
- `RISK-MED` ≈ **개선 권장** (운영 고통 누적)
- `RISK-LOW` ≈ **정보성 / 선택적 개선**
- red-team-advisor `BLOCK` ≈ Phase 진행을 막는 게이팅 역할 — 빌드 중에만 의미 있음. ops-audit은 사후 감사이므로 이에 대응하는 등급이 없음.

사용자는 두 보고서를 동시에 받을 때 "RISK-HIGH = 즉시 수정, BLOCK = 진행 불가"로 이해하면 된다.

## Pre-flight Gate — harness 존재 여부 검증

커맨드 진입 즉시 대상 프로젝트의 하네스 설치 여부를 확인합니다:

1. `$ARGUMENTS` 또는 AskUserQuestion으로 대상 프로젝트 절대 경로 수집
2. 다음 중 **하나라도** 존재하면 정상 감사 진행:
   - `{대상}/CLAUDE.md`
   - `{대상}/.claude/settings.json`
   - `{대상}/.claude/agents/` (파일 1개 이상)
   - `{대상}/playbooks/` (파일 1개 이상)
3. **모두 미존재** 시 AskUserQuestion으로 분기:
   - `부분 감사 계속` — .gitignore·README 등 파일만으로 최소 감사 수행 (출력에 "harness 미설치 — 부분 감사" 명시)
   - `먼저 harness-setup 실행` — `/harness-architect:harness-setup` 안내 후 종료
   - `취소` — 종료

## 에이전트 소환

Pre-flight 통과 후 `ops-auditor` 에이전트에 감사 위임:

```
Agent(
  subagent_type: "ops-auditor",
  description: "Runtime & Ops Audit",
  prompt: "[Target Project Root]
    {대상 프로젝트 절대 경로}

    [Assistant Project Root]
    ${CLAUDE_PLUGIN_ROOT}

    [Scope]
    기존 하네스 사후 감사. playbooks/ops-audit.md 플레이북을 Read하여 5개 Dimension(A~E)을 수행하라.
    AskUserQuestion 사용 금지. 발견 사항은 RISK-HIGH/RISK-MED/RISK-LOW 등급으로 분류한 보고서로 반환.
    파일 생성·수정 금지 (read-only 감사).",
  mode: "auto"
)
```

## 오케스트레이터 역할

- Pre-flight 게이트 수행 (유일한 AskUserQuestion 지점)
- 에이전트 반환 후 RISK 보고서를 사용자에게 **텍스트로** 제시 (파일 생성 없음)
- RISK-HIGH 항목이 있으면 `/harness-architect:harness-setup` 재실행 권장 안내
- 감사 결과를 대상 프로젝트에 쓰지 않음 (기존 하네스 무변경 원칙)

## 파이프라인 분류

이 커맨드는 "리서치" 분류에 해당하지만, ops-auditor 자체가 리뷰어 역할을 수행하므로 `.claude/rules/pipeline-review-gate.md` 의 **"리뷰의 리뷰" 재귀 금지 원칙**에 따라 별도 리뷰어 스텝을 두지 않습니다. 메인 세션이 보고서를 사용자에게 직접 제시하는 것으로 완결합니다.

## 인자 처리

- `$ARGUMENTS` 에 경로가 있으면 Pre-flight 게이트에서 바로 검증
- 비어있으면 AskUserQuestion으로 수집
- 경로에 공백·한글 포함 가능 — 절대 경로로 정규화

## Language

한국어로 응답. 코드/파일명은 영어.
