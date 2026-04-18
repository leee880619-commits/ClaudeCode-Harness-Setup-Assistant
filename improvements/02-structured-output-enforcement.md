# 개선 사항 2: 에이전트 출력 구조 강제화

## 문제 정의

### 배경
harness-architect의 9단계 오케스트레이션에서 각 Phase 에이전트(LLM)는 완료 시 다음을 산출해야 한다:

1. **YAML frontmatter** — `phase`, `completed`, `status`, `advisor_status` 필드 포함
2. **5개 필수 섹션** — `## Summary`, `## Files Generated`, `## Context for Next Phase`, `## Escalations`, `## Next Steps`
3. **Files Generated 경로** — 실제 기록된 파일 경로와 일치

현재 `orchestrator-protocol.md`의 "파일 존재 + 섹션 스키마 검증"에는 정규식 매칭 검증이 명시되어 있으나, 이는 오케스트레이터(메인 세션)가 에이전트 반환 후 **수동으로 확인**하는 방식에 의존한다. 오케스트레이터 자체도 LLM이므로 검증 누락이 발생할 수 있다.

### 실패 시나리오
| 실패 유형 | 후속 결과 |
|---------|---------|
| `advisor_status` frontmatter 누락 | 재개 시 Phase 상태 판별 불가 → 전체 Phase 재실행 |
| `## Context for Next Phase` 누락 | 다음 Phase 에이전트가 컨텍스트 없이 실행 → 설계 품질 저하 |
| `## Escalations` 비어있음 (없음 미기록) | 오케스트레이터가 Escalation 없음으로 오판, 서브에이전트의 AskUserQuestion 우회 감지 실패 |
| Files Generated 경로 불일치 | Phase Gate 검증에서 파일 존재 오판 → 다음 Phase 잘못된 컨텍스트로 진행 |

---

## 도메인 전문가 제안 (Prompt Engineering Specialist 박지호)

### 현재 "수동 확인" 방식의 한계

오케스트레이터 역시 LLM이므로, 에이전트 반환문을 파싱하여 필수 섹션을 확인하라는 지시가 있어도 컨텍스트 압박·반환 길이 초과 상황에서 검증 스텝을 건너뛸 수 있다. 특히:

- **반환 길이가 길면** 오케스트레이터가 Summary 부분만 파싱하고 하위 섹션을 생략
- **연속 Phase 전환 상황에서** 검증 보다 "다음 에이전트 소환"을 우선
- **정규식 매칭 지시가 프롬프트에 있어도** 실제 Bash grep 호출 없이 텍스트로 "확인했습니다" 처리

### 제안 1: 에이전트 산출물 파일에 대한 PostToolUse 검증 스크립트

`syntax-check.sh`는 현재 JSON 구문 + YAML frontmatter 닫힘만 검사한다. 이를 확장하여 Phase 산출물 Markdown의 **필수 섹션 헤더 존재 여부**와 **frontmatter 필드 완전성**을 자동 검증하는 스크립트를 추가한다:

**신규 파일**: `scripts/validate-phase-artifact.sh`

```bash
#!/bin/bash
# validate-phase-artifact.sh
# Phase 산출물 Markdown 파일의 필수 섹션·frontmatter를 검증한다.
# 사용: bash scripts/validate-phase-artifact.sh <artifact_file>
# 종료 코드: 0 = 통과, 1 = 실패

set -euo pipefail
FILE="${1:-}"
if [[ -z "$FILE" ]] || [[ ! -f "$FILE" ]]; then
  echo "❌ 파일 없음: $FILE" >&2; exit 1
fi

BASE="$(basename "$FILE")"
fail=0

# --- YAML frontmatter 필수 필드 ---
if head -1 "$FILE" | grep -q "^---$"; then
  for field in phase completed status advisor_status; do
    if ! awk '/^---$/{n++} n==1{print}' "$FILE" | grep -q "^${field}:"; then
      echo "❌ frontmatter 필드 누락: $field — $BASE" >&2
      fail=1
    fi
  done
else
  echo "❌ YAML frontmatter 없음: $BASE" >&2
  fail=1
fi

# --- 필수 섹션 헤더 ---
REQUIRED_SECTIONS=(
  "^## Summary$"
  "^## Files Generated$"
  "^## Context for Next Phase$"
  "^## Escalations$"
  "^## Next Steps$"
)
for pat in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qE "$pat" "$FILE"; then
    echo "❌ 필수 섹션 누락: $pat — $BASE" >&2
    fail=1
  fi
done

# --- Phase 9 추가 섹션 ---
if [[ "$BASE" == "07-validation-report.md" ]]; then
  for pat in "^## File Inventory$" "^## Security Audit$" "^## Simulation Trace$"; do
    if ! grep -qE "$pat" "$FILE"; then
      echo "❌ Phase 9 필수 섹션 누락: $pat" >&2
      fail=1
    fi
  done
fi

# --- Escalations "없음" 명시 확인 ---
ESCAL_CONTENT=$(awk '/^## Escalations$/,/^## /' "$FILE" | grep -v "^## " | tr -d '[:space:]')
if [[ -z "$ESCAL_CONTENT" ]]; then
  echo "⚠️  Escalations 섹션이 비어있음 (\"없음\" 명시 권장): $BASE" >&2
  # 경고만, fail은 올리지 않음 (운영 정책에 따라 조정 가능)
fi

if [[ $fail -eq 0 ]]; then
  echo "✅ Phase 산출물 검증 통과: $BASE"
  exit 0
fi
exit 1
```

### 제안 2: syntax-check.sh PostToolUse 훅 확장

`syntax-check.sh`에 Phase 산출물 패턴(`docs/*/[0-9][0-9]*.md`) 감지 시 `validate-phase-artifact.sh`를 자동 호출하는 분기 추가:

```bash
# syntax-check.sh 하단 추가 (Markdown 검증 블록 다음)
if [[ "$TARGET_FILE" == *.md ]]; then
  # Phase 산출물 패턴 감지: docs/*/NN-*.md
  if echo "$TARGET_FILE" | grep -qE '/docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$'; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
    VALIDATOR="${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh"
    if [[ -f "$VALIDATOR" ]]; then
      bash "$VALIDATOR" "$TARGET_FILE" >&2 || exit 1
    fi
  fi
fi
```

### 제안 3: 에이전트 프롬프트 구조 강제 (프롬프트 엔지니어링)

`orchestrator-protocol.md`의 에이전트 소환 템플릿에 **Output Contract 체크리스트**를 명시적으로 삽입하고, 에이전트가 반환 전 자기 검증(Self-Audit) 스텝을 실행하도록 지시:

```
[Output Contract — 반환 전 자기 검증 필수]
산출물 파일 저장 후, Write 완료 직전에 다음을 확인하라:
□ YAML frontmatter에 phase/completed/status/advisor_status 4개 필드 존재
□ ## Summary 섹션 존재 (200단어 이내)
□ ## Files Generated 섹션 존재 + 경로가 실제 기록된 파일과 일치
□ ## Context for Next Phase 섹션 존재 + 이 Phase의 필수 항목 포함
□ ## Escalations 섹션 존재 + 항목 없으면 "없음" 명시
□ ## Next Steps 섹션 존재
누락 시 반환하지 말고 파일을 Edit하여 보완한 뒤 반환한다.
```

### 제안 4: "에이전트 실패" vs "잘못된 포맷으로 성공" 구분

오케스트레이터가 에이전트 반환 후 Phase Gate 진입 전에 다음 기준으로 분류:

| 상태 | 감지 기준 | 처리 |
|-----|---------|-----|
| **완전 실패** | 산출물 파일 자체가 없음 | 에이전트 재소환 (최대 2회) |
| **포맷 실패** | 파일 존재 + 섹션/frontmatter 누락 | `validate-phase-artifact.sh` 비정상 종료 → 에이전트에게 "파일을 Edit하여 섹션 보완" 지시 후 재소환 |
| **내용 실패** | 파일·포맷 정상 + Advisor BLOCK | 기존 Advisor 루프 프로토콜 적용 |
| **성공** | 파일 + 포맷 + Advisor pass/note | 다음 Phase 진행 |

---

## 레드팀 비판 (QA Critic 최수아)

### 비판 1: 프롬프트 엔지니어링으로 구조를 강제하는 것의 근본 한계

"Output Contract 자기 검증" 지시는 **에이전트에게 자기 자신의 출력을 채점**하게 요구한다. LLM은 자기가 방금 작성한 텍스트에 대해 "있다고 착각"하는 경향이 강하다 — 특히 컨텍스트 창 말미에 위치한 섹션. 즉, `## Context for Next Phase`를 빠뜨린 에이전트가 자기 검증에서 "존재함"으로 체크할 가능성이 높다. 이는 **검증 효과가 없는 검증**이다.

### 비판 2: PostToolUse 훅이 LLM 에이전트 출력을 검증할 수 있는가?

`syntax-check.sh`는 **사람(또는 Claude Code 자체)이 Write/Edit 도구를 호출할 때** 발동하는 PostToolUse 훅이다. harness-architect의 에이전트(서브에이전트)가 산출물을 쓸 때도 이 훅이 발동한다.

그러나 핵심 문제가 있다:

- **훅이 exit 1을 반환해도 에이전트가 그것을 감지하지 못한다**. Claude Code의 PostToolUse 훅 실패는 메인 세션의 도구 응답 오류로 나타나지만, 서브에이전트 컨텍스트에서는 이 오류가 어떻게 전파되는지 명세가 불분명하다.
- 서브에이전트가 Write 도구를 호출하여 파일을 쓴 후, 훅이 실패하면 **파일은 이미 디스크에 기록된 상태**다. 훅 실패가 Write 자체를 원자적으로 롤백하지 않는다.
- 결과적으로 "훅이 실패했으니 에이전트가 자동으로 재시도"하는 경로가 성립하려면, 서브에이전트가 훅 실패 신호를 받아 Edit으로 수정하는 루프를 직접 구현해야 한다. 이는 에이전트 정의에 훅 실패 처리 로직을 주입하는 복잡도를 요구한다.

### 비판 3: 구조 검증 강화 → 에이전트 자유도 제한

필수 섹션 체크가 강해질수록 에이전트는 "내용보다 형식을 맞추기"에 집중한다. 특히:

- `## Context for Next Phase`가 존재하기만 하면 통과하는 검증은 **빈 섹션 또는 보일러플레이트**를 유발한다
- 에이전트가 검증 통과를 위해 "없음"을 Escalations에 기계적으로 기록하면, 실제 불확실성이 가려진다
- 필수 섹션 헤더 매칭은 **형식 준수**를 보장하지 **내용 품질**을 보장하지 않는다

### 비판 4: 자동 재시도 루프의 무한 루프 위험

박지호의 "포맷 실패 → 에이전트에게 Edit 지시 → 재소환" 흐름에서:

- 에이전트가 Edit으로 섹션을 추가했으나 내용이 부실한 경우, `validate-phase-artifact.sh`는 통과하지만 Advisor는 BLOCK을 반환
- Advisor BLOCK → 에이전트 재소환 → 포맷 재검증 → Advisor 재실행의 **이중 루프**가 형성된다
- 두 루프가 각각 2회 상한을 갖지만, 조합하면 이론상 4회 재시도 + 교착 탈출 3선택 절차가 중첩되어 UX가 복잡해진다
- 재소환 비용(토큰, 시간)이 누적될 때 사용자 경험이 크게 저하된다

### 비판 5: 오케스트레이터 복잡도 폭발

"오케스트레이터가 파일 존재 확인 → frontmatter 파싱 → 섹션 검증 → 스크립트 실행 → 결과 해석 → 분류(완전실패/포맷실패/내용실패/성공)"를 순서대로 수행하면, 오케스트레이터의 책임이 **Phase 관리자 + 파일 검증기 + 분류 엔진** 세 역할을 동시에 담당하게 된다.

현재 `orchestrator-protocol.md`의 원칙("메인 세션은 순수 오케스트레이터")과 충돌하며, 오케스트레이터가 복잡해질수록 **자기 자신도 실수할 가능성**이 높아진다는 역설이 발생한다.

---

## 수렴: 박지호의 반론과 조정

### 반론 1: 자기 검증의 한계 인정 + 보완책

최수아의 지적이 맞다. "자기 검증"은 형식 준수의 **의도 신호**이지, 완전한 보증이 아니다. 따라서 프롬프트 레벨의 Self-Audit은 **선의의 에이전트가 실수로 섹션을 빠뜨리는 경우**를 줄이는 목적으로만 유지하고, 실제 강제는 외부 스크립트에 맡긴다.

자기 검증 지시는 "Write 도구 호출 전 체크리스트 확인"으로 단순화하고, 오케스트레이터 검증을 제거하지 않는다.

### 반론 2: PostToolUse 훅 활용 범위 재정의

최수아의 훅 전파 불확실성 지적을 수용한다. PostToolUse 훅은 **즉각적 자동 롤백의 메커니즘**으로 사용하지 않고, 다음 두 용도로만 활용한다:

1. **JSON/YAML 구문 오류 즉각 감지** (기존 `syntax-check.sh` 역할 — 이미 검증됨)
2. **Phase 산출물 파일 작성 후 경고 로그 생성** — exit 1이 아닌 **exit 0 + stderr 경고**로, 오케스트레이터가 다음 단계에서 별도 Bash 호출로 스크립트를 재실행하여 결과를 확인

즉, 훅은 "강제 차단"이 아닌 "검증 신호 생성"으로 역할을 제한한다.

### 반론 3: 형식 vs 내용 — 책임 분리 명확화

내용 품질 검증은 Advisor의 책임이다. `validate-phase-artifact.sh`는 **형식 검증만** 담당한다는 원칙을 명시한다:

- 스크립트: 헤더 존재, frontmatter 필드, Escalations 비어있음 경고
- Advisor: 내용 품질, 완전성, 설계 적절성

두 검증의 역할을 혼합하지 않는다.

### 반론 4: 재시도 루프 단순화

이중 루프 문제를 해소하기 위해 포맷 실패를 Advisor 루프와 **완전히 분리**한다:

- 포맷 실패(validate-phase-artifact.sh 비정상): 에이전트에게 Edit 지시 → 1회만 재검증. 재검증도 실패 시 Advisor 루프 진입 없이 즉시 오케스트레이터가 사용자에게 "수동 편집" 선택지 제시
- Advisor BLOCK: 기존 2회 루프 유지, 포맷 재검증 미포함

### 반론 5: 오케스트레이터 복잡도 — 검증 위임

검증 로직을 오케스트레이터에 내재화하지 않고, `validate-phase-artifact.sh` 스크립트를 단일 Bash 호출로 위임한다. 오케스트레이터가 파악해야 하는 것은 **스크립트 종료 코드(0/1)와 stderr 한 줄 요약**뿐이다. 내부 검증 로직은 스크립트에 캡슐화된다.

---

## 최종 합의된 개선 방향성

> **핵심 원칙**: 구조 검증은 외부 스크립트로 캡슐화, 오케스트레이터는 종료 코드만 소비, 형식과 내용 검증을 분리한다.

### 세 층위 방어 전략

```
Layer 1 — 예방 (에이전트 프롬프트)
  Self-Audit 체크리스트 → Write 전 형식 인식 강화

Layer 2 — 감지 (외부 스크립트)
  validate-phase-artifact.sh → 형식 검증 (frontmatter + 섹션 헤더)
  오케스트레이터가 Bash로 직접 호출 → 종료 코드로 분기

Layer 3 — 품질 (Advisor)
  Red-team Advisor → 내용 품질, 설계 완전성
  기존 2회 루프 유지
```

### 포맷 실패 처리 흐름 (최종)

```
에이전트 반환
  └─ 오케스트레이터: bash validate-phase-artifact.sh <artifact_file>
       ├─ exit 0 → Advisor 실행 (기존 경로)
       └─ exit 1 → 에이전트에게 Edit 지시 (1회)
                    └─ 재검증
                         ├─ exit 0 → Advisor 실행
                         └─ exit 1 → AskUserQuestion "수동 편집 / Phase 스킵"
```

---

## 구현 방법론 (단계별 + 구체적 파일 변경)

### Step 1: `scripts/validate-phase-artifact.sh` 신규 생성

```bash
#!/bin/bash
# validate-phase-artifact.sh
# Phase 산출물 Markdown 파일의 필수 구조를 검증한다.
# 사용: bash scripts/validate-phase-artifact.sh <artifact_file>
# 종료 코드: 0 = 통과, 1 = 형식 실패

set -euo pipefail
FILE="${1:-}"
[[ -z "$FILE" || ! -f "$FILE" ]] && { echo "❌ 파일 없음: $FILE" >&2; exit 1; }

BASE="$(basename "$FILE")"
fail=0

# --- YAML frontmatter 필수 필드 ---
if head -1 "$FILE" | grep -q "^---$"; then
  FM=$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit} n==1{print}' "$FILE")
  for field in phase completed status advisor_status; do
    echo "$FM" | grep -q "^${field}:" || { echo "❌ frontmatter 필드 누락: $field — $BASE" >&2; fail=1; }
  done
else
  echo "❌ YAML frontmatter 없음: $BASE" >&2; fail=1
fi

# --- 필수 섹션 헤더 ---
for pat in \
  "^## Summary$" \
  "^## Files Generated$" \
  "^## Context for Next Phase$" \
  "^## Escalations$" \
  "^## Next Steps$"; do
  grep -qE "$pat" "$FILE" || { echo "❌ 섹션 누락: $pat — $BASE" >&2; fail=1; }
done

# --- Phase 9 추가 섹션 ---
if [[ "$BASE" == "07-validation-report.md" ]]; then
  for pat in "^## File Inventory$" "^## Security Audit$" "^## Simulation Trace$"; do
    grep -qE "$pat" "$FILE" || { echo "❌ Phase 9 필수 섹션 누락: $pat — $BASE" >&2; fail=1; }
  done
fi

# --- Escalations 비어있음 경고 (fail 올리지 않음) ---
ESCAL=$(awk '/^## Escalations$/{p=1;next} /^## /{p=0} p{print}' "$FILE" | tr -d '[:space:]')
[[ -z "$ESCAL" ]] && echo "⚠️  Escalations 섹션이 비어있습니다 (\"없음\" 명시 권장): $BASE" >&2

[[ $fail -eq 0 ]] && echo "✅ Phase 산출물 검증 통과: $BASE" && exit 0
exit 1
```

### Step 2: `scripts/validate-phase-artifact.sh` 실행 권한 부여

```bash
chmod +x scripts/validate-phase-artifact.sh
```

### Step 3: `syntax-check.sh` 수정 — Phase 산출물 감지 시 경고 통합

파일: `.claude/hooks/syntax-check.sh`

현재 Markdown 검증 블록(75~85번 라인) 이후, `exit 0` 위에 다음 블록을 추가한다:

```bash
# --- Phase 산출물 패턴 감지: docs/*/NN[a-z]?-*.md ---
if [[ "$TARGET_FILE" == *.md ]]; then
  if echo "$TARGET_FILE" | grep -qE '/docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$'; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
    if [[ -n "$PLUGIN_ROOT" && -f "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" ]]; then
      # exit 0으로 실행 — 차단이 아닌 경고 신호 (오케스트레이터가 별도 확인)
      bash "${PLUGIN_ROOT}/scripts/validate-phase-artifact.sh" "$TARGET_FILE" >&2 || \
        echo "⚠️  Phase 산출물 구조 경고 발생 — 오케스트레이터가 재검증 필요: $TARGET_FILE" >&2
    fi
  fi
fi
```

**중요**: `|| exit 1`이 아닌 `|| echo` 처리. 훅이 에이전트의 Write를 차단하지 않고, 오케스트레이터가 Phase Gate 진입 전 스크립트를 별도 재실행하여 확인한다.

### Step 4: `orchestrator-protocol.md` — Phase Gate 검증 절차 구체화

"파일 존재 + 섹션 스키마 검증" 섹션을 다음으로 업데이트:

```markdown
### Phase Gate 검증 절차 (오케스트레이터 실행 순서)

1. 산출물 파일 존재 확인 (Bash ls)
2. **구조 검증** (Bash 직접 호출):
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase-artifact.sh <artifact_file>
   ```
   - exit 0: Step 3으로 진행
   - exit 1: 에이전트에게 "다음 섹션 보완 후 Edit 재저장" 지시 → 1회 재검증
             재검증 실패 시: AskUserQuestion "수동 편집 / Phase 스킵"
3. Advisor 실행 (기존 프로토콜 유지)
```

### Step 5: 에이전트 소환 템플릿에 Self-Audit 체크리스트 추가

`orchestrator-protocol.md`의 프롬프트 템플릿 공통 섹션에 추가:

```markdown
[Output Contract — Write 도구 호출 직전 자기 확인]
산출물 파일을 Write하기 전, 다음 항목을 순서대로 확인하라:
1. YAML frontmatter에 phase/completed/status/advisor_status 4개 필드가 있는가?
2. ## Summary 섹션이 있는가?
3. ## Files Generated 섹션에 실제 기록된 파일의 절대 경로가 있는가?
4. ## Context for Next Phase 섹션에 이 Phase의 필수 항목이 있는가?
5. ## Escalations 섹션이 있고, 항목 없으면 "없음"이 명시되어 있는가?
6. ## Next Steps 섹션이 있는가?
누락 항목이 있으면 파일을 Write하기 전에 보완한다.
```

### Step 6: `final-validation.md` Step 3 — 산출물 섹션 검증 자동화 명시

`playbooks/final-validation.md`의 Step 3 항목 13에, 수동 grep 대신 스크립트 사용 명시:

```markdown
13. **산출물 필수 섹션 스키마 검증** (자동 도구 우선):
    - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase-artifact.sh <각 산출물 파일>`
    - non-zero exit 시: `[BLOCKING] 산출물 {파일명} 구조 실패 — 상세는 stderr 참조`
    - 스크립트 미실행 시: 수동 grep으로 5개 헤더 확인
```

---

## 예상 효과 및 성공 지표

| 지표 | 현재 | 목표 |
|-----|------|------|
| Phase 산출물 구조 실패율 | 오케스트레이터 수동 확인 의존, 측정 불가 | 자동 감지 100%, 실패 시 1회 재시도 내 해결 |
| 재개 프로토콜 성공률 | frontmatter 누락 시 판별 불가 | YAML frontmatter 존재 시 항상 상태 판별 가능 |
| Escalations 비어있음 오판 | 오케스트레이터가 시각적으로 감지 | 스크립트가 경고 출력, 오케스트레이터가 주의 |
| 오케스트레이터 검증 부담 | 정규식 수동 확인 지시 포함 | Bash 1회 호출로 대체, 종료 코드만 소비 |

---

## 잔여 리스크 및 완화 방안

| 리스크 | 확률 | 완화 |
|-------|------|-----|
| 에이전트가 Self-Audit 체크리스트를 건너뜀 | 중 | 외부 스크립트(Layer 2)가 백스톱 역할 |
| validate-phase-artifact.sh가 `CLAUDE_PLUGIN_ROOT` 미설정 환경에서 실행 안 됨 | 저 | 스크립트 내 환경변수 미설정 시 경고 + fallback 수동 체크 |
| 포맷 통과 + 내용 부실 (빈 섹션) | 중 | Advisor 책임 유지. 형식과 내용 검증을 의도적으로 분리 |
| 재시도 1회 후 AskUserQuestion 빈도 증가 | 저-중 | 포맷 실패는 에이전트 역량 문제이므로 사용자 개입이 적절. AskUserQuestion 옵션에 "자동 보완 시도" 추가 가능 |
| `syntax-check.sh` 훅의 서브에이전트 신호 전파 불확실 | 중 | 훅은 경고 전용(exit 0), 실제 검증은 오케스트레이터의 명시적 Bash 호출로 분리 |
