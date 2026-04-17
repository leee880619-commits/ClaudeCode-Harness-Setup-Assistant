# Changelog

All notable changes to `harness-architect` are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.2.0
[0.1.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.1.0
