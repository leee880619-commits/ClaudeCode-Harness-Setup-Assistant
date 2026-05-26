#!/bin/bash
# validate-phase-artifact.sh
# Phase 산출물 Markdown 파일의 필수 구조를 검증한다.
# 사용: bash scripts/validate-phase-artifact.sh <artifact_file>
# 종료 코드: 0 = 통과, 1 = 형식 실패
#
# ============================================================================
# SSoT (Single Source of Truth) — Phase 0 silent inference 차단의 작동 권위
# ============================================================================
# 본 스크립트는 Phase 0 의 silent inference 차단 (Pre-collected Answers 출처 토큰
# 검증, A1~A10 9항목 필수 행, 옵션 라벨 N/A 변형 차단 등) 의 **작동 SSoT** 이다.
# 텍스트 규약 (commands/harness-setup.md, .claude/rules/orchestrator-protocol.md,
# .claude/rules/question-discipline.md, playbooks/fresh-setup.md,
# playbooks/final-validation.md, .claude/agents/phase-setup.md) 은 본 스크립트의
# 검증 항목을 *기술하는 의도 SSoT* 이며, 작동 결과 충돌 시 본 스크립트가 이긴다.
#
# 검증 항목 변경 시:
# 1. 본 스크립트의 해당 블록을 먼저 수정
# 2. 텍스트 규약 6곳에 "validate-phase-artifact.sh 검증 항목 참조" 한 줄로만 인용
#    (정의 본문을 텍스트에 복제 금지 — DRY 위반)
# 3. CHANGELOG.md 에 변경 사유 기록 (incident inline 인용은 가시 텍스트 외 위치)
# ============================================================================

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

# --- Phase 3 전용 운영 가드 섹션 (풀 트랙 워크플로우 설계 산출물) ---
# 경량 트랙 산출물(02-lite-design.md)은 단일 패스이므로 제외 (setup-lite.md Output Contract의
# session_recovery: not_applicable 필드로 대체 명시됨).
# 일반 웹앱/CLI 프로젝트에서도 섹션 헤더만 요구 — 본문에 "단일 세션 완결 — 복구 프로토콜 미필요"
# 한 줄로 도피 가능. 다중 에이전트 여부 판정은 Advisor Dim 13이 품질 검증.
if [[ "$BASE" == "02-workflow-design.md" ]]; then
  if ! grep -qE "^## Session Recovery Protocol$" "$FILE"; then
    err "Phase 3 필수 섹션 누락: ^## Session Recovery Protocol$ — ${BASE} (단일 세션 완결 시 해당 섹션 아래 한 줄 명시로 통과)"
  fi
fi

# --- Phase 4 전용 운영 가드 섹션 (파이프라인 실패 복구 완결성) ---
if [[ "$BASE" == "03-pipeline-design.md" ]]; then
  if ! grep -qE "^## Failure Recovery & Artifact Versioning$" "$FILE"; then
    err "Phase 4 필수 섹션 누락: ^## Failure Recovery & Artifact Versioning$ — ${BASE} (각 파이프라인별 max_retries·timeout·버저닝 전략 품질은 Advisor Dim 13이 검증)"
  fi
fi

# --- Phase 0 전용 Pre-collected Answers 검증 (silent inference 차단 게이트) ---
# v1.0.x 까지 오케스트레이터가 사용자 자유 발화에서 A1·A2·A6·A9 등을 추출하여 AskUserQuestion 발화를 건너뛴
# incident 가 발생. 본 검증은 00-target-path.md 의 ## Pre-collected Answers 섹션에 9개 필수 항목이
# 모두 기록되어 있고, 출처가 AskUserQuestion#N 또는 $ARGUMENTS prefill (경로 한정) 인지 확인.
if [[ "$BASE" == "00-target-path.md" ]]; then
  if ! grep -qE "^## Pre-collected Answers$" "$FILE"; then
    err "Phase 0 필수 섹션 누락: ^## Pre-collected Answers$ — 사용자 발화 추론 검증 게이트 (v1.0.x silent inference incident 재발 차단)"
  else
    PCA_BLOCK="$(awk '/^## Pre-collected Answers$/{p=1;next} /^## /{p=0} p{print}' "$FILE")"
    # 9개 필수 항목 (A4 옵션 제외) 행 존재 확인 — 표 셀에 "A1 " "A2 " 등이 포함되어야 함
    for item in A1 A2 A3 A5 A6 A7 A8 A9 A10; do
      if ! printf '%s\n' "$PCA_BLOCK" | grep -qE "\| ${item}[[:space:]]" ; then
        err "Phase 0 Pre-collected Answers 누락 항목: ${item} (silent inference 차단)"
      fi
    done
    # 출처 토큰 금지어 검출 — 발화 추출/AI 추정/자동 결정/기본값 적용 등은 금지
    if printf '%s\n' "$PCA_BLOCK" | grep -qiE "발화 추출|발화 기반|AI 추정|자동 결정|기본값 적용|self-inferred|silently inferred|inferred from utterance"; then
      err "Phase 0 Pre-collected Answers 에 금지 출처 토큰 발견 (발화 추출/AI 추정/자동 결정/기본값 적용 등) — 모든 항목은 AskUserQuestion#N 또는 \$ARGUMENTS prefill (경로 한정) 출처만 허용. .claude/rules/question-discipline.md \"Free-form Utterance Inference Discipline\" 참조"
    fi
    # 각 필수 항목 행에 출처 토큰 (AskUserQuestion#1|2|3 또는 \$ARGUMENTS prefill) 이 있는지 확인
    for item in A1 A2 A3 A5 A6 A7 A8 A9 A10; do
      LINE="$(printf '%s\n' "$PCA_BLOCK" | grep -E "\| ${item}[[:space:]]" || true)"
      if [[ -n "$LINE" ]] && ! printf '%s\n' "$LINE" | grep -qE "AskUserQuestion#[1-3]|\\\$ARGUMENTS prefill"; then
        err "Phase 0 Pre-collected Answers 의 ${item} 행에 유효한 출처 토큰 없음 (AskUserQuestion#1|2|3 필요)"
      fi
    done
    # 고정 카탈로그 항목 (A2/A3/A5/A7/A8/A9/A10) 의 옵션 라벨 원문 우회 차단 — R-3 + R-4a
    # 자유 텍스트 응답이 정상인 항목 (A1, A6 멀티선택+Other 가능, 경로) 만 라벨 N/A 허용
    # R-4a: N/A 변형 우회 차단 — "미정"/"없음"/"na"/"none"/"-"/"—"/em-dash/빈 셀(`| |`) 모두 매칭
    for item in A2 A3 A5 A7 A8 A9 A10; do
      LINE="$(printf '%s\n' "$PCA_BLOCK" | grep -E "\| ${item}[[:space:]]" || true)"
      [[ -z "$LINE" ]] && continue
      # 라벨 셀의 N/A 변형 검출
      if printf '%s\n' "$LINE" | grep -qiE "\\| ?(N/A|NA|n/a|none|null|미정|미상|없음|모름|불명|자유 텍스트|label N/A|TBD|todo|TODO|undecided) ?\\|"; then
        err "Phase 0 Pre-collected Answers 의 ${item} 행에 옵션 라벨 원문 placeholder 값 (N/A 변형 또는 미정/없음 등) — 고정 카탈로그 항목은 카탈로그 라벨 정확 인용 필수 (출처 토큰 위조 의심). 자유 텍스트 응답 허용은 A1·A6·경로 한정"
      fi
      # 빈 셀 검출 — 마지막 열이 비어있거나 공백만 (예: `| A2 유형 | 값 | AskUserQuestion#1 | |`)
      if printf '%s\n' "$LINE" | grep -qE "\\|[[:space:]]*\\|[[:space:]]*$"; then
        err "Phase 0 Pre-collected Answers 의 ${item} 행 마지막 열 (옵션 라벨 원문) 이 빈 셀 — 고정 카탈로그 항목은 카탈로그 라벨 정확 인용 필수"
      fi
      # em-dash / hyphen 만 적힌 셀 검출
      if printf '%s\n' "$LINE" | grep -qE "\\|[[:space:]]*[—\\-][[:space:]]*\\|"; then
        err "Phase 0 Pre-collected Answers 의 ${item} 행에 라벨 셀이 dash 만 (—/-) — placeholder 우회 의심. 카탈로그 라벨 정확 인용 필수"
      fi
    done
  fi
fi

# --- Escalations 섹션 비어있음 경고 (fail 올리지 않음) ---
# "없음" 미기록 시 오케스트레이터가 Escalation 없음으로 오판할 수 있음
ESCAL_BLOCK="$(awk '/^## Escalations$/{p=1;next} /^## /{p=0} p{print}' "$FILE")"
ESCAL_COMPACT="$(printf '%s' "$ESCAL_BLOCK" | tr -d '[:space:]')"
if [[ -z "$ESCAL_COMPACT" ]]; then
  warn "Escalations 섹션이 비어있습니다 (\"없음\" 명시 권장) — ${BASE}"
fi

# --- Escalation 카운트 (Phase Gate [ASK] 차단의 입력) ---
# [ASK] / [BLOCKING] 항목을 세고, 같은 라인 또는 직후 라인에 `→ [RESOLVED]` 마커가 있으면 제외.
# stdout 에 ESCALATION_COUNT 라인을 출력하여 orchestrator 가 파싱.
ASK_TOTAL=0
BLOCK_TOTAL=0
ASK_RESOLVED=0
BLOCK_RESOLVED=0

if [[ -n "$ESCAL_BLOCK" ]]; then
  # 전체 매치 카운트
  ASK_TOTAL="$(printf '%s\n' "$ESCAL_BLOCK" | grep -cE '\[ASK\]' || true)"
  BLOCK_TOTAL="$(printf '%s\n' "$ESCAL_BLOCK" | grep -cE '\[BLOCKING\]' || true)"
  # 해결된 항목 카운트: [ASK] 또는 [BLOCKING] 이 포함된 라인의 다음 6 라인 내에 `→ [RESOLVED]` 등장
  # awk 로 ASK / BLOCKING 발견 → 다음 6 라인을 확인 → RESOLVED 있으면 카운트
  ASK_RESOLVED="$(printf '%s\n' "$ESCAL_BLOCK" | awk '
    /\[ASK\]/ { window=6; matched=0; next_lines[0]=$0; idx=1; resolved=0; }
    window > 0 {
      if (/→ ?\[RESOLVED\]/ || /\[RESOLVED\]/) { resolved=1; }
      window--;
      if (window == 0 && resolved) { count++; resolved=0; }
    }
    END { print count+0 }
  ' || echo 0)"
  BLOCK_RESOLVED="$(printf '%s\n' "$ESCAL_BLOCK" | awk '
    /\[BLOCKING\]/ { window=6; matched=0; next_lines[0]=$0; idx=1; resolved=0; }
    window > 0 {
      if (/→ ?\[RESOLVED\]/ || /\[RESOLVED\]/) { resolved=1; }
      window--;
      if (window == 0 && resolved) { count++; resolved=0; }
    }
    END { print count+0 }
  ' || echo 0)"
fi

ASK_OPEN=$(( ASK_TOTAL - ASK_RESOLVED ))
BLOCK_OPEN=$(( BLOCK_TOTAL - BLOCK_RESOLVED ))
[[ $ASK_OPEN -lt 0 ]] && ASK_OPEN=0
[[ $BLOCK_OPEN -lt 0 ]] && BLOCK_OPEN=0

# orchestrator 가 파싱하는 stdout 라인 (단일 권위 형식 — 변경 시 orchestrator-protocol.md 동반 갱신)
printf 'ESCALATION_COUNT: ASK=%d, BLOCKING=%d, RESOLVED_ASK=%d, RESOLVED_BLOCKING=%d\n' \
  "$ASK_OPEN" "$BLOCK_OPEN" "$ASK_RESOLVED" "$BLOCK_RESOLVED"

# --- 결과 ---
# exit code 규약 (변경 시 orchestrator-protocol.md "Phase Gate 검증 절차" 동반 갱신):
#   0: 구조 통과. Escalation 카운트는 stdout 으로 별도 노출 — orchestrator 가 [ASK]/[BLOCKING] 미해결 시 자체 차단
#   1: 구조 실패 (frontmatter 누락 / 필수 섹션 누락)
if [[ $fail -eq 0 ]]; then
  ok "Phase 산출물 구조 검증 통과: ${BASE} (미해결: ASK=${ASK_OPEN}, BLOCKING=${BLOCK_OPEN})"
  exit 0
fi
exit 1
