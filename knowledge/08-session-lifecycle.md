<!-- File: 08-session-lifecycle.md | Source: architecture-report Section 9 -->
## SECTION 9: 세션 생명주기 — 파일 로딩 흐름 완전 명세

Claude Code 세션의 파일 로딩은 단순한 "설정 파일 읽기"가 아니다. **정확한 순서, 조건부 로딩, 동적 확장**이라는 세 축으로 구성된 정교한 파이프라인이며, 이 파이프라인을 정확히 이해하지 못하면 지침이 "왜 적용되지 않는지", "왜 충돌하는지"를 진단할 수 없다.

### 9.1 세션 시작 시 자동 로딩 (순서대로)

세션이 시작되면 아래 9단계가 **엄격한 순서대로** 실행된다. 각 단계는 이전 단계의 결과에 의존할 수 있으므로 순서가 보장된다.

#### 단계 1: Managed Policy (조직 강제 정책)

```
로딩 대상:
  /etc/claude-code/CLAUDE.md          — 전문(全文) 로딩, 크기 제한 없음
  /etc/claude-code/managed-settings.json    — 전문 로딩
  /etc/claude-code/managed-settings.d/*.json — 전문 로딩, 파일명 알파벳순
```

**특성:**
- **절대 제외 불가**: 사용자나 프로젝트 설정으로 무효화할 수 없음
- **최우선 적용**: 다른 모든 스코프보다 우선. Managed에서 `deny`한 것은 하위에서 `allow`해도 차단됨
- **로딩 실패 시**: 파일이 없으면 조용히 스킵 (에러 아님). JSON 파싱 실패 시 세션 시작 에러
- **`managed-settings.d/` 처리**: 디렉토리 내 `.json` 파일을 알파벳순으로 읽어 `managed-settings.json`과 병합. 동일 키가 있으면 나중 파일이 우선 (알파벳 후순위가 이김)

```
예시 로딩 순서:
  /etc/claude-code/managed-settings.json        ← 기본
  /etc/claude-code/managed-settings.d/00-base.json    ← 병합
  /etc/claude-code/managed-settings.d/10-security.json  ← 병합 (충돌 시 우선)
  /etc/claude-code/managed-settings.d/20-team-a.json   ← 병합 (충돌 시 최우선)
```

**개인 사용자 환경**: `/etc/claude-code/` 디렉토리 자체가 존재하지 않는 것이 정상. 이 단계는 완전히 스킵됨.

#### 단계 2: User-level CLAUDE.md (사용자 전역 지침)

```
로딩 대상:
  ~/.claude/CLAUDE.md — 전문 로딩
```

**특성:**
- 모든 프로젝트에 공통 적용되는 개인 지침
- @import 가능: 파일 내 `@path/to/file` 참조가 있으면 해당 파일도 로딩 (최대 5홉)
- **시스템 프롬프트에 직접 삽입**: `system-reminder` 메시지의 User Instructions 섹션에 포함됨
- 파일 없으면 조용히 스킵

**@import 처리 세부사항:**
```markdown
# ~/.claude/CLAUDE.md 예시

## 내 코딩 원칙
- 항상 한글 주석 사용
- 커밋 메시지는 한글로

@~/docs/my-git-conventions.md    ← 절대 경로 (홈 기준)
@./personal-rules.md             ← 상대 경로 (~/.claude/ 기준)
```

@import 체인:
1. `~/.claude/CLAUDE.md`가 `@A.md`를 참조
2. `A.md`가 `@B.md`를 참조
3. `B.md`가 `@C.md`를 참조
4. ... 최대 5홉까지 재귀적으로 해석
5. 5홉 초과 시 그 이후는 무시 (에러 아님, 경고만)

#### 단계 3: User-level Settings (사용자 전역 설정)

```
로딩 대상:
  ~/.claude/settings.json — 전문 로딩
```

**특성:**
- JSON 포맷 필수. 파싱 실패 시 세션 시작 에러
- `permissions`, `env`, `hooks`, `model` 등 설정
- Managed Policy와 병합: Managed의 `deny`가 User의 `allow`보다 우선
- 파일 없으면 기본값 사용

**병합 규칙 상세:**
```
Managed deny: ["Bash(rm -rf /*)"]
User allow:   ["Bash(rm -rf /*)"]   ← 이 항목은 무시됨 (Managed deny 우선)
User allow:   ["Bash(npm install)"]  ← 이 항목은 정상 적용

최종 결과:
  allow: ["Bash(npm install)"]
  deny:  ["Bash(rm -rf /*)"]
```

#### 단계 4: User-level Rules (사용자 전역 규칙)

```
로딩 대상:
  ~/.claude/rules/*.md — 조건부 로딩
```

**핵심 분기:**

```
파일에 YAML frontmatter가 있는가?
├── 없음 → always-apply 규칙 → 즉시 전문 로딩
├── 있지만 paths 키 없음 → always-apply 규칙 → 즉시 전문 로딩
└── 있고 paths 키 있음 → path-scoped 규칙 → 등록만 (로딩 안 함)
```

**"등록"의 의미:**
- 파일 존재와 `paths` 패턴이 내부 레지스트리에 기록됨
- 실제 파일 내용은 컨텍스트에 포함되지 않음 (토큰 소비 없음)
- 세션 중 Claude가 해당 패턴에 매칭되는 파일을 열거나 편집할 때 비로소 로딩됨

**always-apply 예시 (즉시 로딩):**
```markdown
# ~/.claude/rules/git-safety.md
(frontmatter 없음)

## Git 안전 규칙
- git push --force 금지
- main 브랜치 직접 커밋 금지
```

**path-scoped 예시 (등록만):**
```markdown
---
paths:
  - "**/*.py"
  - "scripts/**"
---

# Python 코딩 규칙
- type hints 필수
- docstring Google 스타일
```

#### 단계 5: Project CLAUDE.md (프로젝트 지침)

```
로딩 대상:
  현재 작업 디렉토리에서 루트까지 올라가며:
    각 디렉토리의 CLAUDE.md 또는 .claude/CLAUDE.md
```

**디렉토리 워크업 로직:**

현재 작업 디렉토리가 `/home/user/projects/myapp/src/components/`인 경우:

```
탐색 순서 (아래에서 위로):
1. /home/user/projects/myapp/src/components/CLAUDE.md
   /home/user/projects/myapp/src/components/.claude/CLAUDE.md
2. /home/user/projects/myapp/src/CLAUDE.md
   /home/user/projects/myapp/src/.claude/CLAUDE.md
3. /home/user/projects/myapp/CLAUDE.md              ← 보통 여기에 있음
   /home/user/projects/myapp/.claude/CLAUDE.md
4. /home/user/projects/CLAUDE.md                     ← monorepo라면 여기
   /home/user/projects/.claude/CLAUDE.md
5. /home/user/CLAUDE.md
   /home/user/.claude/CLAUDE.md
6. /home/CLAUDE.md
   /home/.claude/CLAUDE.md
7. /CLAUDE.md
   /.claude/CLAUDE.md
```

**탐색 종료 조건:**
- 파일시스템 루트(`/`)에 도달
- 또는 `.git` 디렉토리가 있는 수준 (Git 저장소 루트)에서 보통 멈춤

**다중 CLAUDE.md 처리:**
- 여러 레벨에서 CLAUDE.md가 발견되면 **모두 로딩**
- 상위 디렉토리의 것이 먼저 로딩 (더 일반적인 지침이 먼저)
- 하위 디렉토리의 것이 나중 로딩 (더 구체적인 지침이 보충)
- 충돌 시 하위가 우선 (specificity 원칙)

**@import 처리:**
```markdown
# /home/user/projects/myapp/CLAUDE.md

@docs/architecture/code-map.md          ← 프로젝트 루트 기준 상대 경로
@docs/game-design/master-plan.md        ← 동일
@../shared-lib/CLAUDE.md                ← 상위 디렉토리 참조 가능
```

각 @import는:
1. 경로 해석 (CLAUDE.md 위치 기준 상대 경로)
2. 파일 존재 확인
3. 파일 내용 로딩
4. 재귀적 @import 해석 (최대 5홉)
5. 최초 사용 시 사용자 승인 요청 (보안)

#### 단계 6: Project Settings (프로젝트 설정)

```
로딩 대상:
  <project-root>/.claude/settings.json — 전문 로딩
```

**특성:**
- Git 커밋 대상 (팀 공유)
- User Settings와 병합:
  - `allow` 배열: 합집합
  - `deny` 배열: 합집합
  - `hooks`: 병합 (동일 이벤트의 훅은 모두 실행)
  - `env`: 프로젝트가 유저를 덮어씀

**병합 예시:**
```json
// ~/.claude/settings.json (User)
{
  "permissions": {
    "allow": ["Bash(git *)"],
    "deny": ["Bash(rm -rf /*)"]
  }
}

// .claude/settings.json (Project)
{
  "permissions": {
    "allow": ["Bash(npm run *)"],
    "deny": ["Bash(sudo *)"]
  }
}

// 최종 병합 결과
{
  "permissions": {
    "allow": ["Bash(git *)", "Bash(npm run *)"],
    "deny": ["Bash(rm -rf /*)", "Bash(sudo *)"]
  }
}
```

#### 단계 7: Project Rules (프로젝트 규칙)

```
로딩 대상:
  <project-root>/.claude/rules/*.md — 조건부 로딩
```

단계 4(User Rules)와 동일한 분기 로직:
- frontmatter 없음 / `paths` 없음 → always-apply → 즉시 로딩
- `paths` 있음 → path-scoped → 등록만

**User Rules와의 관계:**
- User Rules와 Project Rules가 모두 always-apply이면 둘 다 로딩
- 동일 주제에 대해 충돌하면 Project Rules가 우선 (더 구체적)
- 하지만 실제로는 "충돌"이 아니라 "보충"으로 작동하는 것이 정상

#### 단계 8: Local Overrides (개인 로컬 오버라이드)

```
로딩 대상:
  <project-root>/CLAUDE.local.md           — 전문 로딩
  <project-root>/.claude/settings.local.json — 전문 로딩
```

**특성:**
- `.gitignore`에 포함되어야 함 (개인용, 커밋 금지)
- `CLAUDE.local.md`: Project CLAUDE.md에 대한 개인 보충/오버라이드
- `settings.local.json`: Project settings.json에 대한 개인 보충/오버라이드
- 병합 시 Local이 Project보다 우선 (마지막에 적용되므로)

**settings.local.json 병합 세부:**
```json
// .claude/settings.json (Project, 팀 공유)
{
  "permissions": {
    "allow": ["Bash(npm run *)"],
    "deny": ["Bash(sudo *)"]
  }
}

// .claude/settings.local.json (개인)
{
  "permissions": {
    "allow": ["Bash(sudo apt-get install *)"]  // sudo 중 apt-get만 개인 허용
  }
}

// 최종: deny에 sudo * 있지만, allow에 sudo apt-get install * 추가
// 구체적 allow가 일반적 deny보다 우선하므로 apt-get install만 허용됨
```

**주의 — `~/.claude/settings.local.json`은 비표준:**
- Claude Code 공식 스코프에서 **유저 레벨의 local 설정 파일은 존재하지 않음**
- `settings.local.json`은 **프로젝트 레벨(`.claude/settings.local.json`)에서만 유효**
- `~/.claude/settings.local.json`에 파일이 있어도 **공식적으로 로딩되지 않을 가능성이 높음**
- 이 위치에 파일이 있다면 의도치 않은 구성이므로 `settings.json`으로 통합해야 함

#### 단계 9: Auto Memory (자동 메모리)

```
로딩 대상:
  ~/.claude/projects/<project-hash>/memory/MEMORY.md — 처음 200줄 또는 25KB
```

**특성:**
- Auto Memory 기능이 활성화된 경우에만 로딩
- `MEMORY.md`는 인덱스 파일: 토픽 목록과 각 토픽 파일의 경로/요약을 포함
- 인덱스 전체가 아닌 **처음 200줄 또는 25KB** 중 먼저 도달하는 제한까지만 로딩
- 토픽 파일(`memory/<topic>.md`)은 이 시점에서 로딩되지 않음 (on-demand)

**프로젝트 해시:**
- 프로젝트 경로를 기반으로 결정론적 해시 생성
- 같은 경로의 프로젝트는 항상 같은 메모리 디렉토리 사용
- 예: `/home/user/projects/myapp` → `~/.claude/projects/abc123def/memory/`

---

### 9.1.1 전체 로딩 순서 요약 다이어그램

```
세션 시작
  │
  ├─[1] /etc/claude-code/CLAUDE.md ─────────────────── Managed (불변)
  ├─[1] /etc/claude-code/managed-settings.json ──────── Managed (불변)
  ├─[1] /etc/claude-code/managed-settings.d/*.json ──── Managed (불변)
  │
  ├─[2] ~/.claude/CLAUDE.md ─────────────────────────── User 지침
  │      └── @import → 참조 파일들 (최대 5홉)
  │
  ├─[3] ~/.claude/settings.json ─────────────────────── User 설정
  │
  ├─[4] ~/.claude/rules/*.md ────────────────────────── User 규칙
  │      ├── always-apply → 즉시 로딩
  │      └── path-scoped → 등록만 ─── [대기: 매칭 파일 접근 시 로딩]
  │
  ├─[5] 디렉토리 워크업 CLAUDE.md ───────────────────── Project 지침
  │      ├── 각 레벨의 CLAUDE.md 또는 .claude/CLAUDE.md
  │      └── @import → 참조 파일들 (최대 5홉)
  │
  ├─[6] .claude/settings.json ──────────────────────── Project 설정
  │
  ├─[7] .claude/rules/*.md ─────────────────────────── Project 규칙
  │      ├── always-apply → 즉시 로딩
  │      └── path-scoped → 등록만 ─── [대기: 매칭 파일 접근 시 로딩]
  │
  ├─[8] CLAUDE.local.md ────────────────────────────── Local 오버라이드
  ├─[8] .claude/settings.local.json ─────────────────── Local 설정
  │
  └─[9] ~/.claude/projects/<hash>/memory/MEMORY.md ── Auto Memory 인덱스
         (처음 200줄 / 25KB)

  ══════════════════════════════════════════════════════
  세션 준비 완료. 첫 번째 사용자 메시지 대기.
```

### 9.2 세션 중 동적 로딩 (On-Demand)

세션 시작 후에도 새로운 파일이 컨텍스트에 추가될 수 있다. 이는 **토큰 효율성**을 위한 설계 — 필요하지 않은 지침을 미리 로딩하여 컨텍스트를 낭비하지 않는다.

#### 9.2.1 Path-Scoped Rules 활성화

**트리거 조건:**
Claude가 `Read`, `Edit`, `Write` 도구를 사용하여 파일에 접근할 때, 해당 파일 경로가 등록된 path-scoped 규칙의 `paths` 패턴과 매칭되면 해당 규칙이 로딩됨.

```
등록된 규칙: .claude/rules/server-verification.md
  paths: ["server/**/*.js", "server/**/*.ts"]

Claude 행동: Read("server/modes/coop.js")

매칭 확인: "server/modes/coop.js" matches "server/**/*.js" → YES

결과: server-verification.md 전문이 컨텍스트에 로딩됨
```

**매칭 시점:**
- `Read` 도구로 파일을 읽을 때
- `Edit` 도구로 파일을 수정할 때
- `Write` 도구로 파일을 작성할 때
- `Bash` 도구에서 파일을 직접 참조하는 경우는 **트리거되지 않음** (예: `cat file.js`는 Read 도구가 아님)

**다중 매칭:**
하나의 파일이 여러 규칙의 패턴에 매칭되면 해당하는 모든 규칙이 로딩됨:

```
server/modes/coop.js 접근 시:
  → server-verification.md (paths: ["server/**/*.js"]) ← 로딩
  → game-logic.md (paths: ["server/modes/**"]) ← 로딩
  → general-js.md (paths: ["**/*.js"]) ← 로딩
```

**한 번 로딩되면:**
- 세션이 끝날 때까지 컨텍스트에 유지됨
- 다시 제거되지 않음 (단방향 로딩)
- 같은 규칙이 두 번 로딩되지 않음 (중복 방지)

#### 9.2.2 하위 디렉토리 CLAUDE.md 발견

**트리거 조건:**
Claude가 세션 시작 시 워크업에서 발견하지 못한 하위 디렉토리의 파일을 읽을 때, 해당 디렉토리에 `CLAUDE.md`가 있으면 발견 및 로딩됨.

```
세션 시작 시 cwd: /project/
워크업으로 발견: /project/CLAUDE.md ✓

세션 중 Claude가 /project/packages/auth/ 의 파일을 읽음
→ /project/packages/auth/CLAUDE.md 발견
→ 로딩 (하위 패키지 전용 지침)
```

**이것은 monorepo에서 특히 중요:**
```
/monorepo/
  CLAUDE.md                    ← 세션 시작 시 로딩
  packages/
    frontend/
      CLAUDE.md                ← frontend 파일 접근 시 발견/로딩
    backend/
      CLAUDE.md                ← backend 파일 접근 시 발견/로딩
    shared/
      CLAUDE.md                ← shared 파일 접근 시 발견/로딩
```

#### 9.2.3 Memory Topic Files 접근

**트리거 조건:**
Claude가 현재 작업과 관련된 메모리 토픽이 있다고 판단할 때, `Read` 도구를 사용하여 토픽 파일을 읽음.

```
MEMORY.md 인덱스 (세션 시작 시 로딩됨):
  ## Topics
  - [project_context](project_context.md) — 프로젝트 아키텍처 결정 사항
  - [feedback_workflow](feedback_workflow.md) — 사용자 피드백 반영 이력
  - [api_patterns](api_patterns.md) — API 설계 패턴

사용자 요청: "새로운 API 엔드포인트 추가해줘"

Claude 판단: "api_patterns" 토픽이 관련됨
→ Read("~/.claude/projects/<hash>/memory/api_patterns.md")
→ 토픽 내용이 컨텍스트에 로딩됨
```

**자동이 아닌 능동적 결정:**
- Claude가 인덱스를 보고 "이 토픽이 필요하다"고 판단해야 함
- 모든 토픽이 자동으로 로딩되지 않음
- 인덱스의 설명(description)이 좋을수록 Claude의 판단이 정확함

#### 9.2.4 @import 대상 파일 로딩

**트리거 조건:**
CLAUDE.md 내의 `@path` 참조가 처리될 때.

```markdown
# CLAUDE.md
@docs/architecture/code-map.md
```

**최초 사용 시 흐름:**
1. CLAUDE.md 파싱 중 `@docs/architecture/code-map.md` 발견
2. 파일 경로 해석 (CLAUDE.md 위치 기준)
3. 파일 존재 확인
4. 사용자 승인 요청 ("이 파일을 참조해도 되는지 확인")
5. 승인 시 파일 내용 로딩
6. 로딩된 파일 내에 @import가 있으면 재귀 처리 (5홉 제한)

**두 번째 이후:**
- 이미 승인된 @import는 재승인 없이 로딩
- 세션 내에서는 캐시됨

#### 9.2.5 Skills 로딩

**트리거 조건:**
- 사용자가 Skill 도구를 명시적으로 호출할 때
- Claude가 현재 작업에 특정 스킬이 필요하다고 판단할 때
- CLAUDE.md에서 특정 작업에 대해 스킬을 참조하도록 지시한 경우

```
사용자: "네트워크 코드 분석해줘"

Claude 판단: co-optris-netcode 스킬이 관련됨
→ Read(".claude/skills/co-optris-netcode/SKILL.md")
→ 스킬 내용이 컨텍스트에 로딩됨
→ 스킬의 지침에 따라 작업 수행
```

**Deferred Tool과의 관계:**
- 스킬은 `system-reminder`에 deferred tool로 등록됨
- 이름만 노출되고 전체 스키마는 로딩되지 않음
- Claude가 스킬이 필요하다고 판단하면 `ToolSearch`로 스키마를 가져온 후 호출
- 호출 시 SKILL.md의 내용이 컨텍스트에 주입됨

### 9.3 세션 종료 시

#### 9.3.1 Auto Memory 업데이트

세션이 종료될 때 Claude는 세션에서 학습한 내용을 메모리에 기록할 수 있다.

**업데이트 대상:**
```
~/.claude/projects/<hash>/memory/
  MEMORY.md          ← 인덱스 업데이트 (새 토픽 추가, 기존 토픽 설명 수정)
  <topic>.md         ← 토픽 파일 업데이트 (새 정보 추가, 오래된 정보 수정)
  <new-topic>.md     ← 새 토픽 파일 생성 (새로운 주제 발생 시)
```

**업데이트 조건:**
- 세션 중 유의미한 새 정보가 발생한 경우
- 사용자가 아키텍처 결정을 한 경우
- 사용자가 선호하는 패턴이나 규칙을 명시한 경우
- 이전 메모리의 내용이 더 이상 유효하지 않은 경우

**업데이트 프로세스:**
1. 세션 중 축적된 "기억할 만한" 정보 식별
2. 기존 MEMORY.md 인덱스 확인
3. 관련 토픽 파일이 있으면 해당 파일에 추가/수정
4. 관련 토픽이 없으면 새 토픽 파일 생성 + 인덱스 업데이트
5. 인덱스 설명 업데이트

#### 9.3.2 세션 종료 시 수행되지 않는 것들

- **설정 파일 자동 수정 없음**: `settings.json`, `settings.local.json` 등은 자동으로 수정되지 않음
- **CLAUDE.md 자동 수정 없음**: 프로젝트 지침은 사용자 명시적 요청 없이 수정하지 않음
- **규칙 파일 자동 수정 없음**: `.claude/rules/`의 파일은 자동으로 수정되지 않음
- **Cursor와의 차이**: Cursor의 `session-continuity.mdc`는 세션 종료 시 `handoff-*.md` 파일 생성을 의무화했지만, Claude Code의 Auto Memory는 이를 자동화하므로 별도 핸드오프 파일이 불필요

```
Cursor 방식 (수동):
  세션 종료 → session-continuity.mdc 지침 → handoff-20260416.md 생성 → 다음 세션에서 수동 로딩

Claude Code 방식 (자동):
  세션 종료 → Auto Memory가 자동으로 판단 → MEMORY.md + topic files 업데이트
                                          → 다음 세션에서 자동 로딩 (9.1 단계 9)
```

---

