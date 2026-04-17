#!/bin/bash
# Syntax Check Hook
# 생성/편집된 파일의 구문을 검증한다.
# Event: PostToolUse (Write, Edit)
# Input: $CLAUDE_TOOL_INPUT (JSON) — file_path 필드에서 대상 경로 추출

set -euo pipefail

# --- $CLAUDE_TOOL_INPUT에서 파일 경로 추출 ---
if [[ -z "${CLAUDE_TOOL_INPUT:-}" ]]; then
  exit 0
fi

TARGET_FILE="$(echo "$CLAUDE_TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null)" || true

if [[ -z "$TARGET_FILE" ]]; then
  exit 0
fi

if [[ ! -f "$TARGET_FILE" ]]; then
  exit 0
fi

# --- 파일명 특수문자 주입 방어 ---
TARGET_BASE="$(basename "$TARGET_FILE")"
case "$TARGET_BASE" in
  *\;*|*\|*|*\&*|*\$*|*\`*|*\\*|*\!*|*\{*|*\}*|*\(*|*\)*|*\'*)
    echo "❌ 파일명 거부: 특수문자가 포함된 파일명은 허용되지 않습니다" >&2
    exit 1
    ;;
esac

# --- JSON 파일 검증 ---
if [[ "$TARGET_FILE" == *.json ]]; then
  if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$TARGET_FILE" 2>/dev/null; then
    echo "❌ JSON 구문 오류: $TARGET_FILE" >&2
    exit 1
  fi

  # settings.json에만 보안 검사 (settings.local.json 제외)
  if [[ "$TARGET_BASE" == "settings.json" ]]; then
    SECURITY_CHECK=$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
perms = d.get('permissions', {})
allow = perms.get('allow', [])
deny = perms.get('deny', None)

# 위험 패턴 검사
dangerous = ['Bash(*)', 'Bash(sudo *)', 'Bash(rm -rf *)', 'Bash(git push --force *)']
for p in dangerous:
    if p in allow:
        print(f'BLOCK:allow에 위험 패턴 발견: {p}')
        sys.exit(0)

# deny 목록 검사
if deny is None:
    print('BLOCK:permissions.deny가 없습니다')
elif len(deny) == 0:
    print('BLOCK:deny 목록이 비어 있습니다')
else:
    print('OK')
" "$TARGET_FILE" 2>/dev/null) || SECURITY_CHECK="OK"

    if [[ "$SECURITY_CHECK" == BLOCK:* ]]; then
      echo "⚠️  보안 경고: ${SECURITY_CHECK#BLOCK:}" >&2
      echo "   파일: $TARGET_FILE" >&2
      exit 1
    fi
  fi

  echo "✅ JSON 유효: $TARGET_FILE" >&2
fi

# --- YAML frontmatter 검증 (Markdown) ---
if [[ "$TARGET_FILE" == *.md ]]; then
  FIRST_LINE=$(head -1 "$TARGET_FILE" 2>/dev/null)
  if [[ "$FIRST_LINE" == "---" ]]; then
    CLOSE_COUNT=$(tail -n +2 "$TARGET_FILE" | grep -c "^---$" 2>/dev/null) || CLOSE_COUNT=0
    if [[ "$CLOSE_COUNT" -eq 0 ]]; then
      echo "❌ YAML frontmatter가 닫히지 않았습니다: $TARGET_FILE" >&2
      exit 1
    fi
  fi
fi

exit 0
