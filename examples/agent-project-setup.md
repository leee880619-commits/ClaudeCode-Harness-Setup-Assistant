# Example scenario: setting up a harness for an agent pipeline project (Fast-Forward 경로)

> 이 문서는 실제 로그가 아니라 **사용 흐름 예시**입니다.

## 전제

- 대상 프로젝트: `/home/alice/workspace/research-agent-team/`
- 목적: 여러 전문 에이전트(researcher, analyst, writer)가 협업해 리서치 리포트를 만드는 파이프라인
- 팀 2명, Python + LangChain, 기존 `.claude/` 없음

이 유형은 Phase 3-5(워크플로우 → 파이프라인 → 팀)가 본질적으로 함께 설계되어야 하므로, 플러그인은 **Fast-Forward** 경로를 제안합니다.

## 실행

```bash
cd /home/alice/workspace/research-agent-team
claude
```

세션 내:

```
/harness-architect:harness-setup
```

## 예상 진행

### Phase 0 — 경로 수집

Orchestrator가 3개 묶음 AskUserQuestion:
- 경로 확인
- 이름/설명: "research-agent-team — multi-agent research report pipeline"
- 팀 2명

### Phase 1-2 — 스캔 (`phase-setup` → `fresh-setup`)

스캔이 `langchain`, `openai`, 다수 에이전트 정의 파일 패턴을 발견.

`phase-setup`이 Escalation에 반환:
- [감지] 에이전트 프로젝트 아키타입 추정됨. Fast-Forward 경로(3-5 통합) 권장.

Orchestrator가 사용자 확인:
> "에이전트 프로젝트로 감지됨. Phase 3-5를 통합 설계 모드로 진행할까요? (워크플로우·파이프라인·팀을 한 번에 설계하고 Advisor는 통합 완료 후 1회)"

→ 승인.

생성:
- `CLAUDE.md`: 에이전트 프로젝트 정체성, 팀 작업 원칙
- `.claude/settings.json`: Bash 제한, Agent/TeamCreate/SendMessage 허용
- `.claude/rules/agent-ownership.md`: 에이전트별 쓰기 범위 규칙

### Phase 3-5 통합 (Fast-Forward)

단일 세션에서 워크플로우·파이프라인·팀을 함께 설계:

**워크플로우 (Phase 3)**
1. Research (web + doc search)
2. Analysis (cross-source synthesis)
3. Drafting (structured report)
4. Review (fact-checking, citation audit)

**파이프라인 (Phase 4)**
- Research: `researcher-agent` (병렬로 여러 쿼리) → 결과 집계
- Analysis: `analyst-agent` (synthesize)
- Drafting: `writer-agent`
- Review: `fact-checker-agent` + `citation-auditor-agent` 병렬

**에이전트 팀 (Phase 5)**
- `researcher-agent`: opus, 웹 검색·문서 읽기
- `analyst-agent`: sonnet, 교차 분석
- `writer-agent`: opus, 구조화된 작성
- `fact-checker-agent`: sonnet, 팩트 검증
- `citation-auditor-agent`: haiku, 인용 포맷 검증

통합 완료 후 **Advisor 1회** 실행:
- BLOCK: "citation-auditor가 haiku로 인용 포맷을 검증하기에 충분한가? 복잡 포맷은 품질 저하 위험." → 사용자 확인 후 sonnet으로 조정.
- NOTE: researcher 병렬 수는 외부 API rate limit 영향. 리서치 플레이북에 rate limit 명시 권장.

### Phase 6 — Playbook 작성 (`phase-skills` → `skill-forge`)

에이전트별 playbook 5개 생성:
- `playbooks/research.md` (rate limit, source priority, 검색 전략)
- `playbooks/analysis.md` (교차 분석 템플릿)
- `playbooks/drafting.md` (리포트 구조, 인용 포맷)
- `playbooks/fact-check.md` (확인 단계, 불확실 표기)
- `playbooks/citation-audit.md` (인용 포맷 규칙)

메인 세션에 `Skill`로 노출하지 않기 위해 `playbooks/`에 저장. 각 에이전트 정의에서 `${CLAUDE_PLUGIN_ROOT}/…` 대신 대상 프로젝트 상대경로(`playbooks/research.md`)로 참조 — 대상 프로젝트에서 실행되므로 플러그인 경로 변수는 사용하지 않음.

### Phase 7-8 — 훅/MCP

- PreToolUse(Write|Edit): ownership-guard (에이전트별 쓰기 범위)
- PostToolUse(Agent): 에이전트 산출물의 최소 필드 검증 스크립트
- MCP 제안: tavily (웹 검색), brave (대안 검색)

### Phase 9 — 최종 검증

- 에이전트 5개 frontmatter 유효 ✅
- 각 에이전트가 참조하는 playbook 존재 ✅
- 팀 편성 사이클 없음 (DAG 확인) ✅
- 메타 누수 0건

## 산출 파일 (대상 프로젝트)

```
research-agent-team/
├── CLAUDE.md
├── .claude/
│   ├── settings.json
│   ├── rules/agent-ownership.md
│   ├── agents/
│   │   ├── researcher-agent.md
│   │   ├── analyst-agent.md
│   │   ├── writer-agent.md
│   │   ├── fact-checker-agent.md
│   │   └── citation-auditor-agent.md
│   └── hooks/
│       ├── ownership-guard.sh
│       └── agent-output-check.sh
├── playbooks/
│   ├── research.md
│   ├── analysis.md
│   ├── drafting.md
│   ├── fact-check.md
│   └── citation-audit.md
├── docs/research-agent-team-setup/
│   ├── 00-target-path.md
│   ├── 01-discovery-answers.md
│   ├── 02-workflow-design.md
│   ├── 03-pipeline-design.md
│   ├── 04-agent-team.md
│   ├── 05-skill-specs.md
│   ├── 06-hooks-mcp.md
│   └── 07-validation-report.md
└── .gitignore
```

## 소요 시간

- Fast-Forward + 통합 Advisor 기준 25-40분 (단순 웹앱 대비 설계 깊이 때문에 길어짐)
