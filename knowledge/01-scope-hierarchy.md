<!-- File: 01-scope-hierarchy.md | Source: architecture-report Section 2 -->
## SECTION 2: 4-Tier Scope 계층 완전 명세

Claude Code는 지침과 설정을 **4단계 스코프 계층(4-Tier Scope Hierarchy)**으로 관리한다. 각 스코프는 독립적으로 존재하며, 더 구체적인(하위) 스코프가 상위 스코프를 덮어쓴다(스칼라 값 기준). 단, `deny` 규칙은 예외적으로 어떤 레벨에서든 설정되면 절대 override 불가하다.

```
[우선순위: 낮음 → 높음]

┌─────────────────────────────────────────────────┐
│  1. MANAGED  (조직 IT 배포)                      │ ← 가장 낮은 override 우선순위
│     /etc/claude-code/  (Linux/WSL)              │    단, deny는 절대 override 불가
│     /Library/Application Support/ClaudeCode/    │
│     C:\Program Files\ClaudeCode\  (Windows)     │
├─────────────────────────────────────────────────┤
│  2. USER  (개인 전역)                            │
│     ~/.claude/                                  │
├─────────────────────────────────────────────────┤
│  3. PROJECT  (팀 공유)                           │
│     <project-root>/CLAUDE.md                    │
│     <project-root>/.claude/                     │
├─────────────────────────────────────────────────┤
│  4. LOCAL  (개인 프로젝트)                       │ ← 가장 높은 override 우선순위
│     <project-root>/CLAUDE.local.md              │
│     <project-root>/.claude/settings.local.json  │
└─────────────────────────────────────────────────┘
```

---

### 2.1 Managed Scope (조직 정책)

#### 위치

| OS | 경로 |
|----|------|
| Linux / WSL | `/etc/claude-code/` |
| macOS | `/Library/Application Support/ClaudeCode/` |
| Windows | `C:\Program Files\ClaudeCode\` |

#### 포함 파일

| 파일 | 역할 | 유형 |
|------|------|------|
| `CLAUDE.md` | 조직 전체 AI 사용 지침 | Context (Markdown) |
| `managed-settings.json` | 조직 전체 설정 (권한, 환경변수, 프록시 등) | Config (JSON) |
| `managed-settings.d/*.json` | 모듈식 설정 분할 (부서별, 정책별 분리 가능) | Config (JSON) |

#### 핵심 특성

1. **`claudeMdExcludes`로 제외 불가**: 사용자가 `~/.claude/settings.json`의 `claudeMdExcludes` 필드를 사용해서 특정 CLAUDE.md를 무시하도록 설정할 수 있지만, Managed 스코프의 CLAUDE.md는 이 메커니즘으로 제외할 수 없다. 클라이언트가 이를 강제로 로딩한다.

2. **`deny` 규칙의 절대성**: Managed 스코프의 `permissions.deny`에 등록된 도구/명령 패턴은 그 어떤 하위 스코프(User, Project, Local)의 `permissions.allow`로도 해제할 수 없다. 이것은 "deny wins everywhere" 원칙의 가장 강력한 형태다.

3. **배포 방식**: 일반 사용자가 직접 편집하는 파일이 아니다. IT/DevOps 팀이 다음 도구를 통해 배포한다:
   - **Linux**: Ansible, Puppet, Chef, Salt 등 구성 관리 도구
   - **macOS**: Jamf, Kandji 등 MDM(Mobile Device Management)
   - **Windows**: GPO(Group Policy Object), SCCM/Intune, 또는 스크립트 배포

4. **`managed-settings.d/` 디렉터리**: 단일 `managed-settings.json` 대신 여러 JSON 파일로 분할할 수 있다. 파일명의 알파벳 순서로 로딩되며, 동일 키가 충돌하면 나중에 로딩된 파일이 우선한다. 이를 통해 "보안팀 정책", "네트워크팀 정책", "개발표준팀 정책"을 독립적으로 관리·배포할 수 있다.

#### 사용 사례

```json
// /etc/claude-code/managed-settings.json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo *)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(chmod 777 *)",
      "Bash(ssh *)",
      "Bash(scp *)"
    ]
  },
  "env": {
    "HTTPS_PROXY": "http://proxy.corp.example.com:8080",
    "HTTP_PROXY": "http://proxy.corp.example.com:8080",
    "NO_PROXY": "localhost,127.0.0.1,.corp.example.com"
  }
}
```

```markdown
<!-- /etc/claude-code/CLAUDE.md -->
# 조직 AI 사용 정책

## 보안 규칙
- .env 파일, 인증서, API 키를 절대 코드에 하드코딩하지 말 것
- 외부 API 호출 시 반드시 사내 프록시를 경유할 것
- 사내 코드를 외부 서비스(pastebin, gist 등)에 업로드하지 말 것
- 암호화되지 않은 채널로 PII(개인식별정보)를 전송하지 말 것

## 코딩 표준
- TypeScript strict mode 필수
- 모든 API 엔드포인트에 인증 미들웨어 적용
- SQL 쿼리는 반드시 파라미터화된 쿼리 사용
```

```json
// /etc/claude-code/managed-settings.d/01-security.json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo *)"
    ]
  }
}

// /etc/claude-code/managed-settings.d/02-network.json
{
  "env": {
    "HTTPS_PROXY": "http://proxy.corp.example.com:8080"
  }
}
```

---

### 2.2 User Scope (개인 전역)

#### 위치

```
~/.claude/
```

모든 OS에서 사용자 홈 디렉터리의 `.claude/` 하위 디렉터리다.
- Linux/WSL: `/home/<username>/.claude/`
- macOS: `/Users/<username>/.claude/`
- Windows: `C:\Users\<username>\.claude\`

#### 포함 파일 완전 목록

```
~/.claude/
├── CLAUDE.md                          ← 전역 개인 지침
├── settings.json                      ← 유저 설정 (model, env, permissions 등)
├── rules/                             ← 전역 규칙 모음
│   ├── git-safety.md                  ← 예: Git 안전 규칙
│   ├── korean-encoding.md             ← 예: 한국어 인코딩 규칙
│   └── response-style.md              ← 예: 응답 스타일 규칙
├── skills/                            ← 전역 스킬
│   └── my-custom-skill/
│       └── SKILL.md
├── projects/                          ← 자동 메모리 저장소
│   └── <project-hash>/               ← 프로젝트별 하위 디렉터리
│       └── memory/
│           ├── MEMORY.md              ← 인덱스 (세션 시작 시 로딩)
│           ├── user_profile.md        ← 토픽: 사용자 프로필
│           ├── feedback_workflow.md   ← 토픽: 워크플로우 피드백
│           └── project_context.md     ← 토픽: 프로젝트 맥락
└── keybindings.json                   ← 키바인딩 설정 (지침 시스템과 무관)
```

#### 2.2.1 `~/.claude/CLAUDE.md` — 전역 개인 지침

**역할**: 모든 프로젝트에 공통 적용되는 개인 작업 원칙. Cursor의 "전역 유저 룰(Global User Settings)"에 정확히 대응한다.

**기재해야 할 내용**:
- 개인 코딩 스타일 원칙 (가독성 우선, placeholder 코드 금지 등)
- Git 커밋 컨벤션 (Conventional Commits, force push 금지 등)
- OS 특화 규칙 (Windows 한국어 인코딩: `git commit -F` 사용, `chcp 65001` 확인 등)
- 문제 해결 철학 (workaround 금지, 불확실하면 질문 등)
- 응답 스타일 선호 (언어, 형식, 상세도)

**기재하지 말아야 할 내용**:
- 특정 프로젝트의 기술 스택이나 아키텍처 (→ 프로젝트 CLAUDE.md로)
- 특정 프로젝트의 디렉터리 구조 (→ 프로젝트 CLAUDE.md로)
- 보안 차단 규칙 (→ settings.json의 `permissions.deny`로)

**권장 길이**: 200줄 이하. 경험적으로 200줄을 초과하면 Claude의 지침 준수율이 눈에 띄게 저하된다. 더 긴 내용은 `~/.claude/rules/` 디렉터리로 분리하거나 `@import`를 사용한다.

**예시**:

```markdown
# Personal Development Principles

## Code Quality
- Readability over performance — optimize only when measured
- No placeholder or TODO code in production
- Complete implementation only — no partial stubs
- Understand code before modifying it

## Git Conventions
- Conventional Commits format required
- No force push to main/master
- Commit only after verification passes
- Korean commit messages: use `git commit -F tmpfile.txt`
  (never `-m "한글"` on Windows — encoding breaks)

## Problem Solving
- Face problems head-on — no workarounds
- No arbitrary decisions — ask user when unclear
- User decides, agent proposes and executes

## Korean Encoding (Windows/WSL)
- All file I/O must use UTF-8
- Terminal output: check `chcp 65001` before commands
- Git: use `-F tmpfile.txt` for Korean messages
- JSON/YAML: ensure UTF-8 BOM-less encoding

## Response Style
- 한국어로 응답해 주세요 (코드 주석은 영어 유지)
- 변경 사항 요약은 간결하게
- diff 형태로 보여주는 것을 선호
```

#### 2.2.2 `~/.claude/settings.json` — 유저 전역 설정

**역할**: 클라이언트가 강제 적용하는 개인 전역 설정. 모든 프로젝트에 기본값으로 적용된다.

**전체 필드 스키마**:

```jsonc
{
  // 사용할 모델 지정
  // 예: "claude-sonnet-4-20250514", "opus[1m]", "claude-opus-4-20250514"
  "model": "string",

  // 환경 변수. 프로세스 환경에 직접 주입됨.
  "env": {
    "KEY": "VALUE"
  },

  // 권한 설정
  "permissions": {
    // 자동 허용: Claude가 이 패턴의 도구를 사용할 때 사용자 확인 없이 즉시 실행
    "allow": [
      "Bash(npm *)",
      "Bash(node *)",
      "Bash(git *)",
      "Bash(npx tsc *)",
      "Read(*)",
      "Glob(*)",
      "Grep(*)"
    ],
    // 절대 차단: 어떤 경우에도 실행 불가. 하위 스코프의 allow로 해제 불가
    "deny": [
      "Bash(rm -rf /)"
    ],
    // 매번 확인: Claude가 사용하려 할 때마다 사용자에게 승인 요청
    "ask": [
      "Bash(git push *)",
      "Bash(npm publish *)"
    ]
  },

  // 자동 메모리 활성화/비활성화
  // true: Claude가 세션 간 학습을 자동 축적
  // false: 메모리 기능 비활성화
  "autoMemoryEnabled": true,

  // 기본 작업 모드
  // "normal": 표준 모드 (매번 확인)
  // "auto": 자동 모드 (allow된 도구는 확인 없이 실행)
  "defaultMode": "auto",

  // 샌드박스 활성화
  // true: 파일 시스템 접근을 제한된 범위로 격리
  "sandbox": {
    "enabled": false
  },

  // CLAUDE.md 제외 패턴
  // 특정 경로의 CLAUDE.md를 로딩하지 않음
  // 주의: Managed 스코프는 이 설정으로 제외 불가
  "claudeMdExcludes": [
    "/path/to/unwanted/CLAUDE.md"
  ]
}
```

**주의사항**:
- `permissions` 필드의 패턴은 glob 스타일이다. `*`는 임의의 문자열에 매칭된다.
- `Bash(...)` 형식은 Bash 도구 호출 패턴이며, 괄호 안에 실제 명령 패턴을 작성한다.
- MCP 서버 도구는 `mcp__<server-name>__<tool-name>` 형식으로 지정한다. 예: `mcp__context-mode__read_context`
- `Read(*)`, `Glob(*)`, `Grep(*)` 등은 Claude Code 내장 도구에 대한 패턴이다.
- `model` 필드는 하위 스코프(Project, Local)에서 override 가능하다.

#### 2.2.3 `~/.claude/rules/*.md` — 전역 규칙 파일

**역할**: 모든 프로젝트에 적용되는 개인 규칙. CLAUDE.md가 길어질 때 주제별로 분리하는 데 사용한다.

**형식**: 표준 Markdown. 선택적으로 YAML 프론트매터에 `paths` 필드를 포함할 수 있다.

**두 가지 모드**:

1. **항상 적용 (Always-Apply)**: 프론트매터가 없거나 `paths` 필드가 없으면, 세션 시작 시 자동으로 컨텍스트에 로딩된다.

```markdown
# Git Safety Rules

## Forbidden Commands
- Never use `git reset --hard`
- Never use `git clean -fd`
- Never use `git push --force` to main

## Commit Policy
- Commit only after QA passes
- Use Conventional Commits format
```

2. **경로 기반 (Path-Scoped)**: `paths` YAML 프론트매터가 있으면, Claude가 매칭 파일을 편집할 때만 온디맨드로 로딩된다. 토큰을 절약하면서 파일 유형별 규칙을 적용할 수 있다.

```markdown
---
paths:
  - "**/*.sql"
  - "db/**"
---

# SQL Safety Rules

- Always use parameterized queries
- Never use string concatenation for SQL
- All migrations must be reversible
```

**`paths` 필드 문법**:
- glob 패턴 사용 (예: `"*.ts"`, `"src/**/*.tsx"`, `"server.js"`)
- 배열 형태로 여러 패턴 지정 가능
- 상대 경로는 프로젝트 루트 기준으로 해석됨
- 패턴 매칭 시 해당 규칙 파일이 컨텍스트에 추가됨

#### 2.2.4 `~/.claude/skills/*/SKILL.md` — 전역 스킬

**역할**: 모든 프로젝트에서 사용 가능한 개인 스킬. 슬래시 명령(`/skill-name`)으로 호출하거나, 특정 트리거 조건에서 자동 활성화된다.

**형식**: YAML 프론트매터 + Markdown 본문

```markdown
---
name: my-review-skill
description: Code review with personal checklist
---

# My Code Review Skill

## Checklist
1. Check for error handling completeness
2. Verify input validation
3. Check for SQL injection risks
4. Ensure logging is adequate
...
```

#### 2.2.5 `~/.claude/projects/<project>/memory/` — 자동 메모리

**역할**: Claude가 세션 간 학습을 자동으로 축적하는 저장소. 사용자가 직접 편집할 수도 있지만, 주로 Claude가 자동으로 관리한다.

**프로젝트 식별**: `<project>` 디렉터리명은 프로젝트 경로의 해시 또는 정규화된 이름이다. 동일 프로젝트를 다른 경로에서 열면 별도 디렉터리가 생성될 수 있다.

**파일 구조**:
- `MEMORY.md`: 인덱스 파일. 세션 시작 시 자동 로딩된다 (200줄/25KB 제한). 토픽 파일들의 목록과 각 파일의 요약을 포함한다.
- `*.md` (토픽 파일): 주제별 상세 메모리. Claude가 필요할 때 `Read` 도구로 접근한다. 세션 시작 시 자동 로딩되지 않는다.

**메모리 유형 4가지**:

| 유형 | 저장 내용 | 예시 |
|------|-----------|------|
| User | 사용자의 역할, 기술 수준, 작업 스타일, 선호도 | "Senior BE engineer, prefers minimal abstractions" |
| Feedback | 사용자 교정 및 검증된 접근 방식 | "NLM URL 직접 링크 금지", "테스트 먼저 작성" |
| Project | 진행 중인 작업, 목표, 아키텍처 결정, 마감 기한 | "Phase 1 멀티플레이어 완료, Phase 2 진행 중" |
| Reference | 외부 시스템 포인터 | "Linear 프로젝트 URL", "Grafana 대시보드 링크" |

**`autoMemoryEnabled` 설정과의 관계**: `~/.claude/settings.json`에서 `"autoMemoryEnabled": false`로 설정하면 Claude가 자동으로 메모리를 축적하지 않는다. 그러나 이미 존재하는 메모리 파일은 여전히 읽힌다.

---

### 2.3 Project Scope (팀 공유)

#### 위치

```
<project-root>/
├── CLAUDE.md                 ← 프로젝트 루트의 지침 (택1)
└── .claude/
    ├── CLAUDE.md             ← .claude/ 내의 지침 (택1, 루트 CLAUDE.md의 대안)
    ├── settings.json         ← 프로젝트 설정
    ├── rules/                ← 모듈식 규칙
    │   ├── git-safety.md
    │   ├── testing-policy.md
    │   └── server/           ← 하위 디렉터리로 재귀적 구성 가능
    │       └── verification.md
    └── skills/               ← 프로젝트 스킬
        ├── tech-lead/
        │   └── SKILL.md
        └── qa-blackbox/
            └── SKILL.md
```

#### 2.3.1 `CLAUDE.md` (프로젝트 루트) 또는 `.claude/CLAUDE.md`

**역할**: 프로젝트의 핵심 지침. 팀원 전원이 Git을 통해 공유한다. Cursor의 `AGENTS.md`에 직접 대응한다.

**두 위치의 관계**: `<project-root>/CLAUDE.md`와 `<project-root>/.claude/CLAUDE.md` 중 하나를 사용한다. **둘 다 존재하면 둘 다 로딩**된다. 일반적으로 프로젝트 루트의 `CLAUDE.md`를 사용하되, 프로젝트 루트를 깔끔하게 유지하고 싶다면 `.claude/CLAUDE.md`를 사용한다.

**기재해야 할 내용**:
- **프로젝트 정체성/미션**: 이 프로젝트가 무엇이며 왜 존재하는지
- **기술 스택 명시**: 언어, 프레임워크, 주요 라이브러리, 아키텍처 패턴
- **개발 원칙/기조**: 팀이 합의한 코딩 철학과 원칙
- **사용자 확인 필수 목록**: Claude가 독단적으로 결정하면 안 되는 사항들
- **참조 문서 인덱스**: `@import` 구문을 사용한 외부 문서 참조

**예시**:

```markdown
# Co-optris

세상에 없던 재미를 주는 co-op 테트리스를 유저에게 대접한다.

## Tech Stack
- Backend: Node.js + better-sqlite3
- Frontend: Plain JavaScript + Canvas (no frameworks)
- Shared: UMD modules (constants, message-keys, collision)
- Pattern: IIFE + window.CoOptris{Name} namespaces

## Development Tenets
1. Face problems head-on — no workarounds or temp fixes
2. Understand before changing — research code first
3. Stop if unclear — ask user immediately
4. User decides code — agent proposes, user approves
5. Service-level quality — same standards regardless of phase
6. Server authority — game logic decided on server only
7. Minimum dependencies — plain JS, no heavy libs
8. Eliminate duplication — one source of truth

## Requires User Confirmation
- Product direction changes (add/remove game modes)
- Any dependency additions
- Architecture changes (server-client boundary, protocol)
- Instruction document modifications

## Reference Index
@docs/architecture/code-map.md
@docs/operations/session_handoff.md
@docs/game-design/master_plan.md
```

#### `@import` 구문 상세

| 속성 | 값 |
|------|-----|
| 구문 | `@path/to/file.md` (줄 시작에서 `@`로 시작) |
| 경로 해석 | 상대 경로는 import하는 파일의 위치 기준으로 해석 |
| 재귀 깊이 | 최대 5단계 (import된 파일이 다시 import하는 것이 5번까지 가능) |
| 승인 | 첫 사용 시 사용자 승인 필요 (보안상 임의 파일 읽기 방지) |
| 순환 참조 | 감지 및 차단됨 (A→B→A 는 B에서 중단) |
| 존재하지 않는 파일 | 경고 메시지를 출력하되 세션 시작은 정상 진행 |

#### HTML 주석 처리

```markdown
<!-- 이 주석은 컨텍스트에서 제거됩니다 -->
<!-- 
  팀 내부 메모: 이 규칙은 2026-Q2에 재검토 예정.
  @담당자: alice
  이 주석은 토큰을 소비하지 않으므로 내부 의사소통에 활용 가능.
-->

# 실제 지침 내용은 여기부터
이 텍스트는 Claude의 컨텍스트에 포함됩니다.
```

블록 레벨 `<!-- -->` HTML 주석은 Claude에게 전달되는 컨텍스트에서 **자동으로 제거**된다. 이를 활용하면:
- 팀 내부 메모를 CLAUDE.md에 포함하되 토큰을 소비하지 않을 수 있다
- 임시로 비활성화하고 싶은 지침을 주석 처리할 수 있다
- 변경 이력이나 담당자 정보를 기록할 수 있다

#### 하위 디렉터리 CLAUDE.md (모노레포 지원)

```
<project-root>/
├── CLAUDE.md                    ← 루트 지침 (항상 로딩)
├── packages/
│   ├── frontend/
│   │   └── CLAUDE.md            ← frontend 작업 시 lazy-load
│   ├── backend/
│   │   └── CLAUDE.md            ← backend 작업 시 lazy-load
│   └── shared/
│       └── CLAUDE.md            ← shared 작업 시 lazy-load
```

**작동 방식**: 하위 디렉터리의 CLAUDE.md는 Claude가 해당 디렉터리의 파일을 읽거나 편집할 때 **lazy-load**된다. 세션 시작 시 자동으로 로딩되지 않는다. 이를 통해 모노레포에서 패키지별로 독립적인 지침을 유지하면서도 토큰 낭비를 방지할 수 있다.

#### 2.3.2 `.claude/settings.json` — 프로젝트 설정

**역할**: 팀이 Git으로 공유하는 프로젝트 설정. 권한, 환경 변수, 훅(hooks) 구성을 포함한다.

**전체 필드 스키마**:

```jsonc
{
  // 프로젝트에서 자동 허용/차단할 도구 패턴
  "permissions": {
    "allow": [
      "Bash(node --check *)",
      "Bash(npm run check:*)",
      "Bash(npm test)",
      "Bash(npx jest *)"
    ],
    "deny": [
      "Bash(npm install *)",    // 의존성 추가는 사용자 승인 필요
      "Bash(npm publish *)"     // 배포는 CI/CD에서만
    ],
    "ask": [
      "Bash(git push *)"        // push는 매번 확인
    ]
  },

  // 프로젝트 환경 변수
  "env": {
    "NODE_ENV": "development",
    "TEST_PORT": "4000"
  },

  // 훅 설정: 도구 실행 전후에 자동 실행되는 명령
  "hooks": {
    // 도구 실행 전에 실행
    "PreToolUse": [
      {
        "matcher": "Write|Edit",    // Write 또는 Edit 도구 사용 시
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/ownership-guard.sh"
          }
        ]
      }
    ],
    // 도구 실행 후에 실행
    "PostToolUse": [
      {
        "matcher": "Bash",           // Bash 도구 사용 후
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/quality-gate.sh"
          }
        ]
      }
    ],
    // 에이전트 중단 시 실행
    "Stop": [
      {
        "matcher": "",               // 항상 실행
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-handoff.sh"
          }
        ]
      }
    ]
  }
}
```

**훅(Hooks) 이벤트 유형**:

| 이벤트 | 시점 | 용도 예시 |
|--------|------|-----------|
| `PreToolUse` | 도구 실행 **전** | 파일 소유권 검증, 위험 명령 차단, lint 실행 |
| `PostToolUse` | 도구 실행 **후** | 품질 게이트, 빌드 검증, 테스트 실행 |
| `Notification` | 알림 발생 시 | 외부 시스템 연동, 로깅 |
| `Stop` | 에이전트 중단 시 | 세션 핸드오프 문서 업데이트, 정리 작업 |

**훅 matcher 패턴**:
- `"Write|Edit"`: Write 또는 Edit 도구에 매칭
- `"Bash"`: Bash 도구에 매칭
- `""` (빈 문자열): 모든 도구에 매칭
- 정규표현식 패턴 지원

**훅 실행 결과 처리**:
- 훅이 비정상 종료(exit code != 0)하면, 해당 도구 실행이 차단될 수 있다 (PreToolUse의 경우)
- 훅의 stdout 출력은 Claude에게 피드백으로 전달된다
- 훅의 stderr 출력은 사용자에게 경고로 표시된다

#### 2.3.3 `.claude/rules/*.md` — 프로젝트 규칙

**역할**: 프로젝트별 모듈식 규칙. User 스코프의 rules와 동일한 형식이지만 프로젝트에 특화된다.

**특성**:
- 하위 디렉터리로 재귀적 구성 가능: `.claude/rules/server/*.md`, `.claude/rules/client/*.md` 등
- 항상 적용(프론트매터 없음)과 경로 기반(`paths:` 프론트매터)을 혼용 가능
- Git으로 팀 전원에게 공유됨

**항상 적용 규칙 예시**:

```markdown
# Testing Policy

## Unit Tests
- Every new function must have corresponding unit test
- Test file naming: `*.test.ts` or `*.spec.ts`
- Minimum 80% branch coverage for new code

## Integration Tests
- API endpoints require integration test
- Use test database, never production
```

**경로 기반 규칙 예시**:

```markdown
---
paths:
  - "server.js"
  - "server/**/*.js"
  - "shared/**/*.js"
---

# Server Verification

After editing server files:
1. Run `node --check server.js`
2. Game-critical changes: `npm run check:phase12`
3. Server is authoritative for game logic — client is display only
```

#### 2.3.4 `.claude/skills/*/SKILL.md` — 프로젝트 스킬

**역할**: 프로젝트에 특화된 도메인 전문 지식 캡슐. 팀원 전원이 동일한 스킬을 사용할 수 있도록 Git으로 공유된다.

**형식**: YAML 프론트매터(`name`, `description` 필수) + Markdown 본문

```markdown
---
name: tech-lead
description: Architecture decisions, state ownership, dependency review
---

# Tech Lead Skill

## Goal
Smallest technical design that keeps the project shippable.

## Focus
- State boundaries: who owns what data
- Dependency discipline: minimal external libs
- Risk reduction: identify irreversible decisions early

## Workflow
1. Identify state boundary (server vs client)
2. Prefer simple infrastructure over clever abstractions
3. Call out the next irreversible decision
4. Define verification command

## Output Contract
- Architecture recommendation with rationale
- Affected files list
- Risk assessment
- Verification method (executable command)

## Guardrails
- No heavy frameworks without user approval
- Keep concerns isolated from core logic
```

---

### 2.4 Local Scope (개인 프로젝트)

#### 위치

```
<project-root>/
├── CLAUDE.local.md              ← 개인 프로젝트 지침 (gitignored)
└── .claude/
    └── settings.local.json      ← 개인 프로젝트 설정 (gitignored)
```

#### 핵심 특성

1. **자동 gitignore**: `CLAUDE.local.md`와 `.claude/settings.local.json`은 Claude Code가 `.gitignore`에 자동으로 추가한다. 팀원에게 보이지 않는다.

2. **최고 우선순위**: Local 스코프는 4-Tier 계층에서 가장 높은 override 우선순위를 가진다. 스칼라 값(model, defaultMode 등)은 Local이 모든 상위 스코프를 덮어쓴다.

3. **배열 값은 병합**: `permissions.allow` 같은 배열 필드는 상위 스코프와 **병합**된다. Local의 allow 목록이 Project/User의 allow 목록에 **추가**된다 (대체하지 않음).

#### 2.4.1 `CLAUDE.local.md` — 개인 프로젝트 지침

**역할**: 특정 프로젝트에서 본인만 적용하는 개인 지침. 응답 언어, 현재 집중 영역, 개인 디버깅 단축키 등을 기록한다.

**기재해야 할 내용**:
- 응답 언어 선호 (예: "한국어로 응답해 주세요")
- 현재 담당/집중 영역 (예: "현재 netcode 모듈 담당 중")
- 개인 디버깅 도구 및 워크플로우
- 팀 규칙에 대한 개인적 보충 (팀 규칙을 위반하지 않는 범위에서)

**예시**:

```markdown
# My Preferences

## Response Style
- 한국어로 응답해 주세요
- 코드 변경 후 요약을 생략해 주세요
- diff만 보여주면 됩니다

## My Focus Areas
- 현재 netcode 모듈 담당 중
- server/transport/ 디렉터리 위주로 작업

## Debug Shortcuts
- 테스트 시 `npm run dev:debug` 사용
- Chrome DevTools 포트: 9229
```

#### 2.4.2 `.claude/settings.local.json` — 개인 프로젝트 설정

**역할**: 팀 설정(`settings.json`)을 건드리지 않고 개인 도구 권한, MCP 서버, 환경 변수를 추가한다.

**전체 필드 스키마**: `settings.json`과 동일한 스키마를 사용한다. 여기에 설정된 값은 프로젝트 `settings.json`과 병합(배열) 또는 override(스칼라)된다.

**예시**:

```jsonc
{
  "permissions": {
    "allow": [
      "Bash(npm run dev:debug)",
      "Bash(chrome-devtools *)",
      "mcp__context-mode__*"           // 개인 MCP 서버 도구 허용
    ]
  },
  "env": {
    "DEBUG": "co-optris:*",
    "NODE_OPTIONS": "--inspect=9229"
  }
}
```

**주의사항**:
- Local의 `permissions.deny`에 추가한 항목도 절대적이다. 팀 `settings.json`의 `allow`로 해제 불가하다.
- 그러나 Local의 `permissions.allow`는 상위 스코프의 `deny`를 해제할 수 없다. `deny`는 항상 우선한다.

---

