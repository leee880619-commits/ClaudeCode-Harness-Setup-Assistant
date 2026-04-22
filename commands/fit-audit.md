---
description: Audit the fit between an already-deployed Claude Code harness and the current state of the target project (track drift, archetype/quality-axis misfit, agent scale misfit, permission-path drift, CLAUDE.md/domain identity drift, MCP/hook external-interface drift). Diagnosis only — improvements are delegated to /harness-architect:harness-setup re-run. Complementary to /harness-architect:harness-setup Phase 9 (build-time), /harness-architect:harness-audit (configuration diagnosis), and /harness-architect:ops-audit (runtime debt).
---

# Harness Fit Audit

> 💡 **대부분의 경우 `/harness-architect:audit` 통합 커맨드 사용을 권장합니다.** 본 커맨드는 프로젝트 적합성(드리프트) 만 단독으로 보고 싶은 고급 사용자용입니다. `/harness-architect:audit` 은 `harness-audit` + `ops-audit` + 본 커맨드를 병렬 실행해 단일 통합 보고서를 제공합니다.

이미 배포된 하네스가 **현재** 대상 프로젝트의 특성·복잡도·도메인에 여전히 적합한지 감사합니다. `/harness-architect:ops-audit` 가 "하네스 자체가 운영 건전한가"를 묻는다면, 이 커맨드는 **"빌드 시점의 전제가 지금도 유효한가"** 를 묻는 시간축 드리프트 감사입니다.

## 범위 비교

| 측면 | harness-audit | ops-audit | fit-audit (본 커맨드) |
|------|---------------|-----------|---------------------|
| 실행 시점 | 기존 하네스 (harness-setup 재진입 분기) | 기존 하네스 (독립 실행) | 기존 하네스 (독립 실행) |
| 주 관심사 | **구성 정합성** (4-scope, JSON, anti-pattern, agent↔playbook 매핑) | **런타임 부채** (세션 복구·retry 상한·덮어쓰기·Jaccard) | **프로젝트 적합성** (빌드 전제 vs 현재 프로젝트 실상) |
| 데이터 소스 | 하네스 파일만 | 하네스 파일만 | 하네스 파일 **+ 대상 프로젝트 실제 스캔 + 외부 인터페이스(MCP·훅) 정적 검증** |
| 출력 등급 | CRITICAL/HIGH/MEDIUM/LOW | RISK-HIGH/MED/LOW | MAJOR-DRIFT/MINOR-DRIFT/ALIGN |
| 근본 질문 | "파일 구조가 올바른가" | "실행할 때 실패하는가" | "이 프로젝트에 여전히 맞는가" |

**세 감사는 독립이며 상호 보완**입니다. 권장 순서: `harness-audit` → `ops-audit` → `fit-audit`. 구성·운영 문제를 먼저 해소한 후 적합성을 판정해야 드리프트 신호가 왜곡되지 않습니다.

### 등급 체계 매핑

- `MAJOR-DRIFT` ≈ **전면 재구축 권장** — `/harness-architect:harness-setup` 재실행이 유지보수 누적 비용보다 저렴한 수준의 괴리
- `MINOR-DRIFT` ≈ **부분 수정 권장** — settings.json 권한 범위 업데이트, 에이전트 1~2개 추가/제거, CLAUDE.md 섹션 리프레시 등 국소 리팩터
- `ALIGN` ≈ **현 하네스 유지** — 드리프트 없음

RISK 등급(ops-audit) 과 BLOCK 등급(Phase 9 Advisor) 과는 **직접 대응되지 않습니다**. DRIFT 는 "프로덕션에서 실패"를 의미하지 않으며, "하네스가 이 프로젝트를 계속 돕는 정도"를 평가합니다.

## Pre-flight Gate — 하네스·baseline 존재 여부 검증

**커맨드 진입 시 사용자에게 먼저 안내 (AskUserQuestion 없이 텍스트로 출력)**:

> 이 커맨드는 **진단 전용**입니다. 드리프트가 발견되어도 fit-audit 자체가 하네스를 수정하지 않습니다. 개선은 보고서의 **Recommendation** 섹션 안내를 따라 `/harness-architect:harness-setup` 재실행, `/harness-architect:ops-audit`, 또는 사용자가 직접 `.claude/` 편집으로 수행합니다.

이후 다음을 확인합니다:

1. **대상 경로 수집**: `$ARGUMENTS` 또는 AskUserQuestion 으로 대상 프로젝트 절대 경로 수집. 경로 유효성 검증(`test -d`).
2. **하네스 최소 존재 검증**: 다음 중 **하나라도** 존재해야 적합성 감사가 의미 있음:
   - `{대상}/CLAUDE.md`
   - `{대상}/.claude/settings.json`
   - `{대상}/.claude/agents/` (파일 1개 이상)
3. **모두 미존재** 시 AskUserQuestion 분기:
   - `먼저 harness-setup 실행` — `/harness-architect:harness-setup` 안내 후 종료
   - `취소` — 종료
4. **Baseline 모드 결정**:
   - `{대상}/docs/*/01-discovery-answers.md` 존재 → `baseline-mode` (전제 vs 현재 비교 가능)
   - 부재 (수동 구축 하네스·baseline 소실) → `heuristic-only-mode` (현재 스캔만으로 추정 baseline 재구성, Coverage Gaps 에 한계 명시)
5. 결정된 모드를 에이전트 프롬프트의 `[Audit Mode]` 필드로 전달.

## 에이전트 소환

Pre-flight 통과 후 `fit-auditor` 에이전트에 감사 위임:

```
Agent(
  subagent_type: "fit-auditor",
  description: "Project-Harness Fit Audit",
  prompt: "[Target Project Root]
    {대상 프로젝트 절대 경로}

    [Assistant Project Root]
    ${CLAUDE_PLUGIN_ROOT}

    [Audit Mode]
    baseline-mode | heuristic-only-mode

    [Scope]
    기존 하네스가 현재 프로젝트 실상에 적합한지 감사. playbooks/fit-audit.md 플레이북을 Read 하여 7개 Dimension(1~7)을 수행하라.
    baseline-mode 이면 docs/{요청명}/01-discovery-answers.md + 00-target-path.md 의 전제를 읽고 현재 스캔 결과와 대조.
    heuristic-only-mode 이면 현재 스캔으로 추정 baseline 을 재구성한 뒤 하네스 현재 상태와 대조하고, Coverage Gaps 에 '추정 감사' 명시.
    AskUserQuestion 사용 금지. 발견 사항은 MAJOR-DRIFT/MINOR-DRIFT/ALIGN 등급으로 분류한 보고서로 반환.
    파일 생성·수정 금지 (하네스·프로젝트 모두 read-only).",
  mode: "auto"
)
```

## 오케스트레이터 역할

- Pre-flight 게이트 수행 (유일한 AskUserQuestion 지점 — 경로 수집·하네스 부재 분기)
- 에이전트 반환 후 DRIFT 보고서를 사용자에게 **텍스트로** 제시 (파일 생성 없음)
- `MAJOR-DRIFT` 항목이 2건 이상이거나 `Dim 1 트랙 드리프트` 가 MAJOR 이면 `/harness-architect:harness-setup` 재실행 권장 안내
- `MINOR-DRIFT` 만 있으면 수정 영역별 구체 권장(예: "settings.json allowed 업데이트", "agent {name} 모델 티어 하향") 만 제시. 실제 수정은 수행하지 않음 (read-only 원칙)
- 감사 결과를 대상 프로젝트에 쓰지 않음 (기존 하네스·baseline·코드 무변경)

## 파이프라인 분류

이 커맨드는 "리서치" 분류에 해당하지만, fit-auditor 자체가 리뷰어 역할을 수행하므로 `.claude/rules/pipeline-review-gate.md` 의 **"리뷰의 리뷰" 재귀 금지 원칙**에 따라 별도 리뷰어 스텝을 두지 않습니다. 메인 세션이 보고서를 사용자에게 직접 제시하는 것으로 완결합니다. 이는 `ops-audit` 과 동일한 설계 원칙입니다.

## 인자 처리

- `$ARGUMENTS` 에 경로가 있으면 Pre-flight 게이트에서 바로 검증
- 비어있으면 AskUserQuestion 으로 수집
- 경로에 공백·한글 포함 가능 — 절대 경로로 정규화

## Language

한국어로 응답. 코드/파일명은 영어.
