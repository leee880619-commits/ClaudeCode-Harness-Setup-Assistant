#!/bin/bash
# validate-settings.sh
# 대상 디렉터리의 .claude/settings.json에 대해 권한/비밀값 정적 검증을 수행한다.
# 사용: bash scripts/validate-settings.sh [PROJECT_ROOT]
#   PROJECT_ROOT 미지정 시 현재 디렉터리.

set -euo pipefail

ROOT="${1:-$(pwd)}"
SETTINGS="${ROOT}/.claude/settings.json"
LOCAL="${ROOT}/.claude/settings.local.json"

fail=0
note() { printf '  • %s\n' "$*" >&2; }
err()  { printf '❌ %s\n' "$*" >&2; fail=1; }
ok()   { printf '✓  %s\n' "$*"; }

if [[ ! -f "$SETTINGS" ]]; then
  echo "ℹ️  $SETTINGS 없음 — 건너뜀 (신규 프로젝트일 수 있음)"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq가 필요합니다. 설치: apt install jq / brew install jq" >&2
  exit 2
fi

if ! jq empty "$SETTINGS" 2>/dev/null; then
  err "$SETTINGS JSON 파싱 실패"
  exit 1
fi

# --- 위험한 allow 패턴 ---
# 완전 허용(Bash(*))과 sudo/rm/force push의 wildcard 허용만 차단한다.
DANGEROUS_ALLOW=(
  'Bash(*)'
  'Bash(sudo *)'
  'Bash(rm -rf *)'
  'Bash(git push --force *)'
  'Bash(git push --force)'
)
for pat in "${DANGEROUS_ALLOW[@]}"; do
  if jq -e --arg p "$pat" '.permissions.allow // [] | index($p)' "$SETTINGS" >/dev/null 2>&1; then
    err "permissions.allow에 위험 패턴 발견: $pat"
  fi
done

# --- 필수 deny 항목 ---
REQUIRED_DENY=(
  'Bash(rm -rf /)'
  'Bash(sudo rm *)'
  'Bash(git push --force *)'
)
for pat in "${REQUIRED_DENY[@]}"; do
  if ! jq -e --arg p "$pat" '.permissions.deny // [] | index($p)' "$SETTINGS" >/dev/null 2>&1; then
    note "권장 deny 누락: $pat  (권장이지 필수 실패는 아님)"
  fi
done

# --- Secret 패턴 (settings.json 본문 전체 grep) ---
SECRET_PATTERNS='sk-[A-Za-z0-9_-]{8,}|ghp_[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{10,}|xoxb-[A-Za-z0-9-]{20,}|Bearer [A-Za-z0-9._-]{10,}'
if grep -Eq "$SECRET_PATTERNS" "$SETTINGS"; then
  err "$SETTINGS 에 비밀값 형태의 문자열이 포함됨. settings.local.json으로 이동하세요."
fi

if [[ -f "$LOCAL" ]]; then
  # local 파일이 있으면 .gitignore 확인
  if [[ -f "${ROOT}/.gitignore" ]] && ! grep -Eq '(^|/)\.claude/settings\.local\.json|settings\.local\.json' "${ROOT}/.gitignore"; then
    err "settings.local.json이 존재하지만 .gitignore에 없음"
  fi
fi

if [[ $fail -eq 0 ]]; then
  ok "$SETTINGS 기본 보안 검증 통과"
  exit 0
fi
exit 1
