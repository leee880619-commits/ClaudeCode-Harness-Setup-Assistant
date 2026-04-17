#!/bin/bash
# Ownership Guard Hook
# 파일 생성/편집 시 대상 파일이 허용 범위 내인지 검증한다.
# 허용 범위: (1) 이 프로젝트 루트 (2) $TARGET_PROJECT_ROOT (대상 프로젝트)
# Event: PreToolUse (Write, Edit)
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

# --- 프로젝트 루트 결정 ---
PROJECT_ROOT="$(pwd)"

# --- 경로 정규화 ---
if [[ "$TARGET_FILE" != /* ]]; then
  TARGET_FILE="${PROJECT_ROOT}/${TARGET_FILE}"
fi

TARGET_DIR="$(dirname "$TARGET_FILE")"
TARGET_BASE="$(basename "$TARGET_FILE")"

if [[ -d "$TARGET_DIR" ]]; then
  CANONICAL_TARGET="$(cd -P "$TARGET_DIR" 2>/dev/null && pwd)/${TARGET_BASE}"
else
  if command -v realpath >/dev/null 2>&1; then
    CANONICAL_TARGET="$(realpath -m -P "$TARGET_FILE" 2>/dev/null)" || CANONICAL_TARGET="$TARGET_FILE"
  else
    CANONICAL_TARGET="$TARGET_FILE"
  fi
fi

CANONICAL_ROOT="$(cd -P "$PROJECT_ROOT" 2>/dev/null && pwd)"

# --- 심볼릭 링크 탈출 검사 ---
if [[ -L "$TARGET_FILE" ]]; then
  RESOLVED="$(readlink -f "$TARGET_FILE" 2>/dev/null || realpath "$TARGET_FILE" 2>/dev/null)" || RESOLVED="$TARGET_FILE"
  CANONICAL_TARGET="$RESOLVED"
fi

# --- .. 잔존 검사 ---
if [[ "$CANONICAL_TARGET" == *".."* ]]; then
  echo "❌ 접근 거부: 경로에 '..'가 포함되어 있습니다" >&2
  exit 1
fi

# --- 허용 범위 검증 ---
ALLOWED=false
SCOPE_HIT=""

# 범위 1: 이 프로젝트 자체
if [[ "$CANONICAL_TARGET" == "$CANONICAL_ROOT"/* || "$CANONICAL_TARGET" == "$CANONICAL_ROOT" ]]; then
  ALLOWED=true
  SCOPE_HIT="plugin"
fi

# 범위 2: 대상 프로젝트 ($TARGET_PROJECT_ROOT)
if [[ -n "${TARGET_PROJECT_ROOT:-}" && -d "${TARGET_PROJECT_ROOT}" ]]; then
  CANONICAL_TPR="$(cd -P "$TARGET_PROJECT_ROOT" 2>/dev/null && pwd)"
  if [[ "$CANONICAL_TARGET" == "$CANONICAL_TPR"/* || "$CANONICAL_TARGET" == "$CANONICAL_TPR" ]]; then
    ALLOWED=true
    SCOPE_HIT="target"
  fi
fi

# --- Phase 0 설정 누락 감지: TPR 미설정 상태에서 docs/{req}/ 경로에 쓰려는 경우 ---
# "docs/[한글포함이름]/NN-*.md" 패턴은 명백히 대상 프로젝트 산출물이므로, 이 경로를 쓰는데
# TARGET_PROJECT_ROOT가 비어있으면 Phase 0이 설정을 누락했거나, 서브에이전트가
# 잘못된 경로로 쓰려는 상황이다. fail-closed 강화.
if [[ -z "${TARGET_PROJECT_ROOT:-}" ]] && [[ "$CANONICAL_TARGET" =~ /docs/[^/]+/[0-9]{2}[a-z]?-[^/]+\.md$ ]]; then
  echo "❌ 접근 거부: Phase 0 설정 누락 감지" >&2
  echo "   대상 경로: $CANONICAL_TARGET" >&2
  echo "   사유: docs/{요청명}/NN-*.md 패턴은 대상 프로젝트 산출물 경로. 그러나 TARGET_PROJECT_ROOT가 비어 있음." >&2
  echo "   조치: 오케스트레이터가 Phase 0에서 TARGET_PROJECT_ROOT 환경변수를 export 했는지 확인하세요." >&2
  exit 1
fi

if [[ "$ALLOWED" != "true" ]]; then
  echo "❌ 접근 거부: 파일은 허용 범위 내에 있어야 합니다" >&2
  echo "   대상 경로: $CANONICAL_TARGET" >&2
  echo "   허용 범위 1: $CANONICAL_ROOT (이 프로젝트)" >&2
  if [[ -n "${TARGET_PROJECT_ROOT:-}" ]]; then
    echo "   허용 범위 2: ${CANONICAL_TPR:-$TARGET_PROJECT_ROOT} (대상 프로젝트)" >&2
  else
    echo "   힌트: Phase 0 미완료로 추정 — 오케스트레이터가 TARGET_PROJECT_ROOT를 설정하지 않았습니다." >&2
    echo "         설정 없이는 대상 프로젝트 쓰기가 조용히 허용되지 않습니다. Phase 0을 완료하세요." >&2
  fi
  exit 1
fi

# --- TPR 미설정 + 플러그인 내부 Write는 감사 로그만 남기고 통과 (기여자 편집 흐름 보존) ---
if [[ -z "${TARGET_PROJECT_ROOT:-}" && "$SCOPE_HIT" == "plugin" ]]; then
  echo "ℹ️  [ownership-guard] TARGET_PROJECT_ROOT 미설정 — 플러그인 자체 편집(기여자 모드)으로 간주하여 허용: $CANONICAL_TARGET" >&2
fi

# --- .local 파일 gitignore 확인 ---
if [[ "$CANONICAL_TARGET" == *".local.json" ]] || [[ "$CANONICAL_TARGET" == *".local.md" ]]; then
  if ! grep -q '\.local\.' .gitignore 2>/dev/null; then
    echo "⚠️  경고: .local.* 파일이 .gitignore에 포함되어 있지 않습니다" >&2
  fi
fi

exit 0
