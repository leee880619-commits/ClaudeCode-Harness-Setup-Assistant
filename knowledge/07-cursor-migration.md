<!-- File: 07-cursor-migration.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 8 -->
## SECTION 8: Co-optris Cursor → Claude Code 완전 변환 명세

### 8.1 레이어 매핑 테이블

Co-optris 프로젝트의 Cursor 설정을 Claude Code로 완전 변환하기 위한 레이어별 매핑이다. 각 Cursor 레이어가 Claude Code의 어떤 요소에 대응하는지, 변환 시 주의 사항은 무엇인지 상세히 기술한다.

| Cursor 레이어 | Cursor 파일 | Claude Code 대응 | 변환 참고 사항 |
|---|---|---|---|
| **L1: 전역 사용자 설정** | Cursor User Settings UI (에디터 내 설정 패널) | `~/.claude/CLAUDE.md` + `~/.claude/rules/*.md` | Cursor는 GUI 기반 설정, Claude Code는 파일 기반. Cursor의 "Workflow 6-step" 같은 전역 워크플로우는 rules/ 파일로 분할하거나 스킬로 변환 |
| **L2: 프로젝트 규칙** | `.cursor/rules/*.mdc` (10개 파일) | `.claude/rules/*.md` | `.mdc` → `.md` 확장자 변경. `alwaysApply: true` → frontmatter 없음 (항상 적용). `globs: [패턴]` → `paths: [패턴]` YAML frontmatter |
| **L3: AGENTS.md** | `AGENTS.md`, `docs/AGENTS.md` | `CLAUDE.md`, `docs/CLAUDE.md` | 파일명만 변경. 내용은 그대로. 하위 디렉터리의 `AGENTS.md`도 동일하게 `CLAUDE.md`로 변경 |
| **L4: 에이전트 스킬** | `.agents/skills/*/SKILL.md` (6개) | `.claude/skills/*/SKILL.md` | 디렉터리 경로만 변경 (`.agents/` → `.claude/`). SKILL.md 내용은 동일 구조 유지. frontmatter에 Claude Code 전용 필드(`model`, `allowed_dirs` 등) 추가 가능 |
| **L5: 운영 문서** | `docs/operations/`, `docs/architecture/` | Auto Memory + `@import` | `session_handoff.md` → 자동 메모리 시스템이 대체. `code-map.md` → `@docs/architecture/code-map.md`로 CLAUDE.md에서 임포트. 운영 문서 자체는 그대로 유지 |
| **L6: 인프라** | `.cursor/mcp.json`, `.cursor/hooks.json` | `.claude/settings.json` (hooks 섹션) | Cursor의 분산된 설정 파일이 하나의 settings.json으로 통합. MCP 서버 설정은 별도 변환 필요 |

### 8.2 .mdc → .md 변환 규칙 상세

Co-optris 프로젝트의 10개 `.mdc` 규칙 파일을 각각 Claude Code `.md` 형식으로 변환한다. 각 파일의 원본 성격, 변환 방법, 결과물을 상세히 기술한다.

#### 규칙 1: context-mode.mdc → .claude/rules/context-mode.md

**원본 성격:** Always Apply. 컨텍스트 윈도우 관리 규칙. Claude가 토큰 사용량을 의식하고 불필요한 컨텍스트 로딩을 피하도록 지시.

**Cursor 원본 (`.cursor/rules/context-mode.mdc`):**

```markdown
---
alwaysApply: true
---

# Context Window Management

## Rules
1. Do not read entire large files — read only the relevant section
2. When searching, use targeted grep with specific patterns rather than broad scans
3. Summarize long outputs before including them in responses
4. Release context by not re-reading files already analyzed in this session
5. When context is running low, prioritize: current task > architecture > history
```

**변환 결과 (`.claude/rules/context-mode.md`):**

```markdown
# Context Window Management

## Rules
1. Do not read entire large files — read only the relevant section (use offset/limit parameters)
2. When searching, use targeted grep with specific patterns rather than broad scans
3. Summarize long outputs before including them in responses
4. Release context by not re-reading files already analyzed in this session
5. When context is running low, prioritize: current task > architecture > history
```

**변환 포인트:** `alwaysApply: true` → frontmatter 완전 제거. `.claude/rules/` 디렉터리의 파일은 frontmatter가 없으면 기본적으로 모든 파일에 적용(Always Apply)된다. 내용은 거의 동일하되, Claude Code의 Read 도구가 `offset`/`limit` 파라미터를 지원하므로 해당 힌트를 추가.

#### 규칙 2: workflow-skill-bindings.mdc → CLAUDE.md에 흡수

**원본 성격:** Always Apply. 스킬과 워크플로우 단계를 바인딩하는 매핑 테이블.

**변환 방법:** 독립 파일로 변환하지 않음. `CLAUDE.md`의 `@import` 참조와 스킬 설명 섹션에 흡수.

**CLAUDE.md에 추가되는 내용:**

```markdown
## Available Skills

Use `/skill-name` to invoke. Each skill handles a specific aspect of Co-optris development:

| Skill | Role | Scope |
|-------|------|-------|
| `/co-optris-tech-lead` | Architecture | State boundaries, dependency discipline, milestone sequencing |
| `/co-optris-gameplay` | Implementation | Board feel, playable slices, vertical slicing |
| `/co-optris-netcode` | Implementation | Room lifecycle, authoritative state, multiplayer protocol |
| `/co-optris-ux` | Implementation | HUD clarity, shared-board readability, ownership visibility |
| `/co-optris-qa-whitebox` | Verification | Static analysis, code review, gate tests, temp patch detection |
| `/co-optris-qa-blackbox` | Verification | Browser live test, feature/visual/interaction verification |
```

**변환 포인트:** Cursor에서는 `.mdc` 파일로 스킬 바인딩을 별도 관리했지만, Claude Code에서는 스킬 자체가 SKILL.md의 frontmatter(`name`, `description`)로 자기 서술적(self-describing)이므로 별도 바인딩 파일이 불필요. CLAUDE.md에 간단한 참조 테이블만 추가.

#### 규칙 3: agent-handoff-contracts.mdc → .claude/rules/handoff-contracts.md

**원본 성격:** Always Apply. 멀티 에이전트 간 핸드오프 시 출력 형식 요구 사항.

**변환 결과 (`.claude/rules/handoff-contracts.md`):**

```markdown
# Agent Handoff Contracts

## Output Requirements
When completing a task that another agent will continue, always produce:

1. **Summary**: 1-3 sentences of what was accomplished
2. **State file**: Update `docs/operations/_state.json` with:
   ```json
   {
     "lastAgent": "role-name",
     "timestamp": "ISO-8601",
     "phase": "current-phase",
     "completedTasks": ["task-1", "task-2"],
     "blockers": ["blocker-1"],
     "nextSteps": ["step-1", "step-2"]
   }
   ```
3. **Changed files**: List all modified files with one-line rationale each
4. **Open questions**: Any decisions deferred or ambiguities found

## Verification
Before handing off, run the project quality gate:
```bash
npm run check:phase12
```
Do not hand off if the quality gate fails.
```

**변환 포인트:** Always Apply이므로 frontmatter 없음. 내용은 거의 동일. Cursor의 핸드오프 계약은 Claude Code의 자동 메모리와 병행 사용 가능 — `_state.json`은 구조화된 데이터이고, 자동 메모리는 비구조화된 학습 데이터이므로 역할이 다르다.

#### 규칙 4: session-continuity.mdc → 자동 메모리 시스템으로 대체

**원본 성격:** Always Apply. 세션 간 연속성 유지를 위한 `session_handoff.md` 읽기/쓰기 규칙.

**변환 방법:** Claude Code의 자동 메모리 시스템이 이 기능을 완전히 대체하므로 별도 파일로 변환하지 않는다.

**대체 매핑:**

| Cursor session-continuity 기능 | Claude Code 대체 |
|---|---|
| 세션 시작 시 `session_handoff.md` 읽기 | 자동 메모리 MEMORY.md 인덱스 자동 로딩 |
| 세션 종료 시 `session_handoff.md` 갱신 | Stop hook + 자동 메모리 `type: project` 자동 갱신 |
| 진행 상황 추적 | `project_context.md` 토픽 파일 |
| 사용자 선호 기억 | `user_profile.md` 토픽 파일 |
| 교정 사항 기억 | `feedback_workflow.md` 토픽 파일 |

**변환 포인트:** 이것이 Cursor → Claude Code 전환에서 가장 큰 차이점이다. Cursor는 수동으로 세션 상태를 파일에 기록/읽기해야 하지만, Claude Code는 자동 메모리 시스템이 대화에서 중요한 정보를 추출하여 자동으로 관리한다. `docs/operations/session_handoff.md` 파일은 레거시로 남겨두되, 새 세션에서는 자동 메모리가 주 연속성 메커니즘이 된다.

#### 규칙 5: code-navigation.mdc → .claude/rules/code-navigation.md + @import

**원본 성격:** Always Apply. 코드 탐색 시 `code-map.md`를 참조하라는 지시.

**변환 결과 (`.claude/rules/code-navigation.md`):**

```markdown
# Code Navigation

@docs/architecture/code-map.md

## Navigation Rules
1. Before searching for a file, consult the code map above for directory structure
2. Use the code map to understand module boundaries — do not cross them without reason
3. When the code map is outdated (file not found), update it after completing your task
4. Key directories:
   - `server/` — Authoritative game logic (room management, board state, scoring)
   - `web/` — Client rendering, input handling, prediction interpolation
   - `shared/` — Types, constants, utilities shared by both server and web
   - `docs/` — Architecture decisions, game design, operations
```

**변환 포인트:** `@docs/architecture/code-map.md`를 사용하여 코드 맵을 인라인 임포트. Cursor에서는 규칙 본문에 "code-map.md를 읽어라"라는 지시만 있었지만, Claude Code에서는 `@import`로 실제 내용을 규칙 로딩 시 함께 포함시킬 수 있다.

#### 규칙 6: git-safety.mdc → .claude/rules/git-safety.md

**원본 성격:** Always Apply. Git 작업 시 안전 규칙.

**변환 결과 (`.claude/rules/git-safety.md`):**

```markdown
# Git Safety Rules

## Commit Rules
1. Never commit directly to main/master — always use feature branches
2. Commit messages follow Conventional Commits: `type(scope): description`
   - Types: feat, fix, refactor, test, docs, chore
   - Scope: server, web, shared, docs
3. Each commit should be atomic — one logical change per commit
4. Run `npm run check:phase12` before committing

## Branch Rules
1. Branch naming: `type/brief-description` (e.g., `feat/wall-kick`, `fix/score-sync`)
2. Keep branches short-lived — merge within 1-2 days

## Dangerous Commands — NEVER execute without explicit user approval:
- `git reset --hard`
- `git push --force`
- `git clean -fd`
- `git checkout .` (discards all changes)
- `git branch -D` (force delete branch)

## Rebase vs Merge
- Default: merge (preserves history)
- Rebase only when user explicitly requests it
```

**변환 포인트:** Always Apply이므로 frontmatter 없음. 이 규칙은 사용자 수준(`~/.claude/rules/git-safety.md`)에 배치하면 모든 프로젝트에 적용할 수 있다. 프로젝트별로 다른 Git 정책이 필요한 경우에만 프로젝트 수준(`.claude/rules/`)에 배치.

#### 규칙 7: test-port.mdc → .claude/rules/test-port.md

**원본 성격:** Always Apply. 테스트 포팅 관련 규칙 (기존 데스크톱 테스트를 웹 환경에 맞게 변환하는 지침).

**변환 결과 (`.claude/rules/test-port.md`):**

```markdown
# Test Porting Rules

## Principles
1. Every server-side game logic function must have a corresponding unit test
2. Tests are co-located: `server/game/board.js` → `server/game/board.test.js`
3. Use Node.js built-in `assert` module — no test framework dependencies in Phase 1
4. Test names describe behavior: `test_block_locks_after_delay`, not `test_lock`

## Porting from Desktop
When porting game logic from a desktop prototype:
1. Identify the core algorithm (ignore UI/rendering code)
2. Extract pure functions that take state and return new state
3. Write tests for the pure functions FIRST, then port the implementation
4. Verify identical behavior with same inputs/outputs as the prototype

## Test Organization
- `server/game/*.test.js` — Game logic unit tests
- `server/room/*.test.js` — Room management tests
- `shared/**/*.test.js` — Shared utility tests
- `test/integration/` — End-to-end server tests (Phase 2+)
```

#### 규칙 8: dependency-management.mdc → .claude/rules/dependency-management.md

**원본 성격:** Always Apply. 의존성 관리 정책.

**변환 결과 (`.claude/rules/dependency-management.md`):**

```markdown
# Dependency Management Rules

## Adding Dependencies
1. NEVER add a new npm package without explicit user approval
2. Before proposing a new dependency, demonstrate why existing tools are insufficient
3. Prefer Node.js built-in modules: `fs`, `path`, `http`, `assert`, `crypto`
4. When a dependency is approved, pin the exact version (no ^ or ~ prefix)

## Forbidden Patterns
- No frontend frameworks (React, Vue, Angular) — vanilla JS only
- No CSS frameworks (Bootstrap, Tailwind) — vanilla CSS only
- No build tools beyond what's already configured (no webpack, rollup, vite additions)
- No ORM libraries — use raw SQL or simple query builders if needed

## Auditing
- Run `npm audit` before committing any package.json change
- If `npm audit` reports high/critical vulnerabilities, resolve before proceeding

## Lockfile
- Always commit `package-lock.json` alongside `package.json` changes
- Never manually edit `package-lock.json`
```

#### 규칙 9: server-verification.mdc → .claude/rules/server-verification.md (경로 제한)

**원본 성격:** Glob 매칭 — `server.js`, `server/**/*.js` 파일을 편집할 때만 적용.

**Cursor 원본:**

```markdown
---
globs: ["server.js", "server/**/*.js"]
---

# Server Verification
After modifying any server file, run:
1. `node --check <modified-file>` for syntax verification
2. `npm run check:phase12` for project-level check
3. Verify server starts: `timeout 5 node server.js` (should not crash in 5 seconds)
```

**변환 결과 (`.claude/rules/server-verification.md`):**

```yaml
---
paths:
  - "server.js"
  - "server/**/*.js"
  - "shared/**/*.js"
---
```

```markdown
# Server Verification

After modifying any server or shared file, run:
1. `node --check <modified-file>` — Syntax verification for the specific file
2. `npm run check:phase12` — Project-level type and logic check
3. Verify server starts: `timeout 5 node server.js` — Should not crash within 5 seconds
4. If modifying shared/, also verify web client is not broken: `node --check web/app.js`
```

**변환 포인트:** Cursor의 `globs` → Claude Code의 `paths` YAML frontmatter. Glob 패턴 문법은 동일. `shared/**/*.js`를 추가하여 서버-클라이언트 공유 코드 변경 시에도 서버 검증이 트리거되도록 확장. 이 규칙은 `paths`에 지정된 파일이 편집 대상일 때만 Claude의 컨텍스트에 로딩된다.

#### 규칙 10: web-client.mdc → .claude/rules/web-client.md (경로 제한)

**원본 성격:** Glob 매칭 — `web/**/*.js`, `web/**/*.css` 파일을 편집할 때만 적용.

**Cursor 원본:**

```markdown
---
globs: ["web/**/*.js", "web/**/*.css"]
---

# Web Client Rules
1. No direct game state mutation — all state changes go through server messages
2. CSS animations use only transform and opacity (no layout triggers)
3. Test in Chrome DevTools: no console errors, 60fps in Performance tab
4. Accessibility: color contrast ratio ≥ 4.5:1, no color-only differentiation
```

**변환 결과 (`.claude/rules/web-client.md`):**

```yaml
---
paths:
  - "web/**/*.js"
  - "web/**/*.css"
  - "shared/**/*.js"
---
```

```markdown
# Web Client Rules

## State Management
1. No direct game state mutation — all state changes go through server messages
2. Client may maintain local prediction state, but server state always wins on reconciliation
3. Use `shared/protocol/messages.d.ts` types for all server communication

## Performance
1. CSS animations use only `transform` and `opacity` (no layout-triggering properties)
2. JavaScript animations must use `requestAnimationFrame`
3. Target: 60fps constant, <16ms frame budget

## Quality
1. Test in Chrome DevTools: no console errors, 60fps in Performance tab
2. Accessibility: color contrast ratio >= 4.5:1, no color-only differentiation
3. No `document.write`, `eval`, or inline event handlers (`onclick="..."`)

## Asset Management
1. Images in `web/assets/` — reference with relative paths
2. No external CDN links — all assets must be local
3. SVG preferred over raster images for UI elements
```

**변환 포인트:** `globs` → `paths`. `shared/**/*.js` 추가로 공유 코드 변경 시에도 웹 클라이언트 규칙이 활성화. 내용은 Cursor 원본을 보강하여 상태 관리, 성능, 품질, 자산 관리 섹션으로 구조화.

### 8.3 전체 변환 후 파일 트리

아래는 Co-optris 프로젝트의 Cursor → Claude Code 완전 변환 후 최종 파일 트리이다. 각 파일의 출처, 역할, 변환 유형을 주석으로 표기한다.

```
Co-optris/
├── CLAUDE.md                                          ← AGENTS.md에서 변환 (파일명만 변경)
│                                                         프로젝트 전체 규칙, @import 참조, 스킬 목록
│
├── CLAUDE.local.md                                    ← 신규 생성 (개인 설정)
│                                                         .gitignore에 추가. 개인별 API 키 경로,
│                                                         로컬 개발 환경 차이, 개인 작업 스타일 기록
│
├── .claude/
│   ├── settings.json                                  ← .cursor/hooks.json + .cursor/mcp.json 통합
│   │                                                     hooks 설정, permissions, MCP 서버 설정
│   │
│   ├── settings.local.json                            ← 신규 생성 (개인 추가 권한)
│   │                                                     .gitignore에 추가. 개인별 추가 도구 허용 등
│   │
│   ├── rules/                                         ← .cursor/rules/*.mdc에서 변환
│   │   ├── git-safety.md                              ← git-safety.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 커밋 규칙, 브랜치 규칙, 위험 명령 차단
│   │   │
│   │   ├── test-port.md                               ← test-port.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 테스트 포팅 원칙, 네이밍, 조직 구조
│   │   │
│   │   ├── dependency-management.md                   ← dependency-management.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 의존성 추가 승인 정책, 금지 패턴, 감사
│   │   │
│   │   ├── code-navigation.md                         ← code-navigation.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 @docs/architecture/code-map.md 임포트 포함
│   │   │
│   │   ├── handoff-contracts.md                       ← agent-handoff-contracts.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 멀티 에이전트 핸드오프 출력 형식
│   │   │
│   │   ├── context-mode.md                            ← context-mode.mdc (Always Apply → frontmatter 없음)
│   │   │                                                 컨텍스트 윈도우 관리 규칙
│   │   │
│   │   ├── server-verification.md                     ← server-verification.mdc (Glob → paths frontmatter)
│   │   │                                                 paths: ["server.js", "server/**/*.js", "shared/**/*.js"]
│   │   │                                                 서버 파일 수정 시에만 활성화
│   │   │
│   │   └── web-client.md                              ← web-client.mdc (Glob → paths frontmatter)
│   │                                                     paths: ["web/**/*.js", "web/**/*.css", "shared/**/*.js"]
│   │                                                     웹 클라이언트 파일 수정 시에만 활성화
│   │
│   ├── skills/                                        ← .agents/skills/*에서 변환 (디렉터리 경로만 변경)
│   │   ├── co-optris-tech-lead/
│   │   │   └── SKILL.md                               ← 아키텍처 결정, 상태 경계, 의존성 규율
│   │   │                                                 model: opus, role: tech-lead
│   │   │
│   │   ├── co-optris-gameplay/
│   │   │   └── SKILL.md                               ← 보드 감각, 플레이 가능 슬라이스, 수직 분할
│   │   │                                                 model: sonnet, role: gameplay
│   │   │
│   │   ├── co-optris-netcode/
│   │   │   └── SKILL.md                               ← 방 생명주기, 권위 상태, 멀티플레이어 프로토콜
│   │   │                                                 model: opus, role: netcode
│   │   │
│   │   ├── co-optris-ux/
│   │   │   └── SKILL.md                               ← HUD 명확성, 공유보드 가독성, 소유권 시각화
│   │   │                                                 model: sonnet, role: ux
│   │   │
│   │   ├── co-optris-qa-whitebox/
│   │   │   └── SKILL.md                               ← 정적 분석, 코드 리뷰, 게이트 테스트, 임시 패치
│   │   │                                                 model: sonnet, role: qa-whitebox
│   │   │
│   │   └── co-optris-qa-blackbox/
│   │       └── SKILL.md                               ← 브라우저 라이브 테스트, 기능/시각/상호작용 검증
│   │                                                     model: sonnet, role: qa-blackbox
│   │
│   └── hooks/                                         ← .cursor/hooks/*에서 변환
│       └── quality-gate.sh                            ← quality-gate.js → .sh 변환
│                                                         node --check + npm run check:phase12
│                                                         + 의존 방향 검증 (web/ → server/ 금지)
│
├── docs/
│   ├── CLAUDE.md                                      ← docs/AGENTS.md에서 변환 (파일명만 변경)
│   │                                                     docs/ 디렉터리 전용 규칙
│   │
│   ├── architecture/
│   │   └── code-map.md                                ← 그대로 유지
│   │                                                     .claude/rules/code-navigation.md에서 @import로 참조
│   │
│   ├── operations/
│   │   └── session_handoff.md                         ← 레거시 유지 (자동 메모리가 기능 대체)
│   │                                                     기존 내용 보존하되, 새 세션에서는 자동 메모리가 주 메커니즘
│   │
│   └── game-design/
│       └── master_plan.md                             ← 그대로 유지
│                                                         스킬의 requires에서 참조, CLAUDE.md에서 @import 가능
│
├── server/                                            ← 변경 없음 (코드 디렉터리)
├── web/                                               ← 변경 없음 (코드 디렉터리)
├── shared/                                            ← 변경 없음 (코드 디렉터리)
│
├── .gitignore                                         ← 다음 항목 추가:
│                                                         CLAUDE.local.md
│                                                         .claude/settings.local.json
│
└── (삭제 가능)
    ├── .cursor/                                       ← Claude Code 전환 완료 후 삭제 가능
    │   ├── rules/*.mdc                                  (백업 권장 후 삭제)
    │   ├── hooks.json
    │   └── mcp.json
    ├── .agents/                                       ← .claude/skills/로 이전 완료 후 삭제 가능
    │   └── skills/*/SKILL.md
    └── AGENTS.md                                      ← CLAUDE.md로 변환 완료 후 삭제 가능
         docs/AGENTS.md                                  (단, 다른 도구가 참조할 수 있으므로 주의)
```

**변환 체크리스트:**

1. `AGENTS.md` → `CLAUDE.md` (루트 + docs/)
2. `.cursor/rules/*.mdc` → `.claude/rules/*.md` (10개 파일)
3. `.agents/skills/*/SKILL.md` → `.claude/skills/*/SKILL.md` (6개 스킬)
4. `.cursor/hooks.json` → `.claude/settings.json` hooks 섹션
5. `.cursor/hooks/*.js` → `.claude/hooks/*.sh` (스크립트 변환)
6. `session_handoff.md` → 자동 메모리 시스템 (기능 대체, 파일 유지)
7. `.gitignore` 갱신 (CLAUDE.local.md, settings.local.json)
8. workflow-skill-bindings.mdc → CLAUDE.md 스킬 테이블에 흡수
9. session-continuity.mdc → 자동 메모리가 대체 (변환 불필요)
10. 원본 Cursor 파일 백업 후 삭제 (선택)

---

# Part 3: 파이프라인, 에이전트 설계 & 환경 진단

---

