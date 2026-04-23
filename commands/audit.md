---
description: Unified audit entry — runs harness-audit (configuration integrity), ops-audit (runtime debt), and fit-audit (project-fit drift) in parallel and assembles a single consolidated report. This is the only audit entry point exposed in slash-command autocomplete.
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

## 범위

- 이 커맨드는 감사 3종(harness / ops / fit) 을 병렬 실행하는 **유일한 슬래시 엔트리** 입니다. 개별 auditor 를 단독 슬래시 커맨드로 호출하는 경로는 autocomplete 에 노출되지 않습니다 (혼란 방지). 단독 실행이 필요할 때는 아래 "개별 auditor 단독 실행" 섹션을 참조하세요.
- **대규모 하네스** (에이전트 30+ 개, CLAUDE.md 여러 파일 @import) 에서 통합 보고서가 커지면 "보고서 크기 관리" 섹션의 자동 축약 규칙이 적용됩니다.

## Pre-flight Gate

커맨드 진입 시 사용자에게 먼저 안내 (AskUserQuestion 없이 텍스트):

> 이 커맨드는 **진단 전용**입니다. 3개 감사가 발견한 문제를 자동으로 수정하지 않습니다. 보고서 출력 후, 마지막 섹션의 **"🛠 다음 실행 방법 (How to apply)"** 가이드에 따라 `/harness-architect:harness-setup <대상 경로>` 를 재실행하여 개선을 적용하거나 수동 편집을 수행합니다.

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
4. **User Work Signal Gate** — 감사 대상(사용자 작업 파일)이 **1개 이상 존재**하는지 단일 이진 신호로 확인. 이 gate 는 임계치·경과일·아키타입 분기 없이 동작하며, 통과 시 기존 감사 플로우와 완전히 동일하게 진행됩니다.

   ```bash
   TARGET="{대상 절대 경로}"    # 공백·한글 경로 대응: 반드시 변수화 + 따옴표 인용
   USER_WORK=$(find "$TARGET" -type f -size +0c \
     -not -path "$TARGET/.claude/*" \
     -not -path "$TARGET/.cursor/*" \
     -not -path "$TARGET/.vscode/*" \
     -not -path "$TARGET/.idea/*" \
     -not -path "$TARGET/docs/*" \
     -not -path "$TARGET/.git/*" \
     -not -path "$TARGET/node_modules/*" \
     -not -path "$TARGET/.venv/*" \
     -not -path "$TARGET/venv/*" \
     -not -path "$TARGET/dist/*" \
     -not -path "$TARGET/build/*" \
     -not -path "$TARGET/.next/*" \
     -not -path "$TARGET/target/*" \
     -not -path "$TARGET/__pycache__/*" \
     -not -path "$TARGET/.pytest_cache/*" \
     -not -path "$TARGET/.mypy_cache/*" \
     -not -name 'README*' -not -name 'LICENSE*' \
     -not -name '.gitignore' -not -name '.editorconfig' \
     -not -name '.gitattributes' -not -name '.gitmodules' \
     -not -name '.DS_Store' -not -name 'Thumbs.db' \
     -not -name 'package-lock.json' -not -name 'yarn.lock' \
     -not -name 'pnpm-lock.yaml' -not -name 'uv.lock' \
     -not -name 'Cargo.lock' -not -name 'go.sum' \
     -not -name 'poetry.lock' -not -name 'Pipfile.lock' \
     2>/dev/null | head -1)
   ```

   - **`$USER_WORK` 가 비어있음 → 감사 불가 (AUDIT-NOT-VIABLE)**: 3 auditor 를 소환하지 않고 아래 "AUDIT-NOT-VIABLE 보고서 템플릿" 을 즉시 출력한 뒤 종료. 이유: 하네스 설계와 비교할 "사용자 작업"이 전무하므로 fit-audit 의 드리프트 판정·ops-audit 의 실행 부채·harness-audit 의 상당수 anti-pattern 이 **구조적 필연** 으로 귀결되어 실질 조치 대상이 되지 못함. 실제 중요한 Critical/High 발행 시의 신뢰도를 보호하기 위한 진입문.
   - **`$USER_WORK` 비어있지 않음 → 계속 진행**: Step 5 (fit-audit baseline mode 결정) 로 이동. 이후 흐름은 기존과 동일.
5. **fit-audit baseline 모드 자동 결정** (fit-audit 에만 필요):
   - `{대상}/docs/*/01-discovery-answers.md` 존재 → `baseline-mode`
   - 부재 → `heuristic-only-mode`

### AUDIT-NOT-VIABLE 보고서 템플릿

User Work Signal Gate 가 빈 결과를 반환할 때 오케스트레이터가 직접 출력합니다 (3 auditor 미소환, 파일 쓰기 없음, 기존 하네스 무변경):

```markdown
# Harness Audit — NOT-VIABLE (User Work Signal Gate)

**대상**: {대상 절대 경로}
**감사 시각**: {ISO8601}
**판정 사유**: 하네스 영역·`docs/`·VCS·빌드 아티팩트·보일러플레이트·락파일을 제외한 사용자 소유 비어있지 않은 파일이 **0개** — 감사할 "실제 작업" 이 아직 존재하지 않음.

## 왜 감사를 수행하지 않는가

3개 auditor (harness / ops / fit) 는 **하네스 설계와 실제 사용·작업 산출물 간의 정합성**을 판정합니다. 사용자 파일이 전무한 상태에서 감사를 강행하면 findings 대부분이 구조적 필연(에이전트 오버피팅 경계·사용자 디렉터리 미존재·워크플로우 미실동작 등)에 해당하여 실질 조치 대상이 되지 못하고, 실제 중요한 Critical/High 발행 시의 신뢰도를 떨어뜨립니다.

## 다음 단계

1. 대상 프로젝트의 첫 사용자 파일(코드·문서·설정 중 1개 이상)을 작성하세요.
2. 파일 작성 후 `/harness-architect:audit {대상 경로}` 를 재실행하세요. gate 는 자동으로 통과됩니다.
3. 하네스 설계 자체에 의심이 있어 지금 감사가 필요하다면, 개별 auditor 에이전트를 직접 소환할 수 있습니다 (예: "harness-auditor 에이전트를 대상 경로 {경로} 로 실행해"). 이 경로는 gate 를 우회하며 감사 결과의 구조적 필연 성격을 사용자가 인지하고 해석한다는 전제입니다. 상세: 보고서 말미 "개별 auditor 단독 실행" 섹션 참조.

## 참고: gate 판정 조건

- 제외 경로: `.claude/`, `.cursor/`, `.vscode/`, `.idea/`, `docs/`, `.git/`, `node_modules/`, `.venv/`, `venv/`, `dist/`, `build/`, `.next/`, `target/`, `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`
- 제외 파일명: `README*`, `LICENSE*`, `.gitignore`, `.editorconfig`, `.gitattributes`, `.gitmodules`, `.DS_Store`, `Thumbs.db`, 주요 락파일 (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`, `go.sum`, `poetry.lock`, `Pipfile.lock`)
- 위 제외 집합에 해당하지 않으면서 **크기 > 0 bytes** 인 파일이 1개 이상 존재해야 감사 진행.
- 이 신호는 이진(binary) 입니다. 파일 수 임계치·경과일·프로젝트 아키타입 분기를 두지 않습니다 — gate 의 의미와 탈출 조건이 동일 (사용자 파일을 만들면 통과).

## 참고: 유사 경고와의 차이

이 판정(**AUDIT-NOT-VIABLE**)은 "사용자 파일 자체가 없어 감사를 **시작하지 않음**" 입니다. 통합 감사 실행 후 나타나는 `heuristic-only-mode` 경고(`docs/*/01-discovery-answers.md` baseline 부재로 fit-audit 이 추정 모드 실행)와는 별개입니다 — 후자는 감사는 진행되나 fit-audit 의 MAJOR-DRIFT-CRITICAL 승격이 유보되는 상태입니다.
```

> **설계 원칙**: 이 gate 는 `commands/audit.md` 의 Pre-flight 에서만 동작하며, 3개 auditor 플레이북(`playbooks/harness-audit.md`, `playbooks/ops-audit.md`, `playbooks/fit-audit.md`) 과 auditor 에이전트 정의(`.claude/agents/*-auditor.md`) 는 이 릴리즈에서 일절 수정되지 않습니다. gate 통과 후의 감사 동작·보고서 포맷·severity 매핑은 기존과 완전히 동일합니다. (side-effect zero)

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
    [Scope] playbooks/ops-audit.md 7개 Dimension 수행. RISK-HIGH/RISK-MED/RISK-LOW 등급 보고서 반환.
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
   영향: 이 축의 발견 사항은 이 보고서에 포함되지 않음. `/harness-architect:audit <대상>` 을 재실행해 재시도하거나, 마지막 섹션의 "개별 auditor 단독 실행" 안내에 따라 해당 auditor 에이전트만 직접 소환하세요.
   ```
3. `## Summary` 섹션 상단에 "⚠️ 부분 감사: {N}/3 auditor 실패" 경고 배너 추가
4. 3개 전부 실패 → 통합 보고서 조립 중단, 사용자에게 "3개 auditor 모두 실행 실패 — `/harness-architect:audit` 재실행 또는 각 auditor 에이전트 직접 소환으로 로그를 확인하세요" 안내 후 종료
5. `## Recommendation` 섹션에 "누락된 축은 `/harness-architect:audit` 재실행 필요" 명시

### 보고서 크기 관리 (대규모 하네스 대응)

3개 auditor 가 각자 수십 KB 의 상세 보고서를 반환하면 통합 결과가 메인 세션 컨텍스트를 과도하게 점유할 수 있습니다. 다음 상한 정책을 적용합니다:

- **통합 보고서 총 라인 수 상한**: 300 라인
- **초과 시 자동 축약 규칙**:
  - `Critical` / `High` 버킷: 전체 inline 표시 (우선 보존)
  - `Medium` / `Low` 버킷: 각 항목 제목 한 줄로 요약, 본문 생략 후 "(상세: 원본 Source Details 섹션 또는 해당 auditor 에이전트 단독 소환으로 확인)" 안내
  - `Aligned` 버킷: 건수만 표시, 개별 항목 생략
  - `Source Details` 섹션: 각 auditor 보고서 앞 30줄만 inline, 나머지는 "(이하 생략 — 해당 auditor 에이전트 단독 소환으로 전체 보고 확인)" 로 절단
- **축약이 발생한 경우**: `## Summary` 에 "보고서 축약됨: {원본 총 라인} → {축약 후 라인}" 명시

사용자가 전체 보고서가 필요하면 보고서 말미 "개별 auditor 단독 실행" 안내에 따라 해당 auditor 에이전트를 단독 소환하도록 유도합니다.

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

- Critical 있으면: "**즉시 조치 필요** — `/harness-architect:harness-setup <대상 경로>` 재실행 (기존 작업 폴더 감지 시 '계속' 선택) 또는 수동 편집"
- Critical 0 & High 2+ 있으면: "가까운 시점에 `/harness-architect:harness-setup <대상 경로>` 재실행 권장"
- Medium 만 있으면: "settings.json 권한 범위 갱신·agent 모델 티어 조정 등 국소 수동 리팩터 권장 (`/harness-architect:harness-setup` 재실행은 선택)"
- 전부 Aligned/Low: "하네스가 현재 프로젝트와 정합. 조치 불필요"

## 🛠 다음 실행 방법 (How to apply)

감사는 **read-only** 이며 이 커맨드는 파일을 수정하지 않습니다. 보고서에서 발견한 이슈를 실제로 적용하려면 아래 경로 중 하나를 따릅니다.

### 1. `/harness-architect:harness-setup` 재실행 — 권장

```
/harness-architect:harness-setup {대상 절대 경로}
```

- 동일 경로를 주면 Phase 0 이 기존 `docs/{요청명}/` 를 감지하고 "이전 작업 발견 — 계속 / 새로 시작?" 으로 질문합니다.
- **"계속"** 선택 시 마지막 완료 Phase 다음부터 재개. 이번 통합 보고서의 Critical/High 항목을 사용자가 산출물에 직접 반영하거나, 영향 받은 Phase 산출물을 편집 후 재실행하면 해당 Phase 이하가 자동 재검증됩니다.
- **"새로 시작"** 선택 시 처음부터 9-Phase 재구축. 하네스가 프로젝트와 크게 어긋나 (MAJOR-DRIFT-CRITICAL 다수) 재설계가 빠를 때 선택.

### 2. 수동 편집

- Medium 이하 이슈, 또는 단일 파일 권한 deny 추가처럼 범위가 좁은 수정은 보고서의 해당 파일을 에디터로 직접 수정하는 편이 빠릅니다.
- 수정 후 `/harness-architect:audit <대상 경로>` 로 재감사하여 이슈 해소를 확인하세요.

### 3. 재감사로 검증

- 수정(코드 또는 `harness-setup` 재실행) 완료 후 동일 경로로 `/harness-architect:audit` 를 다시 실행하여 버킷별 건수 감소를 확인합니다.
- fit-audit 의 `heuristic-only-mode` 경고가 보이면 `harness-setup` 재실행으로 정식 baseline (`docs/{요청명}/01-discovery-answers.md`) 을 생성한 뒤 재감사 권장.

## 개별 auditor 단독 실행 (고급)

슬래시 커맨드 노출은 `audit` 하나로 단순화되어 있습니다. 특정 축만 단독 실행하려면 Claude 에게 다음과 같이 요청하세요:

- "harness-auditor 에이전트를 대상 경로 {경로} 로 실행해" — 구성 정합성만
- "ops-auditor 에이전트를 대상 경로 {경로} 로 실행해" — 런타임 부채만
- "fit-auditor 에이전트를 대상 경로 {경로} 로 실행해" — 프로젝트 적합성만

내부적으로 각 에이전트는 본 통합 커맨드가 호출하는 것과 동일한 playbook 으로 실행됩니다.

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
- **User Work Signal Gate 판정** — 결과 빈 문자열이면 AUDIT-NOT-VIABLE 보고서만 출력 후 종료 (3 auditor 미소환). 결과 존재 시 기존 플로우 진입
- 3개 auditor 병렬 소환
- 반환 수신 → severity 매핑 → SSoT 충돌 병합 → 통합 보고서 조립 → 텍스트로 사용자에게 제시
- 통합 보고서를 대상 프로젝트에 **쓰지 않음** (기존 하네스 무변경 원칙)
- 보고서 말미에 **"🛠 다음 실행 방법 (How to apply)"** 섹션을 항상 포함하여, Critical/High/Medium 여부에 따라 `/harness-architect:harness-setup <대상 경로>` 재실행 또는 수동 편집 경로를 명확히 제시

## 파이프라인 분류

이 커맨드는 "리서치" 분류이나, 3개 auditor 자체가 각자 리뷰어 역할을 수행하므로 `.claude/rules/pipeline-review-gate.md` 의 **"리뷰의 리뷰" 재귀 금지 원칙**에 따라 추가 리뷰어 스텝을 두지 않습니다. 오케스트레이터의 보고서 조립은 병합·재분류 결정론적 변환이므로 면제 가능 (`review_exempt: true` / `exempt_reason: "deterministic transformation of reviewer outputs"`).

## 인자 처리

- `$ARGUMENTS` 에 경로가 있으면 Pre-flight 게이트에서 바로 검증
- 비어있으면 AskUserQuestion 으로 수집
- 경로에 공백·한글 포함 가능 — 절대 경로로 정규화

## Language

한국어로 응답. 코드/파일명은 영어.
