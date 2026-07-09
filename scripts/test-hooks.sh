#!/usr/bin/env bash
# test-hooks.sh
# 훅 계약(contract) 회귀 테스트.
#
# 배경: v1.0.4 까지 훅은 존재하지 않는 $CLAUDE_TOOL_INPUT 환경변수를 읽어
# 항상 즉시 exit 0 했다 (완전 무동작). 실제 Claude Code 는 훅 입력을
# stdin JSON 으로 전달한다:
#   {"tool_name":"Write","tool_input":{"file_path":"C:\\Users\\..."}}
#
# 이 테스트는 그 계약을 고정한다. 훅이 다시 무동작으로 퇴행하면 실패한다.
#
# 실행: bash scripts/test-hooks.sh

set -uo pipefail

REPO_ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
HOOK="${REPO_ROOT}/.claude/hooks/syntax-check.sh"
HOOKS_JSON="${REPO_ROOT}/.claude/hooks/hooks.json"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n     %s\n' "$1" "$2"; }

# stdin JSON 을 만들어 훅에 먹이고 종료 코드를 돌려준다.
run_hook() {
  printf '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" \
    | bash "$HOOK" >/dev/null 2>&1
  printf '%s' "$?"
}

expect_exit() {
  local desc="$1" path="$2" want="$3" got
  got="$(run_hook "$path")"
  if [[ "$got" == "$want" ]]; then ok "$desc"; else bad "$desc" "expected exit $want, got $got"; fi
}

echo "== 1. 입력 계약: stdin JSON 에서 file_path 를 읽는가 =="

# .claude/ 아래 깨진 JSON -> 반드시 잡아야 한다 (exit 2)
mkdir -p "$TMP/.claude"
printf '{ "broken": ' > "$TMP/.claude/broken.json"
expect_exit "깨진 JSON 을 exit 2 로 신고" "$TMP/.claude/broken.json" 2

# .claude/ 아래 정상 JSON -> 통과
printf '{"ok": true}' > "$TMP/.claude/good.json"
expect_exit "정상 JSON 통과" "$TMP/.claude/good.json" 0

echo "== 2. Windows 경로(이스케이프된 백슬래시) 처리 =="
WINPATH="$(printf '%s' "$TMP/.claude/broken.json" | sed 's#^/\([a-z]\)/#\U\1:/#')"
WINPATH_ESC="${WINPATH//\//\\\\}"
got="$(printf '{"tool_input":{"file_path":"%s"}}' "$WINPATH_ESC" | bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?")"
if [[ "$got" == "2" ]]; then ok "C:\\\\Users\\\\... 형태 경로도 파싱"; else bad "Windows 경로 파싱" "expected 2, got $got"; fi

echo "== 3. 범위 축소: 하네스와 무관한 파일은 즉시 통과 =="
printf '{ "broken": ' > "$TMP/unrelated.json"
expect_exit "하네스 밖 깨진 JSON 은 건드리지 않음" "$TMP/unrelated.json" 0

echo "== 4. settings.json 보안 검사 =="
printf '{"permissions":{"allow":["Bash(*)"],"deny":["Bash(rm -rf /)"]}}' > "$TMP/.claude/settings.json"
expect_exit "allow 에 Bash(*) 있으면 exit 2" "$TMP/.claude/settings.json" 2
printf '{"permissions":{"allow":["Bash(ls)"],"deny":["Bash(rm -rf /)"]}}' > "$TMP/.claude/settings.json"
expect_exit "안전한 settings.json 통과" "$TMP/.claude/settings.json" 0

echo "== 5. Markdown frontmatter =="
printf -- '---\nphase: 3\n' > "$TMP/.claude/unclosed.md"
expect_exit "닫히지 않은 frontmatter 는 exit 2" "$TMP/.claude/unclosed.md" 2
printf -- '---\nphase: 3\n---\n\n# ok\n' > "$TMP/.claude/closed.md"
expect_exit "정상 frontmatter 통과" "$TMP/.claude/closed.md" 0

echo "== 6. 방어적 기본값 =="
got="$(printf '' | bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?")"
[[ "$got" == "0" ]] && ok "빈 stdin 은 통과" || bad "빈 stdin" "expected 0, got $got"
got="$(printf '{"tool_input":{}}' | bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?")"
[[ "$got" == "0" ]] && ok "file_path 없으면 통과" || bad "file_path 없음" "expected 0, got $got"
expect_exit "존재하지 않는 파일은 통과" "$TMP/.claude/nope.json" 0

echo "== 7. hooks.json 비용 규약 =="
if grep -q '"timeout"' "$HOOKS_JSON"; then ok "hooks.json 에 timeout 선언"; else bad "timeout 누락" "훅이 기본 600초 동안 살아남아 프로세스가 쌓인다"; fi
if ! grep -q 'SessionStart' "$HOOKS_JSON"; then ok "SessionStart 훅 없음"; else bad "SessionStart 잔존" "세션마다 curl 프로세스가 뜬다"; fi
if ! grep -q 'ownership-guard' "$HOOKS_JSON"; then ok "ownership-guard 등록 해제"; else bad "ownership-guard 잔존" "무동작 훅이 파일마다 프로세스를 띄운다"; fi
if [[ ! -f "${REPO_ROOT}/.claude/hooks/ownership-guard.sh" ]]; then ok "ownership-guard.sh 삭제됨"; else bad "ownership-guard.sh 잔존" "삭제 대상"; fi

echo "== 8. 훅 자신이 외부 인터프리터를 상시 스폰하지 않는가 =="
if grep -qE '^[^#]*python3? ' "$HOOK" && ! grep -q 'command -v' "$HOOK"; then
  bad "무조건 python 스폰" "python 가용성 확인 없이 스폰하면 Windows 스토어 스텁에서 멈출 수 있다"
else
  ok "python 스폰 전 가용성 확인"
fi

echo
printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
