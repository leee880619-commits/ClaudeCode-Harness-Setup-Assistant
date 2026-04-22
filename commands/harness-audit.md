---
description: Audit an existing Claude Code harness for configuration integrity (4-scope scan, JSON validity, anti-patterns, permission safety, agent↔playbook mapping). Diagnosis only — improvements are delegated to /harness-architect:harness-setup re-run. Complementary to /harness-architect:harness-setup Phase 9 (build-time validation), /harness-architect:ops-audit (runtime debt), and /harness-architect:fit-audit (project-fit drift).
---

# Harness Configuration Audit

> 💡 **대부분의 경우 `/harness-architect:audit` 통합 커맨드 사용을 권장합니다.** 본 커맨드는 구성 정합성만 단독으로 보고 싶은 고급 사용자용입니다. `/harness-architect:audit` 은 이 커맨드 + `ops-audit` + `fit-audit` 을 병렬 실행해 단일 통합 보고서를 제공합니다.

이미 배포된 Claude Code 하네스의 **구성 정합성** 을 진단합니다. 파일 구조·JSON 유효성·권한 안전성·anti-pattern·에이전트↔플레이북 매핑을 4-scope 전수 스캔합니다.

## 범위 비교

| 측면 | harness-audit (본 커맨드) | ops-audit | fit-audit |
|------|--------------------------|-----------|-----------|
| 근본 질문 | "파일 구조가 올바른가" | "실행할 때 실패하는가" | "이 프로젝트에 여전히 맞는가" |
| 데이터 소스 | 하네스 파일만 | 하네스 파일만 | 하네스 파일 + 프로젝트 스캔 |
| 출력 등급 | CRITICAL/HIGH/MEDIUM/LOW | RISK-HIGH/MED/LOW | MAJOR-DRIFT-CRITICAL/MAJOR-DRIFT-MED/MINOR-DRIFT/ALIGN |
| 주 관심사 | **구성 정합성** — anti-pattern, JSON, 매핑, 권한 | **런타임 부채** — 세션 복구·retry 상한·덮어쓰기 | **프로젝트 적합성** — 드리프트 |

**세 감사는 독립이며 상호 보완**입니다. 통합 실행은 `/harness-architect:audit` 한 번이면 병렬 감사 + 단일 통합 보고서를 제공합니다. 개별 실행 시 권장 순서: `harness-audit` → `ops-audit` → `fit-audit`.

### 등급 체계

- `CRITICAL` ≈ **보안 침해 직결 + 즉시 수정** — `Bash(*)` / `Bash(sudo *)` allow, 필수 deny 부재, 비밀값 노출
- `HIGH` ≈ **구조·권한 손상 — 조속 수정** — CLAUDE.md 200줄 초과, settings.json 파싱 실패, dangerous allow 패턴, playbook 참조 불일치, D-1 가시성 위반
- `MEDIUM` ≈ **운영 품질 저하 — 개선 권장** — settings.local.json 비대, .gitignore 누락, path 패턴 mismatch, mixed location without hybrid intent
- `LOW` ≈ **정보성 / 선택적 개선** — rules/ 디렉터리 부재, Ask-first directive 부재 등

## Pre-flight Gate — 하네스 존재 여부 검증

**커맨드 진입 시 사용자에게 먼저 안내 (AskUserQuestion 없이 텍스트로 출력)**:

> ⚠️ 이 커맨드는 **구성 정합성만** 진단합니다 (4-scope·JSON·anti-pattern·권한·매핑). 런타임 부채(`ops-audit`) 와 프로젝트 적합성(`fit-audit`) 은 **포함되지 않습니다**. 3개 축을 통합으로 받으려면 `/harness-architect:audit` 을 사용하세요.

> 이 커맨드는 **진단 전용**입니다. 발견된 구성 문제를 harness-audit 자체가 수정하지 않습니다. 개선은 `/harness-architect:harness-setup` 재실행 또는 사용자가 직접 `.claude/` 편집으로 수행합니다.

이후 다음을 확인합니다:

1. `$ARGUMENTS` 또는 AskUserQuestion 으로 대상 프로젝트 절대 경로 수집. 경로 유효성 검증 (`test -d`).
2. **하네스 최소 존재 검증**: 다음 중 **하나라도** 존재해야 감사 진행:
   - `{대상}/CLAUDE.md`
   - `{대상}/.claude/settings.json`
   - `{대상}/.claude/agents/` (파일 1개 이상)
   - `{대상}/playbooks/` (파일 1개 이상)
3. **모두 미존재** 시 AskUserQuestion 분기:
   - `먼저 harness-setup 실행` — `/harness-architect:harness-setup` 안내 후 종료
   - `취소` — 종료

## 에이전트 소환

Pre-flight 통과 후 `harness-auditor` 에이전트에 감사 위임:

```
Agent(
  subagent_type: "harness-auditor",
  description: "Harness Configuration Audit",
  prompt: "[Target Project Root]
    {대상 프로젝트 절대 경로}

    [Assistant Project Root]
    ${CLAUDE_PLUGIN_ROOT}

    [Scope]
    기존 하네스 구성 진단. playbooks/harness-audit.md 플레이북의 Phase 1-3(Full 4-Scope Scan → Anti-Pattern Detection → Diagnostic Report) 만 수행하라.
    Phase 4-5 (User Decision → Execute Remediation) 는 오케스트레이터가 처리한다 — 본 에이전트는 **진단까지만**.
    AskUserQuestion 사용 금지. 발견 사항은 CRITICAL/HIGH/MEDIUM/LOW 등급으로 분류한 보고서로 반환.
    파일 생성·수정 금지 (read-only 감사).",
  mode: "auto"
)
```

## 오케스트레이터 역할

- Pre-flight 게이트 수행 (유일한 AskUserQuestion 지점)
- 에이전트 반환 후 구성 진단 보고서를 사용자에게 **텍스트로** 제시 (파일 생성 없음)
- CRITICAL 항목이 있으면 **즉시 조치** 권장 + 구체 수정 방향 제시
- HIGH 이하 항목은 `/harness-architect:harness-setup` 재실행 또는 수동 편집 권장
- 감사 결과를 대상 프로젝트에 쓰지 않음 (기존 하네스 무변경 원칙)

## 파이프라인 분류

이 커맨드는 "리서치" 분류에 해당하지만, harness-auditor 자체가 리뷰어 역할을 수행하므로 `.claude/rules/pipeline-review-gate.md` 의 **"리뷰의 리뷰" 재귀 금지 원칙**에 따라 별도 리뷰어 스텝을 두지 않습니다. 메인 세션이 보고서를 사용자에게 직접 제시하는 것으로 완결합니다. `ops-audit`·`fit-audit` 과 동일한 설계 원칙입니다.

## 인자 처리

- `$ARGUMENTS` 에 경로가 있으면 Pre-flight 게이트에서 바로 검증
- 비어있으면 AskUserQuestion 으로 수집
- 경로에 공백·한글 포함 가능 — 절대 경로로 정규화

## Language

한국어로 응답. 코드/파일명은 영어.
