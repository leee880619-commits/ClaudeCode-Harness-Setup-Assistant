# 구현 계획: 실사용 예시 및 온보딩 마찰 제거

## 요약 (변경 파일 목록)

| # | 파일 | 변경 유형 | 비고 |
|---|------|-----------|------|
| 1 | `README.md` | 수정 | 30초 퀵스타트 섹션 추가 + 생성 파일 트리 삽입 |
| 2 | `commands/harness-setup.md` | 수정 | Phase 0 시작 텍스트 + 소요 시간 출력 + Phase 9 완료 안내 추가 |
| 3 | `examples/generated/web-app-solo/README.md` | 신규 | 예시 컨텍스트 + 사용법 |
| 4 | `examples/generated/web-app-solo/CLAUDE.md` | 신규 | 솔로 웹앱 CLAUDE.md 참조 패턴 |
| 5 | `examples/generated/web-app-solo/settings.json` | 신규 | 기본 permissions/deny 구조 |
| 6 | `examples/generated/web-app-solo/.claude/rules/dev-conventions.md` | 신규 | rules 파일 참조 패턴 |
| 7 | `examples/generated/agent-pipeline/README.md` | 신규 | 에이전트 파이프라인 예시 컨텍스트 |
| 8 | `examples/generated/agent-pipeline/CLAUDE.md` | 신규 | 에이전트 참조 포함 CLAUDE.md 패턴 |
| 9 | `examples/generated/agent-pipeline/settings.json` | 신규 | WebSearch/WebFetch 허용 패턴 |
| 10 | `examples/generated/agent-pipeline/.claude/agents/researcher.md` | 신규 | 에이전트 정의 참조 패턴 |
| 11 | `CONTRIBUTING.md` | 수정 | 예시 파일 유지보수 체크리스트 추가 |

---

## 구현 순서

1. `commands/harness-setup.md` — Phase 0 텍스트 + 완료 안내 (런타임 동작에 직접 영향)
2. `examples/generated/` — 신규 디렉터리 + 파일들 (가장 많은 신규 파일)
3. `README.md` — 퀵스타트 섹션 추가
4. `CONTRIBUTING.md` — 체크리스트 추가

---

## 변경 1: `commands/harness-setup.md`

### 1-A: Phase 0 시작 안내 텍스트 추가

**삽입 위치**: 파일 마지막 `## 시작` 섹션의 첫 번째 단락 앞.

**변경 전**:
```markdown
## 시작

준비되면 Phase 0부터 시작하세요. Orchestrator Protocol에 정의된 AskUserQuestion 한 번으로 대상 프로젝트 경로와 핵심 인터뷰 질문(이름/유형/팀 규모)을 묶어 받으세요.
```

**변경 후**:
```markdown
## 시작

Phase 0 시작 전, 아래 안내문을 텍스트로 출력하세요 (AskUserQuestion이 아닌 일반 텍스트):

```
대상 프로젝트의 Claude Code 하네스를 구축합니다.
프로젝트 유형을 알려주시면 최적 경로로 안내합니다.
중단 시 docs/{요청명}/에 저장되어 나중에 언제든 재개 가능합니다.
```

AskUserQuestion으로 대상 프로젝트 경로와 핵심 인터뷰 질문(이름/유형/팀 규모)을 묶어 받으세요.
AskUserQuestion 완료 직후, 결정된 트랙에 따라 아래 텍스트를 출력하세요:

- Fast Track 선택 또는 "빠르게"/"--fast" 키워드: `"Fast Track으로 진행합니다. 예상 소요: 10–15분."`
- 에이전트 파이프라인 프로젝트: `"에이전트 파이프라인 경로로 진행합니다. 예상 소요: 30–40분."`
- 그 외 표준 경로: `"표준 경로로 진행합니다. 예상 소요: 20–45분 (프로젝트 복잡도에 따라)."`

준비되면 Phase 0부터 시작하세요. Orchestrator Protocol에 정의된 AskUserQuestion 한 번으로 대상 프로젝트 경로와 핵심 인터뷰 질문(이름/유형/팀 규모)을 묶어 받으세요.
```

**변경 이유**: 사용자가 Phase 0 진입 시 "이게 뭘 하는 건가" 혼란 방지. 소요 시간을 사전이 아닌 트랙 선택 직후 표시해 시작 전 이탈 방지(신민서 비판 수용).

---

### 1-B: Phase 9 완료 후 사용법 안내 추가

**삽입 위치**: `## Output File Order` 테이블 다음, `## Language` 섹션 앞.

**변경 전**: `## Language` 섹션이 Output File Order 바로 다음에 위치.

**변경 후**: 그 사이에 아래 섹션 삽입:

```markdown
## Phase 9 완료 후 오케스트레이터 출력

Phase 9(`phase-validate`)가 반환을 완료하고 Advisor 리뷰가 통과되면, 오케스트레이터는 다음 안내문을 텍스트로 출력합니다 (AskUserQuestion이 아닌 일반 텍스트):

```
✅ 하네스 구축 완료! ({요청명})

생성된 파일:
{phase-validate의 Files Generated 목록 그대로 인용}

이제 어떻게 사용하나요?
1. 대상 프로젝트 디렉터리에서 `claude` 실행 — CLAUDE.md와 rules가 자동 로딩됩니다.
2. 생성된 스킬은 `/{skill-name}`으로 호출합니다.
3. 에이전트가 생성된 경우 Agent(subagent_type: "{agent-name}") 패턴으로 소환합니다.
4. 훅은 파일 저장(Write/Edit) 또는 세션 종료 시 자동 실행됩니다.

하네스 수정/기능 추가가 필요하면: `/harness-architect:harness-setup {대상경로}` 재실행
도움말: `/harness-architect:help`
```

조건부 출력:
- 에이전트 파일(`.claude/agents/*.md`)이 생성된 경우에만 3번 항목(Agent 소환 패턴)을 포함합니다.
- 스킬 파일(`.claude/skills/*/SKILL.md`)이 생성된 경우에만 2번 항목을 포함합니다.
- 훅 파일이 생성된 경우에만 4번 항목을 포함합니다.
```

**변경 이유**: Phase 9 완료 후 "이제 뭐 하지?" Landing 구간이 현재 완전히 비어있음. 구현 비용 낮고 사용자 혼란 해소 효과 높음.

---

### 1-C: Phase 0 성능 수준 options.description 강화

**삽입 위치**: `## 시작` 섹션 또는 Phase 0 AskUserQuestion 지시 근처에 아래 주석을 추가.

**변경 후** (Phase 0 AskUserQuestion 성능 수준 옵션 description 기준):
```markdown
### Phase 0 성능 수준 옵션 description 기준

AskUserQuestion으로 성능 수준을 물을 때 options의 description 필드:
- 경제형: "Haiku 위주. 빠르고 저렴 (Opus 대비 약 1/15 비용). 단순 프로젝트·빠른 프로토타입에 적합."
- 균형형 (권장): "Sonnet 중심, 복잡 설계 판단만 Opus 사용. 대부분 프로젝트에 최적."
- 고성능형: "Opus 중심. 균형형 대비 약 5배 비용. 복잡한 에이전트 아키텍처 설계에 적합."
```

**변경 이유**: 사용자가 선택의 트레이드오프를 질문 내에서 이해할 수 있도록. 별도 문서보다 질문 안에 컨텍스트를 담는 것이 실제 의사결정 품질을 높임(신민서 제안 수용).

---

## 변경 2: `examples/generated/` (신규 디렉터리 + 파일들)

### 공통 sanitization 규약 (모든 예시 파일 준수)
- 실제 경로 없음: `/Users/`, `~`, `C:\` 대신 `/your-project/` 사용
- API 키 패턴 없음: `sk-`, `ghp_` 등 대신 `your-api-key-here` placeholder
- 팀원 이름·이메일 없음
- 각 파일 최상단: `<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->`

---

### 파일 2-1: `examples/generated/web-app-solo/README.md`

```markdown
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 예시: 솔로 React/Node 웹앱 (Fast Track)

이 디렉터리는 `harness-architect`가 솔로 React + Node.js 웹앱 프로젝트에 대해
Fast Track(10–15분)으로 생성한 하네스의 **공개용 참조 예시**입니다.

> 이 파일은 공개용으로 단순화된 참조 예시입니다. 실제 생성 결과는 프로젝트 스캔
> 결과와 인터뷰 답변에 따라 달라집니다.

## 생성 조건

| 항목 | 값 |
|------|----|
| 플러그인 버전 | v0.3.3 |
| 진행 경로 | Fast Track |
| 프로젝트 유형 | 웹 앱 |
| 솔로/팀 | 솔로 |
| 성능 수준 | 균형형 |
| 주요 기술 스택 | React, Node.js, Express, PostgreSQL |

## 포함된 파일

```
examples/generated/web-app-solo/
├── README.md               ← 이 파일
├── CLAUDE.md               ← 프로젝트 정체성·개발 원칙
├── settings.json           ← 권한·훅 구조
└── .claude/
    └── rules/
        └── dev-conventions.md  ← 항상 적용되는 코딩 규약
```

## 이 하네스를 활용하는 방법

프로젝트 디렉터리에서 `claude`를 실행하면:

1. `CLAUDE.md`가 자동 로딩되어 프로젝트 컨텍스트(기술 스택, 개발 원칙)가 주입됩니다.
2. `.claude/rules/dev-conventions.md`가 항상 적용되어 코딩 규약이 유지됩니다.
3. `settings.json`의 권한 설정으로 npm, git 등 자주 쓰는 명령어는 확인 없이 실행됩니다.

에이전트 프로젝트 예시는 `../agent-pipeline/` 디렉터리를 참조하세요.
```

---

### 파일 2-2: `examples/generated/web-app-solo/CLAUDE.md`

```markdown
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# my-web-app

개인 포트폴리오 겸 사이드 프로젝트용 React + Node.js 웹 애플리케이션.
사용자 인증, 게시물 CRUD, 이미지 업로드 기능을 제공한다.

## 기술 스택

- **프론트엔드**: React 18, TypeScript, Tailwind CSS
- **백엔드**: Node.js 20, Express, Prisma ORM
- **데이터베이스**: PostgreSQL 15
- **테스트**: Vitest (유닛), Playwright (E2E)
- **배포**: Docker, Railway

## 개발 원칙

- 타입 안전성: TypeScript strict 모드 유지
- 테스트: 새 기능은 유닛 테스트 필수
- 커밋: Conventional Commits (`feat:`, `fix:`, `docs:`)
- 코드 리뷰: PR 머지 전 자기 리뷰 체크리스트 확인

## 디렉터리 구조

```
src/
├── client/     # React 프론트엔드
├── server/     # Express API 서버
└── shared/     # 공유 타입·유틸리티
```

## 자주 쓰는 명령어

```bash
npm run dev        # 개발 서버 (프론트 + 백 동시 실행)
npm run test       # 유닛 테스트
npm run test:e2e   # E2E 테스트
npm run build      # 프로덕션 빌드
```

## 규칙 및 설계 문서

@import .claude/rules/dev-conventions.md
```

---

### 파일 2-3: `examples/generated/web-app-solo/settings.json`

```json
{
  "_comment": "generated-with: harness-architect v0.3.3 | sanitized for public use",
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(npx *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git log *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Read(*)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm *)",
      "Bash(git push --force *)"
    ]
  },
  "env": {
    "NODE_ENV": "development"
  }
}
```

---

### 파일 2-4: `examples/generated/web-app-solo/.claude/rules/dev-conventions.md`

```markdown
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 개발 규약

## 코드 스타일

- TypeScript strict 모드 준수. `any` 타입 사용 금지.
- 컴포넌트 파일: PascalCase (`UserProfile.tsx`)
- 유틸리티·훅 파일: camelCase (`useAuth.ts`)
- 상수: SCREAMING_SNAKE_CASE

## 커밋 규약

Conventional Commits 형식 준수:
- `feat:` — 새 기능
- `fix:` — 버그 수정
- `docs:` — 문서 변경
- `refactor:` — 기능 변경 없는 코드 개선
- `test:` — 테스트 추가·수정

## 테스트 원칙

- 새 API 엔드포인트는 통합 테스트 필수
- 비즈니스 로직 함수는 유닛 테스트 필수
- UI 컴포넌트는 핵심 인터랙션만 E2E 테스트

## 금지 패턴

- `console.log`를 프로덕션 코드에 남기지 않는다
- `// TODO` 주석은 이슈 번호를 함께 기재 (`// TODO #42`)
- 환경변수는 반드시 `.env.example`에 키 이름을 문서화
```

---

### 파일 2-5: `examples/generated/agent-pipeline/README.md`

```markdown
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 예시: 멀티에이전트 리서치 파이프라인 (Fast-Forward)

이 디렉터리는 `harness-architect`가 멀티에이전트 딥 리서치 파이프라인 프로젝트에 대해
Fast-Forward 경로(30–40분)로 생성한 하네스의 **공개용 참조 예시**입니다.

> 이 파일은 공개용으로 단순화된 참조 예시입니다. 실제 생성 결과는 프로젝트 스캔
> 결과와 인터뷰 답변에 따라 달라집니다.

## 생성 조건

| 항목 | 값 |
|------|----|
| 플러그인 버전 | v0.3.3 |
| 진행 경로 | Fast-Forward (에이전트 파이프라인 감지) |
| 프로젝트 유형 | 에이전트 파이프라인 |
| 솔로/팀 | 솔로 |
| 성능 수준 | 균형형 |
| 핵심 도메인 | 딥 리서치 |

## 포함된 파일

```
examples/generated/agent-pipeline/
├── README.md                       ← 이 파일
├── CLAUDE.md                       ← 프로젝트 정체성·에이전트 팀 참조
├── settings.json                   ← 권한·WebSearch/WebFetch 허용
└── .claude/
    └── agents/
        └── researcher.md           ← 리서치 에이전트 정의 패턴
```

## 이 하네스를 활용하는 방법

프로젝트 디렉터리에서 `claude`를 실행하면:

1. `CLAUDE.md`가 자동 로딩되어 에이전트 팀 구조와 파이프라인 개요가 주입됩니다.
2. `Agent(subagent_type: "researcher")` 패턴으로 리서치 에이전트를 소환합니다.
3. `settings.json`의 `WebSearch`·`WebFetch` 허용으로 에이전트가 웹 검색을 수행합니다.

솔로 웹앱 예시는 `../web-app-solo/` 디렉터리를 참조하세요.
```

---

### 파일 2-6: `examples/generated/agent-pipeline/CLAUDE.md`

```markdown
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# deep-research-pipeline

주제를 입력받아 멀티에이전트 파이프라인으로 심층 리서치 보고서를 생성하는 자동화 시스템.
오케스트레이터가 리서처·분석가·작가 에이전트를 순차 소환하여 최종 보고서를 작성한다.

## 기술 스택

- **런타임**: Claude Code (멀티에이전트 모드)
- **도구**: WebSearch, WebFetch, Read, Write
- **출력**: Markdown 보고서 (`output/reports/`)

## 에이전트 팀

| 에이전트 | 역할 | 소환 방법 |
|----------|------|-----------|
| researcher | 주제 탐색·출처 수집 | `Agent(subagent_type: "researcher")` |
| analyst | 수집 정보 분류·평가 | `Agent(subagent_type: "analyst")` |
| writer | 최종 보고서 작성 | `Agent(subagent_type: "writer")` |

## 파이프라인 흐름

```
사용자 요청 (주제)
  → researcher (웹 검색·출처 수집)
  → analyst (정보 평가·구조화)
  → writer (보고서 초안)
  → research-redteam (출처·편향 검증)
  → 최종 보고서 저장
```

## 개발 원칙

- 각 에이전트는 자신의 쓰기 범위(`allowed_dirs`) 밖에 파일을 생성하지 않는다
- 외부 URL 인용 시 발췌일을 함께 기록한다
- 보고서는 항상 리뷰어 에이전트를 거친 후 최종 저장된다

## 설계 문서

@import docs/example-setup/03-pipeline-design.md
@import docs/example-setup/04-agent-team.md
```

---

### 파일 2-7: `examples/generated/agent-pipeline/settings.json`

```json
{
  "_comment": "generated-with: harness-architect v0.3.3 | sanitized for public use",
  "permissions": {
    "allow": [
      "WebSearch(*)",
      "WebFetch(*)",
      "Read(*)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(mkdir -p output/reports)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm *)",
      "Bash(git push --force *)"
    ]
  },
  "env": {
    "OUTPUT_DIR": "output/reports"
  }
}
```

---

### 파일 2-8: `examples/generated/agent-pipeline/.claude/agents/researcher.md`

```markdown
---
name: researcher
description: 주어진 주제에 대해 웹 검색으로 출처를 수집하고 원문을 요약하는 리서치 에이전트
model: claude-sonnet-4-6
---

<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# Researcher

딥 리서치 파이프라인의 1단계 에이전트. 주제를 입력받아 신뢰할 수 있는 출처를
수집하고 핵심 내용을 구조화된 형식으로 반환한다.

## 역할

- WebSearch로 관련 출처 탐색 (최대 6회)
- WebFetch로 주요 페이지 본문 수집 (최대 3회)
- 각 출처에 URL + 발췌일 기록
- 수집 결과를 `output/research-raw/` 에 저장

## 규칙

- 쓰기 범위: `output/research-raw/` 만 허용
- 대상 프로젝트의 개인정보·내부 경로를 검색 쿼리에 포함하지 않는다
- 신뢰도가 낮은 출처(개인 블로그·비검증 포럼)는 별도 표기

## 반환 포맷

수집 완료 후 다음 형식으로 반환:

```
## Sources
- [제목](URL) — 발췌일: YYYY-MM-DD — 핵심 요점 1~2문장

## Key Findings
주제별 핵심 발견사항 (불릿 리스트)

## Next Step
analyst 에이전트에 전달할 컨텍스트 요약
```
```

---

## 변경 3: `README.md`

### 변경 전 (현재 `## 사용법` 섹션 앞부분)

```markdown
## 사용법

설치 후, 하네스를 만들 **대상 프로젝트에서** Claude Code 세션을 열고 슬래시 커맨드로 시작합니다.
```

### 변경 후

`## 배경 (Why this exists)` 섹션과 `## 언제 쓰면 좋은가` 섹션 사이에 다음 섹션을 **삽입**:

```markdown
## 30초 퀵스타트

```bash
# 1) 플러그인 설치 (한 번만)
/plugin marketplace add leee880619-commits/ClaudeCode-Harness-Setup-Assistant
/plugin install harness-architect@harness-architect-marketplace

# 2) 하네스를 만들 프로젝트 디렉터리에서 Claude 실행
cd /path/to/your/project
claude

# 3) 슬래시 커맨드 실행
/harness-architect:harness-setup
```

**완료 후 생성되는 파일:**

```
your-project/
├── CLAUDE.md                    ← Claude의 프로젝트 이해 기반
├── .claude/
│   ├── settings.json            ← 권한·환경변수·훅·MCP
│   ├── rules/                   ← 항상 적용되는 규칙
│   ├── agents/                  ← 에이전트 정의 (에이전트 프로젝트)
│   └── skills/                  ← 재사용 가능한 스킬
└── docs/{요청명}/               ← 설계 산출물 (참고용)
```

**예상 소요 시간:**

| 프로젝트 유형 | 경로 | 예상 소요 |
|---|---|---|
| 솔로 웹앱·CLI | Fast Track | 10–15분 |
| 팀 웹앱 | 표준 | 20–45분 |
| 에이전트 파이프라인 | Fast-Forward | 30–40분 |

실제 예시 파일: [`examples/generated/`](./examples/generated/)
기여자라면: [CLAUDE.md](./CLAUDE.md) 참조
```

**변경 이유**: GitHub/마켓플레이스 첫 인상에서 "무엇이 만들어지나"와 "얼마나 걸리나"를 5초 안에 파악 가능하도록. 내용을 최소화해 유지보수 부담을 낮춤(신민서·임채은 합의안).

---

## 변경 4: `CONTRIBUTING.md`

### 변경 위치

`## Phase / 규칙 변경 체크리스트` 섹션의 표 다음, `각 변경 PR에는` 단락 앞.

### 변경 전

```markdown
각 변경 PR에는 위 파일 중 **어느 것이 함께 변경됐는지** 본문에 명시하세요.
```

### 변경 후

그 앞에 아래 하위 섹션을 삽입:

```markdown
### 예시 파일 업데이트 체크리스트 (`examples/generated/` 변경 시)

`examples/generated/` 의 파일을 추가·수정할 때 아래를 확인하세요.

**커밋 전 필수 확인:**
- [ ] 각 파일 최상단 `generated-with: v{버전}` 을 현재 버전으로 업데이트
- [ ] 실제 경로(`/Users/`, `~`, `C:\`) 없음 — `/your-project/` 형태 사용
- [ ] API 키 패턴(`sk-`, `ghp_`, `AKIA`) 없음 — `your-api-key-here` 사용
- [ ] 팀원 이름·이메일 없음
- [ ] `CHANGELOG.md` `[Unreleased]` 섹션에 예시 변경 항목 추가

**유지보수 정책:**
- 예시 파일은 핵심 패턴 참조용이며 완성된 산출물 스냅샷이 아닙니다
- 플러그인 버전 업그레이드 시 예시 파일의 구조적 변경 여부를 확인하세요
- 예시가 구식이 되면 삭제보다 버전 메타데이터 업데이트를 우선합니다

각 변경 PR에는 위 파일 중 **어느 것이 함께 변경됐는지** 본문에 명시하세요.
```

**변경 이유**: 신민서의 "구식 예시가 오히려 해롭다" 지적 반영. 버전 메타데이터와 sanitization 규약을 기여자 체크리스트로 공식화해 유지보수 부채를 최소화.

---

## 리스크 및 주의사항

| 리스크 | 가능성 | 완화 방안 |
|--------|--------|-----------|
| `commands/harness-setup.md`의 Phase 0 텍스트 출력 지시를 오케스트레이터가 무시하고 바로 AskUserQuestion 호출 | 중간 | 지시 문구를 명령형으로 작성("출력하세요"). 실제 실행 테스트 필수. |
| Phase 9 완료 안내의 조건부 출력(에이전트 유무 등)이 오케스트레이터에서 구현되지 않아 항상 전체 출력 | 낮음 | 최악의 경우 관련 없는 항목 1개가 더 표시될 뿐 — 기능 저해 없음. |
| `examples/generated/` 파일이 향후 버전 업그레이드에서 구식 상태로 방치 | 높음 | `CONTRIBUTING.md` 체크리스트 + CHANGELOG 항목으로 완화. CI 없으므로 수동 확인 의존. |
| `settings.json` 예시의 `"_comment"` 필드가 JSON 파서에서 허용되지 않는 환경 존재 | 낮음 | 실제 `settings.json` 으로 복사해 사용하지 않는다는 것을 README에 명시. `_comment`는 표준 JSON이므로 대부분 파서에서 허용됨. |
| `CLAUDE.md`의 `@import` 예시가 실제 Claude Code `@import` 문법과 다를 경우 혼란 | 낮음 | 예시 README에 "이 파일은 참조 패턴이며 직접 사용 불가"를 명시. |
| README.md 소요 시간 표가 실제 소요와 달라 불만족 유발 | 중간 | 표 아래에 "(사용자 응답 속도·프로젝트 복잡도에 따라 달라질 수 있습니다)" 주석 추가. |

---

## Implementer 체크리스트

구현 완료 후 확인:

- [ ] `commands/harness-setup.md` `## 시작` 섹션에 Phase 0 안내 텍스트 추가됨
- [ ] `commands/harness-setup.md` `## Output File Order` 다음에 Phase 9 완료 안내 섹션 추가됨
- [ ] `commands/harness-setup.md` Phase 0 성능 수준 description 기준 추가됨
- [ ] `examples/generated/web-app-solo/` 4개 파일 생성됨
- [ ] `examples/generated/agent-pipeline/` 4개 파일 생성됨
- [ ] 모든 예시 파일 최상단에 `generated-with: v0.3.3` 메타데이터 포함됨
- [ ] 모든 예시 파일에 실제 경로·API 키·이름 없음 확인됨
- [ ] `README.md` `## 배경` 다음에 `## 30초 퀵스타트` 섹션 삽입됨
- [ ] `CONTRIBUTING.md` 예시 파일 업데이트 체크리스트 추가됨
- [ ] `CHANGELOG.md` `[Unreleased]` 섹션에 이번 변경사항 기록됨
