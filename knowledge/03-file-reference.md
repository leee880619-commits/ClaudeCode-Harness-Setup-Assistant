<!-- File: 03-file-reference.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 4 -->
## SECTION 4: 모든 파일의 완전 명세 (File-by-File Reference)

### 4.1 `/etc/claude-code/CLAUDE.md` (Managed 지침)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | Linux/WSL: `/etc/claude-code/CLAUDE.md`<br>macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` |
| **형식** | Markdown |
| **로딩 시점** | 세션 시작 시 자동 (가장 먼저 로딩) |
| **생성 주체** | IT 관리자 / DevOps 팀 |
| **Git 공유 여부** | 아니오. OS 레벨 파일이므로 프로젝트 Git과 무관 |
| **필수/선택** | 선택. 없으면 무시됨 |
| **크기 권장** | 100줄 이하. 조직 정책을 간결하게 유지 |
| **claudeMdExcludes로 제외 가능** | **불가능** |
| **@import 지원** | 가능 |

**일반적 내용**: 조직 보안 정책, 코딩 표준, 데이터 처리 규칙, 라이선스 제한, 규정 준수 사항.

**흔한 실수**:
- 프로젝트별 세부 사항을 넣는 것 (→ 프로젝트 CLAUDE.md로 이동)
- 너무 길게 작성하여 모든 프로젝트의 토큰을 낭비하는 것
- 보안 차단을 CLAUDE.md에만 의존하는 것 (→ `managed-settings.json`의 deny로 보강 필수)

---

### 4.2 `/etc/claude-code/managed-settings.json` (Managed 설정)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | Linux/WSL: `/etc/claude-code/managed-settings.json`<br>macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`<br>Windows: `C:\Program Files\ClaudeCode\managed-settings.json` |
| **형식** | JSON (주석 불가. 엄격한 JSON) |
| **로딩 시점** | 세션 시작 시 자동 (가장 먼저 로딩) |
| **생성 주체** | IT 관리자 / DevOps 팀 |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택. 없으면 무시됨 |

**지원 필드**:

```jsonc
{
  "permissions": {
    "allow": ["..."],    // 조직 전체 자동 허용
    "deny": ["..."],     // 조직 전체 절대 차단 (override 불가!)
    "ask": ["..."]       // 조직 전체 확인 요청
  },
  "env": {               // 조직 환경 변수
    "KEY": "VALUE"
  }
}
```

**흔한 실수**:
- JSONC(주석 포함 JSON)로 작성하는 것. 표준 JSON만 지원된다. 주석이 필요하면 별도 문서로 관리할 것.
- `deny`에 너무 넓은 패턴(예: `"Bash(*)"`)을 넣어 Claude를 사실상 무력화하는 것.
- 파일 권한을 잘못 설정하여 Claude Code 프로세스가 읽지 못하는 것. 읽기 권한(644 이상) 필요.

---

### 4.3 `/etc/claude-code/managed-settings.d/*.json` (Managed 모듈식 설정)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | Linux/WSL: `/etc/claude-code/managed-settings.d/*.json`<br>macOS: `/Library/Application Support/ClaudeCode/managed-settings.d/*.json`<br>Windows: `C:\Program Files\ClaudeCode\managed-settings.d\*.json` |
| **형식** | JSON (엄격한 JSON, 주석 불가) |
| **로딩 시점** | 세션 시작 시 자동. **파일명 알파벳순**으로 로딩 |
| **생성 주체** | IT 관리자 / DevOps 팀 |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택. 디렉터리가 없어도 무시됨 |
| **managed-settings.json과의 관계** | 동일 필드 충돌 시 이 디렉터리의 파일이 이후에 적용됨 |

**파일명 정렬 전략**:
```
managed-settings.d/
├── 01-security.json       ← 보안 정책 (먼저 로딩)
├── 02-network.json        ← 네트워크 정책
├── 03-dev-standards.json  ← 개발 표준
└── 99-overrides.json      ← 최종 override (마지막 로딩)
```

숫자 접두사를 사용하면 로딩 순서를 명확하게 제어할 수 있다.

**흔한 실수**:
- 파일명 정렬 순서를 고려하지 않아 의도치 않은 override가 발생하는 것
- 서로 다른 부서가 같은 키를 설정하여 충돌이 발생하는 것

---

### 4.4 `~/.claude/CLAUDE.md` (User 전역 지침)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/CLAUDE.md` |
| **형식** | Markdown |
| **로딩 시점** | 세션 시작 시 자동 (Managed 다음) |
| **생성 주체** | 사용자 본인 (수동 작성) |
| **Git 공유 여부** | 아니오. 사용자 홈 디렉터리의 개인 파일 |
| **필수/선택** | 선택. 없으면 무시됨 |
| **크기 권장** | **200줄 이하** (길수록 준수율 저하) |
| **@import 지원** | 가능 |
| **claudeMdExcludes로 제외 가능** | 가능 (다른 사용자나 Managed에서 설정 시) |

**흔한 실수**:
- 프로젝트별 내용을 넣는 것 (모든 프로젝트에 불필요한 토큰 소비)
- 200줄을 크게 초과하는 것 (→ `~/.claude/rules/`로 분리할 것)
- `settings.json`에 넣어야 할 설정(모델, 권한 등)을 여기에 자연어로 적는 것

---

### 4.5 `~/.claude/settings.json` (User 전역 설정)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/settings.json` |
| **형식** | JSON |
| **로딩 시점** | 세션 시작 시 자동 |
| **생성 주체** | 사용자 본인 (수동 작성 또는 `/config` 명령으로 자동 생성) |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택. 없으면 기본값 사용 |

**전체 필드 명세**:

| 필드 | 타입 | 합성 방식 | 설명 |
|------|------|-----------|------|
| `model` | string | Override | 기본 모델. 예: `"opus[1m]"`, `"claude-sonnet-4-20250514"` |
| `env` | object | Last-write-wins (키별) | 환경 변수 |
| `permissions.allow` | string[] | Merge (합집합) | 자동 허용 도구 패턴 |
| `permissions.deny` | string[] | Merge (합집합) | 절대 차단 도구 패턴 |
| `permissions.ask` | string[] | Merge (합집합) | 매번 확인 도구 패턴 |
| `autoMemoryEnabled` | boolean | Override | 자동 메모리 on/off |
| `defaultMode` | string | Override | `"normal"` 또는 `"auto"` |
| `sandbox.enabled` | boolean | Override | 샌드박스 격리 |
| `claudeMdExcludes` | string[] | — | 제외할 CLAUDE.md 경로 패턴 |

**흔한 실수**:
- `permissions.allow`에 너무 광범위한 패턴(예: `"Bash(*)"`)을 넣어 보안 위험을 만드는 것
- JSON 구문 오류(trailing comma, 주석 등)로 파일 전체가 무시되는 것
- 파일이 UTF-8이 아닌 인코딩으로 저장되어 파싱 실패

---

### 4.6 `~/.claude/rules/*.md` (User 전역 규칙)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/rules/*.md` (모든 `.md` 파일) |
| **형식** | Markdown + 선택적 YAML 프론트매터 |
| **로딩 시점** | 항상 적용: 세션 시작 시 / 경로 기반: 매칭 파일 접근 시 |
| **생성 주체** | 사용자 본인 (수동 작성) |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택. 디렉터리가 없어도 무시됨 |
| **하위 디렉터리** | 지원하지 않음 (User rules는 1단계만) |

**YAML 프론트매터 형식**:

```yaml
---
paths:
  - "**/*.ts"
  - "src/**/*.tsx"
---
```

| 프론트매터 필드 | 타입 | 필수 | 설명 |
|----------------|------|------|------|
| `paths` | string[] | 선택 | 이 규칙이 적용될 파일 패턴. 없으면 항상 적용 |

**흔한 실수**:
- 프론트매터 구분자(`---`)를 빠뜨려서 YAML이 본문으로 파싱되는 것
- `paths` 패턴에 프로젝트 루트 기준 경로를 쓰지 않는 것
- 파일 확장자를 `.mdc`로 쓰는 것 (Cursor 형식. Claude Code는 `.md`만 인식)

---

### 4.7 `~/.claude/skills/*/SKILL.md` (User 전역 스킬)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/skills/<skill-name>/SKILL.md` |
| **형식** | YAML 프론트매터 + Markdown |
| **로딩 시점** | 슬래시 명령 호출 시 또는 트리거 조건 매칭 시 |
| **생성 주체** | 사용자 본인 (수동 작성) |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택 |

**YAML 프론트매터 필수 필드**:

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | 필수 | 스킬 이름 (슬래시 명령에 사용) |
| `description` | string | 필수 | 스킬 설명 (스킬 목록에 표시) |

**흔한 실수**:
- `SKILL.md`가 아닌 다른 파일명을 사용하는 것 (`skill.md`, `README.md` 등은 인식되지 않음)
- 디렉터리 구조를 `skills/SKILL.md`로 만드는 것 (반드시 `skills/<name>/SKILL.md` 2단계 구조)
- 프론트매터에 `name`이나 `description`을 빠뜨리는 것

---

### 4.8 `CLAUDE.md` (프로젝트 루트)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/CLAUDE.md` |
| **형식** | Markdown |
| **로딩 시점** | 세션 시작 시 자동 |
| **생성 주체** | 팀 (수동 작성 또는 `/init` 명령으로 자동 생성) |
| **Git 공유 여부** | **예** — 팀 전원이 동일한 지침을 공유 |
| **필수/선택** | 선택이지만, 사실상 모든 프로젝트에서 필수 |
| **크기 권장** | **200줄 이하**. 세부 규칙은 `.claude/rules/`로, 참조 문서는 `@import`로 분리 |
| **@import 지원** | 가능 |
| **HTML 주석 제거** | 가능 (블록 레벨 `<!-- -->` 주석은 컨텍스트에서 제거됨) |

**`.claude/CLAUDE.md`와의 관계**: 프로젝트 루트의 `CLAUDE.md`와 `.claude/CLAUDE.md`는 **양립 가능**하다. 둘 다 존재하면 둘 다 로딩된다. 일반적으로 하나만 사용하는 것을 권장한다:
- 프로젝트 루트의 `CLAUDE.md`: 가시성이 높고, 팀원이 쉽게 발견
- `.claude/CLAUDE.md`: 프로젝트 루트를 깔끔하게 유지

**흔한 실수**:
- 프로젝트 루트와 `.claude/` 양쪽에 모두 작성하여 중복/충돌 발생
- 기술 스택이나 아키텍처 설명 없이 규칙만 나열하는 것 (Claude에게 맥락 부족)
- `@import` 경로를 절대 경로로 작성하는 것 (→ 팀원마다 경로가 다름. 상대 경로 사용)
- `.gitignore`에 `CLAUDE.md`를 넣어 팀 공유가 안 되는 것

---

### 4.9 `.claude/CLAUDE.md` (프로젝트 .claude 디렉터리 내)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/CLAUDE.md` |
| **형식** | Markdown |
| **로딩 시점** | 세션 시작 시 자동 |
| **생성 주체** | 팀 |
| **Git 공유 여부** | **예** |
| **필수/선택** | 선택. 프로젝트 루트의 `CLAUDE.md`가 있으면 이 파일은 보충용 |
| **크기 권장** | 200줄 이하 |

**특기 사항**: 프로젝트 루트의 `CLAUDE.md`와 완전히 동일한 역할을 수행한다. 위치만 다르다. 프로젝트 루트를 깔끔하게 유지하고 싶은 팀에게 적합하다.

---

### 4.10 `.claude/settings.json` (프로젝트 설정)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/settings.json` |
| **형식** | JSON |
| **로딩 시점** | 세션 시작 시 자동 |
| **생성 주체** | 팀 (수동 작성 또는 `/update-config` 명령) |
| **Git 공유 여부** | **예** — 팀 전원에게 동일한 권한/환경/훅 적용 |
| **필수/선택** | 선택 |

**지원 필드**:

| 필드 | 타입 | 합성 방식 | 설명 |
|------|------|-----------|------|
| `permissions.allow` | string[] | Merge | 프로젝트 자동 허용 |
| `permissions.deny` | string[] | Merge | 프로젝트 절대 차단 |
| `permissions.ask` | string[] | Merge | 프로젝트 매번 확인 |
| `env` | object | Last-write-wins | 프로젝트 환경 변수 |
| `hooks` | object | — | PreToolUse, PostToolUse, Stop 등 훅 설정 |
| `model` | string | Override | 프로젝트 기본 모델 |

**흔한 실수**:
- `settings.local.json`에 넣어야 할 개인 설정을 여기에 커밋하는 것
- 민감한 환경 변수(API 키, 토큰)를 `env`에 넣고 Git에 커밋하는 것 (→ `.claude/settings.local.json`으로)
- `hooks` 경로에 로컬 절대 경로를 사용하는 것 (→ 상대 경로 사용)

---

### 4.11 `.claude/settings.local.json` (개인 프로젝트 설정)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/settings.local.json` |
| **형식** | JSON |
| **로딩 시점** | 세션 시작 시 자동 (가장 마지막에 적용) |
| **생성 주체** | 사용자 본인 |
| **Git 공유 여부** | **아니오** — 자동 gitignore |
| **필수/선택** | 선택 |

**역할**: 팀 `settings.json`에 개인 설정을 추가하거나 스칼라 값을 override한다. 팀 설정을 건드리지 않고 개인 환경을 구성하는 핵심 메커니즘이다.

**흔한 실수**:
- 이 파일을 Git에 커밋하려 시도하는 것 (자동 gitignore되어 있지만, force add 시 주의)
- 팀 `settings.json`의 `deny`를 이 파일의 `allow`로 해제하려 시도하는 것 (불가능)

---

### 4.12 `.claude/rules/*.md` (프로젝트 규칙)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/rules/*.md` |
| **형식** | Markdown + 선택적 YAML 프론트매터 |
| **로딩 시점** | 항상 적용: 세션 시작 시 / 경로 기반: 매칭 파일 접근 시 |
| **생성 주체** | 팀 |
| **Git 공유 여부** | **예** |
| **필수/선택** | 선택 |
| **하위 디렉터리** | **지원** (재귀적으로 탐색. 예: `rules/server/*.md`, `rules/client/auth/*.md`) |

**User rules와의 차이**:
- 프로젝트 규칙은 하위 디렉터리를 재귀적으로 탐색한다 (`rules/server/auth/jwt.md` 등)
- User 규칙은 1단계만 탐색한다 (`~/.claude/rules/*.md`)
- 프로젝트 규칙이 User 규칙보다 나중에 로딩되므로 실효 우선순위가 높다

**흔한 실수**:
- Cursor의 `.mdc` 확장자를 그대로 사용하는 것 (→ `.md`로 변환 필요)
- `alwaysApply: true` 프론트매터를 그대로 가져오는 것 (→ Claude Code에서는 프론트매터를 삭제하면 항상 적용)
- `glob:` 필드를 그대로 가져오는 것 (→ `paths:` 필드로 변환 필요)

---

### 4.13 `.claude/skills/*/SKILL.md` (프로젝트 스킬)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/skills/<skill-name>/SKILL.md` |
| **형식** | YAML 프론트매터 + Markdown |
| **로딩 시점** | 슬래시 명령 호출 시 또는 트리거 매칭 시 |
| **생성 주체** | 팀 |
| **Git 공유 여부** | **예** |
| **필수/선택** | 선택 |

**User skills와의 차이**:
- 프로젝트 스킬은 해당 프로젝트에서만 사용 가능
- 팀 전원이 동일한 스킬을 공유
- 동일 이름의 User 스킬과 Project 스킬이 있으면, Project 스킬이 우선

---

### 4.14a `~/.claude/agents/*.md` (User 전역 서브에이전트)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/agents/<agent-name>.md` |
| **형식** | YAML 프론트매터 + Markdown |
| **로딩 시점** | `Agent` 도구의 `subagent_type` 매칭 시 또는 Claude가 자동 선택 시 |
| **생성 주체** | 사용자 본인 (수동 작성) |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택 |

**YAML 프론트매터 필드**:

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | 필수 | 에이전트 식별자. `subagent_type` 값으로 사용 |
| `description` | string | 필수 | 에이전트 용도 설명. Claude가 자동 선택 시 참조 |
| `model` | string | 선택 | 에이전트 전용 모델. 미지정 시 부모 세션 모델 사용 |

**예시:**
```markdown
---
name: researcher
description: Use this agent when you need to research topics, search documentation, or analyze large codebases
model: claude-opus-4-6
---

You are a research specialist. Your job is to...
```

**Skills와의 핵심 차이**:

| 구분 | Skills (`skills/*/SKILL.md`) | Agents (`agents/*.md`) |
|------|------------------------------|------------------------|
| 실행 컨텍스트 | 메인 세션에 로드 (컨텍스트 공유) | 독립된 서브에이전트 (격리된 컨텍스트) |
| 호출 방식 | `/skill-name` 슬래시 명령 | `Agent(subagent_type: "name")` |
| 모델 | 메인 세션과 동일 | 별도 지정 가능 |
| 용도 | 워크플로우 지시사항, 절차 정의 | 전문화된 독립 작업자 |

**흔한 실수**:
- `name`을 빠뜨려 `subagent_type`으로 참조 불가한 것
- Skills과 혼동하여 슬래시 명령으로 호출하려 시도하는 것
- 에이전트 파일에 너무 긴 시스템 프롬프트를 넣는 것 (→ `@import`로 분리)

---

### 4.14b `<root>/.claude/agents/*.md` (프로젝트 서브에이전트)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/.claude/agents/<agent-name>.md` |
| **형식** | YAML 프론트매터 + Markdown |
| **로딩 시점** | `Agent` 도구의 `subagent_type` 매칭 시 또는 Claude가 자동 선택 시 |
| **생성 주체** | 팀 |
| **Git 공유 여부** | **예** |
| **필수/선택** | 선택 |

**User agents와의 차이**:
- 프로젝트 에이전트는 해당 프로젝트에서만 사용 가능
- 팀 전원이 동일한 에이전트 정의를 공유
- 동일 `name`의 User 에이전트와 Project 에이전트가 있으면, **Project 에이전트가 우선**

**Built-in 에이전트 타입** (별도 정의 없이 사용 가능):

| `subagent_type` | 특성 |
|----------------|------|
| `general-purpose` | 기본 범용 에이전트 |
| `Explore` | 코드베이스 탐색 전문. 쓰기 도구 없음 |
| `Plan` | 구현 계획 설계 전문 |

커스텀 에이전트는 이 built-in 타입을 **확장 또는 대체**할 수 있다.

---

### 4.14 `CLAUDE.local.md` (개인 프로젝트 지침)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `<project-root>/CLAUDE.local.md` |
| **형식** | Markdown |
| **로딩 시점** | 세션 시작 시 자동 (가장 마지막에 로딩) |
| **생성 주체** | 사용자 본인 |
| **Git 공유 여부** | **아니오** — 자동 gitignore |
| **필수/선택** | 선택 |
| **크기 권장** | 50줄 이하 (개인 보충 사항만) |
| **@import 지원** | 가능 |

**흔한 실수**:
- 팀 공유 규칙을 여기에 작성하는 것 (→ 프로젝트 `CLAUDE.md`로)
- 이 파일이 프로젝트 `CLAUDE.md`를 대체한다고 오해하는 것 (→ 연결됨. 대체가 아님)
- `.claude/` 디렉터리 안에 `CLAUDE.local.md`를 넣는 것 (→ 프로젝트 루트에 위치해야 함)

---

### 4.15 `~/.claude/projects/<project>/memory/MEMORY.md` (메모리 인덱스)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/projects/<project-hash>/memory/MEMORY.md` |
| **형식** | Markdown (Claude가 자동 생성·유지) |
| **로딩 시점** | 세션 시작 시 자동 (200줄 / 25KB 제한) |
| **생성 주체** | Claude (자동). 사용자가 수동 편집 가능 |
| **Git 공유 여부** | 아니오. 사용자 홈 디렉터리 |
| **필수/선택** | 선택. `autoMemoryEnabled: false`이면 생성되지 않음 |
| **크기 제한** | 200줄 또는 25KB (초과 시 잘림) |

**내용 구조**:

```markdown
---
# Auto Memory Index
---

- [User Profile](user_profile.md) — 기술 수준, 작업 스타일
- [Workflow Feedback](feedback_workflow.md) — 레드팀 피드백 규칙
- [Project Context](project_context.md) — 아키텍처 결정, 구현 상태
```

**`<project-hash>` 결정 방식**: 프로젝트 루트의 절대 경로를 기반으로 해시 또는 정규화된 디렉터리명이 생성된다. 동일 프로젝트를 다른 경로(`~/projects/myapp` vs `/tmp/myapp`)에서 열면 **별도의 메모리 디렉터리**가 생성된다.

**흔한 실수**:
- `MEMORY.md`를 직접 편집한 후 Claude가 다시 덮어쓰는 것에 놀라는 것 (→ Claude가 지속적으로 업데이트함)
- 메모리 인덱스에 200줄 이상의 내용을 수동으로 넣어 잘리는 것
- `autoMemoryEnabled: false`로 설정했는데 이미 존재하는 메모리가 여전히 읽히는 것에 혼동 (→ 읽기는 계속됨, 새 축적만 중단)

---

### 4.16 `~/.claude/projects/<project>/memory/*.md` (메모리 토픽 파일)

| 속성 | 값 |
|------|-----|
| **정확한 경로** | `~/.claude/projects/<project-hash>/memory/<topic>.md` |
| **형식** | Markdown (Claude가 자동 생성·유지) |
| **로딩 시점** | **온디맨드** — Claude가 필요할 때 Read 도구로 접근 |
| **생성 주체** | Claude (자동). 사용자가 수동 편집/추가 가능 |
| **Git 공유 여부** | 아니오 |
| **필수/선택** | 선택. Claude가 자동 생성 |
| **크기 제한** | 개별 파일에 크기 제한 없음. 단, MEMORY.md 인덱스의 200줄 제한은 적용 |

**일반적 토픽 파일 목록**:

| 파일명 | 내용 |
|--------|------|
| `user_profile.md` | 사용자의 역할, 기술 수준, 언어 선호 |
| `feedback_workflow.md` | 사용자 교정 사항 ("이렇게 하지 마", "이 방식이 좋다") |
| `project_context.md` | 아키텍처 결정, 현재 진행 상태, 마감 기한 |
| `reference_links.md` | 외부 시스템 포인터 (URL, 문서 경로) |

**MEMORY.md 인덱스와의 관계**:
- `MEMORY.md`는 세션 시작 시 자동 로딩되어 "어떤 토픽 파일이 있는지" Claude에게 알려준다
- Claude는 필요한 토픽을 `Read` 도구로 접근하여 상세 내용을 가져온다
- 세션 중 Claude가 새로운 학습을 하면 관련 토픽 파일을 업데이트하거나 새 토픽 파일을 생성한다
- 세션 종료 시 또는 중간에 `MEMORY.md` 인덱스도 업데이트된다

**흔한 실수**:
- 토픽 파일을 직접 삭제한 후 `MEMORY.md` 인덱스를 업데이트하지 않는 것 (→ Claude가 존재하지 않는 파일을 Read하려 시도)
- 토픽 파일에 프로젝트의 핵심 설정을 의존하는 것 (→ 메모리는 보조 수단. 핵심 설정은 CLAUDE.md와 settings.json에)

---

## 부록: 전체 파일 요약표

| # | 파일 | 스코프 | 유형 | 로딩 | Git | 생성자 |
|---|------|--------|------|------|-----|--------|
| 1 | `/etc/claude-code/CLAUDE.md` | Managed | Context | 시작 시 | N | IT |
| 2 | `/etc/claude-code/managed-settings.json` | Managed | Config | 시작 시 | N | IT |
| 3 | `/etc/claude-code/managed-settings.d/*.json` | Managed | Config | 시작 시 | N | IT |
| 4 | `~/.claude/CLAUDE.md` | User | Context | 시작 시 | N | 사용자 |
| 5 | `~/.claude/settings.json` | User | Config | 시작 시 | N | 사용자 |
| 6 | `~/.claude/rules/*.md` | User | Context | 시작 시/온디맨드 | N | 사용자 |
| 7 | `~/.claude/skills/*/SKILL.md` | User | Context | 트리거 시 | N | 사용자 |
| 8 | `~/.claude/agents/*.md` | User | Agent | 에이전트 소환 시 | N | 사용자 |
| 9 | `<root>/CLAUDE.md` | Project | Context | 시작 시 | **Y** | 팀 |
| 10 | `<root>/.claude/CLAUDE.md` | Project | Context | 시작 시 | **Y** | 팀 |
| 11 | `<root>/.claude/settings.json` | Project | Config | 시작 시 | **Y** | 팀 |
| 12 | `<root>/.claude/settings.local.json` | Local | Config | 시작 시 | N | 사용자 |
| 13 | `<root>/.claude/rules/*.md` | Project | Context | 시작 시/온디맨드 | **Y** | 팀 |
| 14 | `<root>/.claude/skills/*/SKILL.md` | Project | Context | 트리거 시 | **Y** | 팀 |
| 15 | `<root>/.claude/agents/*.md` | Project | Agent | 에이전트 소환 시 | **Y** | 팀 |
| 16 | `<root>/CLAUDE.local.md` | Local | Context | 시작 시 | N | 사용자 |
| 17 | `~/.claude/projects/<p>/memory/MEMORY.md` | Memory | Context | 시작 시 | N | Claude |
| 18 | `~/.claude/projects/<p>/memory/*.md` | Memory | Context | 온디맨드 | N | Claude |

> **범례**: 시작 시 = 세션 시작 시 자동 로딩 / 온디맨드 = 조건 충족 시 로딩 / 트리거 시 = 슬래시 명령이나 조건 매칭 시 로딩 / 에이전트 소환 시 = `Agent(subagent_type:)` 호출 시

---

---

# Part 2: 메모리, 스킬, Hooks & 변환 명세

---

