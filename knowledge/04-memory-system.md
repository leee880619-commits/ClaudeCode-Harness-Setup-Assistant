<!-- File: 04-memory-system.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 5 -->
## SECTION 5: 자동 메모리 시스템 완전 명세

### 5.1 메모리 저장 위치

Claude Code의 자동 메모리 시스템은 세션 간 지속되는 학습 데이터를 파일 시스템에 저장한다. 이 시스템은 Cursor의 수동 `session_handoff.md` 패턴을 완전히 대체하며, 에이전트가 사용자와의 대화에서 자동으로 중요한 정보를 추출하여 구조화된 형태로 보존한다.

**물리적 저장 경로:**

```
~/.claude/projects/<project-path-encoded>/memory/
```

**프로젝트 경로 인코딩 규칙:**

프로젝트의 절대 경로에서 모든 슬래시(`/`)를 대시(`-`)로 치환하고, 경로 시작부의 슬래시도 대시로 변환한다.

| 실제 프로젝트 경로 | 인코딩된 디렉터리명 |
|---|---|
| `/home/alice/projects/my-app` | `-home-alice-projects-my-app` |
| `/home/alice/workspace/bright-data-test` | `-home-alice-workspace-bright-data-test` |
| `/home/alice/workspace/Agent Team Builder` | `-home-alice-workspace-Agent Team Builder` |

**Git 리포지토리와의 관계:**

하나의 Git 리포지토리에 속하는 모든 워크트리(worktree)와 하위 디렉터리는 동일한 메모리 디렉터리를 공유한다. 예를 들어 `/home/user/project/` 리포지토리 안에서 `/home/user/project/packages/frontend/`를 작업 디렉터리로 세션을 열어도, 메모리는 리포지토리 루트 기준으로 `-home-user-project` 디렉터리에 저장된다. 이는 프로젝트 전체에 대한 학습이 하위 모듈 작업 시에도 유지됨을 의미한다.

**활성화/비활성화 제어:**

```jsonc
// ~/.claude/settings.json (전역 설정)
{
  "autoMemoryEnabled": true   // 기본값: true
}

// 또는 환경변수로 비활성화
CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
```

환경변수 방식은 CI/CD 파이프라인이나 일회성 스크립트 실행 시 메모리 시스템의 오버헤드를 제거하는 데 유용하다. `settings.json` 설정보다 환경변수가 우선한다.

### 5.2 MEMORY.md (인덱스 파일)

`MEMORY.md`는 메모리 시스템의 진입점이다. 이 파일 자체는 메모리가 아니며, 토픽 파일들을 가리키는 인덱스 역할만 수행한다.

**로딩 규칙:**

- 세션 시작 시 자동 로딩된다
- 처음 **200줄** 또는 **25KB** 중 먼저 도달하는 한도까지만 읽는다
- 200줄을 초과하는 내용은 잘린다 — 인덱스는 간결하게 유지해야 한다

**파일 형식:**

```markdown
- [사용자 프로파일](user_profile.md) — 기술 수준, 작업 스타일, 품질 기준, 언어 선호
- [워크플로우 피드백](feedback_workflow.md) — NLM URL 정책, 환각 방지, 신뢰도 상한, 에이전트간 상태 파일
- [프로젝트 컨텍스트](project_context.md) — 프로젝트 목표, 아키텍처 결정, 스킬 구성, 현재 상태
- [배포 참조](deploy_reference.md) — AWS 계정 구조, CI/CD 파이프라인 위치, 스테이징 URL
```

**핵심 규칙:**

- Frontmatter가 없다 — 순수 마크다운
- 각 항목은 한 줄이다: `- [제목](파일명.md) — 한줄 설명`
- 설명(hook)은 Claude가 관련성을 판단하는 데 사용한다. "사용자 선호" 같은 모호한 설명보다 "TypeScript strict mode 강제, 세미콜론 없는 스타일" 같은 구체적 설명이 효과적이다
- 파일명에 경로 구분자를 포함하지 않는다 — 모든 토픽 파일은 `memory/` 디렉터리 바로 아래에 위치한다

**잘못된 예시:**

```markdown
<!-- 이렇게 하면 안 된다 -->
# 메모리 목록

## 사용자 관련
- [사용자 프로파일](profiles/user_profile.md) — 프로필 정보

## 프로젝트 관련  
- [프로젝트 컨텍스트](contexts/project_context.md) — 프로젝트 정보
```

위 예시의 문제점: (1) 헤딩 구조를 사용하여 줄 수를 낭비, (2) 하위 디렉터리 경로 사용, (3) 설명이 너무 모호하여 관련성 판단에 도움이 되지 않음.

### 5.3 토픽 파일 (memory/*.md)

토픽 파일은 실제 메모리 내용을 담는 파일이다. MEMORY.md 인덱스와 달리, 세션 시작 시 전부 로딩되지 않는다. Claude가 현재 작업과 관련이 있다고 판단할 때 Read 도구를 사용하여 온디맨드로 읽는다.

**YAML Frontmatter 필수 사항:**

모든 토픽 파일은 YAML frontmatter로 시작해야 한다. 이 메타데이터는 Claude가 파일의 성격과 관련성을 빠르게 판단하는 데 사용된다.

```yaml
---
name: memory-name
description: one-line description used for relevance matching
type: user | feedback | project | reference
---
```

**type별 상세 명세 및 실전 예시:**

#### type: user — 사용자 프로파일

사용자의 역할, 목표, 전문 분야, 선호도를 기록한다. 세션이 바뀌어도 Claude가 사용자를 "기억"하는 효과를 만든다.

```yaml
---
name: user_profile
description: 데이터 사이언티스트, Go 고급, React 초급, 한국어 작업 선호
type: user
---
```

```markdown
## 기술 수준
- Python/Go: 고급 (5년+), 코드 리뷰 수준의 피드백 가능
- React/TypeScript: 초급 (6개월), 기본 개념 설명이 필요할 수 있음
- 인프라: AWS CDK 중급, Terraform 초급

## 작업 스타일
- 코드 변경 전 항상 근거(rationale) 설명을 요구함
- 한 번에 하나의 파일만 변경하는 것을 선호 (대규모 일괄 수정 지양)
- 커밋 메시지는 Conventional Commits 형식, 한국어 본문

## 품질 기준
- 테스트 커버리지 80% 이상 유지
- any 타입 사용 절대 금지
- console.log 대신 structured logger 사용
```

#### type: feedback — 사용자 피드백 (수정 및 확인)

사용자가 Claude의 행동을 수정하거나 확인한 내용을 기록한다. 단순한 "이렇게 해라"가 아니라, **규칙 → 이유(Why) → 적용 방법(How)**의 3단 구조를 따른다.

```yaml
---
name: feedback_workflow
description: NLM URL 정책, 환각 방지, 신뢰도 상한, 에이전트간 상태 파일 규칙
type: feedback
---
```

```markdown
## 규칙 1: NLM URL 정책
- **규칙**: NLM(National Library of Medicine) URL을 제시할 때 반드시 실제 접속 가능한 URL만 사용
- **이유**: 이전 세션에서 존재하지 않는 PubMed ID를 생성하여 사용자가 잘못된 논문을 참조한 사고 발생
- **적용**: URL을 제시해야 할 때 Bash 도구로 `curl -sI <url>` 실행하여 HTTP 200 확인. 확인 불가 시 "검색 키워드: ..."로 대체

## 규칙 2: 통합 테스트는 실제 DB 사용
- **규칙**: 통합 테스트에서 모의(mock) 데이터베이스 사용 금지, 실제 테스트 DB 연결 필수
- **이유**: 이전 인시던트에서 mock과 실제 운영 DB 간의 차이가 깨진 마이그레이션을 은폐한 사례 존재
- **적용**: `*_integration_test.go` 파일에서 `sqlmock`, `mockDB` 등의 패턴이 발견되면 경고. 대신 `testcontainers-go`로 실제 PostgreSQL 인스턴스 구동

## 규칙 3: 신뢰도 상한(Credibility Ceiling)
- **규칙**: 검증되지 않은 정보에 대해 "확실합니다" 등의 표현 금지
- **이유**: 사용자가 Claude의 확신에 찬 답변을 검증 없이 신뢰하여 프로덕션 장애 발생
- **적용**: 직접 확인하지 않은 사실에는 "~으로 예상됩니다", "문서에 따르면" 등의 한정 표현 사용. 코드를 직접 읽어서 확인한 경우에만 단정적 표현 허용

## 규칙 4: 에이전트 간 상태 파일
- **규칙**: 멀티 에이전트 작업 시 `_state.json` 파일로 상태 전달, 구두(prose) 전달 금지
- **이유**: 자연어 핸드오프가 누락/왜곡되어 후속 에이전트가 잘못된 전제로 작업한 사례 다수
- **적용**: 스킬 완료 시 `docs/operations/_state.json`에 구조화된 결과 기록. 후속 에이전트는 이 파일을 첫 번째로 읽음
```

#### type: project — 프로젝트 진행 상황

진행 중인 작업, 결정 사항, 마감일을 기록한다. **상대 날짜는 반드시 절대 날짜로 변환하여 저장**한다 — "다음 주 금요일"은 세션이 바뀌면 의미가 달라지기 때문이다.

```yaml
---
name: project_context
description: 프로젝트 목표, 12개 아키텍처 결정, 스킬 구성, 현재 상태, 테스트 결과
type: project
---
```

```markdown
## 프로젝트 목표
bright-data-test는 Bright Data의 Web Scraper API, SERP API, Dataset API를 체계적으로 검증하여 
NLM(National Library of Medicine) 데이터 수집 파이프라인의 기술적 기반을 확립하는 프로젝트이다.

## 아키텍처 결정 (12건)
1. **AD-001**: API 호출은 모두 `src/core/client.ts`를 통해 수행 (직접 fetch 금지)
   - 결정일: 2026-02-15, 결정자: 사용자
   - 이유: Rate limit, retry, logging을 한 곳에서 제어
2. **AD-002**: 테스트 데이터는 `fixtures/` 디렉터리에 JSON으로 저장
   - 결정일: 2026-02-16, 결정자: 사용자+Claude 합의
   - 이유: 실제 API 응답 스냅샷으로 회귀 테스트 가능
3. **AD-003**: 환경변수는 `.env.test`와 `.env.production` 분리
   ...
   
## 현재 상태 (2026-03-01 갱신)
- Phase 1 (Web Scraper API): 완료, 테스트 18/18 통과
- Phase 2 (SERP API): 진행 중, 테스트 12/15 통과 (3건 타임아웃 조사 중)
- Phase 3 (Dataset API): 미착수
- 머지 프리즈: 2026-03-05 시작 (모바일 릴리스 컷)

## 스킬 구성
- bright-data-web-scraper: Phase 1 전담
- bright-data-serp-analyzer: Phase 2 전담
- bright-data-dataset-validator: Phase 3 전담 (미착수)
```

#### type: reference — 외부 시스템 참조

외부 도구, 시스템, URL 등 프로젝트 외부에 존재하는 자원을 가리킨다.

```yaml
---
name: deploy_reference
description: AWS 계정 구조, CI/CD 파이프라인, 스테이징 URL, Linear 프로젝트 키
type: reference
---
```

```markdown
## 이슈 트래킹
- 파이프라인 버그: Linear 프로젝트 `INGEST` (https://linear.app/team/INGEST)
- 인프라 이슈: Jira 프로젝트 `INFRA`
- 긴급 온콜: PagerDuty 서비스 `bright-data-pipeline`

## 환경
- 스테이징: https://staging.bright-data-test.internal.example.com
- 프로덕션: https://api.bright-data-test.example.com
- CI/CD: GitHub Actions, `.github/workflows/test.yml`

## 외부 API 문서
- Bright Data Web Scraper: https://docs.brightdata.com/scraping-automation/web-scraper
- Bright Data SERP: https://docs.brightdata.com/scraping-automation/serp-api
```

### 5.4 메모리에 저장하면 안 되는 것

자동 메모리 시스템은 "코드에서 유도할 수 없는 정보"만 저장해야 한다. 다음은 저장하면 안 되는 항목과 그 이유이다:

| 저장하면 안 되는 것 | 이유 | 대안 |
|---|---|---|
| 코드 패턴, 아키텍처 구조 | 코드 자체에서 유도 가능. 코드가 변경되면 메모리와 불일치 발생 | Claude가 필요할 때 코드를 직접 읽음 |
| 파일 경로, 디렉터리 구조 | `Glob`, `Grep` 도구로 실시간 탐색 가능 | 도구 사용 |
| Git 히스토리, 커밋 내역 | `git log`, `git blame`으로 조회 가능 | Bash 도구로 git 명령 실행 |
| 디버깅 솔루션 | 수정 사항은 코드에 이미 반영됨 | 코드 자체가 기록 |
| CLAUDE.md에 이미 있는 내용 | 중복 저장 시 불일치 위험. CLAUDE.md가 정본(authoritative source) | CLAUDE.md 참조 |
| 일시적 작업 상세 | "지금 X 파일 수정 중" 같은 정보는 세션 종료 후 무의미 | 세션 내 컨텍스트로 충분 |

**판단 기준 — "이 정보가 없어도 Claude가 코드를 읽어서 알아낼 수 있는가?"**

- YES → 저장하지 않는다
- NO → 저장 후보이다 (사용자 선호, 비즈니스 결정, 외부 시스템 참조 등)

### 5.5 실제 프로젝트 메모리 사례 (bright-data-test)

bright-data-test 프로젝트는 자동 메모리 시스템이 실제로 작동하는 완전한 사례를 보여준다. 이 프로젝트의 메모리 디렉터리 구조와 각 파일의 역할을 상세히 분석한다.

```
~/.claude/projects/-home-user-projects-bright-data-test/memory/
├── MEMORY.md               ← 인덱스 (4줄)
├── user_profile.md          ← type: user
├── feedback_workflow.md     ← type: feedback  
└── project_context.md       ← type: project
```

**MEMORY.md (인덱스):**

```markdown
- [사용자 프로파일](user_profile.md) — 기술 수준, 작업 스타일, 품질 기준, 언어 선호
- [워크플로우 피드백](feedback_workflow.md) — NLM URL 정책, 환각 방지, 신뢰도 상한, 에이전트간 상태 파일
- [프로젝트 컨텍스트](project_context.md) — 프로젝트 목표, 12개 아키텍처 결정, 스킬 구성, 현재 상태, 테스트 결과
```

4줄로 모든 메모리를 인덱싱한다. 200줄 한도 대비 매우 여유 있으며, 각 줄의 설명(hook)이 구체적이어서 Claude가 관련성을 즉시 판단할 수 있다.

**user_profile.md — 사용자 컨텍스트 보존:**

```yaml
---
name: user_profile
description: 기술 수준, 작업 스타일, 품질 기준, 언어 선호
type: user
---
```

```markdown
## 기술 수준
- TypeScript/Node.js: 중급 (API 연동, 비동기 패턴 이해)
- Python: 고급 (데이터 파이프라인, 분석)
- Web Scraping: 중급 (Puppeteer, Playwright 경험)
- API 테스트: 고급 (REST, 페이지네이션, rate limiting 이해)

## 작업 스타일
- 변경 전 반드시 근거(rationale) 설명 요구
- 한 번에 하나의 API 엔드포인트만 테스트 (병렬 X)
- 실제 API 응답을 fixtures/에 스냅샷으로 저장하는 패턴 선호

## 품질 기준
- API 호출 실패 시 재시도 로직 필수 (최소 3회, 지수 백오프)
- 모든 API 응답에 대해 JSON Schema 검증
- 비용 발생 API 호출은 반드시 사전 확인 요청

## 언어 선호
- 코드 주석: 영어
- 커밋 메시지: 영어 (Conventional Commits)
- 대화 및 보고서: 한국어
```

이 파일 덕분에 새 세션을 열어도 Claude는 "이 사용자는 변경 전 근거 설명을 요구하고, 비용 발생 API 호출 전에 확인을 받아야 한다"는 것을 즉시 알게 된다.

**feedback_workflow.md — 축적된 교정 규칙:**

이 파일에는 6개의 피드백 규칙이 기록되어 있다. 각 규칙은 실제 세션에서 사용자가 Claude의 행동을 수정한 결과이다:

1. **NLM URL 정책**: 존재하지 않는 PubMed URL 생성 금지 → curl로 사전 검증
2. **환각 방지**: API 응답 구조를 추측하지 말고 fixtures/에서 실제 응답 확인
3. **신뢰도 상한**: 검증하지 않은 정보에 단정적 표현 금지
4. **에이전트간 상태 파일**: 멀티 에이전트 작업 시 `_state.json`으로 상태 전달
5. **비용 경고**: Bright Data API 호출은 비용이 발생하므로 테스트 실행 전 예상 비용 표시
6. **타임아웃 처리**: SERP API 타임아웃 시 즉시 실패가 아닌 재시도 + 로그 기록

**project_context.md — 프로젝트 지속성:**

이 파일이 Cursor의 `session_handoff.md`를 대체하는 핵심이다. Cursor에서는 세션 종료 시 수동으로 `session_handoff.md`를 갱신해야 했지만, Claude Code에서는 자동 메모리 시스템이 프로젝트 상태를 자동으로 추적하고 갱신한다.

| Cursor 방식 | Claude Code 방식 |
|---|---|
| 세션 종료 시 수동으로 `session_handoff.md` 갱신 | 자동 메모리가 대화에서 상태 변화 감지하여 갱신 |
| 다음 세션에서 수동으로 "이 파일 읽어줘" | 세션 시작 시 MEMORY.md 인덱스 자동 로딩, 관련 토픽 온디맨드 읽기 |
| 정보 누락 시 세션 간 단절 | 자동 추출이므로 누락 가능성 최소화 |
| 하나의 파일에 모든 것을 기록 | 토픽별 분리로 관련성 기반 선택적 로딩 |

---

