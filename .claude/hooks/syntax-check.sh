#!/bin/bash
# Syntax Check Hook
# Event: PostToolUse (Write, Edit)
#
# 입력 계약 (Claude Code 공식):
#   훅 입력은 stdin 으로 오는 JSON 이다. 환경변수가 아니다.
#   {"tool_name":"Write","tool_input":{"file_path":"C:\\Users\\..."}}
#   v1.0.4 까지 이 스크립트는 존재하지 않는 $CLAUDE_TOOL_INPUT 을 읽어
#   항상 즉시 exit 0 했다 (완전 무동작). scripts/test-hooks.sh 가 이 계약을 고정한다.
#
# 종료 코드 계약 (Claude Code 공식):
#   0 = 통과, 2 = 문제 발견 (stderr 가 Claude 에게 전달됨), 그 외 = 비차단 오류.
#   exit 1 은 차단하지 않는다.
#
# 비용 규약:
#   이 훅은 모든 Write/Edit 마다 프로세스 1개를 띄운다. 하네스와 무관한 파일이면
#   아무것도 하지 않고 즉시 빠져나간다. hooks.json 의 timeout 이 상한을 강제한다.

set -uo pipefail

INPUT="$(cat 2>/dev/null)" || INPUT=""
[[ -z "$INPUT" ]] && exit 0

# --- stdin JSON 에서 tool_input.file_path 추출 (인터프리터 스폰 없음) ---
REST="${INPUT#*\"file_path\":\"}"
[[ "$REST" == "$INPUT" ]] && exit 0
RAW="${REST%%\"*}"
[[ -z "$RAW" ]] && exit 0

# JSON 이스케이프 해제 후 슬래시로 정규화 (C:\\Users\\x -> C:/Users/x)
TARGET_FILE="${RAW//\\\\//}"
TARGET_FILE="${TARGET_FILE//\\//}"

# --- 범위 축소: 하네스가 만들거나 관리하는 파일만 검사한다 ---
IN_SCOPE=0
case "$TARGET_FILE" in
  */.claude/*|.claude/*) IN_SCOPE=1 ;;
  */CLAUDE.md|CLAUDE.md) IN_SCOPE=1 ;;
esac
if [[ "$TARGET_FILE" =~ /docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$ ]]; then
  IN_SCOPE=1
fi
[[ "$IN_SCOPE" -eq 0 ]] && exit 0

[[ -f "$TARGET_FILE" ]] || exit 0

# --- 파일명 특수문자 주입 방어 ---
TARGET_BASE="${TARGET_FILE##*/}"
case "$TARGET_BASE" in
  *\;*|*\|*|*\&*|*\$*|*\`*|*\!*|*\{*|*\}*|*\(*|*\)*|*\'*)
    echo "[syntax-check] 파일명 거부: 특수문자가 포함된 파일명은 허용되지 않습니다" >&2
    exit 2
    ;;
esac

# --- JSON 파서 선택: 없으면 검증을 건너뛴다 (스토어 스텁 정지 방지) ---
# jq 를 우선한다. Windows 에서 python3 는 Microsoft Store 스텁일 수 있어
# 실행 시 정지할 위험이 있다 (hooks.json 의 timeout 이 최종 상한).
PY_TOOL=""
for py in python3 python; do
  if command -v "$py" >/dev/null 2>&1; then PY_TOOL="$py"; break; fi
done

JSON_TOOL=""
if command -v jq >/dev/null 2>&1; then
  JSON_TOOL="jq"
elif [[ -n "$PY_TOOL" ]]; then
  JSON_TOOL="$PY_TOOL"
fi

json_is_valid() {
  case "$JSON_TOOL" in
    "")   return 0 ;;   # 검증 도구 없음 -> 통과로 간주
    jq)   jq -e . "$1" >/dev/null 2>&1 ;;
    *)    "$JSON_TOOL" -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1 ;;
  esac
}

# settings.json 위험 패턴 검사. 파서 종류와 무관하게 항상 수행한다.
# 출력: "OK" 또는 "BLOCK:<사유>"
settings_security_check() {
  if [[ "$JSON_TOOL" == "jq" ]]; then
    jq -r '
      (.permissions.allow // []) as $a
      | .permissions.deny as $d
      | (["Bash(*)","Bash(sudo *)","Bash(rm -rf *)","Bash(git push --force *)"]
         | map(select(. as $p | $a | index($p))) | first) as $hit
      | if $hit then "BLOCK:allow 에 위험 패턴 발견: " + $hit
        elif $d == null then "BLOCK:permissions.deny 가 없습니다"
        elif ($d | length) == 0 then "BLOCK:deny 목록이 비어 있습니다"
        else "OK" end
    ' "$1" 2>/dev/null
  elif [[ -n "$PY_TOOL" ]]; then
    "$PY_TOOL" -c '
import json, sys
d = json.load(open(sys.argv[1]))
perms = d.get("permissions", {})
allow = perms.get("allow", [])
deny = perms.get("deny", None)
for p in ["Bash(*)", "Bash(sudo *)", "Bash(rm -rf *)", "Bash(git push --force *)"]:
    if p in allow:
        print("BLOCK:allow 에 위험 패턴 발견: " + p)
        sys.exit(0)
if deny is None:
    print("BLOCK:permissions.deny 가 없습니다")
elif len(deny) == 0:
    print("BLOCK:deny 목록이 비어 있습니다")
else:
    print("OK")
' "$1" 2>/dev/null
  else
    printf 'OK'
  fi
}

# --- JSON 파일 검증 ---
if [[ "$TARGET_FILE" == *.json ]]; then
  if ! json_is_valid "$TARGET_FILE"; then
    echo "[syntax-check] JSON 구문 오류: $TARGET_FILE" >&2
    exit 2
  fi

  # settings.json 에만 보안 검사 (settings.local.json 제외)
  if [[ "$TARGET_BASE" == "settings.json" ]]; then
    SECURITY_CHECK="$(settings_security_check "$TARGET_FILE")" || SECURITY_CHECK="OK"

    if [[ "$SECURITY_CHECK" == BLOCK:* ]]; then
      echo "[syntax-check] 보안 경고: ${SECURITY_CHECK#BLOCK:}" >&2
      echo "               파일: $TARGET_FILE" >&2
      exit 2
    fi
  fi
fi

# --- YAML frontmatter 검증 (Markdown) ---
if [[ "$TARGET_FILE" == *.md ]]; then
  FIRST_LINE="$(head -1 "$TARGET_FILE" 2>/dev/null)"
  if [[ "$FIRST_LINE" == "---" ]]; then
    CLOSE_COUNT="$(tail -n +2 "$TARGET_FILE" | grep -c '^---$' 2>/dev/null)" || CLOSE_COUNT=0
    if [[ "$CLOSE_COUNT" -eq 0 ]]; then
      echo "[syntax-check] YAML frontmatter 가 닫히지 않았습니다: $TARGET_FILE" >&2
      exit 2
    fi
  fi

  # Phase 산출물 패턴: 구조 경고만 낸다 (강제 검증은 오케스트레이터가 Phase Gate 에서 수행)
  if [[ "$TARGET_FILE" =~ /docs/[^/]+/[0-9]{2}[a-z]?-[a-z-]+\.md$ ]]; then
    VALIDATOR="${CLAUDE_PLUGIN_ROOT:-}/scripts/validate-phase-artifact.sh"
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -f "$VALIDATOR" ]]; then
      bash "$VALIDATOR" "$TARGET_FILE" >&2 || \
        echo "[syntax-check] Phase 산출물 구조 경고 - 오케스트레이터가 Phase Gate 에서 재검증 필요: $TARGET_FILE" >&2
    fi
  fi
fi

exit 0
