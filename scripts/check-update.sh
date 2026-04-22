#!/usr/bin/env bash
# check-update.sh
# SessionStart 훅: 매 세션 시작 시 현재 설치 버전과 최신 릴리즈를 비교하여
# 업데이트가 있으면 배너를 출력한다.
#
# 설계 원칙:
# - 현재 설치 버전(CURRENT)은 매 세션마다 plugin.json 에서 새로 읽는다 (로컬 업데이트 즉시 반영).
# - 최신 버전(LATEST)은 하루 1회만 GitHub API 로 조회 후 캐시 (rate limit 방지).
# - 캐시는 "최신 버전 문자열"만 저장한다 (배너 문자열이 아님 — CURRENT 변화 즉시 반영).
# - 매 세션마다 CURRENT vs LATEST 를 새로 비교하여 배너를 생성.
# Event: SessionStart
#
# 보안:
# - 모든 외부 입력(경로, API 응답)을 python argv 로 전달하여 쉘 인젝션 차단
# - curl 응답 64KB 상한, 타임아웃 5초
# - 모든 실패 경로는 exit 0 (사용자 흐름 비방해)

set -uo pipefail

CACHE_FILE="/tmp/harness-architect-update-check-$(id -u 2>/dev/null || echo 0)"
PLUGIN_JSON="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
GITHUB_REPO="leee880619-commits/ClaudeCode-Harness-Setup-Assistant"

[[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]] && exit 0
[[ ! -f "$PLUGIN_JSON" ]] && exit 0

# 현재 설치 버전 — 매 세션 새로 읽기 (핵심: 로컬 /plugin update 즉시 반영)
CURRENT=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(json.load(f).get("version", ""))
except Exception:
    sys.exit(1)
' "$PLUGIN_JSON" 2>/dev/null) || exit 0
[[ -z "$CURRENT" ]] && exit 0

# 캐시 로드 — 24h 이내면 API 스킵
LATEST=""
SHOULD_FETCH=1
if [[ -f "$CACHE_FILE" ]]; then
  LAST_CHECK=$(stat -c %Y "$CACHE_FILE" 2>/dev/null \
    || stat -f %m "$CACHE_FILE" 2>/dev/null \
    || echo 0)
  NOW=$(date +%s)
  if (( NOW - LAST_CHECK < 86400 )); then
    LATEST=$(head -n 1 "$CACHE_FILE" 2>/dev/null | tr -d '[:space:]')
    SHOULD_FETCH=0
  fi
fi

# 캐시 만료/없음 — API 조회
if (( SHOULD_FETCH )); then
  RESPONSE=$(curl -sf --max-time 5 --max-filesize 65536 \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null) \
    || RESPONSE=""

  NEW_LATEST=""
  if [[ -n "$RESPONSE" ]]; then
    NEW_LATEST=$(python3 -c '
import json, sys, re
try:
    tag = json.loads(sys.argv[1]).get("tag_name", "")
    tag = str(tag).lstrip("v").strip()
    if re.match(r"^\d+\.\d+\.\d+", tag):
        print(tag)
except Exception:
    sys.exit(0)
' "$RESPONSE" 2>/dev/null)
  fi

  if [[ -n "$NEW_LATEST" ]]; then
    # API 성공 — 캐시 갱신
    printf '%s' "$NEW_LATEST" > "$CACHE_FILE" 2>/dev/null || true
    LATEST="$NEW_LATEST"
  else
    # API 실패 — 기존 캐시 내용은 유지하고 타임스탬프만 갱신 (같은 날 반복 API 호출 방지)
    touch "$CACHE_FILE" 2>/dev/null || true
    if [[ -s "$CACHE_FILE" ]]; then
      LATEST=$(head -n 1 "$CACHE_FILE" 2>/dev/null | tr -d '[:space:]')
    fi
  fi
fi

[[ -z "$LATEST" ]] && exit 0

# 매 세션마다 CURRENT vs LATEST 비교 — 배너 생성
python3 -c '
import sys, re

current = sys.argv[1]
latest = sys.argv[2]

pattern = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
m_cur = pattern.match(current)
m_lat = pattern.match(latest)
if not (m_cur and m_lat):
    sys.exit(0)

cur_tuple = tuple(int(x) for x in m_cur.groups())
lat_tuple = tuple(int(x) for x in m_lat.groups())

if lat_tuple > cur_tuple:
    print(f"⬆  harness-architect v{latest} 출시됨 (현재: v{current}) — `/plugin update harness-architect` 로 업데이트하세요.")
' "$CURRENT" "$LATEST" 2>/dev/null || true

exit 0
