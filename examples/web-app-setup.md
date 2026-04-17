# Example scenario: setting up a harness for a small web app (solo, React + Node)

> 이 문서는 실제 실행 로그가 아니라 **사용 흐름 예시**입니다. 플러그인 설치 후 `/harness-architect:harness-setup`이 어떻게 진행되는지 감을 잡기 위한 목적입니다.

## 전제

- 대상 프로젝트: `/home/alice/projects/my-new-web-app/`
- React 프론트엔드 + Express 백엔드, Postgres
- 혼자 작업 (솔로), 테스트 커버리지 기본 수준
- 보안·비밀값은 `.env`로 관리 중

## 실행

```bash
cd /home/alice/projects/my-new-web-app
claude
```

세션 내에서:

```
/harness-architect:harness-setup
```

## 예상 진행

### Phase 0 — 경로 수집 (orchestrator)

Orchestrator가 3개의 묶인 질문을 AskUserQuestion으로 제시:
1. 대상 프로젝트 경로 확인
2. 프로젝트 이름 + 한 줄 설명
3. 솔로 / 팀

답변 예시:
- 경로: 현재 세션 CWD 사용
- 이름: "my-new-web-app — Small internal note-taking app"
- 솔로

`docs/my-new-web-app-setup/00-target-path.md` 생성.

### Phase 1-2 — 스캔 + 기본 하네스 (`phase-setup` → `fresh-setup`)

`phase-setup` 에이전트가 스캔:
- 감지된 스택: Node 20, React 18, Express 4, Postgres
- 기존 `.claude/` 없음 → `fresh-setup` 경로

에이전트는 다음을 Escalations로 돌려보냄:
- [확인 필요] 테스트 프레임워크 2개 감지 (Vitest + Playwright). 우선순위?
- [확인 필요] `.env.example`에 `DATABASE_URL` 존재. 비밀값 정책?

Orchestrator가 이 두 건을 묶어 AskUserQuestion으로 질문 → 답변 반영 후 재소환.

생성:
- `CLAUDE.md` (~80줄): 프로젝트 정체성, 기술 스택, 솔로 작업 원칙
- `.claude/settings.json`: Bash allow/deny, Read/Write/Edit/Grep 허용
- `.claude/rules/`: `testing.md`, `secrets.md` (프로젝트 특화 규칙)
- `CLAUDE.local.md` 템플릿, `.claude/settings.local.json` 템플릿
- `.gitignore` 확장

### Phase 3-6 — Fast Track (단순 웹앱 → 경량 설계)

솔로 + 표준 웹앱이므로 복잡도 게이트가 경량 모드 활성화. Advisor는 NOTE만 수집.

- Phase 3 (workflow): Implement → Test → Review 3단계
- Phase 4 (pipeline): 단일 에이전트 (사용자 + Claude) 실행
- Phase 5: 에이전트 팀 불필요 (스킵)
- Phase 6: 단일 SKILL `/smart-fix` 생성 여부 질문 (선택)

### Phase 7-8 — 훅/MCP (`phase-hooks` → `hooks-mcp-setup`)

감지 기반 제안:
- **PreToolUse(Write|Edit)**: prettier + eslint auto-fix
- **PostToolUse(Write|Edit)**: type-check (단, 저장 속도 영향 고려)
- **MCP 제안**: postgres MCP (Postgres 감지됨), GitHub MCP (레포 원격 감지됨)

Advisor가 질문: "prettier를 매 편집마다 돌리는 것이 솔로 워크플로우에 과하지 않은가?" → NOTE로 보고만.

### Phase 9 — 최종 검증 (`phase-validate` → `final-validation`)

- JSON parse: `settings.json` ✅
- YAML frontmatter 닫힘: 모든 rules 통과
- 메타 누수 키워드: 0건
- `.gitignore`에 `.env`, `node_modules` 포함 확인

`docs/my-new-web-app-setup/07-validation-report.md` 생성, 요약을 Orchestrator가 사용자에게 제시.

## 산출 파일 (대상 프로젝트)

```
my-new-web-app/
├── CLAUDE.md                    ← 신규
├── CLAUDE.local.md              ← 신규 (개인)
├── .claude/
│   ├── settings.json            ← 신규
│   ├── settings.local.json      ← 신규 (gitignored)
│   ├── rules/
│   │   ├── testing.md
│   │   └── secrets.md
│   └── hooks/
│       ├── prettier-eslint.sh   ← PreToolUse
│       └── typecheck.sh         ← PostToolUse
├── docs/my-new-web-app-setup/   ← 진행 상태 (재개용)
│   ├── 00-target-path.md
│   ├── 01-discovery-answers.md
│   └── 07-validation-report.md
└── .gitignore                   ← 확장 (settings.local.json, CLAUDE.local.md)
```

## 소요 시간

- Fast Track 모드 기준 10-15분 (Phase 3-6 경량, Phase 7-8에서 3-4개 결정)
- 세션 중단 후 다음날 재개 가능 (`docs/my-new-web-app-setup/`)
