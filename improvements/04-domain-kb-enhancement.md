# 개선 사항 4: 도메인 KB 커버리지 확장

> 작성일: 2026-04-18
> 대상 파일: `knowledge/domains/*.md`, `playbooks/domain-research.md`, `.claude/agents/phase-setup.md`

---

## 문제 정의

Phase 2.5(`phase-domain-research`)는 대상 프로젝트의 핵심 도메인에 대해 업계 표준 패턴을 수집·합성한다. 이를 위해 `knowledge/domains/`에 8개의 시드 KB 파일이 존재하며, 각 파일은 53~64줄 수준이다.

현재 구조적 한계:

1. **커버리지 부재**: 8개 도메인만 커버. 게임 개발, 모바일 앱, DevOps/인프라, 데이터 과학, 보안 감사, 임베디드 등 Claude Code 사용 빈도가 높은 도메인 미포함. `playbooks/domain-research.md` Step 1 slug 매핑 테이블에 이 slug들이 없으므로 "매칭 실패 → Step 3 라이브 검색 only 모드"로 fallback됨.

2. **깊이 부족**: `knowledge/domains/README.md`의 "full 등급 작성 규약"은 최소 3개 1차 출처 + 4개 필수 섹션을 요구하나, 현재 `full` 파일(`deep-research.md` 기준 54줄)은 이를 겨우 충족하는 수준. Phase 2.5가 라이브 웹서치(WebSearch ≤ 6 쿼리, WebFetch ≤ 3 페이지) 실패 또는 예산 소진 시, seed만으로는 Phase 3-6이 인용할 수 있는 깊이 있는 패턴을 제공하기 어렵다.

3. **URL 노화**: `deep-research.md`의 Reference Sources에 arXiv URL, Anthropic 블로그 URL이 하드코딩됨. 1년 후 URL이 이동하거나 내용이 변경되어도 파일이 자동 갱신되지 않음.

4. **도메인 감지 신호 부족**: `playbooks/fresh-setup.md`의 phase-setup 에이전트가 Phase 1-2 스캔 결과를 바탕으로 도메인 후보 1~3개를 추정하여 Escalations에 기록하지만, 어떤 신호(파일 패턴, 의존성, 디렉터리 구조)가 어떤 도메인으로 매핑되는지 체계적 규칙이 없어 미스매치 발생 가능.

---

## 도메인 전문가 제안 (Knowledge Engineer 윤재원)

### 1. 새 도메인 우선순위 기준

단순히 "사용 빈도"만으로 우선순위를 정하면 long-tail 도메인이 영원히 커버되지 않는다. 나는 세 가지 기준을 교차 적용하자고 제안한다:

**A. Claude Code 사용 패턴 적합성 (가중치 40%)**
에이전트가 실질적으로 자동화 가치를 창출할 수 있는 도메인인가? 즉, 워크플로우가 반복 가능하고, 역할 분업이 명확하며, 에이전트가 판단할 수 있는 체크포인트가 존재하는가.

예시:
- `game-development` — 게임 루프, QA 자동화, 빌드 파이프라인 → 적합
- `devops-infrastructure` — CI/CD, 인프라 as Code, 온콜 대응 → 적합
- `mobile-app` — 플랫폼별 빌드, 스토어 제출 워크플로우 → 적합
- `data-science` — 실험 추적, 모델 평가 파이프라인 → 적합

**B. 도메인 경계 명확성 (가중치 35%)**
도메인이 다른 도메인과 명확히 구분되는가? 경계가 모호한 도메인(예: "AI 에이전트 프레임워크")은 stub로 먼저 추가하고, 커뮤니티 검증 후 full 승격.

**C. 1차 출처 접근성 (가중치 25%)**
업계 백서, 표준 단체, 컨퍼런스 자료가 공개 접근 가능한가? 비공개 도메인(예: 특정 기업 내부 프로세스)은 stub만 허용.

### 신규 추가 우선순위 도메인 (1차 배치 — stub로 시작)

| 우선순위 | Slug | 근거 |
|---------|------|------|
| 1 | `game-development` | Claude Code 사용자 중 게임 개발자 비율 높음, CI/QA 자동화 수요 명확 |
| 2 | `devops-infrastructure` | IaC, 배포 파이프라인 설계는 에이전트 자동화 효과 큼 |
| 3 | `mobile-app` | iOS/Android 빌드 + 스토어 제출 워크플로우 반복성 높음 |
| 4 | `data-science` | 실험 추적, 피처 엔지니어링, 모델 평가 파이프라인 표준화 수요 |
| 5 | `security-audit` | 보안 점검 워크플로우는 체크리스트가 명확 → 에이전트 적합 |
| 6 | `content-moderation` | 콘텐츠 리뷰 파이프라인, 멀티 레이어 판정 구조 |

### 2. 기존 파일 깊이 보강 방향

`deep-research.md`(54줄 full)와 `webtoon-production.md`(65줄 stub)를 비교하면, full과 stub의 실질적 차이는 "1차 출처 존재 여부"다. 현재 full 파일도 각 섹션 당 2~4개 항목에 그쳐, Phase 2.5가 라이브 검색 없이 Phase 3-6 설계를 지원하기에는 얇다.

보강 방향:
- **표준 워크플로우**: 스텝당 "Claude Code 에이전트가 자동화 가능한 부분"과 "인간 개입 필수 부분" 구분 칼럼 추가
- **안티패턴**: 현재 3~5개 → 5~7개로, 각 안티패턴에 "완화 전략" 추가
- **Project Fit Heuristics 섹션 신설**: Phase 1-2 스캔 결과로 이 도메인을 감지할 수 있는 신호 목록 (파일 패턴, 의존성 키워드, 디렉터리 구조)

예시 (deep-research.md에 추가할 섹션):
```markdown
## Project Fit Heuristics
이 도메인으로 분류할 때 Phase 1-2 스캔에서 감지해야 하는 신호:
- 파일 패턴: `*research*.py`, `*crawler*.py`, `*scraper*.py`
- 의존성 키워드: `langchain`, `langgraph`, `serpapi`, `firecrawl`, `playwright`
- 디렉터리: `research/`, `data/raw/`, `sources/`
- README 키워드: "research", "investigation", "multi-agent", "web search"
```

### 3. URL 노화 문제 해결

현재: `deep-research.md`에 `https://www.anthropic.com/engineering/built-multi-agent-research-system` 등 URL 하드코딩.

해결 방법 — 3계층 추상화:

**계층 1: DOI/arXiv ID로 대체 (논문류)**
URL 대신 `arXiv:2210.03629` 형식으로 기록. DOI는 URL보다 안정적이며, 에이전트가 검색 시 ID로 조회 가능.

**계층 2: 섹션 기반 참조 (블로그/문서류)**
불안정한 URL 대신 "Anthropic 엔지니어링 블로그 > 멀티에이전트 리서치 시리즈"처럼 콘텐츠 위계로 기록. 상세 URL은 `last_verified` 날짜와 함께 부록으로.

**계층 3: `last_verified` 강제 + 자동 경고**
frontmatter의 `last_verified` 필드가 180일 이상 경과한 파일은, Phase 2.5가 Step 2에서 "KB 노화 감지됨 — 라이브 검색으로 보강"을 Escalations에 `[NOTE]`로 기록하도록 `playbooks/domain-research.md`에 규칙 추가.

### 4. 도메인 감지 신호 개선

`playbooks/fresh-setup.md`(또는 phase-setup 에이전트 지침)에 **도메인 감지 규칙 테이블** 추가:

```markdown
## 도메인 감지 신호 테이블
| 감지 신호 | 우선 후보 도메인 | 확신도 |
|----------|----------------|-------|
| `package.json` + `express`/`next`/`react` | website-build | high |
| `requirements.txt` + `pandas`/`scikit-learn`/`torch` | data-science | high |
| `*.gd` (GDScript) 또는 `Assets/` + `UnityEngine` | game-development | high |
| `Dockerfile` + `*.tf` (Terraform) + `k8s/` | devops-infrastructure | high |
| `Podfile` 또는 `build.gradle` + `AndroidManifest.xml` | mobile-app | high |
| `langchain`/`langgraph` imports + `research/` 디렉터리 | deep-research | medium |
| `clip_studio` / `*.csp` + `webtoon`/`manhwa` in README | webtoon-production | medium |
```

이 테이블을 KB 각 파일의 `## Project Fit Heuristics` 섹션과 연동.

### 5. 커뮤니티 기여 구조

`knowledge/domains/README.md`의 "확장" 섹션에 PR 체크리스트 추가:

```markdown
## PR 체크리스트 (새 도메인 KB 기여)
- [ ] frontmatter 필드 4개 완비 (name, slug, quality, sources_count, last_verified)
- [ ] quality: stub이면 TODO 섹션 포함
- [ ] quality: full이면 1차 출처 ≥ 3개 (URL + 발췌일 + 한 줄 요약)
- [ ] 메타 누수 없음 (Phase, Orchestrator, Escalation 등 플러그인 용어 미포함)
- [ ] playbooks/domain-research.md Step 1 slug 매핑 테이블에 라인 추가
- [ ] Project Fit Heuristics 섹션 포함 (감지 신호 ≥ 3개)
```

---

## 레드팀 비판 (Information Architecture Critic 한소희)

윤재원의 제안은 체계적이지만, 몇 가지 근본적인 문제를 직시하지 못했다.

### 비판 1: 유지보수 부담의 선형 증가

윤재원은 6개 도메인을 1차 배치로 추가하자고 한다. 현재 8개 파일의 `last_verified`는 모두 `2026-04-17`로 동일 — 즉 최초 작성 시점에 일괄 생성된 것이다. 이 파일들이 실제로 "검증된" 것인지, 아니면 Claude가 기억에서 생성한 것인지 구분이 어렵다.

`deep-research.md`의 Reference Sources를 보면:
- `https://cookbook.openai.com/` — 하위 문서 URL 없이 루트만 기재. 어떤 페이지에서 인용했는지 불분명.
- `deep-research.md` 본문의 "출처: Anthropic 멀티에이전트 연구 글"은 URL 없이 텍스트만 있음. full 등급 요건 위반 의혹.

현재 `full` 파일도 이미 품질이 의심스러운 상황에서, stub 6개를 더 추가하면 "존재하지만 신뢰할 수 없는 KB"가 늘어날 뿐이다. 검증 비용이 파일 수에 비례하여 증가하지만 검증 주체가 없다.

### 비판 2: "깊은 KB" vs "라이브 웹서치"의 방향성 오류

`playbooks/domain-research.md` Step 2를 보면, `quality: full` KB가 있어도 "보강 목적으로만 옵션 실행 (budget의 절반만 사용)"이다. 즉 라이브 검색은 어차피 실행된다.

라이브 웹서치가 항상 최신 정보를 제공하는데, KB를 늘리는 투자 대비 효과는 무엇인가? KB의 진짜 가치는 "라이브 검색이 실패할 때의 fallback"이다. 그런데 WebSearch ≤ 6 쿼리라는 budget 제약이 있고, 네트워크 불안정 등으로 실패하는 경우는 드물다.

KB를 늘리는 대신, **라이브 검색 budget을 늘리거나 검색 전략을 개선하는 것**이 더 높은 ROI를 제공한다. Phase 2.5가 항상 "KB stub + 라이브 full"로 실행된다면, 굳이 stub를 다수 유지하는 이유가 뭔가?

### 비판 3: 단일 도메인 KB의 혼합 프로젝트 부적합성

실제 Claude Code 사용자의 프로젝트 상당수는 혼합형이다:
- "AI 에이전트 + 게임 NPC" — deep-research + game-development 혼합
- "데이터 파이프라인 + 대시보드 웹앱" — data-science + website-build 혼합
- "DevOps + 보안 감사" — devops-infrastructure + security-audit 혼합

`orchestrator-protocol.md`의 Phase 2.5 소환 분기를 보면, "[Domain Hint]"는 단수로 전달된다. KB도 단일 도메인 파일로 설계되어 있다. 복합 도메인 프로젝트에서는 어떤 KB를 읽어야 하는지 모호하고, 두 KB를 동시에 읽으면 4개 섹션이 충돌할 수 있다.

윤재원이 "도메인 경계 명확성"을 우선순위 기준으로 제시했지만, 실제 프로젝트는 경계가 불명확한 경우가 더 많다.

### 비판 4: 커뮤니티 KB의 품질 관리와 meta-leakage 위험

`knowledge/domains/README.md`의 "메타 누수 금지" 항목:
> "이 플러그인의 행동 규칙(Phase, Orchestrator, Escalation, Playbook 등의 용어)을 KB 본문에 포함하지 않는다."

커뮤니티 기여자는 이 플러그인을 사용하면서 플러그인 내부 용어(Escalation, Phase gate 등)에 노출된다. 기여 PR에서 이 용어들이 KB에 혼입될 가능성이 높다. PR 체크리스트로 막을 수 있지만, 검토자가 없으면 형해화된다.

또한 커뮤니티 KB가 늘면 `playbooks/domain-research.md` Step 1의 slug 매핑 테이블이 길어지고, Phase-setup 에이전트가 이를 한 번에 읽어야 하므로 컨텍스트 소비가 증가한다.

### 비판 5: Phase 2.5가 라이브 서치만으로 충분한가?

솔직히 말하면, `playbooks/domain-research.md`의 Step 3 라이브 검색은:
- `{domain} workflow architecture` 등 6개 템플릿 쿼리
- WebFetch ≤ 3 페이지

이 정도로도 Phase 3-6 설계에 충분한 워크플로우/역할/도구 패턴을 추출할 수 있다. 특히 Claude Sonnet의 사전 지식으로 대부분의 주류 도메인을 커버할 수 있다. KB의 실질적 역할은 "에이전트의 기억에만 의존한 주장 생성"을 막고 "검증된 인용"을 강제하는 것인데, 라이브 검색도 같은 역할을 한다.

KB를 추가하는 것보다, **Step 4 패턴 합성의 출처 강제 규칙을 강화**하는 것이 더 실질적인 품질 향상이다.

---

## 수렴: 윤재원의 반론과 조정

한소희의 비판 중 "유지보수 부담"과 "혼합 도메인 한계"는 타당하다. 그러나 "라이브 서치만으로 충분"에는 동의하지 않는다. 이유:

1. **오프라인/제한 환경**: 기업 환경에서 Claude Code가 외부 웹서치를 할 수 없는 경우(방화벽, 프록시)가 있다. KB가 없으면 Phase 2.5 전체가 무력화된다.

2. **쿼리 품질 의존성**: 라이브 검색 쿼리 템플릿이 도메인에 맞지 않으면 노이즈가 많다. KB는 "이미 큐레이션된 패턴"이므로 검색 품질 의존성을 낮춘다.

3. **기억 기반 서술 방지**: KB에 1차 출처 URL이 있으면 Phase 2.5가 "기억에서 생성"하는 것을 구조적으로 차단한다. 라이브 검색도 이 역할을 하지만, KB는 이미 검증된 출처를 재활용하므로 신뢰도가 높다.

그러나 한소희의 비판을 반영하여 제안을 수정한다:

**수정 1**: 6개 신규 도메인 전체 추가 → **3개 우선, 나머지는 backlog**
- 즉시 추가: `game-development`, `devops-infrastructure`, `data-science` (사용 빈도 + 1차 출처 접근성 높음)
- Backlog: `mobile-app`, `security-audit`, `content-moderation` (커뮤니티 PR로 커버)

**수정 2**: KB 깊이 보강보다 **Step 2 노화 감지 + Step 3 쿼리 개선** 우선
- `last_verified` 180일 경과 → Step 3 full budget 강제 (KB 신뢰도 자동 하향)
- Step 3 쿼리 템플릿에 도메인별 특화 쿼리 추가

**수정 3**: 혼합 도메인 → **복수 slug 지원 (최대 2개)**
- `[Domain Hint]`를 최대 2개 도메인 slug로 확장: `"deep-research + game-development"`
- Phase 2.5가 각 KB를 Read하여 교차 패턴을 합성하되, 충돌 항목은 Escalations에 `[NOTE]` 기록

**수정 4**: 커뮤니티 기여는 **PR 자동 검증 스크립트로 meta-leakage 차단**
- `scripts/validate-domain-kb.sh` 추가: meta-leakage 키워드 + slug 매핑 누락 자동 탐지

---

## 최종 합의된 개선 방향성

한소희와 윤재원이 합의한 핵심 원칙:

> **KB는 "라이브 검색의 대체재"가 아니라 "큐레이션된 기준점"이다. KB를 늘리는 것보다, 기존 KB의 신뢰도를 높이고 라이브 검색과의 연동 로직을 개선하는 것이 우선이다.**

합의 방향:
1. **신규 도메인 추가는 보수적으로** — 즉시 3개(stub), backlog 3개
2. **기존 full KB 강화** — `Project Fit Heuristics` 섹션 추가, 노화 감지 자동화
3. **복수 도메인 지원** — `[Domain Hint]` 최대 2개 slug
4. **라이브 검색 개선** — Step 3 쿼리 템플릿에 도메인별 특화 쿼리 추가
5. **meta-leakage 자동 검증** — 커뮤니티 기여 KB 검증 스크립트

---

## 구현 방법론 (단계별 + 구체적 파일 변경)

### Phase 1: 기존 KB 강화 (즉시 실행 가능)

#### 1-A. 모든 full KB에 `## Project Fit Heuristics` 섹션 추가

각 `knowledge/domains/{slug}.md` 파일 말미에 추가:

```markdown
## Project Fit Heuristics
Phase 1-2 스캔에서 이 도메인으로 분류하는 신호:

### 강한 신호 (high confidence)
- 의존성 키워드: {예: `langchain`, `langgraph`, `serpapi`}
- 파일 패턴: {예: `*crawler*.py`, `*research*.py`}
- 디렉터리 구조: {예: `research/`, `sources/`, `data/raw/`}

### 보조 신호 (medium confidence — 단독으로는 부족)
- README 키워드: {예: "research", "investigation", "multi-agent"}
- 설정 파일: {예: `firecrawl.config.json`}
```

파일별 구체적 신호 (초안):

| 파일 | 강한 신호 |
|------|----------|
| `deep-research.md` | `langchain`/`langgraph` imports, `research/` 디렉터리, `serpapi`/`firecrawl` 의존성 |
| `code-review.md` | `.github/CODEOWNERS`, `reviewdog` CI 설정, PR 템플릿 존재 |
| `technical-docs.md` | `docs/` 디렉터리 + `mkdocs.yml`/`docusaurus.config.js`, `sphinx` 의존성 |
| `website-build.md` | `package.json` + `next`/`nuxt`/`react`/`vue`, `tailwind.config.js` |
| `data-pipeline.md` | `airflow`/`prefect`/`dbt` 의존성, `dags/` 디렉터리, `*.parquet` 파일 |
| `webtoon-production.md` | `*.csp` 파일, README에 "webtoon"/"manhwa"/"에피소드", `episodes/` 디렉터리 |
| `youtube-content.md` | `scripts/` + `thumbnails/` 디렉터리, README에 "youtube"/"영상" 키워드 |
| `marketing-campaign.md` | `campaigns/` 디렉터리, `copy/`/`assets/`, A/B 테스트 설정 파일 |

#### 1-B. `last_verified` 노화 감지 로직을 `playbooks/domain-research.md`에 추가

Step 2 내에 다음 규칙 삽입 (현재 Step 2.2와 Step 2.3 사이):

```markdown
2.5. **노화 체크**: KB frontmatter의 `last_verified` 날짜를 현재 날짜와 비교.
   - 180일 미만: 정상 → Step 2.3으로 진행 (원래 흐름)
   - 180일 이상: "KB 노화됨" → Step 3를 full budget으로 실행 + Escalations에
     `[NOTE] {slug} KB가 {last_verified} 이후 갱신되지 않아 라이브 검색으로 보강함` 기록
   - 365일 이상: Escalations에 `[ASK] {slug} KB가 1년 이상 미갱신 — 업데이트 필요`
```

#### 1-C. Step 1 slug 매핑 테이블 확장 (즉시 추가할 3개 신규 도메인 포함)

`playbooks/domain-research.md` Step 1의 매핑 테이블에 추가:

```markdown
   - "게임 개발" / "game development" / "게임 엔진" → `game-development`
   - "DevOps" / "인프라" / "CI/CD" / "배포 파이프라인" → `devops-infrastructure`
   - "데이터 과학" / "머신러닝" / "ML pipeline" / "feature engineering" → `data-science`
```

### Phase 2: 신규 stub KB 파일 생성 (즉시 추가할 3개)

#### 신규 파일 구조 — `knowledge/domains/game-development.md` 초안

```markdown
---
name: Game Development (Build, QA & Release Pipeline)
slug: game-development
quality: stub
sources_count: 0
last_verified: 2026-04-18
---

# Game Development — 빌드·QA·릴리즈 파이프라인

> **Stub**: 1차 출처 수집 미완. Phase 2.5는 라이브 검색으로 보강한다.

## 표준 워크플로우 (검증되지 않은 추정)

1. **Design Doc & Milestone Planning** — GDD(Game Design Document) 작성, 마일스톤별 기능 범위 확정.
2. **Core Loop Development** — 핵심 게임 루프(이동, 충돌, 점수 등) 구현. 완료 조건: 플레이어블 프로토타입.
3. **Asset Pipeline** — 아트·사운드·애니메이션 에셋 임포트 + 최적화. 완료 조건: 타겟 플랫폼 성능 기준 통과.
4. **QA & Playtesting** — 버그 트래킹, 플레이테스트 세션, 크래시 리포트 수집.
5. **Performance Profiling** — CPU/GPU/메모리 프로파일링, 병목 구간 최적화.
6. **Platform Certification** — 콘솔(PS/Xbox/Nintendo) 또는 스토어(Steam/Apple/Google) 제출 요건 충족.
7. **Release & Live Ops** — 패치 배포, 서버 모니터링, 라이브 이벤트 운영.

## 표준 역할/팀 분업 (검증되지 않은 추정)

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Game Designer | GDD, 레벨 디자인, 밸런싱 | 게임 이론, 분석력 | 1~3 |
| Programmer | 게임 로직, 엔진 통합, 최적화 | C++/C#, 엔진 SDK | 2~10 |
| Artist | 모델링, 텍스처, 애니메이션 | 3D/2D 툴, 아트 파이프라인 | 2~8 |
| QA Engineer | 테스트 케이스, 버그 리포팅, 자동화 | 테스트 방법론, 스크립팅 | 1~5 |
| DevOps/Build Engineer | CI/CD, 빌드 파이프라인, 패치 배포 | Jenkins/GitHub Actions, 패키징 | 1~2 |
| Producer/PM | 마일스톤, 의사소통, 우선순위 | 프로젝트 관리 | 1 |

## 표준 도구·스킬 스택 (검증되지 않은 추정)

- **엔진**: Unity (C#), Unreal Engine (C++/Blueprint), Godot (GDScript)
- **빌드 자동화**: Jenkins, GitHub Actions, FastLane (모바일), GameCI
- **버전 관리**: Git + Git LFS (바이너리 에셋), Perforce (대형 스튜디오)
- **QA**: Jira (버그 트래킹), Xray, TestRail, 자체 플레이테스트 시스템
- **프로파일링**: Unity Profiler, Unreal Insights, RenderDoc, PIX
- **배포**: Steam SDK, Apple TestFlight, Google Play Console, PlayStation DevNet

## 흔한 안티패턴 (검증되지 않은 추정)

1. **"프로토타입 완성=게임 완성" 착각** — 핵심 루프 검증 후 스코프 크립이 폭증. 해결: 마일스톤별 기능 동결 정책.
2. **에셋 파이프라인 후순위** — 아트 에셋을 최적화 없이 임포트하다 빌드 후반 성능 문제 폭발.
3. **QA 최후 단계 투입** — 개발 내내 QA 없다가 출시 직전 투입. 근본 버그 수정 비용 급증.
4. **플랫폼 인증 요건 무시** — 각 플랫폼(콘솔, 스토어)의 기술/법적 요건을 뒤늦게 확인해 제출 실패.
5. **라이브 서비스 인프라 미준비** — 출시 후 급격한 트래픽 대응 실패. 해결: 로드 테스트 사전 수행.

## Project Fit Heuristics

### 강한 신호 (high confidence)
- 의존성/파일: `*.unity`, `*.uproject`, `*.gd` (GDScript), `Assets/` + `ProjectSettings/`
- 설정: `ProjectSettings/ProjectVersion.txt`, `Packages/manifest.json` (Unity)
- CI 설정: `GameCI`, `fastlane` 설정, 빌드 스크립트에 `apk`/`ipa`/`exe` 빌드 타겟

### 보조 신호 (medium confidence)
- README 키워드: "game", "gameplay", "level", "player", "boss", "NPC"
- 디렉터리: `Assets/`, `Content/` (Unreal), `Scenes/`, `Prefabs/`

## TODO (Full로 승격 시 작성 필요)

- [ ] GDC(Game Developers Conference) 발표 자료 1차 출처 수집
- [ ] IGDA(국제 게임 개발자 협회) 표준 워크플로우 참조
- [ ] Unity/Unreal 공식 문서의 프로덕션 파이프라인 가이드
- [ ] 인디 vs AAA 스튜디오 역할 분업 차이 사례
- [ ] 흔한 안티패턴 1차 출처 확인

## Reference Sources

(Stub 상태 — 1차 출처 미확보. Phase 2.5는 라이브 검색으로 보강한다.)
```

#### 신규 파일 구조 — `knowledge/domains/devops-infrastructure.md` 초안

```markdown
---
name: DevOps & Infrastructure (CI/CD and Platform Engineering)
slug: devops-infrastructure
quality: stub
sources_count: 0
last_verified: 2026-04-18
---

# DevOps & Infrastructure — CI/CD 및 플랫폼 엔지니어링

> **Stub**: 1차 출처 수집 미완. Phase 2.5는 라이브 검색으로 보강한다.

## 표준 워크플로우 (검증되지 않은 추정)

1. **IaC 설계** — Terraform/Pulumi로 인프라 코드화. 완료 조건: state 파일 원격 저장소 연동.
2. **CI 파이프라인 구축** — 빌드, 린트, 유닛 테스트, 취약점 스캔 자동화.
3. **CD 파이프라인 구축** — 스테이징 → 프로덕션 배포 자동화 (블루/그린, 카나리).
4. **모니터링·알림 설정** — 메트릭, 로그, 트레이스 수집. 온콜 알림 설정.
5. **보안·컴플라이언스 게이팅** — SAST/DAST, 의존성 취약점 스캔, 정책 준수 체크.
6. **인시던트 대응** — 런북 기반 대응, 포스트모텀 작성.

## 표준 역할/팀 분업 (검증되지 않은 추정)

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Platform Engineer | IaC, 클러스터 관리, 플랫폼 서비스 | Kubernetes, Terraform, 클라우드 SDK | 1~3 |
| DevOps Engineer | CI/CD 파이프라인, 빌드 최적화 | GitHub Actions/Jenkins, Docker | 1~3 |
| SRE | SLO/SLA, 인시던트 대응, 용량 계획 | 모니터링, 분산 시스템 | 1~2 |
| Security Engineer | 파이프라인 보안 게이팅, 취약점 관리 | SAST/DAST 도구, 컴플라이언스 | 1 |

## 표준 도구·스킬 스택 (검증되지 않은 추정)

- **IaC**: Terraform, Pulumi, AWS CDK, Ansible
- **컨테이너/오케스트레이션**: Docker, Kubernetes (EKS/GKE/AKS), Helm
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins, ArgoCD, Flux
- **모니터링**: Prometheus + Grafana, Datadog, New Relic, OpenTelemetry
- **보안**: Trivy (컨테이너 스캔), Snyk, Checkov (IaC 보안), SonarQube
- **클라우드**: AWS, GCP, Azure, Cloudflare

## 흔한 안티패턴 (검증되지 않은 추정)

1. **ClickOps 잔존** — IaC 도입 후에도 콘솔에서 수동 변경. state drift 발생.
2. **단일 환경 배포** — 스테이징 없이 바로 프로덕션 배포. 롤백 비용 폭증.
3. **모니터링 후순위** — 배포 후 모니터링을 나중에 붙이려다 인시던트 대응 실패.
4. **시크릿 하드코딩** — 코드/파이프라인에 API 키 직접 기입. 보안 사고.
5. **포스트모텀 미작성** — 인시던트 후 개선 없이 반복.

## Project Fit Heuristics

### 강한 신호 (high confidence)
- 파일: `*.tf` (Terraform), `*.yaml` in `k8s/` 또는 `helm/`, `Dockerfile` + `docker-compose.yml`
- CI 설정: `.github/workflows/` + 배포 job, `Jenkinsfile`, `.gitlab-ci.yml`
- 의존성: `terraform`, `pulumi`, `ansible`, `helm`

### 보조 신호 (medium confidence)
- 디렉터리: `infra/`, `deploy/`, `charts/`, `manifests/`, `modules/`
- README 키워드: "deployment", "infrastructure", "CI/CD", "kubernetes", "pipeline"

## TODO (Full로 승격 시 작성 필요)

- [ ] DORA(DevOps Research and Assessments) 연구 보고서 1차 출처
- [ ] Google SRE Book 관련 섹션 인용
- [ ] CNCF(Cloud Native Computing Foundation) 가이드라인
- [ ] 흔한 안티패턴 사례 1차 출처 확인

## Reference Sources

(Stub 상태 — 1차 출처 미확보. Phase 2.5는 라이브 검색으로 보강한다.)
```

#### 신규 파일 구조 — `knowledge/domains/data-science.md` 초안

```markdown
---
name: Data Science (ML Experiment & Model Pipeline)
slug: data-science
quality: stub
sources_count: 0
last_verified: 2026-04-18
---

# Data Science — ML 실험 및 모델 파이프라인

> **Stub**: 1차 출처 수집 미완. Phase 2.5는 라이브 검색으로 보강한다.

## 표준 워크플로우 (검증되지 않은 추정)

1. **Problem Framing** — 비즈니스 문제를 ML 태스크(분류/회귀/군집 등)로 정의. 완료 조건: 성공 메트릭 합의.
2. **Data Collection & EDA** — 데이터 수집, 탐색적 데이터 분석. 완료 조건: 데이터 품질 리포트.
3. **Feature Engineering** — 피처 추출, 변환, 선택. 완료 조건: 피처 스토어 등록 또는 파이프라인 코드화.
4. **Model Training & Experiment Tracking** — 하이퍼파라미터 탐색, 실험 로깅(MLflow/W&B). 완료 조건: 베이스라인 대비 개선 확인.
5. **Model Evaluation** — 홀드아웃 세트 평가, 공정성·편향 체크. 완료 조건: 성공 메트릭 달성.
6. **Model Deployment** — 서빙 인프라(REST API, batch) 구축. 완료 조건: 엔드포인트 헬스체크 통과.
7. **Monitoring & Drift Detection** — 데이터/모델 드리프트 모니터링. 완료 조건: 재훈련 트리거 정의.

## 표준 역할/팀 분업 (검증되지 않은 추정)

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Data Scientist | 모델 설계, 실험, 분석 | 통계, ML 프레임워크, Python | 1~4 |
| ML Engineer | 피처 파이프라인, 서빙 인프라 | MLOps, 분산처리, API 설계 | 1~3 |
| Data Engineer | 데이터 수집, 변환, 웨어하우스 | SQL, Spark, Airflow | 1~2 |
| Analytics Engineer | 비즈니스 메트릭, 대시보드 | dbt, BI 툴, SQL | 1 |

## 표준 도구·스킬 스택 (검증되지 않은 추정)

- **실험 추적**: MLflow, Weights & Biases, DVC
- **피처 스토어**: Feast, Tecton, Hopsworks
- **훈련 프레임워크**: PyTorch, TensorFlow, scikit-learn, XGBoost
- **오케스트레이션**: Apache Airflow, Prefect, Kubeflow Pipelines, ZenML
- **서빙**: FastAPI + Docker, BentoML, Triton Inference Server, SageMaker
- **데이터 품질**: Great Expectations, Soda, dbt tests

## 흔한 안티패턴 (검증되지 않은 추정)

1. **실험 미추적** — 노트북에서 실험하고 결과를 기억에 의존. 재현 불가.
2. **트레인-테스트 누수** — 피처 엔지니어링에 테스트 데이터 정보 사용. 과적합 미탐지.
3. **오프라인 메트릭과 비즈니스 메트릭 불일치** — 모델 정확도는 높지만 비즈니스 KPI 무개선.
4. **드리프트 모니터링 부재** — 데이터 분포 변화를 감지 못해 성능 무성능 저하 방치.
5. **모델 버전 미관리** — 어떤 모델이 프로덕션에 있는지 추적 불가.

## Project Fit Heuristics

### 강한 신호 (high confidence)
- 의존성: `pandas`, `scikit-learn`, `torch`/`tensorflow`, `mlflow`, `wandb`
- 파일: `*.ipynb` (Jupyter 노트북), `requirements.txt`/`environment.yml` + ML 패키지
- 디렉터리: `notebooks/`, `models/`, `data/raw/`, `data/processed/`, `experiments/`

### 보조 신호 (medium confidence)
- README 키워드: "model", "training", "accuracy", "dataset", "feature", "prediction"
- CI 설정에 모델 평가 스텝 존재

## TODO (Full로 승격 시 작성 필요)

- [ ] MLOps 업계 리포트(Algorithmia, Gartner) 1차 출처
- [ ] Hidden Technical Debt in Machine Learning Systems (NeurIPS 2015) 인용
- [ ] Sculley et al. "Challenges in Production ML" 관련 안티패턴 출처 확인
- [ ] 피처 스토어 설계 패턴 1차 출처

## Reference Sources

(Stub 상태 — 1차 출처 미확보. Phase 2.5는 라이브 검색으로 보강한다.)
```

### Phase 3: 복수 도메인 지원 (`playbooks/domain-research.md` 개정)

`[Domain Hint]`가 `"deep-research + game-development"` 형식으로 전달될 경우 처리 로직을 Step 1에 추가:

```markdown
### 복수 도메인 처리 (최대 2개)
- `[Domain Hint]`에 `+` 구분자가 있으면 최대 2개 slug로 분리
- 각 slug에 대해 Step 2-3을 순차 실행 (budget을 각 50%씩 분배)
- Step 4 패턴 합성 시 두 KB의 패턴을 교차 적용:
  - 워크플로우: 두 도메인의 스텝을 병합하되 중복 제거, 교차점 `[통합]` 태그
  - 역할: 두 도메인의 역할 중 겹치는 것은 통합, 고유한 것은 유지
  - 충돌 항목(예: 서로 다른 도구 스택 권장): Escalations에 `[ASK] 도구 충돌 — 도메인 A vs 도메인 B 우선순위`
```

`orchestrator-protocol.md` Phase 2.5 소환 분기 프롬프트 템플릿도 동일하게 갱신:
```
[Domain Hint] {slug1} (+ {slug2} — 복합 도메인인 경우)
```

### Phase 4: 커뮤니티 기여 검증 스크립트

`scripts/validate-domain-kb.sh` 신규 생성:

```bash
#!/usr/bin/env bash
# validate-domain-kb.sh — 도메인 KB 파일의 meta-leakage 및 구조 검증

FILE="$1"
ERRORS=0

# meta-leakage 키워드 검사 (checklists/meta-leakage-keywords.md와 동기화)
META_KEYWORDS=("Phase" "Orchestrator" "Escalation" "Playbook" "phase-setup" "harness-architect" "AskUserQuestion" "서브에이전트" "오케스트레이터")
for kw in "${META_KEYWORDS[@]}"; do
  if grep -q "$kw" "$FILE"; then
    echo "ERROR: meta-leakage 키워드 발견 — '$kw' in $FILE"
    ERRORS=$((ERRORS + 1))
  fi
done

# frontmatter 필수 필드 검사
for field in "name:" "slug:" "quality:" "sources_count:" "last_verified:"; do
  if ! grep -q "^$field" "$FILE"; then
    echo "ERROR: frontmatter 필드 누락 — '$field'"
    ERRORS=$((ERRORS + 1))
  fi
done

# full 등급이면 Reference Sources에 URL 존재 확인
if grep -q "^quality: full" "$FILE"; then
  if ! grep -q "https://" "$FILE"; then
    echo "ERROR: quality: full이지만 Reference Sources에 URL 없음"
    ERRORS=$((ERRORS + 1))
  fi
fi

# slug 매핑 확인
SLUG=$(grep "^slug:" "$FILE" | awk '{print $2}')
if ! grep -q "$SLUG" "playbooks/domain-research.md"; then
  echo "WARNING: slug '$SLUG'가 playbooks/domain-research.md Step 1 매핑에 없음"
fi

# Project Fit Heuristics 섹션 확인
if ! grep -q "## Project Fit Heuristics" "$FILE"; then
  echo "WARNING: Project Fit Heuristics 섹션 없음 (추가 권장)"
fi

if [ $ERRORS -eq 0 ]; then
  echo "OK: $FILE 검증 통과"
else
  echo "FAIL: $FILE — $ERRORS 에러"
  exit 1
fi
```

`knowledge/domains/README.md` 확장 섹션에 이 스크립트 실행 방법 추가.

---

## 예상 효과 및 성공 지표

### 정량 지표

| 지표 | 현재 | 목표 (Phase 1-3 완료 후) |
|------|------|------------------------|
| 커버 도메인 수 | 8개 | 11개 (즉시 3개 추가) |
| full 등급 KB 수 | 5개 | 5개 (신규는 stub로 시작) |
| Project Fit Heuristics 섹션 보유 파일 수 | 0개 | 11개 |
| slug 매핑 테이블 항목 수 | 8개 | 11개 |
| Phase 2.5 "매칭 실패 → 라이브 only" 비율 | 높음 | 감소 (게임/DevOps/DS 프로젝트 커버) |
| KB 노화 감지 로직 존재 | 없음 | 있음 (180일 임계값) |
| 커뮤니티 기여 자동 검증 스크립트 | 없음 | 있음 |

### 정성 지표

- Phase 2.5가 "매칭 실패" fallback 없이 3개 추가 도메인에서 KB 기반 패턴 제공
- Phase 1-2 스캔 시 `Project Fit Heuristics`를 참조하여 도메인 후보 정확도 향상
- 복합 도메인 프로젝트에서 2개 slug 조합으로 교차 패턴 합성 가능
- 커뮤니티 PR에서 meta-leakage가 자동으로 탐지되어 검토자 부담 감소

---

## 잔여 리스크 및 완화 방안

### 리스크 1: stub KB의 "검증되지 않은 추정" 신뢰 오용

**위험**: Phase 2.5가 stub KB의 "검증되지 않은 추정" 항목을 실제 업계 표준처럼 Phase 3-6에 전달.

**완화**:
- `domain-research.md` Step 4 패턴 합성 규칙에 "stub KB 출처 항목은 Sources에 `[UNVERIFIED]` 태그로 표시, Escalations에 `[NOTE] stub KB 사용 — 라이브 검색으로 보강 권장` 기록" 추가
- `02b-domain-research.md` 산출물의 `## Domain Identification` 섹션에 `KB 사용 여부: stub` 명시 (이미 템플릿에 있음)

### 리스크 2: 복수 도메인 budget 분배 시 양쪽 모두 얕은 리서치

**위험**: 두 도메인 각각 50% budget → 각 도메인에서 WebSearch 3 쿼리, WebFetch 1.5 페이지만 사용 → 두 도메인 모두 얕은 결과.

**완화**:
- 복수 도메인 처리 시, 두 도메인 중 하나가 full KB이면 해당 도메인의 라이브 검색을 생략하고 다른 도메인에 full budget 집중
- 두 도메인 모두 stub/미매칭이면 오케스트레이터가 Phase 2.5 호출 전에 "두 도메인 모두 리서치 필요 — 예상 소요 증가. 하나만 선택하거나 둘 다 진행?" AskUserQuestion

### 리스크 3: `scripts/validate-domain-kb.sh` 미실행

**위험**: PR 제출자가 스크립트를 실행하지 않아 meta-leakage 혼입.

**완화**:
- `CONTRIBUTING.md`에 PR 체크리스트에 `[ ] scripts/validate-domain-kb.sh knowledge/domains/{slug}.md 실행 및 OK 확인` 추가
- 중장기: GitHub Actions CI에 이 스크립트를 `knowledge/domains/` 파일 변경 시 자동 실행

### 리스크 4: `playbooks/domain-research.md` slug 매핑 테이블 누락

**위험**: 신규 KB 파일은 추가했지만 slug 매핑을 잊어 Phase 2.5에서 "매칭 실패 → 라이브 only"로 fallback.

**완화**:
- `validate-domain-kb.sh`의 slug 매핑 체크가 이를 WARNING으로 감지 (Phase 4 구현 항목)
- `knowledge/domains/README.md` 확장 섹션의 3단계 절차("1. 파일 생성 → 2. slug 매핑 추가 → 3. stub로 시작")를 명확히 유지

### 리스크 5: 한소희 비판의 핵심 — "라이브 서치가 실질적으로 충분한 경우 KB 유지비용 낭비"

**완화 (합의된 입장)**:
- 이 개선안은 KB를 "라이브 서치 대체재"가 아닌 "오프라인 fallback + 큐레이션된 기준점"으로 위치시킴
- KB full 승격은 커뮤니티가 실제로 1차 출처를 검증한 경우에만 허용 (기여 PR 게이팅)
- KB가 실질적 가치를 제공하지 못한다고 판단되면, 해당 도메인 slug를 "deprecated" 처리하고 라이브 only 모드로 전환하는 옵션을 `knowledge/domains/README.md`에 명시
