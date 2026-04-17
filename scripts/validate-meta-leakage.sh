#!/bin/bash
# validate-meta-leakage.sh
# 대상 디렉터리의 하네스 생성 파일에서 이 플러그인의 메타 용어 누수를 정적 검사한다.
# 사용: bash scripts/validate-meta-leakage.sh [SCAN_ROOT]
#   SCAN_ROOT 미지정 시 현재 디렉터리. 이 플러그인 자기 자신(레포 루트)을 스캔하면
#   이 어시스턴트 내부 설명이 "허용 문맥"이므로 많은 히트가 발생한다 — 의도된 동작.
#
# ⚠ CI/기여자 주의: 이 스크립트를 플러그인 레포 **루트**에 대고 돌리지 말 것 (자기참조 오탐 폭발).
#   실제 감사는 **대상 프로젝트(하네스가 설치된 외부 프로젝트) 루트**에 대해서만 실행한다.
#   예: bash scripts/validate-meta-leakage.sh /path/to/target-project
#   기여자 로컬 테스트에서 이 스크립트를 레포 자신에 돌려 exit 1 을 받아도 그것은
#   "이 스크립트가 동작한다"는 확인일 뿐 실제 regression 은 아니다.

set -euo pipefail

ROOT="${1:-$(pwd)}"

# 스캔 대상 (대상 프로젝트 기준 — 이 플러그인 레포가 아니라 하네스가 설치된 프로젝트)
PATTERNS_IN_GENERATED=(
  "$ROOT/CLAUDE.md"
  "$ROOT/.claude/rules"
  "$ROOT/.claude/skills"
  "$ROOT/.claude/agents"
  "$ROOT/playbooks"
)

# 명시적으로 제외 (이 플러그인 내부 파일은 허용 — 인자로 이 레포를 주지 않으면 해당 없음)
EXCLUDE_PATTERN='/(knowledge|checklists|commands/harness-setup\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|CHANGELOG\.md|docs/redteam-review-)'

# 정규식 히트 규칙 (meta-leakage-keywords.md의 Regex Hints 섹션과 동기화)
# NOTE: `Phase[ -]?[0-9]` 는 대상 프로젝트의 정당한 도메인 단어("Phase 1 릴리스" 등)와 충돌하여
# 과탐을 일으키므로 제거. `Phase Gate` 같은 관용구만 고정 포착한다.
REGEX='모든.{0,5}(결정|설정).{0,10}(먼저|반드시).{0,10}(질문|확인)|메타[ -]?누수|meta[ -]?leak(age)?|점진[ ]?적.{0,3}공개|질문[ ]?규율|question[ ]?discipline|하네스[ ]?(설정|구축|어시스턴트|에이전트)|Orchestrator Pattern Decision|BLOCKING REQUIREMENT|Phase[ ]?Gate'

# 직접 키워드 (meta-leakage-keywords.md의 Tool Identity / Behavioral Rules)
KEYWORDS=(
  "Harness Setup"
  "Setup Assistant"
  "harness-architect"
  "ask everything"
  "assume nothing"
  "질문을 먼저"
  "모든 것을 먼저 질문"
  "가정하지 마세요"
  "암묵적 합의 금지"
  "progressive disclosure"
  "점진적 공개"
  "meta-leakage"
)

hits=0

for target in "${PATTERNS_IN_GENERATED[@]}"; do
  [[ -e "$target" ]] || continue
  # 정규식 히트
  while IFS= read -r -d '' f; do
    # 제외 패턴 적용
    if [[ "$f" =~ $EXCLUDE_PATTERN ]]; then
      continue
    fi
    if lines=$(grep -InE "$REGEX" "$f" 2>/dev/null); then
      if [[ -n "$lines" ]]; then
        printf '❌ META-LEAKAGE (regex): %s\n%s\n\n' "$f" "$lines" >&2
        hits=$((hits+1))
      fi
    fi
    # 직접 키워드 히트
    for kw in "${KEYWORDS[@]}"; do
      if lines=$(grep -InF "$kw" "$f" 2>/dev/null); then
        if [[ -n "$lines" ]]; then
          printf '❌ META-LEAKAGE (keyword "%s"): %s\n%s\n\n' "$kw" "$f" "$lines" >&2
          hits=$((hits+1))
        fi
      fi
    done
  done < <(find "$target" -type f \( -name '*.md' -o -name '*.json' \) -print0 2>/dev/null)
done

if [[ $hits -gt 0 ]]; then
  printf '❌ 메타 누수 의심 위치 %d건 발견 (스캔 루트: %s)\n' "$hits" "$ROOT" >&2
  exit 1
fi
printf '✓  메타 누수 검사 통과 (스캔 루트: %s)\n' "$ROOT"
exit 0
