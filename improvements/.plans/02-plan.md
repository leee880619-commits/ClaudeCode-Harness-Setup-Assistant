# 구현 계획: 에이전트 출력 구조 강제화

## 요약 (변경 파일 목록)

| # | 파일 | 유형 | 변경 내용 |
|---|------|------|---------|
| 1 | `scripts/validate-phase-artifact.sh` | 신규 생성 | Phase 산출물 구조 검증 스크립트 |
| 2 | `.claude/hooks/syntax-check.sh` | 수정 | Phase 산출물 패턴 감지 시 경고 블록 추가 |
| 3 | `.claude/rules/orchestrator-protocol.md` | 수정 | Phase Gate 검증 절차 + 에이전트 소환 템플릿에 Output Contract 추가 |

에이전트 Self-Audit은 orchestrator-protocol.md 소환 템플릿 공통 섹션에 통합한다 (별도 파일 불필요).

---

## 구현 순서

1. `scripts/validate-phase-artifact.sh` 신규 생성 + 실행 권한 부여
2. `.claude/hooks/syntax-check.sh` 수정 (Phase 산출물 패턴 감지 경고 블록 추가)
3. `.claude/rules/orchestrator-protocol.md` 수정 (두 곳: Phase Gate 절차 + 소환 템플릿)

순서 이유: 스크립트를 먼저 만들어야 훅과 프로토콜 문서에서 참조 경로를 확인할 수 있다.

---

## 변경 1: `scripts/validate-phase-artifact.sh` (신규)

### 설계 결정

| 항목 | 결정 | 근거 |
|------|------|------|
| 입력 인수 | `<artifact_file>` (파일 경로 1개) | phase 번호는 파일명(`07-validation-report.md`)으로 자동 판별 가능. 별도 인수 불필요 |
| 종료 코드 | 0 = 통과, 1 = 형식 실패 | validate-settings.sh 패턴 동일. 2-레벨(0/1)로 단순화 — 오케스트레이터가 종류별 분기 불필요 |
| stdout | 통과 시 `✅` 메시지 | 오케스트레이터가 Bash 결과를 간략 확인 가능 |
| stderr | 실패 항목별 `❌` + 경고 `⚠️` | 파일명·항목명 명시. 오케스트레이터가 에이전트 재소환 지시에 재사용 |
| validate-settings.sh 재사용 패턴 | `fail=0` 플래그, `note()`/`err()`/`ok()` 패턴, `set -euo pipefail` | 동일 스타일 유지 |

### 전체 스크립트 코드

```bash
#!/bin/bash
# validate-phase-artifact.sh
# Phase 산출물 Markdown 파일의 필수 구조를 검증한다.
# 사용: bash scripts/validate-phase-artifact.sh <artifact_file>
# 종료 코드: 0 = 통과, 1 = 형식 실패

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "❌ 파일 없음: ${FILE:-인수 미지정}" >&2
  exit 1
fi

BASE="$(basename "$FILE")"
fail=0

err()  { printf '❌ %s\n' "$*" >&2; fail=1; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
ok()   { printf '✅ %s\n' "$*"; }

# --- YAML frontmatter 필수 필드 (4개) ---
FIRST_LINE="$(head -1 "$FILE" 2>/dev/null)"
if [[ "$FIRST_LINE" == "---" ]]; then
  # 첫 번째 --- 와 두 번째 --- 사이의 텍스트 추출
  FM="$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit} n==1{print}' "$FILE")"
  for field in phase completed status advisor_status; do
    if ! echo "$FM" | grep -q "^${field}:"; then
      err "frontmatter 필드 누락: ${field} — ${BASE}"
    fi
  done
else
  err "YAML frontmatter 없음 (파일이 --- 로 시작해야 함) — ${BASE}"
fi

# --- 필수 섹션 헤더 (5개) ---
REQUIRED_SECTIONS=(
  "^## Summary$"
  "^## Files Generated$"
  "^## Context for Next Phase$"
  "^## Escalations$"
  "^## Next Steps$"
)
for pat in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qE "$pat" "$FILE"; then
    err "필수 섹션 누락: ${pat} — ${BASE}"
  fi
done

# --- Phase 9 전용 추가 섹션 (3개) ---
if [[ "$BASE" == "07-validation-report.md" ]]; then
  for pat in "^## File Inventory$" "^## Security Audit$" "^## Simulation Trace$"; do
    if ! grep -qE "$pat" "$FILE"; then
      err "Phase 9 필수 섹션 누락: ${pat} — ${BASE}"
    fi
  done
fi

# --- Escalations 섹션 비어있음 경고 (fail 올리지 않음) ---
# "없음" 미기록 시 오케스트레이터가 Escalation 없음으로 오판할 수 있음
ESCAL_CONTENT="$(awk '/^## Escalations$/{p=1;next} /^## /{p=0} p{print}' "$FILE" | tr -d '[:space:]')"
if [[ -z "$ESCAL_CONTENT" ]]; then
  warn "Escalations 섹션이 비어있습니다 (\"없음\" 명시 권장) — ${BASE}"
fi

# --- 결과 ---
if [[ $fail -eq 0 ]]; then
  ok "Phase 산출물 구조 검증 통과: ${BASE}"
  exit 0
fi
exit 1
```

### validate-settings.sh와의 코드 스타일 대응

| validate-settings.sh 패턴 | validate-phase-artifact.sh 적용 |
|--------------------------|-------------------------------|
| `set -euo pipefail` | 동일 |
| `fail=0` + `exit 1` | 동일 |
| `err()` → stderr + fail=1 | 동일 |
| `ok()` → stdout | 동일 (warn() 추가) |
| `[[ ! -f "$SETTINGS" ]]` 파일 존재 선제 확인 | `[[ -z "$FILE" \|\| ! -f "$FILE" ]]` |
| jq 의존성 없음 (grep/awk만 사용) | 동일 — grep/awk만 사용, 외부 의존성 없음 |

---

## 변경 2: `.claude/hooks/syntax-check.sh` 수정

### 삽입 위치

파일의 85번 라인, 기존 YAML frontmatter 검증 블록 끝(`fi`) 이후, `exit 0` 바로 위.

**변경 전** (85~87번 라인):

```bash
  fi
fi

exit 0
```

**변경 후**:

```bash
  fi
fi

# --- Phase 산출물 패턴 감지: docs/*/NN[a-z]?-*.md ---
# 훅은 "경고 신호 생성" 역할만 수행한다 (exit 0 유지 — 에이전트 Write 차단 금지).
# 실제 강제 검증은 오케스트레이터가 Phase Gate 진입 전 별도 Bash 호출로 수행한다.
if [[ "$TARGET_FILE" == *.md ]]; then
  if echo "$TARGET_FILE" | grep -qE '/docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$'; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
    if [[ -n "$PLUGIN_ROOT" && -f "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" ]]; then
      bash "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" "$TARGET_FILE" >&2 || \
        warn "Phase 산출물 구조 경고 발생 — 오케스트레이터가 Phase Gate에서 재검증 필요: $TARGET_FILE"
    fi
  fi
fi

exit 0
```

참고: `warn()`은 이 파일에 정의되지 않으므로 아래와 같이 인라인 echo로 작성한다.

**실제 삽입 코드** (warn 함수 없이):

```bash
# --- Phase 산출물 패턴 감지: docs/*/NN[a-z]?-*.md ---
if [[ "$TARGET_FILE" == *.md ]]; then
  if echo "$TARGET_FILE" | grep -qE '/docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$'; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
    if [[ -n "$PLUGIN_ROOT" && -f "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" ]]; then
      bash "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" "$TARGET_FILE" >&2 || \
        echo "⚠️  Phase 산출물 구조 경고 — 오케스트레이터가 Phase Gate에서 재검증 필요: $TARGET_FILE" >&2
    fi
  fi
fi
```

**변경 이유**: 훅이 exit 1로 에이전트의 Write를 차단하면 서브에이전트 컨텍스트에서 신호 전파가 불확실하고, 파일은 이미 디스크에 기록된 상태이므로 원자적 롤백이 불가능하다. 따라서 훅은 경고 로그 생성 역할로 한정하고, 실제 강제는 오케스트레이터의 명시적 Bash 호출에 맡긴다 (02-structured-output-enforcement.md 반론 2 수용).

---

## 변경 3: `.claude/rules/orchestrator-protocol.md` 수정

두 곳을 수정한다.

### 3-A: Phase Gate — 파일 존재 + 섹션 스키마 검증 섹션 교체

**삽입 위치**: `## Phase Gate` > `### 파일 존재 + 섹션 스키마 검증` 섹션 전체 (282~288번 라인)

**변경 전**:

```markdown
### 파일 존재 + 섹션 스키마 검증

산출물 파일 존재 확인만으로는 "에이전트가 작성 중 실패했는데 부분 파일이 남은" 경우를 거르지 못한다. 각 산출물에 대해 **필수 섹션 헤더가 실제로 존재하는지**를 함께 검증한다:

- 모든 Phase 산출물: `^## Summary$`, `^## Files Generated$`, `^## Context for Next Phase$`, `^## Escalations$`, `^## Next Steps$` 5개 헤더가 정규식으로 매칭되어야 한다.
- Phase 9 산출물(`07-validation-report.md`)은 추가로 `^## File Inventory$`, `^## Security Audit$`, `^## Simulation Trace$` 3개도 요구한다.
- 매칭 실패 시: 해당 Phase 에이전트 재소환. 재소환 후에도 매칭 실패가 반복되면 Advisor BLOCK 루프 소진 프로토콜의 3개 선택지 중 "수동 개입"을 사용자에게 제시.

산출물 미존재 시: 이전 Phase 에이전트를 재소환한다.
사용자가 "Phase N으로 바로 가자" 요청 시 → 누락된 Phase를 안내하고 순서대로 진행.
```

**변경 후**:

```markdown
### 파일 존재 + 섹션 스키마 검증

산출물 파일 존재 확인만으로는 "에이전트가 작성 중 실패했는데 부분 파일이 남은" 경우를 거르지 못한다. 각 산출물에 대해 **필수 섹션 헤더와 frontmatter 필드**가 실제로 존재하는지를 외부 스크립트로 자동 검증한다.

#### Phase Gate 검증 절차 (오케스트레이터 실행 순서)

1. 산출물 파일 존재 확인 (`Bash(ls <artifact_file>)`)
   - 미존재 시: 이전 Phase 에이전트 재소환
2. **구조 검증** (Bash 직접 호출):
   ```
   Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase-artifact.sh <artifact_file>)
   ```
   - exit 0 → Step 3(Advisor)으로 진행
   - exit 1 → stderr의 누락 항목을 에이전트에게 전달하며 "다음 항목을 Edit으로 보완 후 재저장" 지시 → 1회만 재검증
     - 재검증 exit 0 → Advisor 진행
     - 재검증 exit 1 → `AskUserQuestion` "수동 편집 / Phase 스킵" (2선택)
3. Advisor 실행 (기존 Red-team Advisor 프로토콜 유지)

**포맷 실패와 Advisor BLOCK은 완전히 분리된 루프**다. 포맷 재검증이 Advisor 루프에 진입하지 않으며, Advisor BLOCK이 포맷 재검증을 유발하지 않는다.

검증 항목 (스크립트 내부 — 오케스트레이터는 종료 코드만 소비):
- frontmatter 필드 4개: `phase`, `completed`, `status`, `advisor_status`
- 필수 섹션 헤더 5개: `## Summary`, `## Files Generated`, `## Context for Next Phase`, `## Escalations`, `## Next Steps`
- Phase 9 전용 추가 3개: `## File Inventory`, `## Security Audit`, `## Simulation Trace`
- Escalations 섹션 비어있음: 경고(exit 0 유지) — 오케스트레이터가 참고 후 수동 확인

사용자가 "Phase N으로 바로 가자" 요청 시 → 누락된 Phase를 안내하고 순서대로 진행.
```

**변경 이유**: 기존 "정규식 수동 확인 지시"를 `validate-phase-artifact.sh` 단일 Bash 호출로 대체하여 오케스트레이터의 검증 부담을 종료 코드 소비로 캡슐화. 포맷 실패와 Advisor BLOCK을 명시적으로 분리하여 이중 루프 방지.

---

### 3-B: 에이전트 소환 템플릿에 Output Contract 추가

**삽입 위치**: `## Phase 실행 프로토콜` > `### 에이전트 소환 템플릿 (Agent-Playbook 분리)` 섹션의 프롬프트 템플릿 블록 끝 (`---` 닫힘 라인) 바로 앞.

현재 템플릿 구조 (관련 부분):

```markdown
프롬프트 템플릿 (동적 컨텍스트만 전달 — 정체성/규칙은 에이전트 정의에 포함):
---
[Two Project Paths — 반드시 구분]
...
[Artifacts Directory]
Phase 산출물을 대상 프로젝트에 저장 (절대 경로 사용):
{대상 프로젝트 절대 경로}/docs/{요청명}/{NN}-{phase-name}.md
---
```

**변경 후** (템플릿 닫힘 `---` 바로 앞에 삽입):

```markdown
프롬프트 템플릿 (동적 컨텍스트만 전달 — 정체성/규칙은 에이전트 정의에 포함):
---
[Two Project Paths — 반드시 구분]
...
[Artifacts Directory]
Phase 산출물을 대상 프로젝트에 저장 (절대 경로 사용):
{대상 프로젝트 절대 경로}/docs/{요청명}/{NN}-{phase-name}.md

[Output Contract — Write 도구 호출 직전 자기 확인]
산출물 파일을 Write하기 전, 다음 항목을 순서대로 확인하라:
1. YAML frontmatter에 phase / completed / status / advisor_status 4개 필드가 있는가?
2. ## Summary 섹션이 있는가? (200단어 이내)
3. ## Files Generated 섹션에 실제 기록된 파일의 절대 경로가 있는가?
4. ## Context for Next Phase 섹션에 이 Phase의 필수 항목이 있는가?
5. ## Escalations 섹션이 있고, 항목 없으면 "없음"이 명시되어 있는가?
6. ## Next Steps 섹션이 있는가?
누락 항목이 있으면 Write 전에 보완한다. 이 체크리스트는 오케스트레이터의 외부 스크립트 검증(validate-phase-artifact.sh)을 보조하는 선의 예방 레이어다.
---
```

**변경 이유**: 자기 검증(Self-Audit)은 "선의의 에이전트가 실수로 섹션을 빠뜨리는 경우"를 줄이는 Layer 1 예방 수단이다 (완전한 보증이 아님). 실제 강제는 외부 스크립트(Layer 2)와 Advisor(Layer 3)에 맡기며, 세 레이어의 역할 분리를 체크리스트 마지막 문장에 명시하여 에이전트가 "형식만 맞추면 된다"는 오해를 방지한다.

---

## 리스크 및 주의사항

| 리스크 | 확률 | 완화 방안 |
|-------|------|---------|
| `CLAUDE_PLUGIN_ROOT` 미설정 환경에서 훅이 스크립트를 찾지 못함 | 저 | `[[ -n "$PLUGIN_ROOT" && -f "..." ]]` 조건부 실행으로 안전 처리. 미설정 시 훅 경고 없이 통과 (개발자가 `--plugin-dir .` 없이 실행한 경우) |
| awk의 frontmatter 추출 로직이 중첩 `---` 있는 파일에서 오동작 | 저 | frontmatter는 파일 최상단에 위치해야 하는 규약이므로 중첩 가능성 낮음. 추가 보호 필요 시 `head -20` 범위 제한 가능 |
| 포맷 통과 + 내용 부실 (빈 섹션) | 중 | 의도적 설계 — 내용 품질은 Advisor 책임. 형식/내용 분리 원칙 준수 |
| 재검증 1회 후 AskUserQuestion 빈도 증가 | 저~중 | 포맷 실패는 에이전트 역량 문제. 사용자 개입이 적절하며, "수동 편집" 선택지 제공으로 제어권 유지 |
| phase-setup.md의 Rules 섹션이 "반환 포맷 준수" 4개 섹션만 나열 (Context for Next Phase 누락) | 기존 버그 | 이번 변경 범위에서는 수정하지 않음. 단, orchestrator-protocol.md의 Output Contract가 에이전트 소환 시 프롬프트로 전달되므로 실질적 보완 가능 |
| syntax-check.sh 훅의 서브에이전트 신호 전파 불확실성 | 중 | 훅을 경고 전용(exit 0)으로 설계하여 차단 메커니즘 의존 제거. 실제 게이팅은 오케스트레이터 명시적 Bash 호출로 분리 (02-structured-output-enforcement.md 최수아 비판 2 수용) |
