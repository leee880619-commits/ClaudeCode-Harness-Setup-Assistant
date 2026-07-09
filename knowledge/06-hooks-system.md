<!-- File: 06-hooks-system.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 7 -->
## SECTION 7: Hooks 시스템 완전 명세

### 7.1 Hook 이벤트 종류

Hook은 Claude Code의 도구 실행 생명주기에 개입하여 자동 검증, 보호, 정리 작업을 수행하는 메커니즘이다. 세 가지 이벤트 타입을 지원한다.

| 이벤트 | 트리거 시점 | 대표 활용 사례 | 실행 환경 |
|---|---|---|---|
| `PreToolUse` | 도구 실행 **직전** | 파일 소유권 가드, 위험한 명령 차단, 디렉터리 접근 제어 | 프로젝트 루트에서 실행 |
| `PostToolUse` | 도구 실행 **직후** | 품질 게이트, 빌드 검증, 구문 검사, 린트 | 프로젝트 루트에서 실행 |
| `Stop` | 에이전트 응답 **완료 시** | 세션 핸드오프 갱신, 임시 파일 정리, 상태 파일 갱신 | 프로젝트 루트에서 실행 |

**Hook 실행 흐름 시각화:**

```
사용자 요청
  │
  ▼
Claude가 Write 도구 호출 결정
  │
  ▼
[PreToolUse] matcher: "Write" → ownership-guard.sh 실행
  │
  ├─ 종료 코드 0 → Write 도구 실행 허용
  │    │
  │    ▼
  │  Write 도구 실제 실행
  │    │
  │    ▼
  │  [PostToolUse] matcher: "Write" → quality-gate.sh 실행
  │    │
  │    ├─ 종료 코드 0 → 계속 진행
  │    └─ 종료 코드 ≠ 0 → stderr 내용이 Claude에게 전달 → 수정 시도
  │
  └─ 종료 코드 2 → Write 도구 실행 차단, stderr 내용이 Claude에게 전달
  
  ...
  
Claude가 응답 완료
  │
  ▼
[Stop] → cleanup.sh 실행
```

**Hook의 입출력 프로토콜:**

- **입력**: **stdin으로 전달되는 단일 JSON 객체**다. 환경변수가 아니다.

  ```json
  {
    "hook_event_name": "PreToolUse",
    "tool_name": "Write",
    "tool_input": { "file_path": "C:\\Users\\me\\proj\\a.json", "content": "..." },
    "tool_response": { "...": "PostToolUse에만 존재" },
    "cwd": "C:\\Users\\me\\proj",
    "session_id": "..."
  }
  ```

  `$CLAUDE_TOOL_INPUT` / `$CLAUDE_TOOL_NAME` / `$CLAUDE_TOOL_OUTPUT` 같은 환경변수는 **존재하지 않는다.**
  이것을 읽는 훅은 항상 빈 문자열을 받아 조용히 통과하므로, 검사하는 척하면서 아무것도 하지 않는다.

- **훅이 실제로 받는 환경변수**: `$CLAUDE_PROJECT_DIR`, `$CLAUDE_PLUGIN_ROOT`, `$CLAUDE_PLUGIN_DATA`, `$CLAUDE_EFFORT`.
  임의 환경변수(`$TARGET_PROJECT_ROOT` 등)는 다른 도구 호출에서 `export` 해도 훅에 전달되지 않는다.
  훅은 Claude Code가 별도 프로세스로 띄우기 때문이다. 상태가 필요하면 **파일에 적어라.**

- **출력 (종료 코드)**:
  - `0` → 통과. stdout이 유효 JSON이면 구조화 응답으로 해석됨
  - `2` → **차단.** stderr가 Claude에게 전달됨 (PreToolUse: 도구 실행 취소 / PostToolUse: 실행은 끝났고 Claude가 후속 수정)
  - `1` 또는 그 외 → **차단이 아니다.** 비차단 오류로 기록될 뿐 도구는 그대로 실행된다
  - `stderr`로 출력한 내용이 Claude에게 전달되는 통로다

  차단하려면 반드시 `exit 2`. `exit 1`은 아무것도 막지 못한다.

**stdin JSON에서 file_path 뽑기 (인터프리터 스폰 없이):**

```bash
INPUT="$(cat)"
REST="${INPUT#*\"file_path\":\"}"
[[ "$REST" == "$INPUT" ]] && exit 0        # file_path 없음
RAW="${REST%%\"*}"
FILE="${RAW//\\\\//}"                      # C:\\Users\\x -> C:/Users/x
FILE="${FILE//\\//}"
```

Windows에서 `file_path`는 백슬래시가 이스케이프된 형태(`C:\\Users\\...`)로 온다.
`/`로 시작하는지로 절대경로를 판별하면 Windows 경로가 상대경로로 오인되어 가드가 열린다.

### 7.2 settings.json hooks 설정 포맷

Hook은 `.claude/settings.json`의 `hooks` 섹션에 정의한다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "timeout": 5,
            "command": "bash .claude/hooks/ownership-guard.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "timeout": 5,
            "command": "bash .claude/hooks/dangerous-command-guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "timeout": 10,
            "command": "bash .claude/hooks/syntax-check.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "timeout": 30,
            "command": "bash .claude/hooks/quality-gate.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "shell": "bash",
            "timeout": 30,
            "command": "bash .claude/hooks/session-cleanup.sh"
          }
        ]
      }
    ]
  }
}
```

#### 7.2.1 훅 비용 규약 (필수)

훅은 **매 도구 호출마다 OS 프로세스를 새로 띄운다.** `Write|Edit` 매처는 파일을 하나 쓸 때마다 발동하고, 서브에이전트 안에서도 동일하게 발동한다. 다중 에이전트 워크플로우는 한 번 실행에 수백 번 Write를 하므로, 훅 하나의 낭비가 수백 배로 증폭된다.

1. **모든 훅에 `timeout` 을 명시한다.** 생략 시 기본값은 **600초**다. 머신이 잠깐 느려지면 훅이 끝나지 못하고 10분간 살아남아, 그 사이 새 훅이 계속 쌓인다. 실제로 이 방식으로 훅 프로세스 378개가 누적된 사례가 있다. 가드는 5초, 검사는 10초, 빌드/테스트를 도는 훅만 30초 이상을 준다.

2. **`"shell": "bash"` 를 명시한다.** 생략하면 Windows에서 셸이 PATH를 뒤져 `bash` 를 찾고, 후보에 WSL 런처(`WindowsApps\bash.exe`)가 섞여 있으면 훅 하나마다 WSL VM을 깨운다.

3. **범위 밖 파일이면 즉시 `exit 0`.** 검사 대상이 `.json` / 특정 디렉터리뿐이라면, 그 판별을 **인터프리터 스폰 전에** 순수 bash로 끝낸다.

4. **`python` / `node` 를 조건 없이 부르지 않는다.** Windows에서 `python3` 는 Microsoft Store 스텁일 수 있어 실행 시 멈출 수 있다. `command -v` 로 존재를 확인하고, 가능하면 `jq` 를 우선한다.

**설정 구조 상세:**

```
hooks
├── PreToolUse: Array<MatcherGroup>
│   └── MatcherGroup
│       ├── matcher: string          ← 도구 이름 매칭 패턴 (정규식)
│       └── hooks: Array<HookDef>
│           └── HookDef
│               ├── type: "command"  ← 현재 "command"만 지원
│               ├── shell: string    ← "bash" 권장 (Windows에서 WSL 경유 방지)
│               ├── timeout: number  ← 초. 생략 시 600초 (반드시 명시할 것)
│               └── command: string  ← 실행할 셸 명령
├── PostToolUse: Array<MatcherGroup>  ← 같은 구조
└── Stop: Array<MatcherGroup>         ← 같은 구조 (matcher는 보통 빈 문자열)
```

**matcher 패턴:**

| 패턴 | 매칭 대상 | 설명 |
|---|---|---|
| `"Write"` | Write 도구만 | 정확히 일치 |
| `"Write\|Edit"` | Write 또는 Edit | 파이프(`\|`)로 OR 조건 |
| `"Bash"` | Bash 도구만 | 명령 실행 도구 |
| `""` (빈 문자열) | 모든 도구 | Stop 이벤트에서 주로 사용 |
| `".*"` | 모든 도구 | 정규식 와일드카드 |

**다중 Hook 실행 순서:**

하나의 이벤트에 여러 MatcherGroup이 매칭될 경우, 배열 순서대로 실행된다. 하나라도 실패하면 후속 Hook은 실행되지 않는다.

### 7.3 실제 Hook 패턴 (3개 프로젝트)

#### 프로젝트 1: GUI2WEBAPP hooks

GUI2WEBAPP은 멀티 에이전트(다수의 역할이 동시 작업) 프로젝트에서 가장 정교한 Hook 시스템을 운영한다. 3개의 핵심 Hook이 팀워크 규율을 강제한다.

**1-a. quality-gate.sh (PostToolUse — Bash 매칭)**

작업 완료 시 코드 품질을 자동 검증하는 게이트이다.

```bash
#!/bin/bash
# .claude/hooks/quality-gate.sh
# PostToolUse 트리거: Bash 명령 실행 후 품질 검증

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ERRORS=()

# 1. Python 구문 검증
echo "Checking Python syntax..." >&2
while IFS= read -r -d '' pyfile; do
    if ! python3 -c "import ast; ast.parse(open('$pyfile').read())" 2>/dev/null; then
        ERRORS+=("Python syntax error: $pyfile")
    fi
done < <(find "$PROJECT_ROOT" -name '*.py' -not -path '*/node_modules/*' -not -path '*/.venv/*' -print0)

# 2. TypeScript 컴파일 검증
if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    echo "Checking TypeScript compilation..." >&2
    if ! npx tsc --noEmit 2>/dev/null; then
        ERRORS+=("TypeScript compilation failed")
    fi
fi

# 3. ESLint 검증 (설정 파일이 있는 경우만)
if [ -f "$PROJECT_ROOT/.eslintrc.json" ] || [ -f "$PROJECT_ROOT/.eslintrc.js" ]; then
    echo "Running ESLint..." >&2
    if ! npx eslint --quiet "$PROJECT_ROOT/src/" 2>/dev/null; then
        ERRORS+=("ESLint violations found")
    fi
fi

# 4. 테스트 실행 (빠른 테스트만)
if [ -f "$PROJECT_ROOT/package.json" ] && grep -q '"test:fast"' "$PROJECT_ROOT/package.json"; then
    echo "Running fast tests..." >&2
    if ! npm run test:fast 2>/dev/null; then
        ERRORS+=("Fast tests failed")
    fi
fi

# 5. console.log 잔류 검사
CONSOLE_LOGS=$(grep -rn 'console\.log' "$PROJECT_ROOT/src/" --include='*.ts' --include='*.js' 2>/dev/null | grep -v '// keep' | head -5)
if [ -n "$CONSOLE_LOGS" ]; then
    ERRORS+=("Residual console.log found:\n$CONSOLE_LOGS")
fi

# 결과 보고
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "❌ Quality gate FAILED:" >&2
    for err in "${ERRORS[@]}"; do
        echo "  - $err" >&2
    done
    exit 2   # 차단/보고는 2. exit 1 은 Claude 에게 전달되지 않는다.
fi

echo "✅ Quality gate passed" >&2
exit 0
```

**1-b. idle-check.sh (Stop — 에이전트 유휴 시)**

에이전트가 작업을 마치고 유휴 상태로 전환될 때 실행된다. 현재 워크스페이스의 건강 상태를 점검하고, 다른 역할의 에이전트가 이어받을 때 문제가 없는지 확인한다.

```bash
#!/bin/bash
# .claude/hooks/idle-check.sh
# Stop 트리거: 에이전트 응답 완료 시 워크스페이스 건강 검사

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROLE="${CLAUDE_SKILL_ROLE:-unknown}"

WARNINGS=()

# 1. 구문 검증 (모든 역할 공통)
SYNTAX_ERRORS=$(find "$PROJECT_ROOT/src" -name '*.py' -exec python3 -c "
import sys, ast
try:
    ast.parse(open(sys.argv[1]).read())
except SyntaxError as e:
    print(f'{sys.argv[1]}:{e.lineno}: {e.msg}')
" {} \; 2>/dev/null)

if [ -n "$SYNTAX_ERRORS" ]; then
    WARNINGS+=("Syntax errors left behind:\n$SYNTAX_ERRORS")
fi

# 2. 빌드 검증 (모든 역할 공통)
if [ -f "$PROJECT_ROOT/package.json" ]; then
    if ! npm run build --silent 2>/dev/null; then
        WARNINGS+=("Build is broken — next agent will inherit broken state")
    fi
fi

# 3. 역할별 유닛 테스트 누락 경고
case "$ROLE" in
    "build-html"|"build-css"|"build-javascript")
        # 구현 역할: 유닛 테스트 존재 확인
        CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null | grep -E '\.(ts|js|py)$' | grep -v '\.test\.' | grep -v '\.spec\.')
        for f in $CHANGED_FILES; do
            TEST_FILE="${f%.*}.test.${f##*.}"
            if [ ! -f "$PROJECT_ROOT/$TEST_FILE" ]; then
                WARNINGS+=("Missing unit test for changed file: $f")
            fi
        done
        ;;
    "validate-*")
        # 검증 역할: 보고서 생성 확인
        if [ ! -f "$PROJECT_ROOT/docs/operations/latest-validation.md" ]; then
            WARNINGS+=("Validation role completed without generating report")
        fi
        ;;
esac

# 결과 보고
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "⚠️ Idle check warnings:" >&2
    for w in "${WARNINGS[@]}"; do
        echo "  - $w" >&2
    done
    exit 2   # 차단/보고는 2. exit 1 은 Claude 에게 전달되지 않는다.
fi

exit 0
```

**1-c. ownership-guard.sh (PreToolUse — Write|Edit 매칭)**

멀티 에이전트 환경에서 각 역할이 자신의 담당 영역 외의 파일을 수정하지 못하도록 강제하는 가드이다.

```bash
#!/bin/bash
# .claude/hooks/ownership-guard.sh
# PreToolUse 트리거: Write 또는 Edit 도구 실행 전 파일 소유권 확인

set -uo pipefail

# 도구 입력은 stdin JSON 으로 온다 (환경변수가 아니다)
INPUT="$(cat 2>/dev/null)" || INPUT=""
[ -z "$INPUT" ] && exit 0

REST="${INPUT#*\"file_path\":\"}"
[ "$REST" = "$INPUT" ] && exit 0            # file_path 없음 -> 통과
RAW="${REST%%\"*}"
TARGET_FILE="${RAW//\\\\//}"                # C:\\Users\\x -> C:/Users/x
TARGET_FILE="${TARGET_FILE//\\//}"
[ -z "$TARGET_FILE" ] && exit 0

# 역할은 환경변수로 전달되지 않는다. 파일에 적어두고 읽는다.
ROLE="$(cat .claude/.current-role 2>/dev/null || echo unknown)"

# 역할별 허용 경로 패턴
declare -A OWNERSHIP_MAP
OWNERSHIP_MAP["build-html"]="^src/.*\.html$|^templates/"
OWNERSHIP_MAP["build-css"]="^src/.*\.css$|^styles/"
OWNERSHIP_MAP["build-javascript"]="^src/.*\.(js|ts)$|^scripts/"
OWNERSHIP_MAP["analyze-gui"]="^docs/analysis/"
OWNERSHIP_MAP["validate-port"]="^docs/validation/"
OWNERSHIP_MAP["optimize-responsive"]="^src/.*\.css$|^src/.*\.html$"

# 공유 허용 경로 (모든 역할 접근 가능)
SHARED_PATTERN="^docs/operations/|^\.claude/|^package\.json$|^README\.md$"

# 상대 경로로 변환
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REL_PATH="${TARGET_FILE#$PROJECT_ROOT/}"

# 공유 경로 확인
if echo "$REL_PATH" | grep -qE "$SHARED_PATTERN"; then
    exit 0
fi

# 역할별 소유권 확인
ALLOWED_PATTERN="${OWNERSHIP_MAP[$ROLE]:-}"

if [ -z "$ALLOWED_PATTERN" ]; then
    echo "⚠️ Role '$ROLE' has no ownership mapping — allowing write" >&2
    exit 0
fi

if ! echo "$REL_PATH" | grep -qE "$ALLOWED_PATTERN"; then
    echo "OWNERSHIP VIOLATION: Role '$ROLE' cannot write to '$REL_PATH'" >&2
    echo "   Allowed pattern: $ALLOWED_PATTERN" >&2
    echo "   Transfer this task to the appropriate role." >&2
    exit 2   # 차단은 2. exit 1 은 도구를 막지 못한다.
fi

exit 0
```

#### 프로젝트 2: Project-Integration-Agent hooks

PIA는 통합(integration) 프로젝트의 핵심 불변식(invariant)을 Hook으로 강제한다: **통합된 코드는 원본 프로젝트를 참조하지 않아야 한다.**

**2-a. quality-gate.sh (PostToolUse — Bash 매칭)**

```bash
#!/bin/bash
# .claude/hooks/quality-gate.sh
# 통합 디렉터리의 독립성 검증

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
INTEGRATED_DIR="$PROJECT_ROOT/integrated"

if [ ! -d "$INTEGRATED_DIR" ]; then
    exit 0  # 통합 디렉터리가 없으면 스킵
fi

ERRORS=()

# 1. 원본 프로젝트 참조 금지 검증
VIOLATIONS=$(grep -rn "projects/" "$INTEGRATED_DIR" \
    --include='*.ts' --include='*.js' --include='*.py' --include='*.json' \
    2>/dev/null | grep -v 'node_modules' | head -10)

if [ -n "$VIOLATIONS" ]; then
    ERRORS+=("Independence violation — integrated/ references projects/:\n$VIOLATIONS")
fi

# 2. 상대 경로로 원본 탈출 금지
ESCAPE_VIOLATIONS=$(grep -rn '\.\./projects/' "$INTEGRATED_DIR" \
    --include='*.ts' --include='*.js' --include='*.py' \
    2>/dev/null | head -10)

if [ -n "$ESCAPE_VIOLATIONS" ]; then
    ERRORS+=("Path escape violation — integrated/ reaches back to projects/:\n$ESCAPE_VIOLATIONS")
fi

# 3. 구문 검증
if [ -f "$INTEGRATED_DIR/tsconfig.json" ]; then
    if ! (cd "$INTEGRATED_DIR" && npx tsc --noEmit 2>/dev/null); then
        ERRORS+=("TypeScript compilation failed in integrated/")
    fi
fi

# 4. 통합 디렉터리 자체 테스트 실행
if [ -f "$INTEGRATED_DIR/package.json" ] && grep -q '"test"' "$INTEGRATED_DIR/package.json"; then
    if ! (cd "$INTEGRATED_DIR" && npm test 2>/dev/null); then
        ERRORS+=("Tests failed in integrated/")
    fi
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "❌ Integration quality gate FAILED:" >&2
    for err in "${ERRORS[@]}"; do
        echo -e "  - $err" >&2
    done
    exit 2   # 차단/보고는 2. exit 1 은 Claude 에게 전달되지 않는다.
fi

echo "✅ Integration quality gate passed — integrated/ is independent" >&2
exit 0
```

**2-b. idle-check.sh (Stop)**

```bash
#!/bin/bash
# .claude/hooks/idle-check.sh
# 에이전트 유휴 시 구문 + 독립성 검증

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

WARNINGS=()

# 구문 검증 (projects/ 와 integrated/ 모두)
for dir in "$PROJECT_ROOT/projects" "$PROJECT_ROOT/integrated"; do
    if [ -d "$dir" ]; then
        SYNTAX_ERRORS=$(find "$dir" -name '*.ts' -exec npx tsc --noEmit {} + 2>&1 | head -5)
        if [ -n "$SYNTAX_ERRORS" ]; then
            WARNINGS+=("Syntax issues in $(basename $dir)/: $SYNTAX_ERRORS")
        fi
    fi
done

# 독립성 경고 (idle-check은 차단이 아닌 경고만)
if [ -d "$PROJECT_ROOT/integrated" ]; then
    REFS=$(grep -rc "projects/" "$PROJECT_ROOT/integrated" --include='*.ts' --include='*.js' 2>/dev/null | grep -v ':0$' | wc -l)
    if [ "$REFS" -gt 0 ]; then
        WARNINGS+=("$REFS files in integrated/ still reference projects/ — needs cleanup")
    fi
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "⚠️ Idle check found issues:" >&2
    for w in "${WARNINGS[@]}"; do
        echo "  - $w" >&2
    done
    exit 2   # 차단/보고는 2. exit 1 은 Claude 에게 전달되지 않는다.
fi

exit 0
```

#### 프로젝트 3: Co-optris hooks (Cursor → Claude Code 변환)

Co-optris의 Cursor hooks를 Claude Code 형식으로 변환한 사례이다.

**원본 (Cursor `.cursor/hooks.json`):**

```json
{
  "hooks": {
    "preToolUse": {
      "Write|Edit": "node .cursor/hooks/ownership-guard.js",
      "Bash": "node .cursor/hooks/dangerous-cmd-guard.js"
    },
    "postToolUse": {
      "Bash": "node .cursor/hooks/quality-gate.js"
    },
    "stop": "node .cursor/hooks/session-handoff.js"
  }
}
```

**변환 후 (Claude Code `.claude/settings.json`):**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/ownership-guard.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/dangerous-cmd-guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/quality-gate.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-cleanup.sh"
          }
        ]
      }
    ]
  }
}
```

**3-a. quality-gate.sh (변환된 Co-optris 품질 게이트)**

```bash
#!/bin/bash
# .claude/hooks/quality-gate.sh
# Co-optris PostToolUse: 구문 + 프로젝트 체크

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ERRORS=()

# 1. Node.js 구문 검증 — server/, web/, shared/ 의 모든 .js 파일
while IFS= read -r -d '' jsfile; do
    if ! node --check "$jsfile" 2>/dev/null; then
        ERRORS+=("Syntax error: $jsfile")
    fi
done < <(find "$PROJECT_ROOT/server" "$PROJECT_ROOT/web" "$PROJECT_ROOT/shared" \
    -name '*.js' -not -path '*/node_modules/*' -print0 2>/dev/null)

# 2. 프로젝트 수준 검증 (Phase 1+2 체크)
if grep -q '"check:phase12"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    if ! npm run check:phase12 2>/dev/null; then
        ERRORS+=("npm run check:phase12 failed")
    fi
fi

# 3. 의존 방향 검증: web/ → server/ 직접 참조 금지
WEB_TO_SERVER=$(grep -rn "require.*['\"].*server/" "$PROJECT_ROOT/web/" \
    --include='*.js' 2>/dev/null | head -5)
if [ -n "$WEB_TO_SERVER" ]; then
    ERRORS+=("Dependency direction violation (web/ → server/):\n$WEB_TO_SERVER")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "❌ Co-optris quality gate FAILED:" >&2
    for err in "${ERRORS[@]}"; do
        echo -e "  - $err" >&2
    done
    exit 2   # 차단/보고는 2. exit 1 은 Claude 에게 전달되지 않는다.
fi

echo "✅ Co-optris quality gate passed" >&2
exit 0
```

**변환 시 주요 변경 사항 요약:**

| 항목 | Cursor 원본 | Claude Code 변환 |
|---|---|---|
| 설정 파일 위치 | `.cursor/hooks.json` | `.claude/settings.json` (hooks 섹션) |
| 스크립트 언어 | Node.js (`.js`) | Bash (`.sh`) 권장 (Node도 가능) |
| 이벤트명 | `preToolUse`, `postToolUse`, `stop` | `PreToolUse`, `PostToolUse`, `Stop` (PascalCase) |
| matcher 형식 | 키-값 직접 매핑 | 배열 내 객체, `matcher` 필드로 분리 |
| `stop` 핸들러 | `session-handoff.js` (수동 상태 저장) | `session-cleanup.sh` (자동 메모리가 대체하므로 정리만) |

---

