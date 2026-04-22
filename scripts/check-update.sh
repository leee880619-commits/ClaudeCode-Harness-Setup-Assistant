#!/usr/bin/env bash
# check-update.sh
# SessionStart 훅: 하루 1회 GitHub Releases에서 최신 버전을 확인하고,
# 새 버전이 있으면 업데이트 배너를 stdout으로 출력한다.
# Event: SessionStart
#
# 보안 원칙:
# - 모든 외부 입력(경로, API 응답)은 python argv 로 전달하여 쉘 인젝션 차단
# - curl 응답 크기 64KB 상한 (--max-filesize) 으로 메모리 소모 차단
# - 실패 시 조용히 exit 0 (사용자 흐름 비방해)

set -uo pipefail

# 사용자별 캐시 경로 — /tmp 공유 환경에서 충돌 방지
CACHE_FILE="/tmp/harness-architect-update-check-$(id -u 2>/dev/null || echo 0)"
PLUGIN_JSON="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
GITHUB_REPO="leee880619-commits/ClaudeCode-Harness-Setup-Assistant"

# CLAUDE_PLUGIN_ROOT 미설정 또는 plugin.json 없으면 조용히 종료
[[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]] && exit 0
[[ ! -f "$PLUGIN_JSON" ]] && exit 0

# 하루 1회 제한 — 캐시 파일이 24시간 이내면 캐시 결과를 그대로 사용
if [[ -f "$CACHE_FILE" ]]; then
  last_check=$(stat -c %Y "$CACHE_FILE" 2>/dev/null \
    || stat -f %m "$CACHE_FILE" 2>/dev/null \
    || echo 0)
  now=$(date +%s)
  if (( now - last_check < 86400 )); then
    [[ -s "$CACHE_FILE" ]] && cat "$CACHE_FILE"
    exit 0
  fi
fi

# 현재 설치 버전 읽기 — 경로는 argv 로 안전 전달
CURRENT=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(json.load(f).get("version", ""))
except Exception:
    sys.exit(1)
' "$PLUGIN_JSON" 2>/dev/null) || exit 0
[[ -z "$CURRENT" ]] && exit 0

# GitHub Releases API 조회 (타임아웃 5초, 응답 크기 64KB 상한)
RESPONSE=$(curl -sf --max-time 5 --max-filesize 65536 \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null) \
  || { touch "$CACHE_FILE" 2>/dev/null; exit 0; }

[[ -z "$RESPONSE" ]] && { touch "$CACHE_FILE" 2>/dev/null; exit 0; }

# 버전 파싱 및 비교 — 응답도 argv 로 전달, python3 튜플 비교로 OS-무관 semver 처리
BANNER=$(python3 -c '
import json, sys, re

current = sys.argv[1]
response = sys.argv[2]

try:
    data = json.loads(response)
    latest = str(data.get("tag_name", "")).lstrip("v").strip()
except Exception:
    sys.exit(0)

if not latest:
    sys.exit(0)

# semver X.Y.Z 만 파싱 (prerelease/build 메타데이터는 무시)
pattern = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
m_cur = pattern.match(current)
m_lat = pattern.match(latest)
if not (m_cur and m_lat):
    sys.exit(0)

cur_tuple = tuple(int(x) for x in m_cur.groups())
lat_tuple = tuple(int(x) for x in m_lat.groups())

if lat_tuple > cur_tuple:
    print(f"⬆  harness-architect v{latest} 출시됨 (현재: v{current}) — `/plugin update harness-architect` 로 업데이트하세요.")
' "$CURRENT" "$RESPONSE" 2>/dev/null) || BANNER=""

if [[ -n "$BANNER" ]]; then
  printf '%s' "$BANNER" > "$CACHE_FILE" 2>/dev/null || true
  echo "$BANNER"
else
  # 최신 버전 사용 중 또는 파싱 실패 — 캐시 내용은 비우고 타임스탬프만 갱신
  > "$CACHE_FILE" 2>/dev/null || true
fi

exit 0
