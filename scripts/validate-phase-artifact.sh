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
