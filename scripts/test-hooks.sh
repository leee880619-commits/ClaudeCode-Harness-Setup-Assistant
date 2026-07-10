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

echo "== 9. 신원 계약: 훅이 위조 불가능한 agent_type 을 쓰는가 =="
# 배경: 훅은 "허가증을 발급하는 주체" 를 신뢰할 수 없다.
#   - ORCHESTRATOR_DIRECT_TOKEN (환경변수): 메인 세션이 스스로 발급 -> 인증이 아님.
#     게다가 임의 환경변수는 훅 프로세스에 도달조차 하지 않아 분기 전체가 죽어 있었다.
#   - .claude/.current-role (파일): 아무도 쓰지 않아 항상 unknown -> fail-open.
# Claude Code 는 서브에이전트 호출에 한해 stdin JSON 에 agent_type 을 넣는다.
# 메인 세션 호출에는 키 자체가 없다. 모델은 이 값을 위조할 수 없다.

# 과거 기록(CHANGELOG, 위키 이력)과 이 테스트 파일 자신은 제외하고 레포 전체를 검색한다.
grep_repo() {
  grep -rlF "$1" "$REPO_ROOT" \
    --exclude-dir=.git --exclude-dir=docs \
    --exclude=CHANGELOG.md --exclude=test-hooks.sh 2>/dev/null || true
}

absent() {  # $1=설명  $2=패턴  $3=왜 없어야 하는가
  local hits; hits="$(grep_repo "$2")"
  if [[ -z "$hits" ]]; then ok "$1"; else bad "$1" "$3 -- 잔존: $(printf '%s' "$hits" | tr '\n' ' ')"; fi
}

present() {  # $1=설명  $2=파일  $3=패턴
  if grep -qF "$3" "${REPO_ROOT}/$2" 2>/dev/null; then ok "$1"; else bad "$1" "$2 에 '$3' 없음"; fi
}

# 아래 absent 검사는 '언급' 이 아니라 '코드 패턴' 을 금지한다.
# 문서가 "이렇게 하지 마라" 며 이름을 거론하는 것은 오히려 회귀 방지에 필요하다.
# _TOKEN 접미사만 막으면 맨몸 ORCHESTRATOR_DIRECT=1 플래그가 빠져나간다.
# v1.0.5 시점에 실제로 pipeline-design / design-review / red-team-advisor 세 곳에 남아 있었고,
# Advisor 는 이제 없는 메커니즘을 '명시하라' 고 요구하고 있었다. 이름 전체를 금지한다.
absent "ORCHESTRATOR_DIRECT 계열 제거됨 (토큰·플래그 전부)" \
  "ORCHESTRATOR_DIRECT" \
  "환경변수는 훅에 도달하지 않고, 메인 세션이 자가 발급하므로 인증 수단이 될 수 없다"

absent "복잡도 게이트 락 파일 제거됨" \
  "complexity-gate.lock" \
  "메인 세션이 스스로 쓰는 파일은 자가 승인일 뿐 인증이 아니다"

absent "역할을 파일에서 읽지 않음" \
  "cat .claude/.current-role" \
  "아무도 쓰지 않는 파일이라 항상 unknown 으로 읽혀 가드가 fail-open 된다"

absent "ownership-guard 템플릿이 fail-open 하지 않음" \
  "allowing write" \
  "매핑 없는 역할을 통과시키면 가드가 형해화된다. 차단(exit 2)해야 한다"

absent "'유일 방어선' 거짓 주장 제거됨" \
  "유일 방어선" \
  "훅 matcher 는 Write|Edit 뿐이라 Bash 우회를 못 막는다. 진짜 벽은 sandbox.filesystem 이다"

present "06-hooks-system.md 가 agent_type 을 문서화" \
  "knowledge/06-hooks-system.md" "agent_type"
present "hooks-mcp-setup.md 가 agent_type 기반 예외를 기술" \
  "playbooks/hooks-mcp-setup.md" "agent_type"
present "ownership-guard 템플릿이 미매핑 에이전트를 차단" \
  "knowledge/06-hooks-system.md" "write denied"

echo "== 10. S 등급 정의가 자기모순이 아닌가 =="
# 표: "파일 <=3개 변경".  구 Section 3: "영구 산출이 없는 작업 에만 허용".
# 둘 다 참일 수 없다. 표를 정본으로 두고 Section 3 을 정밀화했다.
absent "S 등급 모순 문장 제거됨" \
  "영구 산출이 없는 작업" \
  "표의 '파일 <=3개 변경' 과 정면 충돌한다"

# ops-audit F-4 는 라우팅 프로토콜에서 우회 가드 문구를 grep 한다. 깨뜨리면 안 된다.
for f in playbooks/workflow-design.md playbooks/fresh-setup.md; do
  present "ops-audit F-4 유지 ($f)" "$f" "mandatory_review"
done

echo "== 11. 문서에 실린 agent_type 추출 코드를 실제로 실행해 본다 =="
# knowledge/06-hooks-system.md 가 깨진 훅 코드를 가르친 것이 이번 사고의 뿌리였다.
# 그래서 문서의 코드 블록을 파일로 뽑아 실제 페이로드로 돌린다. grep 이 아니라 실행이다.
SNIP="$TMP/agent_type_snippet.sh"
awk '/stdin JSON에서 agent_type 뽑기/{f=1}
     f && /^```bash$/ {c=1; next}
     c && /^```$/     {exit}
     c                {print}' "${REPO_ROOT}/knowledge/06-hooks-system.md" > "$SNIP"

if [[ ! -s "$SNIP" ]]; then
  bad "문서에서 agent_type 스니펫 추출" "코드 블록을 찾지 못했다"
else
  ok "문서에서 agent_type 스니펫 추출 ($(wc -l < "$SNIP") 줄)"

  probe_role() { INPUT="$1"; ROLE=""; . "$SNIP"; printf '%s' "$ROLE"; }

  # 실측 페이로드 (이 세션에서 라이브 훅으로 직접 캡처):
  #   메인 세션에는 agent_type 키 자체가 없고, 서브에이전트에만 들어온다.
  main_json='{"hook_event_name":"PostToolUse","tool_name":"Write","cwd":"C:\\proj","tool_input":{"file_path":"a.txt"}}'
  sub_json='{"agent_id":"a29a93d048bc9fff5","agent_type":"general-purpose","tool_name":"Write","tool_input":{"file_path":"a.txt"}}'

  got="$(probe_role "$main_json")"
  [[ -z "$got" ]] && ok "메인 세션 -> 역할 없음 (가드 통과)" \
                  || bad "메인 세션 오판" "빈 문자열이어야 하는데 '$got'"

  got="$(probe_role "$sub_json")"
  [[ "$got" == "general-purpose" ]] && ok "서브에이전트 -> 'general-purpose' 로 식별" \
                                    || bad "서브에이전트 오판" "expected general-purpose, got '$got'"
fi

echo
printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
