<!-- File: 02-composition-rules.md | Source: architecture-report Section 3 -->
## SECTION 3: 설정 합성(Composition) 규칙 완전 명세

### 3.1 CLAUDE.md 합성

#### 로딩 순서

세션이 시작되면 Claude Code 클라이언트는 다음 순서로 CLAUDE.md 계열 파일을 로딩하여 프롬프트 컨텍스트에 **연결(concatenation)**한다:

```
1. Managed CLAUDE.md         (/etc/claude-code/CLAUDE.md)
      ↓
2. User CLAUDE.md            (~/.claude/CLAUDE.md)
      ↓
3. User rules/*.md           (~/.claude/rules/*.md — 항상 적용 규칙)
      ↓
4. Project CLAUDE.md         (<root>/CLAUDE.md 또는 .claude/CLAUDE.md)
      ↓
5. Project rules/*.md        (.claude/rules/*.md — 항상 적용 규칙)
      ↓
6. Local CLAUDE.local.md     (<root>/CLAUDE.local.md)
```

**중요**: 위 순서에서 `경로 기반 규칙(paths: 프론트매터가 있는 rules)`과 `하위 디렉터리 CLAUDE.md`는 세션 시작 시 로딩되지 않는다. Claude가 해당 파일을 편집하거나 접근할 때 **온디맨드로 추가** 로딩된다.

#### 합성 방식

- **대체(Replace)가 아닌 연결(Concatenate)**: 모든 CLAUDE.md 파일이 하나의 긴 컨텍스트로 이어붙여진다. 하위 스코프의 파일이 상위 스코프의 파일을 "교체"하지 않는다.
- **충돌 해결**: 동일한 주제에 대해 상반되는 지침이 있을 때, **나중에 로딩된 것(더 구체적인 스코프)**이 우선한다. 이것은 LLM의 "recency bias"를 활용한 것이다 — 프롬프트 끝에 가까운 지침이 더 강하게 영향을 미친다.
- **토큰 영향**: 모든 파일이 합산되어 토큰을 소비한다. 파일이 많고 길수록 비용 증가, 준수율 저하.

#### 실전 예시: 충돌 시나리오

```markdown
# ~/.claude/CLAUDE.md (User)
## Response Style
- 영어로 응답해 주세요
```

```markdown
# CLAUDE.local.md (Local)
## Response Style
- 한국어로 응답해 주세요
```

**결과**: Claude는 한국어로 응답한다. Local(나중에 로딩됨)이 User를 override한다. 그러나 이것은 "best-effort"이므로 100% 보장은 아니다. 지침이 매우 길면 User의 "영어" 지침을 따를 수도 있다.

---

### 3.2 settings.json 합성

#### 배열 필드: 합집합(MERGE)

`permissions.allow`, `permissions.deny`, `permissions.ask`는 모든 스코프의 값을 합산한다.

```
최종 allow = Managed.allow ∪ User.allow ∪ Project.allow ∪ Local.allow
최종 deny  = Managed.deny  ∪ User.deny  ∪ Project.deny  ∪ Local.deny
최종 ask   = Managed.ask   ∪ User.ask   ∪ Project.ask   ∪ Local.ask
```

**예시**:

```jsonc
// ~/.claude/settings.json (User)
{ "permissions": { "allow": ["Bash(npm *)"] } }

// .claude/settings.json (Project)
{ "permissions": { "allow": ["Bash(node --check *)"] } }

// .claude/settings.local.json (Local)
{ "permissions": { "allow": ["Bash(npm run dev:debug)"] } }

// 최종 결과: allow = ["Bash(npm *)", "Bash(node --check *)", "Bash(npm run dev:debug)"]
```

#### 스칼라 필드: 구체적 스코프 우선(OVERRIDE)

`model`, `defaultMode`, `sandbox.enabled`, `autoMemoryEnabled` 등 단일 값 필드는 가장 구체적인 스코프(Local)가 우선한다.

```
최종 값 = Local ?? Project ?? User ?? Managed ?? 기본값
```

**예시**:

```jsonc
// ~/.claude/settings.json (User)
{ "model": "claude-sonnet-4-20250514" }

// .claude/settings.local.json (Local)
{ "model": "opus[1m]" }

// 최종 결과: model = "opus[1m]" (Local이 User를 override)
```

#### env 변수: Last-Write-Wins

환경 변수는 모든 스코프에서 수집된 후, 동일 키가 충돌하면 가장 구체적인 스코프의 값이 사용된다.

```jsonc
// managed-settings.json (Managed)
{ "env": { "HTTPS_PROXY": "http://proxy.corp:8080", "NODE_ENV": "production" } }

// ~/.claude/settings.json (User)
{ "env": { "NODE_ENV": "development" } }

// .claude/settings.json (Project)
{ "env": { "TEST_PORT": "4000" } }

// .claude/settings.local.json (Local)
{ "env": { "DEBUG": "app:*" } }

// 최종 결과:
// HTTPS_PROXY = "http://proxy.corp:8080"  (Managed에서만 설정)
// NODE_ENV    = "development"              (User가 Managed를 override)
// TEST_PORT   = "4000"                     (Project에서만 설정)
// DEBUG       = "app:*"                    (Local에서만 설정)
```

**주의**: Managed의 `HTTPS_PROXY`는 하위 스코프에서 같은 키로 override 가능하다. 이것은 `deny` 규칙과 다르다. 환경 변수에는 "절대 override 불가" 메커니즘이 없다. 조직이 프록시를 강제하려면 Managed의 `CLAUDE.md`에서 지침으로 보충하거나, OS 레벨 환경 변수를 사용해야 한다.

---

### 3.3 권한 평가 순서

#### 평가 알고리즘

Claude가 도구를 사용하려 할 때, 클라이언트는 다음 순서로 권한을 평가한다:

```
1. deny 목록 확인 (모든 스코프의 합집합)
   → 매칭되면: 즉시 차단. 종료.

2. ask 목록 확인 (모든 스코프의 합집합)
   → 매칭되면: 사용자에게 승인 요청. 사용자 결정에 따라 허용/차단.

3. allow 목록 확인 (모든 스코프의 합집합)
   → 매칭되면: 즉시 허용. 종료.

4. 어디에도 매칭되지 않으면:
   → defaultMode가 "auto"이면: 기본 허용 (일부 위험한 도구 제외)
   → defaultMode가 "normal"이면: 사용자에게 확인 요청
```

#### deny > ask > allow 원칙

```
┌──────────────────────────────────────────────┐
│  deny (최고 우선순위)                          │
│  모든 스코프에서 deny된 패턴은 절대 실행 불가   │
│  ← allow로 해제 불가                          │
├──────────────────────────────────────────────┤
│  ask (중간 우선순위)                           │
│  사용자에게 매번 확인 요청                      │
│  ← deny에 의해 차단될 수 있음                  │
│  ← allow보다 우선함                           │
├──────────────────────────────────────────────┤
│  allow (최저 우선순위)                         │
│  자동 허용                                    │
│  ← deny, ask에 의해 override됨               │
└──────────────────────────────────────────────┘
```

#### 실전 시나리오

**시나리오 1: Managed deny vs Local allow**

```jsonc
// managed-settings.json
{ "permissions": { "deny": ["Bash(sudo *)"] } }

// .claude/settings.local.json
{ "permissions": { "allow": ["Bash(sudo apt install *)"] } }
```

**결과**: `sudo apt install` 명령은 **차단**된다. Managed의 deny가 Local의 allow를 이긴다.

**시나리오 2: Project deny vs User allow**

```jsonc
// ~/.claude/settings.json
{ "permissions": { "allow": ["Bash(npm install *)"] } }

// .claude/settings.json
{ "permissions": { "deny": ["Bash(npm install *)"] } }
```

**결과**: `npm install` 명령은 **차단**된다. deny는 어떤 스코프에서 설정되든 allow보다 우선한다.

**시나리오 3: ask와 allow의 충돌**

```jsonc
// ~/.claude/settings.json
{ "permissions": { "allow": ["Bash(git push *)"] } }

// .claude/settings.json
{ "permissions": { "ask": ["Bash(git push *)"] } }
```

**결과**: `git push` 명령은 **사용자에게 확인을 요청**한다. ask가 allow보다 우선한다.

**시나리오 4: 동일 패턴이 deny와 ask에 동시 존재**

```jsonc
// 어떤 스코프
{ "permissions": { "deny": ["Bash(rm -rf *)"], "ask": ["Bash(rm -rf *)"] } }
```

**결과**: `rm -rf` 명령은 **차단**된다. deny가 ask보다 우선한다. 사용자에게 묻지도 않는다.

---

### 3.4 Rules 합성

#### 로딩 동작

| 규칙 유형 | 로딩 시점 | 우선순위 |
|-----------|-----------|----------|
| User always-apply (`~/.claude/rules/*.md`, 프론트매터 없음) | 세션 시작 | 낮음 (먼저 로딩) |
| Project always-apply (`.claude/rules/*.md`, 프론트매터 없음) | 세션 시작 | 높음 (나중 로딩) |
| User path-scoped (`~/.claude/rules/*.md`, `paths:` 있음) | 매칭 파일 접근 시 | 낮음 |
| Project path-scoped (`.claude/rules/*.md`, `paths:` 있음) | 매칭 파일 접근 시 | 높음 |

#### 합성 방식

- **누적(Cumulative)**: User rules와 Project rules가 모두 로딩된다. 서로를 대체하지 않는다.
- **실효 우선순위**: Project rules가 User rules보다 나중에 로딩되므로 더 강한 영향력을 가진다.
- **경로 기반 규칙의 효율성**: `paths`가 지정된 규칙은 매칭 파일이 접근될 때만 로딩되므로, 토큰 절약 효과가 크다. 서버 파일 편집 시 클라이언트 규칙이 로딩되지 않고, 그 반대도 마찬가지다.

#### 실전 예시: 동일 파일에 대한 중복 규칙

```markdown
<!-- ~/.claude/rules/sql-safety.md (User) -->
# SQL Safety
- Always use parameterized queries
```

```markdown
<!-- .claude/rules/sql-policy.md (Project) -->
---
paths:
  - "**/*.sql"
  - "db/**"
---

# SQL Policy
- All queries must go through the ORM layer
- Direct SQL is forbidden except in migration files
```

**결과**: `db/schema.sql`을 편집할 때 두 규칙 모두 로딩된다. User의 "parameterized queries" 규칙은 항상 적용 규칙이므로 세션 시작 시 이미 로딩되어 있고, Project의 "ORM layer" 규칙은 해당 파일 접근 시 추가로 로딩된다. 두 규칙이 상충하지 않으므로 Claude는 두 규칙을 모두 따른다. 상충하는 경우 Project(나중 로딩)가 우선한다.

---

