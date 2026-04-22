# Changelog

All notable changes to `harness-architect` are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.1] - 2026-04-22

Advisor 비용 최적화. 실측 세션(`frontend-forge` 하네스 세팅, $9.17)에서 13% 비용($1.2)이 Phase 3-6 Advisor 의 "Dim 6 보안 BLOCK 조기 발행 → 재작업 루프" 에서 발생한 점을 근거로, **Dim 6 시행 시점 localization** 과 **Haiku security-auditor 분리** 두 가지를 적용. 세션당 ~$1.0 절감 예상. "Dim 6 복잡도 게이트 무관 전체 실행" 원칙과 "비밀값 즉시 BLOCK" 원칙은 유지 — 이번 변경은 경량화가 아닌 **시행 지점 명확화**.

### Added
- **신규 에이전트 `security-auditor`** (`.claude/agents/security-auditor.md`) — Haiku 기반 Dim 6 패턴 매칭 전용 보조 에이전트. Phase 9 final-validation Step 5 에서 병렬 소환 가능. Read-only, 검사 대상을 대상 프로젝트의 실제 하네스 파일(`settings.json`, `agents/*.md`, `SKILL.md`, `hooks.json`)로 엄격 제한. 판정 애매 시 `[BLOCK]` 금지, `[ASK]` 로 에스컬레이션하여 Haiku false-positive 리스크 방어. `plugin.json` `agents` 배열에 등록.
- **`playbooks/design-review.md` Dimension 6 재작성** — Phase별 등급 매트릭스 도입. 5열 표(산출물 유형·실제 JSON 패턴·서술적 언급·실제 비밀값·더미 비밀값)로 Phase 3-6/7-8/9 각각의 [BLOCK]/[ASK]/[NOTE] 등급을 명시. "실제 비밀값 vs 더미 플레이스홀더" 판정 기준(난수성+맥락) 추가.
- **`playbooks/final-validation.md` Step 5 3단계 fallback 구조화** — 5-A(security-auditor 소환, 선택적) → 5-B(수동 체크, 항상 수행) → 5-C(자동 도구). security-auditor 실패 시 5-B 로 자동 fallback. 최소 2개 경로 성공해야 Dim 6 게이트 통과로 인정.
- **`.claude/rules/orchestrator-protocol.md` Phase 9 security-auditor 병렬 소환 문구** — 소환 템플릿 인라인. Dim 6 localization 원칙(`[NOTE]` 처리 후 Phase 7-8/9 시행) 명시. `phase-validate` 가 Phase 9 완결성에 대한 최종 권위 유지.

### Changed
- **Red-team Advisor Dim 6 항목 업데이트** (`.claude/agents/red-team-advisor.md`) — "Phase 3-6 설계 마크다운의 서술적 언급은 [NOTE], 실제 JSON 하드 텍스트 위반만 [BLOCK]. 비밀값은 실제 vs 더미 구분하여 각각 [BLOCK]/[ASK]" 로 명시. 이는 "경량화"가 아닌 "시행 시점 localization" 임을 강조.
- **Red-team Advisor Dim 11 항목에 security-auditor 적합성 노트** 추가 — Haiku 배정이 "단순 검증 역할"로 정당함을 명시하여 Model Confirmation Gate 오탐 방지.
- **`ARCHITECTURE.md` 에이전트 집계 업데이트** — `.claude/agents/*.md` 집계를 8개에서 **12개**로 갱신(기존 9 phase workers + red-team-advisor + phase-setup-lite + ops-auditor + 신규 security-auditor). Phase 역할 표에 security-auditor 행 추가.

### Security
- **비밀값 즉시 BLOCK 원칙 불변** — 실제 비밀값(난수성 토큰) 은 Phase 무관 어디서든 즉시 [BLOCK]. 이번 변경은 **더미/플레이스홀더 구분**만 추가 (교육용 예시로 의도된 `<YOUR_API_KEY>` 등은 Phase 3-6 에서 [ASK]). Phase 7-8 실제 파일에는 더미도 [BLOCK].
- **security-auditor Scope Boundary 엄격** — 어시스턴트 프로젝트(`${CLAUDE_PLUGIN_ROOT}`) · 대상 프로젝트 소스 코드 · `docs/` 설계 문서는 검사 범위 **외**. 플러그인 자체 파일 오검사 방지.
- **Dim 6 "복잡도 게이트 무관 전체 실행" 원칙 유지** — 매트릭스는 시행 시점 명확화이며, 모든 위반은 최소 1회 [BLOCK] 으로 승격된다 (Phase 3-6 조기 BLOCK 또는 Phase 7-8/9 최종 BLOCK).

### Rationale
- **왜 Red-team Advisor 전체를 Haiku 로 바꾸지 않았는가**: Red-team Advisor 는 Dim 1~13 중 대다수가 **맥락 추론**(목적-수단 정합성, 암묵적 가정 식별 등) 을 요구. Haiku false-positive 리스크가 크다. 반면 Dim 6 는 grep 수준 패턴 매칭만 필요 → Haiku 로 분리가 자연스러움. `ops-auditor` 가 Sonnet 을 쓰는 이유(운영 부채 맥락 추론) 와 동일 논리.
- **왜 Phase 3-6 [NOTE] 로 하강하는가**: Phase 3-6 산출물은 **설계 마크다운**이며 실제 `settings.json` 권한 목록은 Phase 7-8 에서 확정된다. 설계 스펙의 "이 에이전트는 쉘 실행 필요" 서술을 [BLOCK] 으로 걸면 **premature reject** — 실제 위반은 Phase 7-8 에서 확실히 판정 가능.
- **순비용 효과**: BLOCK 루프 감소(세션당 ~$0.8 절감) + Haiku 분리(~$0.2 절감) = ~$1.0. 보수 추정 -$0.5, 낙관 추정 -$0.8 (Phase 7-8 재작업 1회 가정).

### Breaking
- 없음. 기존 하네스는 영향 없음. Dim 6 매트릭스는 **Advisor 실행 시점의 행동 변경**이며 기존 생성물 재검증 불필요.

## [0.8.0] - 2026-04-22

자동 판별 로직의 구조적 결함 일괄 수정. 기존 시스템은 프론트엔드 프리셋(3-E)·Strict Coding(3-B)·code-researcher(3-D) 판별을 전적으로 **파일 아티팩트** 에만 의존하여, 빈 폴더(greenfield) 프로젝트에서 사용자가 발화로 명시한 의도가 점수 0점으로 묵살되는 맹점이 있었다. 예: 사용자가 "프론트엔드 디자인도 개선" 을 초기 발화에 명시해도 `package.json` 이 없으면 프리셋 자동 주입이 스킵되는 케이스. 이번 릴리즈는 Phase 0 사전 인터뷰에 **구조화된 "품질 축" 멀티셀렉트 질문(A6)** 을 추가하여 판별 입력을 명시적 사용자 답변으로 승격하고, 빈 폴더 greenfield 에서도 사용자 의도가 자동 판별의 공식 입력이 되도록 재설계한다. 경량 트랙 판별 기준도 8→9 로 확장되어 "대규모 마이그레이션/리라이트 의도가 있는 빈 폴더" 가 lightweight 로 오분류되던 역설을 해소한다.

### Added
- **Phase 0 사전 인터뷰 A6 "품질 축" 멀티셀렉트 질문** (`.claude/rules/orchestrator-protocol.md`) — `프론트엔드 디자인·UX` / `Strict Coding` / `보안·컴플라이언스` / `에이전트 파이프라인` / `해당 없음` 중 복수 선택. 답변은 `phase-setup` 에이전트 프롬프트의 `[User Quality Axes]` 로 전달되어 Step 3-B/3-D/3-E 판별의 공식 입력으로 사용된다. 기존 `[Model Tier]` 패턴과 동일.
- **`playbooks/fresh-setup.md` Step 1.5 "User-Declared Structure" 섹션 신설** — A1 자유 서술과 초기 발화에서 에이전트 체인·서비스 분할·외부 의존·마이그레이션 동사·규모/팀 힌트를 구조화 추출하여 산출물 `## Context for Next Phase` 에 기록. Phase 3-4 설계가 발화 구조를 누락하는 것을 방지. 추론이 아닌 발화 증거 기반.
- **트랙 판별 9번째 조건** (`.claude/rules/orchestrator-protocol.md`) — 경량 트랙 AND 조건 8→9 확장. 새 조건: "A6 품질 축 답변 0~1개 (`해당 없음` 포함) AND User-Declared Structure 에 대규모 마이그레이션/리라이트/멀티 서비스(3개 이상)/에이전트 체인 신호 없음". `playbooks/setup-lite.md` Prerequisites 도 9개 조건 목록으로 갱신.

### Changed
- **Step 3-B Strict Coding 판별에 A6 승격 규칙 추가** (`playbooks/fresh-setup.md`) — `[User Quality Axes]` 에 `Strict Coding` 포함 시 스캔 신호 개수 무관하게 `[ASK]` 즉시 승격. 기존 키워드("엄격/정석/프로덕션") 단독 감지 규칙(신호 #7)은 호환 유지. A6 답변이 키워드 파싱보다 우선.
- **Step 3-D code-researcher 감지 기준 OR 조건 확장** — 기존 3개 조건(소스 디렉터리/매니페스트/Language 감지)에 두 가지 추가: (1) A6 품질 축 답변에 `Strict Coding`/`프론트엔드 디자인·UX`/`보안·컴플라이언스` 중 하나 이상 포함, (2) User-Declared Structure 에 마이그레이션·리라이트 신호 존재. 빈 폴더 + "GUI→웹앱 포팅" 발화 케이스가 비코드로 오분류되던 문제 해소.
- **Step 3-E 프론트엔드 프리셋 판별에 A6 우선 규칙 추가** — `[User Quality Axes]` 에 `프론트엔드 디자인·UX` 포함 시 아티팩트 기반 가중치 스코어링을 건너뛰고 `[ASK]` 즉시 승격. 기존 점수 테이블은 A6 에 해당 축이 없는 경우에만 보조로 작동.

### Fixed
- **Greenfield 의도 무시 버그 (핵심)** — 사용자가 "프론트엔드 디자인도 개선" 같은 명시적 의도를 Phase 0 발화에 포함해도 빈 폴더라서 Frontend Signal Score 가 0점 처리되어 프리셋이 스킵되던 버그. 본 릴리즈로 A6 답변이 아티팩트 점수와 OR 결합되어 구조적으로 해소. 동일 구조의 맹점이 Step 3-B/3-D 에도 존재했으며 동일 원리로 수정.
- **빈 폴더 greenfield 가 경량 트랙으로 오분류되던 역설** — 기존 8개 트랙 조건이 모두 "파일/디렉터리 부재 기반" 이라 빈 폴더는 자동으로 lightweight 후보가 됐다. "GUI→웹 대규모 마이그레이션 + 디자인 개선" 같은 대규모 작업 의도가 있는 빈 폴더도 단일-패스 lightweight 로 떨어졌다. 9번째 조건(사용자 발화 의도)이 이 역설을 해소.

### Rationale
키워드·가중치 기반 확장 대안(예: "UI/디자인/프론트엔드" 키워드 +3 가중치 추가)을 검토했으나 세 가지 이유로 기각:
1. **키워드 화이트리스트는 두더지잡기** — "프론트엔드" 는 잡아도 "화면 개선"·"리뉴얼"·"Figma 기반"·"레이아웃 갈아엎기" 같은 표현은 놓친다.
2. **가중치 튜닝의 임의성** — +3 vs +2 근거 부족. 판별기마다 별도 튜닝 필요.
3. **LLM 의 자연어 파싱은 재현성 없음** — 같은 발화도 세션마다 점수가 달라질 수 있음.

대신 Phase 0 에 **구조화된 선택지 질문** 을 한 번 추가하여 사용자 의도를 결정적 입력으로 받는다. 새 품질 축은 옵션 추가만으로 확장 가능하며 키워드 사전 유지보수 부담이 없다.

### Breaking
- **Phase 0 사전 인터뷰 질문 1개 증가** (A5 → A6). 기존 하네스 세팅 흐름은 동일하게 동작하나, 새 세션에서는 품질 축 질문이 추가로 노출된다.
- **트랙 판별 기준 8개 → 9개**. 기존 하네스 재생성·재개 시 이전 버전에서 lightweight 로 분류되던 일부 greenfield 프로젝트가 full 트랙으로 승격될 수 있다.

## [0.7.2] - 2026-04-22

v0.7.1 업데이트 체크 훅의 캐시 스테일 버그 픽스. 이전 구현은 "배너 문자열 전체"를 캐시에 저장했는데, 사용자가 `/plugin update` 로 로컬 버전을 갱신해도 24시간 동안은 캐시된 옛 배너가 계속 출력되어 "이미 최신인데 업데이트하라"는 잘못된 알림이 노출됐다. 이번 패치는 캐시에 "최신 버전 문자열"만 저장하고 매 세션마다 로컬 `plugin.json` 과 비교하도록 재설계하여 로컬 업데이트 직후 즉시 정확한 상태를 반영한다.

### Fixed
- **캐시 스테일 배너 버그** — `scripts/check-update.sh` 재설계. 캐시에 저장하는 내용을 "전체 배너 텍스트"에서 "최신 버전 문자열 (예: `0.7.2`)"로 변경. `CURRENT` 는 매 세션 `plugin.json` 에서 새로 읽고, `LATEST` 는 캐시 또는 API 에서 가져와, 매 세션마다 fresh 비교. 로컬 플러그인 업데이트 후 첫 세션에서 즉시 배너가 사라짐.

### Changed
- **API 실패 복원력 향상** — 기존에는 API 실패 시 캐시를 덮어쓰지 않거나 비웠는데, 이제는 이전 캐시 내용을 유지하면서 타임스탬프만 갱신. 일시적 네트워크 장애에도 직전까지 알려진 "최신 버전" 정보로 배너를 계속 제공.
- **캐시 파싱 방어** — `head -n 1 | tr -d '[:space:]'` 로 개행/공백 정리. `re.match(r"^\d+\.\d+\.\d+")` 정규식이 파싱 실패 시 조용히 no-op (손상된 캐시도 크래시 없이 무시).

### Verified
- 5개 시나리오 스모크 테스트 통과: (1) 구버전+캐시 없음 → 배너, (2) 구버전+캐시 신선 → 배너, (3) **로컬 업데이트 후 스테일 캐시 → 배너 없음 (핵심 픽스)**, (4) 현재==최신 → 배너 없음, (5) 손상 캐시 `asdf` → 조용히 스킵.

## [0.7.1] - 2026-04-22

세션 시작 시 자동 버전 체크 훅 신설. 플러그인 저장소에 새 릴리즈가 올라오면 Claude Code 세션이 열릴 때 `⬆ harness-architect vX.Y.Z 출시됨` 배너를 자동으로 출력해 사용자에게 업데이트를 알린다. 네트워크·쉘·버전 비교 로직은 방어적으로 설계되어 실패 시 사용자 흐름을 방해하지 않는다.

### Added
- **`scripts/check-update.sh` 신규** — SessionStart 훅으로 실행되어 GitHub Releases API (`/repos/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/latest`) 에서 최신 버전을 조회하고, 현재 설치 버전보다 높으면 배너를 stdout 으로 출력한다.
- **하루 1회 캐시** — `/tmp/harness-architect-update-check-$(id -u)` 에 24시간 캐시. 세션을 여러 번 열어도 GitHub API 호출은 사용자당 하루 1회. 사용자별 UID 분리로 공유 `/tmp` 환경 충돌 방지.
- **`.claude/hooks/hooks.json` — `SessionStart` 훅 엔트리 추가**. `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-update.sh` 를 세션 시작 시 실행.

### Security
- **쉘 인젝션 방어** — 플러그인 경로(`CLAUDE_PLUGIN_ROOT`)와 GitHub API 응답을 python 인라인 코드 내부에 보간하지 않고 `sys.argv` 로 전달. 경로에 공백/특수문자가 포함돼도 안전.
- **응답 크기 상한** — `curl --max-filesize 65536` (64KB) 로 악의적 응답의 메모리 소모 차단.
- **타임아웃** — `curl --max-time 5` 로 네트워크 정체 시 세션 시작 지연 최소화.
- **OS 무관 semver 비교** — BSD `sort` 에 없는 `-V` 플래그 대신 python3 튜플 비교 (`re.match(r"^(\d+)\.(\d+)\.(\d+)")`) 로 macOS/Linux/WSL 모두 이식성 확보.
- **실패 시 조용히 종료** — `CLAUDE_PLUGIN_ROOT` 미설정, `plugin.json` 부재, `curl`/`python3` 실패, 네트워크 불가, 파싱 실패 등 모든 엣지케이스에서 `exit 0` 으로 사용자 흐름 비방해.

## [0.7.0] - 2026-04-22

프론트엔드 디자인 프리셋 신설. UI 레이어 중심 프로젝트를 대상 프로젝트로 감지하면 하네스 세팅 과정에서 `frontend-designer` + `frontend-ux-reviewer` 에이전트와 `frontend-design` 진입점 스킬이 자동 주입된다. 외부 스킬 추가 설치 없이 자체 내장 색상 규칙(OKLCH·APCA Lc≥60·WCAG AA·2계층 토큰·60-30-10·색맹 대응)만으로 완결 동작. 생성형 파이프라인은 디자이너→리뷰어 필수 페어로 실행되며 3회차 에스컬레이션 래더(1회 자동재작업·2회 사용자 3선택·3회 중단)가 내장되어 있다. Phase 5·6 및 경량 트랙 모두 프리셋 주입 파일을 재작성·덮어쓰기 금지하는 소유권 보호 규약을 준수한다.

### Added
- **프론트엔드 디자인 프리셋** — UI 레이어 중심 프로젝트 전용 에이전트·스킬·KB 번들.
  - `knowledge/domains/frontend-design.md` (Full 품질 도메인 KB) — 표준 워크플로우 8스텝, 역할/팀 분업, 도구 스택(React/Vue/Svelte/Tailwind/shadcn/Radix 등), 안티패턴 5개, 5개 1차 출처(Refactoring UI·Design Tokens CG·WCAG 2.2·APCA·web.dev INP).
  - `.claude/templates/frontend-design/agents/frontend-designer.md` — 토큰 2계층·상태 매트릭스·접근성·모션까지 통제하는 디자이너 에이전트 템플릿. AI 디폴트 거부 원칙.
  - `.claude/templates/frontend-design/agents/frontend-ux-reviewer.md` — 8차원(D1~D8) 방어적 UX 감사 리뷰어 템플릿. `allowed_dirs: []` 읽기 전용, BLOCK/ASK/NOTE 출력 계약.
  - `.claude/templates/frontend-design/skills/frontend-design/SKILL.md` — 대상 프로젝트 진입점 스킬. 7단계 작업 절차 + **자체 내장 색상 규칙**(OKLCH·APCA Lc≥60·WCAG AA·2계층 토큰·60-30-10·색맹 대응). 외부 스킬(`color-expert`·`interface-design`)은 옵션 보강일 뿐 의존 아님.
- **자가 완결성 원칙** — 이 프리셋은 `.claude/templates/frontend-design/` 번들만으로 완결 동작. 사용자가 외부 스킬을 추가 설치하지 않아도 하네스 세팅 과정에서 전부 자동 주입된다.
- **생성-리뷰 페어 의무화** — `frontend-designer` 의 생성 작업은 `frontend-ux-reviewer` 쌍 리뷰를 필수로 거친다. SKILL.md 와 에이전트 템플릿에 3회차 에스컬레이션 래더(1회 자동 재작업 · 2회 사용자 3선택 · 3회 작업 중단) 내장. 리뷰어 부재는 오류로 처리.
- **프리셋 소유권 보호** — Phase 5(`agent-team.md`)·Phase 6(`skill-forge.md`)·경량 트랙(`setup-lite.md`) Prerequisites 에 "주입된 프리셋 파일은 재작성·덮어쓰기 금지" 규약 추가. Agent Model Table / Agent-Skill 매핑에 "프리셋 주입 — 재작성 제외" 비고 기록. 보완은 `references/` 하위 별도 파일로만.
- **백엔드 역가중치** — `fresh-setup` Step 3-E 가중 점수에 역신호 추가: `server/`/`backend/` 디렉터리(−1), 루트 `Dockerfile`+`docker-compose.yml`(−1), 루트 외 추가 백엔드 매니페스트(−1). 풀스택 모노레포에서 백엔드가 메인일 때의 프리셋 오탐 제안 억제.
- **`allowed_dirs` 자동 재조정** — 프리셋 주입 시 `phase-setup` 에이전트가 대상 프로젝트 실제 디렉터리를 Glob 확인하여 `frontend-designer.md` 의 `allowed_dirs` 를 Edit. 경로 전무 시 `[ASK] 쓰기 권한 디렉터리 확인` Escalation 으로 사용자 답변 대기(안전한 읽기 전용 폴백 유지).

### Security
- `frontend-designer` 의 `allowed_tools` 에서 무제한 `Bash` 권한 제거. 필요 시 `Bash(npm run lint)` 등 구체 패턴으로만 추가 허용.
- **`fresh-setup` Step 3-E 신설** — 프론트엔드 디자인 프리셋 신호 감지 (가중 점수). UI 프레임워크(+2), 메타 프레임워크(+2), 스타일링·UI 컴포넌트·모션·디자인 시스템 디렉터리·외부 토큰 파일 감지(각 +1). 점수 ≥ 3 시 Escalation `[ASK] 프론트엔드 디자인 프리셋 주입?`.
- **도메인 slug 매핑 확장** (`playbooks/domain-research.md`) — "프론트엔드 디자인" / "UI 디자인" / "UI/UX" / "frontend design" → `frontend-design`.
- **시드 KB 표 갱신** (`knowledge/domains/README.md`) — `frontend-design` (full) 항목 추가.

### Research / Credits
- 외부 공개 자료 참고 (번들 없음, 원칙 일반화 재작성): `meodai/skill.color-expert` (MIT, 색상 이론·토큰 아키텍처), `oikon48/cc-frontend-skills` (MIT, Anthropic 공식 블로그 참조 구현), `Dammyjay93/interface-design` (MIT, 토큰 메모리 패턴), `pbakaus/impeccable` (MIT, 동사형 액션 분해 영감).

## [0.6.0] - 2026-04-21

오케스트레이터 런타임 라우팅 레이어 신설. 생성된 하네스가 사용자 요청을 무조건 풀 워크플로우로 태우던 구조적 결함(실측 $18.29 오버런, "복잡 웹앱의 4줄 보안 패치 → 3000줄+ 문서" 사례의 근본 원인)을 해결. 기존 Complexity Gate 구조 강제 방식을 **오케스트레이터 재량 기반 라우팅 프로토콜** 로 대체하고, 코드 확인이 필요할 때 메인 세션이 직접 Read 하지 않도록 `code-researcher` 베이스라인 에이전트를 항상 설치.

### Added
- **오케스트레이터 라우팅 프로토콜 섹션** — 모든 코드 프로젝트의 생성 CLAUDE.md 에 의무 포함. 6개 하위 섹션으로 구성:
  1. 코드 확인 시 `code-researcher` 선호출 원칙 (메인 세션 컨텍스트 오염 방지)
  2. 작업 복잡도 3등급 평가 (S: 직접 처리 / M: 취사선택 / L: 전체 워크플로우)
  3. 리뷰 게이트 우회 금지 — 영구 산출·`mandatory_review` 파이프라인은 S 등급 금지, 최소 M 상향
  4. 애매 시 M 기본, 매우 애매 시 L. 다운그레이드는 사용자 명시 요청 시만
  5. 취사선택은 이 하네스의 `.claude/agents/` 내에서만
  6. 사용자 명시 오버라이드 허용 (Section 3 우회 금지는 오버라이드 불가)
- **`code-researcher` 베이스라인 에이전트 템플릿 신규** (`.claude/templates/common/agents/code-researcher.md`) — `allowed_tools: [Read, Glob, Grep]`, `allowed_dirs: []` 구조적 read-only. `brief` / `standard` / `detailed` 3단계 상세도 지원. 원문 코드 덤프 금지·의견 제시 금지·요청 범위 초과 탐색 금지 가드레일.
- **`fresh-setup` Step 3-D 신설** — 코드 프로젝트 감지 로직 (OR: 소스 디렉터리 / 패키지 매니페스트 / Language 감지). 감지 시 Step 6 에서 자동으로 CLAUDE.md 라우팅 프로토콜 섹션 삽입 + `code-researcher.md` 복사. 비코드 프로젝트는 섹션 생략 + 에이전트 스킵.
- **`setup-lite` Step 1-bis 신설** — 경량 트랙에서 fresh-setup 산출물의 code-researcher 존재 + 라우팅 프로토콜 섹션 존재를 검증. 누락 시 `[BLOCKING]` Escalation 으로 fresh-setup 재소환 유도 (경량 트랙 "산출물 1개" 원칙 유지).
- **ops-audit Dim F 신설** (`playbooks/ops-audit.md`) — "오케스트레이터 라우팅 프로토콜 + 코드 리서처 베이스라인" 검사. 4개 하위 검사:
  - F-1: `## 오케스트레이터 라우팅 프로토콜` ATX 헤더 존재 + placeholder 잔존 검증
  - F-2: `code-researcher.md` 존재, 부재 시 **frontmatter `allowed_tools` 파싱으로 대체자 감지** (grep 키워드 방식보다 FP 감소)
  - F-3: 섹션 본문의 `code-researcher` 참조 확인
  - F-4: 리뷰 게이트 우회 가드 문구(`mandatory_review` / `영구 산출`) 존재 확인
  - Pre-check 로 비코드 프로젝트는 자동 스킵. RISK-HIGH (라우팅 프로토콜 완전 부재) / RISK-MED (리서처 부재·placeholder 잔존·우회 가드 누락) / RISK-LOW (완전 구성 or 면제).

### Changed
- **`workflow-design.md` Step 4-B 전면 재설계** — 기존 Complexity Gate (S/M/L) **구조 강제** 로직을 **라우팅 프로토콜 섹션 의무 포함** 으로 교체. 멀티 에이전트·strict-coding·대형 코드베이스 프로젝트는 추가로 `pipeline-design` Step 2.5 에서 S/M/L 파이프라인 계약을 생성하도록 전달 (라우팅 프로토콜은 상위 레이어).
- **`pipeline-design.md` Step 2.5 조건 명시 강화** — workflow-design Step 4-B 가 "Complexity Gate Pipeline Contracts 생성 필요" 를 전달한 경우에만 수행. 소규모 프로젝트는 라우팅 프로토콜만으로 커버 (계약 테이블 생성 불필요).
- **`ops-auditor.md` description 갱신** — "5개 Dimension" → "6개 Dimension (A~F)".

### Fixed
- **리뷰 게이트 우회 위험 제거** — 라우팅 프로토콜 Section 3 에서 생성·결정·설계·계획·리서치 파이프라인 또는 영구 산출물 생성 작업의 S 등급 분류를 명시적으로 금지하여, 오케스트레이터 재량 부여가 `pipeline-review-gate.md` 의 `mandatory_review` 원칙을 우회할 수 있었던 구조적 취약점 해결.
- **`code-researcher` `allowed_dirs` 주석 정확화** — 빈 배열이 "쓰기 허용 디렉터리 없음" 이라는 의미임을 명시. 읽기 권한은 `allowed_tools` 로 제어됨을 주석에 기록 (유지보수자 오해 방지).

### Migration Notes (기존 사용자 주의)
- **기존 코드 프로젝트 하네스**: `/harness-architect:ops-audit` 실행 시 Dim F 가 라우팅 프로토콜 섹션 부재를 **RISK-HIGH** 로 발행한다. 해소하려면 CLAUDE.md 에 본 릴리스의 라우팅 프로토콜 섹션 템플릿을 수동 추가하거나, `/harness-architect:harness-setup` 재실행 (이 경우 기존 설정을 덮지 않고 섹션만 추가되는 흐름은 향후 과제 — 현재는 수동 편집 권장).
- **기존 하네스에 `code-researcher` 없음**: Dim F 가 **RISK-MED** 발행. `.claude/templates/common/agents/code-researcher.md` 를 대상 프로젝트 `.claude/agents/code-researcher.md` 로 수동 복사하면 해소됨. 기존 리서처 에이전트(`researcher-agent` 등)가 있고 `allowed_tools` 에 쓰기 도구가 없으면 Dim F F-2 가 대체자로 인정하여 추가 설치 불필요.
- **strict-coding-6step 프로젝트**: 기존 `researcher-agent` 와 `code-researcher` 가 공존한다. 두 에이전트는 역할이 다름 — `researcher-agent` 는 `research.md` 파일 산출 (워크플로우 스텝), `code-researcher` 는 오케스트레이터 온디맨드 호출용 (채팅 반환). `phase-team` 재실행 시 역할 중복 `[NOTE]` Escalation 이 발생할 수 있으나 병합이 필수는 아님.
- **비코드 프로젝트(콘텐츠 자동화·순수 문서 저장소)**: 라우팅 프로토콜 섹션 생략 + code-researcher 미설치가 **설계상 정상**. Dim F Pre-check 에서 자동으로 RISK-LOW 면제 처리됨.

### Rejected Alternatives (이 릴리스에서 폐기한 대안)
- **스킬 레벨 lite 모드 분기 주입 (P4)**: 각 SKILL.md 에 "lite 모드 시 문서 생략 가능" 조항을 박는 안. 기각 사유 — 오케스트레이터가 에이전트를 안 부르면 문서도 안 생기므로, 스킬 계약 대수술 없이 오케스트레이터 재량만으로 동일 목적 달성.
- **이중 워크플로우 병렬 설계 (heavy + light)**: 워크플로우를 2개 설계하는 안. 기각 사유 — 단일 풀 워크플로우 + 상위 라우팅 레이어 조합이 더 단순하고 오케스트레이터에게 자유도를 제공.
- **Complexity Gate(S/M/L) 를 모든 프로젝트에 강제**: 소규모 프로젝트에도 동일한 구조 게이트를 박는 안. 기각 사유 — 소규모 프로젝트는 라우팅 프로토콜만으로 충분. 구조 강제는 과설계.

## [0.5.3] - 2026-04-20

CI 오탐지 수정 — `red-team-advisor.md` 환경 이식성 예시 경로가 플러그인 내 하드코딩 경로 검사 grep에 걸리는 문제를 해소.

### Fixed
- **CI false-positive 수정** (`.claude/agents/red-team-advisor.md`) — Dim 13 "환경 이식성" 체크 항목의 예시 경로(`/Users/`, `/home/`, `C:\Users\`)가 CI `Verify plugin-internal references use ${CLAUDE_PLUGIN_ROOT}` 단계의 grep 패턴(`/Users/[A-Za-z0-9._-]`, `C:\\Users`)에 오탐지되던 문제 수정. 예시를 플레이스홀더 형식(`/Users/{user}/`, `/home/{user}/`, `%USERPROFILE%`)으로 변경하여 의미 보존하면서 false-positive 제거.

## [0.5.2] - 2026-04-20

런타임·운영 관점의 하네스 가드를 대규모로 추가. 세션 연속성·실패 복구 종료 조건·산출물 버저닝·에이전트-스킬 이중 관리 부채·크로스 워크플로우 구조 중복·절대 경로 이식성을 설계(Phase 3·4) / 검증(Phase 9) / 사후 감사(신규 커맨드) 세 층위에서 교차 점검하도록 체계화.

### Added
- **`/harness-architect:ops-audit` 커맨드 신설** — 기존 하네스 사후 런타임 감사. 5개 Dimension(A: 세션 연속성, B: 실패 복구 완결성, C: Agent-Skill 이중 관리, D: 산출물 덮어쓰기, E: 크로스 워크플로우 구조 중복). RISK-HIGH/MED/LOW 등급 보고서. 파일 수정 금지 (read-only). 신규: `commands/ops-audit.md`, `playbooks/ops-audit.md`, `.claude/agents/ops-auditor.md`. `plugin.json` agents 배열에 등록.
- **Advisor Dim 13 신설** (`.claude/agents/red-team-advisor.md`, `playbooks/design-review.md`) — "상태 지속성 & 실패 복구 & 운영 부채". **대상 프로젝트 자체가 에이전트 파이프라인/오케스트레이터 구조인 경우에 한해** Phase 3·4·5·6 산출물에 적용 (일반 웹앱/CLI 하네스 설계 산출물에는 스킵하여 메타 누수 방지). 경량 트랙은 상태 지속성·리더 연속성·W5를 NOTE 수준으로 완화하되 W6(덮어쓰기)는 완화 금지.
- **Advisor Dim 12 본문 신설** (`playbooks/design-review.md`) — "파이프라인 리뷰 게이트 준수". `.claude/rules/pipeline-review-gate.md` 규약을 참조 형식으로 요약하여 Phase 4·5·9 각각의 검사 체크리스트만 인라인. 래더·분류 기준 본문은 규약 파일이 SSoT.
- **Phase 3 산출물 필수 섹션**: `## Session Recovery Protocol` — 체크포인트 위치·재개 감지 로직·리더 교체 프로토콜·실패 시나리오 4개 소항목. `playbooks/workflow-design.md` Step 4-E 신설.
- **Phase 4 산출물 필수 섹션**: `## Failure Recovery & Artifact Versioning` — 각 파이프라인별 `max_retries`·timeout·에스컬레이션 분기·버저닝 전략(overwrite_ok/timestamp/version/archive). `playbooks/pipeline-design.md` Step 4.6 신설.
- **Phase 9 Step 15·16 신설** (`playbooks/final-validation.md`) — 절대 경로 하드코딩 감지(`/Users/`, `/home/`, `/mnt/c/Users/`, `C:\Users\` 패턴, 코드 예시 블록 제외), 스킬·플레이북 간 Jaccard 70% 이상 구조 중복 감지.
- **`scripts/validate-phase-artifact.sh` 확장** — 파일명 기반 조건부 필수 섹션 검증. `02-workflow-design.md` → `## Session Recovery Protocol`, `03-pipeline-design.md` → `## Failure Recovery & Artifact Versioning`. 경량 트랙 `02-lite-design.md`는 제외.
- **경량 트랙 공식 운영 가드 선언** (`playbooks/setup-lite.md`) — YAML frontmatter에 `session_recovery: not_applicable` + `artifact_versioning: idempotent` 고정 필드. ops-audit Dim A·D가 이 필드를 감지하여 RISK-LOW 자동 분류 (경량 트랙 사후 감사 오판정 방지). Summary 서두에 "단일 에이전트 단일 패스 — 세션 중단 시 처음부터 재실행 (25~35분)" 명시 필수.
- **harness-audit ↔ ops-audit 역할 경계 공식화** (`playbooks/harness-audit.md` Guardrails) — harness-audit은 설계·구성 진단, 런타임/운영 부채 5개 Dimension은 ops-audit에 위임. Phase 3 진단 리포트 말미에 `/harness-architect:ops-audit` 실행 권장 1줄 안내.
- **커맨드 간 양방향 See also** (`commands/ops-audit.md` description + 본문 "관련 커맨드" 표) — harness-setup/harness-audit/ops-audit 3개의 역할·실행 시점·출력 등급 매트릭스.
- **RISK ↔ BLOCK 등급 매핑 명시** (`commands/ops-audit.md`) — RISK-HIGH ≈ 시급 권장(진행 중단 아님), red-team-advisor BLOCK은 빌드 중 게이팅 전용으로 사후 감사에 대응 개념 없음을 설명.

### Changed
- **소요 시간 고지 확장** (`commands/harness-setup.md`) — 에이전트 파이프라인/표준 경로에 "Advisor 재검토 발생 시 Phase당 +5~8분 추가" 각주 추가. Phase 3·4 운영 가드 섹션 누락 시 Dim 13 BLOCK 루프로 최악 60분+ 소요 가능함을 명시.
- **경량 트랙 고지 강화** (`.claude/rules/orchestrator-protocol.md`) — 트랙 판별 AskUserQuestion 문구에 "단일 에이전트 단일 패스 — 세션 중단 시 재개 불가, 처음부터 재실행 필요" 주의사항 추가.
- **SSoT 양방향 교차 참조 명확화** (`playbooks/final-validation.md` Step 16 ↔ `playbooks/ops-audit.md` Dim E) — Jaccard 70% 임계값과 비교 로직이 두 파일의 양방향 SSoT이며 한쪽 변경 시 다른 쪽 동반 갱신 필수임을 양쪽 주석에 명시.

### Fixed
- **Dim 번호 순서 꼬임 3곳 수정** — `.claude/agents/red-team-advisor.md`의 `11→13→12` 역순, `playbooks/design-review.md`의 `9→11→10→13` 비연속(Dim 12 섹션 누락), `playbooks/final-validation.md`의 `13→15→16→14` 순서. 모두 순방향 연속 재배치. Dim 번호 자체는 불변 유지 (`orchestrator-protocol.md`의 Skip Gate `[Scope] Dim 6+12만 검사` 같은 기존 인용 보존).

### Migration Notes (기존 사용자 주의)
- **기존 하네스 재개 시**: 이 릴리즈로 업데이트 후 재개하는 세션이 Phase 3·4 산출물을 가지고 있으면, `validate-phase-artifact.sh` 가 `## Session Recovery Protocol` 또는 `## Failure Recovery & Artifact Versioning` 섹션 부재로 실패한다. 이 경우 오케스트레이터가 해당 Phase 에이전트를 재소환하여 섹션을 보완한다 — Advisor Dim 13이 "단일 세션 완결 — 복구 프로토콜 미필요" 한 줄 도피를 감지하여 다중 에이전트 프로젝트에서 BLOCK을 재발행할 수 있다.
- **경량 트랙 재진입**: 기존 `02-lite-design.md` 는 `session_recovery`·`artifact_versioning` 필드가 없다. Phase L 에이전트 재소환 또는 사용자 수동 frontmatter 편집 필요.
- **에이전트 파이프라인 프로젝트의 Advisor 비용**: 운영 가드 누락 시 Phase 3·4에서 Advisor 루프가 Phase당 최대 2회 추가 발생할 수 있다 (기존 비용 대비 +$0.8~1.6). 단순 웹앱/CLI 프로젝트는 Dim 13 스킵으로 비용 변화 없음.
- **후속 리팩터링 이슈**: `validate-phase-artifact.sh` 의 Phase별 필수 섹션 목록 하드코딩은 향후 `scripts/artifact-schema.yaml` 분리 검토 대상 (현재는 파일명 4건 분기만 존재하여 drift 리스크 낮음).

## [0.5.1] - 2026-04-20

항상 로드되는 규칙 파일·CLAUDE.md·red-team-advisor 에이전트 정의에서 TMI·중복 정의·과도한 예시 제거. 기능 동작 변경 없음.

### Changed (문서 슬림화)
- **AskUserQuestion 소유권 중복 제거** (`orchestrator-protocol.md`) — `question-discipline.md`와 이중 정의되어 있던 섹션 본문을 링크 한 줄로 축약. 드리프트 위험원 제거.
- **컨텍스트 예산 관리 섹션 삭제** (`orchestrator-protocol.md`) — 규칙이 아닌 정보성 서술이라 제거.
- **Phase별 Context for Next Phase 표 뒤 마무리 문장 / 반환 포맷 섹션별 bullet 설명 제거** (`orchestrator-protocol.md`) — 코드블록 예시로 충분.
- **"스펙 대비 강화된 조건" 이력성 괄호주석 제거** (`orchestrator-protocol.md`) — 판별 기준은 그대로.
- **도메인 식별 절차 서술 압축** (`orchestrator-protocol.md`).
- **Rejected Alternatives 이유 설명 축약** (`orchestrator-protocol.md`).
- **meta-leakage-guard.md 압축** — 영문 장문 해설을 한국어 핵심 규칙으로 재작성. Self-Check 3문항은 유지.
- **pipeline-review-gate.md 원칙/리뷰어 예시/Guardrails 서술 압축** — 리뷰어 예시 3종 → 1종 (research-redteam). 도그푸딩 맥락 설명 제거. 규칙 본문은 그대로.
- **output-quality.md 서브에이전트 실행 모드 플로우 명료화** — 6개 bullet 구조 유지.
- **CLAUDE.md 중요 원칙 섹션 해설 축약** — 각 원칙 1줄 + 규칙 파일 참조.
- **red-team-advisor.md Output Format Tagging 예시 축약** — BLOCK 4건/ASK 2건 → 각 1건.

### Preserved (건드리지 않은 것)
- Phase Gate 필수 산출물 표, 트랙 판별 8조건, Advisor Skip Gate 5조건, Model Confirmation Gate 8단계, 에스컬레이션 래더 3회차, 프론트매터 필드 정의, Dim 1~12 상세 정의, Complexity Gate S/M/L 계약.
- `scripts/validate-phase-artifact.sh`, `scripts/validate-meta-leakage.sh` 등 외부 검증 스크립트.

### Metrics
- 항상 로드되는 규칙 파일·CLAUDE.md 합산 ~53줄 절감 (~1,100 tokens). 세션당 API 비용 절감은 미미(Sonnet ~$0.01, Opus ~$0.06)하나 cache write 페널티 완화 + 장기 세션 compaction 트리거 지연 + 규칙 파일 가독성 향상 효과.

## [0.5.0] - 2026-04-20

실측 비용 데이터 기반의 대대적 비용 최적화 릴리즈. 단일 세션 $12.52 → ~$5 수준을 목표.

### Changed (비용 최적화 — 이 플러그인 자체)
- **Red-team Advisor 모델 다운그레이드** (`red-team-advisor.md`) — `model: opus` → `model: claude-sonnet-4-6`. 6회 Advisor 실행이 전체 비용의 ~34%를 차지하던 최대 드라이버 제거. 예상 절감 ~$3.4/세션. 설계 질 검증보다 체크리스트·패턴 매칭이 주 업무이므로 Sonnet으로 충분.
- **단순 Phase 에이전트 모델 다운그레이드** — `phase-setup`, `phase-workflow`, `phase-hooks`, `phase-validate` 를 `opus` → `claude-sonnet-4-6` 로 변경. 스캔·워크플로우 스텝 나열·훅 wiring·구조 검증은 Sonnet으로 충분. 예상 절감 ~$3.2/세션. 복잡 설계를 요하는 `phase-pipeline`/`phase-team`/`phase-skills`/`phase-domain-research` 는 Opus 유지.

### Added (Advisor 정확도 개선)
- **[Confirmed User Decisions] 필드** (`orchestrator-protocol.md`) — Red-team 소환 템플릿에 이전 Phase들의 AskUserQuestion 응답 누적 목록 전달. Advisor가 이미 사용자가 확정한 사항에 BLOCK/ASK를 잘못 발행하는 구조적 문제(실측 ~$0.8/세션 재작업) 해결. 오케스트레이터는 Phase 0 사전 인터뷰·Escalation 처리·Model Confirmation Gate 응답을 누적해 전달 의무.
- **Advisor Skip Gate** (`orchestrator-protocol.md`) — 풀 트랙 Phase 3/4/7-8 한정, 에이전트 반환 Escalations가 `[BLOCKING]`/`[ASK]` 0건이고 산출물 구조 검증 1회 통과 시 경량 Advisor(Dim 6 보안 + Dim 12 파이프라인 리뷰 게이트만)로 대체. Phase 5·6(설계 중요)·Phase 1-2·2.5·9(전체 검증 필요)는 스킵 금지. 예상 절감 ~$1.5~2.9/세션 (Skip Gate 진입률에 비례).

### Added (대상 프로젝트 하네스 생성 품질)
- **Complexity Gate S/M/L 필수 포함** (`workflow-design.md` Step 4-B) — 에이전트 파이프라인 / 멀티 에이전트 프로젝트는 워크플로우 최상단에 STEP -1 Complexity Gate(태스크 크기 S/M/L 분류)를 **반드시** 포함하도록 강제. 누락 시 보안 패치 4줄 작업도 풀 파이프라인 강제되어 실측 $18.29 수준의 오버비용 발생. S 등급은 메인 세션 직접 편집 허용(`ORCHESTRATOR_DIRECT=1`).
- **ORCHESTRATOR_DIRECT 예외 필수 포함** (`hooks-mcp-setup.md` Step 2) — 대상 프로젝트 `ownership-guard.sh` 템플릿에 S 등급 early-exit 블록 삽입을 필수화. Complexity Gate와 짝을 이뤄 동작. 파괴적 패턴(`rm -rf /` 등)은 계속 차단되도록 위치 지정.
- **Specialist Review 트리거 조건 강화** (`workflow-design.md` Step 4-C) — L 등급 + UI 디렉터리 변경 + 명시적 플래그 3조건 AND 시에만 design/ux/security review 병렬 호출. S/M 등급은 QA 단독. 실측으로 Specialist 3종이 loop-back 포함 L 등급 비용의 ~30% 점유.
- **Handoff 문서 분리 원칙** (`workflow-design.md` Step 4-D) — 세션 간 상태 전달 문서는 `next-session-handoff.md`(최신+직전 1개, 10KB 이내) + `session-history.md`(아카이브, @import 비대상) 분리. 누적 증가 방지. 실측으로 60KB 단일 파일 → 세션당 cache write ~$2~3 추가 비용.

### Technical Notes
- 다운그레이드 대상 4개 Phase 에이전트(phase-setup/phase-workflow/phase-hooks/phase-validate)는 작업 성격이 스캔·나열·wiring·구조 검증 중심이므로 Sonnet으로 충분하다고 판단. **A/B 비교 실측은 아직 수행되지 않음** — v0.5.x 기간 중 누적 세션 데이터로 재검증 예정. 품질 저하가 관측되면 Model Confirmation Gate로 개별 재조정 가능.
- Red-team Advisor 다운그레이드는 Dim 1~12 체크리스트 기반 검증이라 패턴 매칭 성격이 강하다고 판단했으나, **긴 산출물(>500줄) 검토에서 section miss 가능성**이 자체 검증 과정에서 관측됨. 실사용 중 false negative가 누적되면 재조정 필요.
- Skip Gate는 `advisor_status: pass:skip-gate` 접미사로 감사 추적 가능. 재개 시 "경량 검증만 받았음" 식별.
- ORCHESTRATOR_DIRECT는 단일 환경변수가 아니라 **per-task 토큰 + 민감 경로 블랙리스트 + 사용자 명시 승인** 3중 가드로 설계 (hooks-mcp-setup.md Step 2 참조).

## [0.4.1] - 2026-04-18

### Changed
- **Blackbox QA 서버 종료 지침 강제화** (`strict-coding-6step` 템플릿) — 테스트 종료 후 서버가 좀비 프로세스로 남는 문제를 방지하기 위해 다음 변경 적용:
  - `agents/qa-blackbox-agent.md` Rules — Cleanup(서버 종료)을 필수 단계로 명시. 종료 대상을 "서버, 자식 프로세스, 브라우저 자동화 세션, 임시 컨테이너"로 구체화. PASS/FAIL·예외·중단 무관 반환 직전 필수 실행. 직접 기동하지 않은 프로세스는 종료 금지. Cleanup 실패 시 PID·포트를 보고서 Regressions 섹션에 명시.
  - `playbooks/qa-blackbox.md` Workflow — Step 2(환경 준비)에 포트 충돌 사전 확인 및 PID·포트 즉시 기록 의무화 추가. Step 7(Verdict) 직후 Step 8 **"Cleanup (필수)"** 신규 삽입 (docker-compose 포함, 포트 해제 확인, 종료 실패 시 보고 포함). 기존 Step 8 보고서 작성은 Step 9로 이동.
  - `playbooks/qa-blackbox.md` Guardrails — 동일 종료 지침을 이중 방어로 추가. "직접 기동하지 않은 프로세스 종료 금지" 명시.

## [0.4.0] - 2026-04-18

### Added
- **경량 트랙 (Phase L)** — 8개 AND 조건(솔로, 웹앱/CLI, 비에이전트, 에이전트·Strict Coding 신호 없음, 소스 파일 ≤100개·깊이 ≤5, 배포 단순, 단일 서비스) 충족 시 Phase 3-6을 단일 에이전트 `phase-setup-lite`가 25~35분에 처리. 신규: `playbooks/setup-lite.md`, `.claude/agents/phase-setup-lite.md`. Phase L 완료 후 "Phase 7-8 스킵 가능" 플래그 기반 분기 명시.
- **`scripts/validate-phase-artifact.sh`** — Phase 산출물 Markdown 구조 자동 검증. frontmatter 4필드 + 공통 5섹션 + Phase 9 전용 3섹션. Phase Gate에서 오케스트레이터가 명시적 Bash 호출(exit 0/1).
- **`examples/generated/`** — `web-app-solo`(솔로 React/Node 경량 트랙) + `agent-pipeline`(멀티에이전트 딥리서치) 두 가지 참조 예시. `CLAUDE.md` · `settings.json` · rules/agents 포함. sanitized + 버전 메타데이터.
- **`README.md` 30초 퀵스타트** — 설치·실행 3단계 + 생성 파일 트리 + 예상 소요 시간 표(트랙별) 삽입.
- **Phase 9 완료 안내** (`commands/harness-setup.md`) — 완료 후 생성 파일 목록 + 사용법 1~4단계 + 재실행 명령어 출력 지시 추가.
- **Phase 0 소요 시간 고지** (`commands/harness-setup.md`) — 트랙 결정 직후 예상 소요 시간 자동 출력 지시 추가.
- **`CONTRIBUTING.md` 예시 파일 업데이트 체크리스트** — sanitization·버전 메타데이터·파일 수 ≤3개 확인 의무화.

### Changed
- **경량 트랙 판별 조건 5개 → 8개** (`orchestrator-protocol.md`) — 코드베이스 규모(소스 파일 ≤100개·깊이 ≤5), 배포/환경 복잡도(`.env.staging` 없음·CI ≤1개), 서비스 복잡도(단일 서비스) 3개 조건 추가. "솔로=단순" 가정 제거 및 경고 명문화.
- **`fresh-setup.md` 복잡도 신호 스캔 추가** — 소스 파일 수·최대 디렉터리 깊이·환경 파일 목록·CI 워크플로우 수·docker-compose 서비스 수·루트 외 `package.json` 수 6종 스캔 항목 + Context for Next Phase 숫자 형식 기록 명세.
- **Phase Gate 검증 3단계 절차** (`orchestrator-protocol.md`) — 파일 존재 → `validate-phase-artifact.sh` Bash 호출(포맷 루프, 1회) → Advisor BLOCK 루프(2회) 명시적 분리. 소환 템플릿에 `[Output Contract]` 자기점검 체크리스트 추가.
- **`syntax-check.sh`** — Phase 산출물 패턴(`/docs/*/NN-*.md`) 감지 시 `validate-phase-artifact.sh` 경고 신호 출력. exit 0 유지(차단 아닌 경고 전용).
- **`ARCHITECTURE.md`** — Dimensions 표 Dim 11(모델 드리프트)·Dim 12(파이프라인 리뷰 게이트) 추가. Phase L 행, 경량 트랙 8조건, 복잡도 게이트 기준 `track: lightweight` 기반으로 갱신.
- **모델 버전 업데이트** — `claude-sonnet-4-5` → `claude-sonnet-4-6`, `claude-opus-4-6` → `claude-opus-4-7` (에이전트 정의, examples 예시 파일, knowledge 참조 예시).

## [0.3.3] - 2026-04-18

### Changed
- **Phase 에이전트에 `## Input Context` 섹션 추가** — 7개 Phase 서브에이전트(`phase-domain-research`, `phase-workflow`, `phase-pipeline`, `phase-team`, `phase-skills`, `phase-hooks`, `phase-validate`)가 작업 시작 전 **이전 Phase 산출물(`docs/{요청명}/NN-*.md`)을 전체 Read하도록 강제**. 각 에이전트 정의 파일에 필수 입력 파일 목록과 "Summary는 힌트, 파일이 source of truth" 원칙을 명시.
  - 배경: `orchestrator-protocol.md` 는 "다음 에이전트는 이전 파일을 Read하여 `## Context for Next Phase` 섹션에서 상세 컨텍스트를 확보한다"고 **설계 의도**를 기술했으나, 에이전트 정의·플레이북 레벨에서 **강제 지시가 누락**되어 있었음. 에이전트가 프롬프트의 ~200단어 Summary만 보고 작업을 시작할 위험이 실존.
  - 제외: `phase-setup`(Phase 1-2는 선행 산출물 없음 — Phase 0은 경로 수집만), `red-team-advisor`(이미 `orchestrator-protocol.md` 에 "필요 시 Advisor가 직접 이전 산출물을 Read" 명시).
  - Phase 9(`phase-validate`)에는 "전체 산출물(`00~06`)을 교차 검증"하도록 확장 지시.

## [0.3.2] - 2026-04-18

### Changed
- **Strict Coding 6-Step 제안 임계값 이원화** — 기존 "신호 2개 이상 → `[ASK]`" 단일 기준을 이원화:
  - 2개 이상 → `[ASK]` (의사결정 요청, 기존 동작 유지)
  - 정확히 1개 → `[NOTE]` (정보 전달만, 사용자가 Phase 3에서 원하면 채택 가능)
  - 0개 → 기록하지 않음
  - **예외**: 단일 신호가 #7(사용자 의지 발화 — "엄격", "production-ready" 등)이면 `[ASK]`로 승격. 명시적 품질 의지 표명 시 질문 누락 방지.
  - 단일 신호 프로젝트(예: tsconfig strict만 있는 POC)에도 워크플로우 존재를 소개하면서, `question-discipline` 의 "합리적 복수 선택지일 때만 질문" 원칙과 양립.
  - Phase 3 `workflow-design` Step 0 범위 명시: Phase 1-2가 `[ASK]`로 이미 결정 완료한 케이스는 재검토하지 않고, `[NOTE]` 단일 신호 케이스만 재검토 + 사용자 명시 요청 시 채택.
  - 수정: `playbooks/fresh-setup.md` Step 3-B, `playbooks/workflow-design.md` Step 0, `knowledge/13-strict-coding-workflow.md` 적용 판단 기준·절차.

## [0.3.1] - 2026-04-17

### Added
- **Pipeline Review Gate** (`.claude/rules/pipeline-review-gate.md`) — 대상 프로젝트의 워크플로우 파이프라인 중 **생성·결정·설계·계획·리서치** 출력을 내보내는 파이프라인에 대해 **도메인 전문 레드팀 리뷰어** 스텝을 말단에 **필수 포함**하도록 강제하는 권위 규칙. 메타 레벨 Red-team Advisor 패턴을 대상 프로젝트 런타임으로 전파하는 도그푸딩.
  - 파이프라인 분류: `mandatory_review` / `exempt_eligible` (결정론적 변환/단순 I/O/조회/실행만 면제, `exempt_reason` 필수).
  - **에스컬레이션 래더 (3단)** — BLOCK 1회: 오케스트레이터 자동 승인 재실행 / BLOCK 2회: 사용자 AskUserQuestion (재실행·수용·수동 편집) / BLOCK 3회: **작업 전면 중단** + 3선택 (무시·수동 개입·파이프라인 스킵).
  - 리뷰어 도메인 특화 의무 (`{domain}-redteam` 컨벤션), 리뷰어 쓰기 권한 금지, 리뷰의 리뷰 재귀 금지, 복잡도 게이트로 스킵 불가.
- **Phase 4 Step 4.5 — 파이프라인 리뷰 게이트 분류** (`playbooks/pipeline-design.md`). 파이프라인 분류·리뷰어 배치·도메인 Dimension 초안 작성. Output Contract에 `## Pipeline Review Gate` 필수 섹션 추가. Context for Next Phase에 `Pipeline Review Gate Decisions` 표 포함 (Phase 5 리뷰어 프로비저닝 입력).
- **Red-team Advisor Dimension 12 — 파이프라인 리뷰 게이트 준수** (`.claude/agents/red-team-advisor.md`). Phase 4 필수 적용, Phase 5·9 확장 적용. 리뷰 스텝 누락·`exempt_reason` 공백·범용 Advisor 공유 커버·재귀 구조·래더 본문 복붙·리뷰어 쓰기 권한 부여를 BLOCK으로 감지.

### Changed
- `playbooks/pipeline-design.md` Guardrails — 도메인 리뷰어 6개 금지 사항 추가 (누락·공유 커버·쓰기 권한·재귀·래더 복붙·복잡도 스킵). 에이전트 수 상한에서 도메인 리뷰어는 별도 취급.
- Phase 4 산출물 다이어그램 예시 — `mandatory_review` 파이프라인 말단에 리뷰어 스텝 명시, `exempt` 파이프라인은 사유 표기.

### Notes
- 이 변경은 Phase 5(`agent-team`)·Phase 6(`skill-forge`)·Phase 9(`final-validation`) 플레이북 수정 없이 연계됨 — 기존 플레이북이 Phase 4의 Context for Next Phase를 Read하는 구조이므로 자동 전파. 향후 v0.4 에서 도메인 리뷰어용 SKILL.md 템플릿(`{domain}-redteam` 컨벤션 박스) 표준화 예정.

## [0.3.0] - 2026-04-17

### Added
- **Phase 0 A5 — "기본 성능 수준" 인터뷰 질문** (경제형 / 균형형(권장) / 고성능형). 답변은 Phase 5 `phase-team` 프롬프트에 `[Model Tier]` 로 전달되어 에이전트별 모델 자동 배정의 힌트가 된다.
- **Phase 5 모델 매트릭스** (`playbooks/agent-team.md` Step 3). 역할 복잡도(복잡 설계 / 구현 / 단순 검증) × 티어(경제/균형/고성능)의 3×3 매트릭스로 에이전트별 모델을 자동 배정. 매트릭스 이탈 시 근거를 Escalations에 기록.
- **Phase 6 완료 직후 — Model Confirmation Gate** (`.claude/rules/orchestrator-protocol.md`). 스킬 완성 후 에이전트-모델-스킬 통합 표를 1회 AskUserQuestion으로 제시, "전체 승인 / 개별 조정 / 티어 일괄 변경" 선택. 에이전트 ≥ 2 일 때만 실행, 복잡도 게이트와 무관하게 항상 실행. 상대 비용 힌트(Opus ≈ Sonnet × 5, Sonnet ≈ Haiku × 3) 표기.
- **Gate 재소환 상한 2회** + 소진 시 "수용 / 수동 편집" 2선택 (Advisor 루프 패턴과 동일).
- **재소환 후 Dim 11 한정 경량 Advisor 재실행** — 재작성된 `04-agent-team.md` / `05-skill-specs.md` 에 대해 모델 드리프트·미스매치만 재검증.
- **Red-team Dimension 11 — 모델-복잡도 미스매치** (`playbooks/design-review.md`, `.claude/agents/red-team-advisor.md`). Phase 5·6 전용. 복잡 설계에 haiku → BLOCK, 단순 검증에 opus → ASK. `04-agent-team.md` ↔ `.claude/agents/*.md` frontmatter ↔ SKILL.md 3중 드리프트 감지.
- **`05-skill-specs.md` 모델 필드 3중 일관성 검증** (`playbooks/skill-forge.md` Step 9).

### Changed
- **CLAUDE.md에 에이전트 모델 기재 금지** (`playbooks/agent-team.md` Step 6). `## 에이전트 팀 구조` 섹션은 `@import docs/{요청명}/04-agent-team.md` 한 줄만. 모델의 단일 진실(source of truth)은 `.claude/agents/{이름}.md` frontmatter `model` 필드. Confirmation Gate 재조정 시 CLAUDE.md 본문을 건드리지 않아 드리프트 원천 차단.
- **`04-agent-team.md` frontmatter `model_confirmation` 필드** (`pending` / `confirmed` / `manual_override`). 재개 시 `confirmed` 가 아니면 Gate 재진입 대상. 재개 안전 체크: Agent Model Table ↔ agents/*.md frontmatter 1회 sanity check.
- **Rejected Alternatives 누적 상한** — 최근 1개(직전 배정)만 유지, 더 오래된 이관은 한 줄 압축 주석으로 교체 (파일 비대화 방지).
- **메타 누수 정규식 보강** (`checklists/meta-leakage-keywords.md`, `scripts/validate-meta-leakage.sh`) — `기본 성능 수준` / `모델 티어` / `Model Tier` / `Model Confirmation Gate` / `경제형 … 균형형 … 고성능형` 근접 패턴 추가. `docs/{요청명}/NN-*.md` 표준 산출물은 스캔 제외.

## [0.2.2] - 2026-04-17

### Added
- **Q10 — "Ask-first when uncertain" 지침 옵션** (기본 권장: Yes). `playbooks/fresh-setup.md`, `playbooks/cursor-migration.md`에 사용자 질문을 Escalations로 기록하고, Yes 응답 시 생성되는 CLAUDE.md에 "워크플로우·파이프라인과 무관하게 결정이 모호하면 AskUserQuestion으로 먼저 확인" 취지의 1~2줄 규약을 삽입한다.
- `playbooks/harness-audit.md`: Anti-pattern 감지에 `Missing Ask-first directive` (LOW) 추가. 기존 CLAUDE.md 본문 재작성 없이 append-only로 규약을 보강하는 특례 경로 명시.

## [0.2.1] - 2026-04-17

### Added
- `/harness-architect:help` slash command (`commands/help.md`) — 플러그인 사용법, 9-Phase 흐름, 재개 방법, 생성 파일 트리, 문제 해결 안내를 정적으로 출력.

## [0.2.0] - 2026-04-17

### Added
- **Phase 2.5 — Domain Research** (optional). A new agent `phase-domain-research` + playbook `playbooks/domain-research.md` collect industry-standard workflows, team roles, and tool stacks for the project's core domain, using a curated KB first and live web research as fallback.
- `knowledge/domains/` reference KB with 8 seed domains (5 full: deep-research, code-review, technical-docs, website-build, data-pipeline — and 3 stub: webtoon-production, youtube-content, marketing-campaign). Stub domains automatically trigger live search mode.
- `knowledge/domains/README.md` authoring contract: minimum 3 primary sources per full KB, stub/full quality frontmatter field.
- Phase 2.5 artifact: `docs/{요청명}/02b-domain-research.md` (file numbering preserves existing 02-07 chain — no cascade renumbering).
- Phase 3-6 playbooks (`workflow-design`, `pipeline-design`, `agent-team`, `skill-forge`) now optionally Read the Phase 2.5 artifact when present. Domain patterns are cited in downstream designs.
- Red-team Advisor (`playbooks/design-review.md`) gained a Dimension 6 for domain research consistency including source URL validation (renumbered to Dimension 10 in a later change — see below).
- `final-validation.md` Step 1 inventory + Step 3 consistency check now covers `02b-domain-research.md`.
- `.claude/settings.json` allows `WebSearch` and `WebFetch` so Phase 2.5 can run without permission prompts.
- **Slash-command argument support**: `/harness-architect:harness-setup /path/to/project` — Phase 0 의 경로 질문을 생략하고 인터뷰로 바로 진입.
- **Advisor Dimensions 6~9 추가** — 보안 권한 적절성(Dim 6), 타깃 프로젝트 특이성(Dim 7), 에이전트 소유권 충돌(Dim 8), 미기록 결정 감지(Dim 9). 기존 도메인 리서치 정합성은 Dim 10으로 재배치. 각 BLOCK/ASK/NOTE 항목에 `[Dim N]` 태그 부여.
- **Advisor BLOCK 루프 소진 후 3개 선택지** — "무시/수동개입/스킵"을 AskUserQuestion으로 제시. `status: manual_override` 로 frontmatter 갱신.
- **Phase 산출물 YAML frontmatter** (`phase`/`completed`/`status`/`advisor_status`). 기존 HTML 주석은 역호환 fallback.
- **`scripts/validate-settings.sh`** (jq 기반) — `permissions.allow` 위험 패턴·필수 `deny`·비밀값 패턴 정적 검증. Phase 9 `final-validation` Step 5 에서 자동 호출.
- **`scripts/validate-meta-leakage.sh`** — 대상 프로젝트 하네스 생성 파일의 메타 용어 grep/regex 스캔. 인자로 스캔 루트 지정.
- **Phase 7.1 — MCP 설치 실패 복구 프로토콜** (`playbooks/hooks-mcp-setup.md`). 설치 실패 시 settings.json 롤백 + 수동 설치 가이드 Escalation.
- `CONTRIBUTING.md` 보강: Phase/규칙 변경 체크리스트, 명명 규약 (파일명 ↔ frontmatter `name` ↔ `subagent_type` 삼자 일치), 외부 의존성 리스크 섹션, `knowledge/VERSION.md` 범프 가이드, `validate-*.sh` 로컬 테스트 + 파일명 일치 검증 커맨드.
- `examples/cli-arg-usage.md` — 슬래시 커맨드 경로 인자 사용 시나리오 예시.

### Changed
- Domain identification is solicited via Phase 1-2 Escalation (`[ASK] 핵심 도메인 식별`) rather than Phase 0 AskUserQuestion, preserving the Phase 0 "≤4 questions" rule in `question-discipline.md`.
- Fast Track / Fast-Forward paths explicitly specify Phase 2.5 skip triggers ("해당 없음" answer, `--fast` keyword).
- **보안 감사는 복잡도 게이트와 무관하게 항상 전체 실행** (Advisor Dim 6, `final-validation` Step 5). 단순 프로젝트에서도 `Bash(*)` / 비밀값 / 필수 `deny` 검사는 경량화 대상이 아님.
- **Phase Gate가 파일 존재만이 아니라 필수 섹션 헤더 정규식 매칭까지** 검증 (공통 5섹션 + Phase 9의 전용 3섹션).
- **CLAUDE.md 단일 소유자 원칙** — 본문은 Phase 1-2(`phase-setup`)만 작성. Phase 3-6은 `@import` 링크 추가만 허용. 적용 시점: 신규 설치만 (기존 하네스는 `harness-audit` 에서 재구성 확인).
- **`ownership-guard.sh` fail-closed 강화** — TPR 미설정 + `docs/{요청명}/NN-*.md` 경로 쓰기 시도는 exit 1. TPR 미설정 + 플러그인 범위 내 Write는 기여자 모드로 허용하되 stderr 감사 로그.
- **Source of Truth 규약** — 산출물 파일 > Summary. 불일치 시 파일 기준 재작성. Context for Next Phase에 `### 기각된 대안` 하위 항목 필수.
- **Non-blocking Escalation 보류 한계** — 다음 Phase Advisor 리뷰 종료 직후까지만. 2개 이상 Phase 건너뛰며 보류 금지 (맥락 손실 방지).
- **진행 피드백 UX** — 각 Phase 시작 시 "최대 재시도 2회, 예상 소요" 노출. Advisor 재시도 카운터(`🔁 Advisor 재검토 (M/2회차)`), BLOCK 루프 소진 시 별도 안내.
- **Advisor 프롬프트 슬림화** — "Previous Phases Summary"(누적) → "직전 Phase Summary"(N-1만). Advisor가 필요 시 산출물 파일을 직접 Read.
- **재개 프로토콜 강화** — 다수 작업 폴더 선택, 수정 감지 시 상류·하류 Phase 영향 평가, 비표준 파일명 `^[0-9]{2}[a-z]?-[a-z-]+\.md$` 엄격 매칭, 미해결 Escalation 복원.
- **메타 누수 키워드 확장** — 한국어 변형("질문 규율", "점진적 공개 방식", "하네스 설정 도구" 등)·띄어쓰기 변형("메타 누수") 추가. `checklists/meta-leakage-keywords.md` 에 정규식 힌트 섹션 추가.
- **`skill-forge` Guardrail** — 대상 프로젝트의 `.claude/skills/*/SKILL.md` 에 오케스트레이션 로직(에이전트 소환·Phase 전환 지시) 포함 금지. 도메인 로직만 허용.
- **AskUserQuestion 우회 감지** — Escalation 수 0건인데 사용자 확인 없는 결정 흔적이 있으면 `[재확인]` 으로 AUQ에 자동 올림.
- Phase 에이전트 8종 모두 `## Rules` 섹션 최상단에 "⚠ **AskUserQuestion 절대 호출 금지**" 강조 문구.
- `commands/harness-setup.md` "세션 시작 시 필수 로드 4개 Read 지시" 제거 — `.claude/rules/*.md` 가 always-apply 로 자동 로딩되므로 중복. 참고 목록 형태로만 유지.

### Notes
- 레드팀 외부 감사 리포트(`docs/redteam-review-20260417/`) Tier 1-3 지적 31건 중 반영 범위 내 항목 전원 처리. B-State-1 (.state.json 인덱스)은 배포본 호환 비용으로 판정 ✅→🟡 로 투명 하향 — 상세 이력은 `docs/redteam-review-20260417/01-findings.md`.

## [0.1.0] - 2026-04-17

Initial public release (soft launch).

### Added
- Plugin manifest (`.claude-plugin/plugin.json`) with custom component paths for `.claude/agents/`, `commands/`, and `.claude/hooks/hooks.json`.
- Self-hosted single-plugin marketplace (`.claude-plugin/marketplace.json`).
- Orchestrator slash command `/harness-architect:harness-setup` (entry point at `commands/harness-setup.md`).
- 8 Phase workers under `.claude/agents/`:
  `phase-setup`, `phase-workflow`, `phase-pipeline`, `phase-team`, `phase-skills`, `phase-hooks`, `phase-validate`, `red-team-advisor`.
- 11 playbooks under `playbooks/` (Agent-Playbook separation — HOW files, not exposed as Skills to the main session).
- 4 always-apply rules under `.claude/rules/`:
  `orchestrator-protocol`, `question-discipline`, `output-quality`, `meta-leakage-guard`.
- 2 plugin hooks under `.claude/hooks/`:
  `ownership-guard.sh` (PreToolUse Write/Edit — scope guard) and `syntax-check.sh` (PostToolUse Write/Edit — JSON/YAML validation).
- 14-file knowledge base under `knowledge/` (commentary derived from Claude Code documentation).
- 3 validation checklists under `checklists/`:
  `validation-checklist`, `security-audit`, `meta-leakage-keywords`.
- `strict-coding-6step` workflow preset under `.claude/templates/workflows/` for complex coding projects (8 agents + 8 playbooks).
- Documentation: `README.md` (Korean), `ARCHITECTURE.md`, `LICENSE` (Apache-2.0).

### Known limitations
- English README (`README_EN.md`) and `examples/` scenarios are incomplete in this release — see Unreleased.
- Submission to the official Anthropic plugin marketplace has not been completed; installation currently relies on GitHub-hosted marketplace path.

[Unreleased]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.3.3
[0.3.2]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.3.2
[0.3.1]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.3.1
[0.3.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.3.0
[0.2.2]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.2.2
[0.2.1]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.2.1
[0.2.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.2.0
[0.1.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.1.0
