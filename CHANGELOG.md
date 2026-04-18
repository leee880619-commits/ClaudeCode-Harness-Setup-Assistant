# Changelog

All notable changes to `harness-architect` are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
