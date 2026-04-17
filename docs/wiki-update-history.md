# harness-architect 업데이트 히스토리

> Confluence 페이지(1004308574)에 붙여넣기 위한 초안. 레퍼런스 레이아웃: all2md 가이드 페이지(848746646).

---

## v0.3.2 — 2026-04-18

**한 줄 요약:** Strict Coding 6-Step 프리셋 제안 임계값을 이원화 — 단일 신호 프로젝트에도 워크플로우를 소개하면서 `question-discipline` 원칙과 양립.

### 변경
- **제안 임계값 이원화** (`playbooks/fresh-setup.md` Step 3-B, `playbooks/workflow-design.md` Step 0, `knowledge/13-strict-coding-workflow.md`):
  - 신호 2개 이상 → `[ASK]` (기존 동작 유지, 의사결정 요청)
  - 신호 정확히 1개 → `[NOTE]` (정보 전달만, Phase 3에서 사용자가 원하면 채택 가능)
  - 신호 0개 → 기록하지 않음
- **신호 #7 단독 승격 예외** — 단일 신호가 사용자 의지 발화("엄격", "production-ready" 등)인 경우 `[ASK]`로 승격. 명시적 품질 의지 표명 시 질문 누락 방지.
- **에이전트 프로젝트 동시 감지 시** — Fast-Forward 경로 우선, Strict Coding 신호는 개수와 무관하게 `[NOTE]`로 강등.
- **Phase 3 Step 0 범위 명시** — Phase 1-2가 `[ASK]`로 이미 사용자 답변을 받은 케이스는 결정 종료로 간주, Step 0는 `[NOTE]` 단일 신호 케이스만 재검토 (+ 사용자 명시 요청 시 채택).

### 비고
- Red-team Advisor 2회 리뷰를 통과. 단순 1→1 하향 제안은 "합리적 복수 선택지일 때만 질문" 원칙과 충돌한다는 BLOCK을 받고, 이원화 + 예외 규칙 설계로 우아하게 해소.
- 기존 2+ 신호 시나리오는 동작 불변(회귀 없음). `[NOTE]` 케이스는 이전엔 아예 기록되지 않던 구간이므로 포지티브 변화.

---

## v0.3.1 — 2026-04-17

**한 줄 요약:** 대상 프로젝트 생성 하네스에 **도메인 전문 파이프라인 리뷰 게이트** + **BLOCK 3단 에스컬레이션 래더** 자동 주입.

### 신규 기능
- **Pipeline Review Gate** (`.claude/rules/pipeline-review-gate.md`) — 메타 레벨 Red-team Advisor 패턴을 대상 프로젝트 런타임으로 전파하는 도그푸딩 규칙.
  - **리뷰 필수 분류** — 생성 / 결정 / 설계 / 계획 / 리서치 파이프라인은 말단에 도메인 전문 레드팀 리뷰어 필수.
  - **면제 가능 분류** — 결정론적 변환 / 단순 I/O / 조회 / 실행만 면제. `exempt_reason` 필수 기재.
  - **도메인 특화 의무** — `{domain}-redteam` 컨벤션 (예: `research-redteam`, `plan-redteam`, `content-redteam`). 범용 Advisor 1명 공유 금지.
  - **리뷰어 쓰기 권한 금지**, **리뷰의 리뷰 재귀 금지**, **복잡도 게이트 스킵 불가**.
- **에스컬레이션 래더 (3단)** — BLOCK 반복 시 처리 규약.
  - 1회차: 메인 오케스트레이터 자동 승인 → 파이프라인 재실행 (사용자 중단 없음).
  - 2회차: 사용자 AskUserQuestion — 재실행 / BLOCK 수용 / 수동 편집.
  - 3회차: **작업 전면 중단** + 3선택 (무시 / 수동 개입 / 파이프라인 스킵).
- **Phase 4 Step 4.5 — 파이프라인 리뷰 게이트 분류** (`playbooks/pipeline-design.md`). 파이프라인 분류 · 리뷰어 배치 · 도메인 Dimension 초안 작성. Output Contract에 `## Pipeline Review Gate` 필수 섹션.
- **Red-team Advisor Dimension 12** — 파이프라인 리뷰 게이트 준수 검사. Phase 4 필수, Phase 5·9 확장 적용. 리뷰 스텝 누락 · `exempt_reason` 공백 · 공유 커버 · 재귀 구조 · 래더 복붙 · 리뷰어 쓰기 권한을 BLOCK으로 감지.

### 변경
- `playbooks/pipeline-design.md` Guardrails — 도메인 리뷰어 관련 6개 금지 사항 추가. 에이전트 수 상한에서 도메인 리뷰어는 별도 취급.
- Phase 4 산출물 다이어그램 예시 — `mandatory_review` 파이프라인 말단에 리뷰어 스텝 명시, `exempt` 파이프라인은 사유 표기.

### 비고
- Phase 5(`agent-team`) · Phase 6(`skill-forge`) · Phase 9(`final-validation`) 플레이북 수정 없이 자동 연계 — 기존 Context for Next Phase Read 흐름을 활용. 향후 v0.4 에서 도메인 리뷰어용 SKILL.md 표준 템플릿 예정.

---

## v0.3.0 — 2026-04-17

**한 줄 요약:** 에이전트 모델 자동 배정(티어 매트릭스) + 스킬 완성 후 단일 Model Confirmation Gate + Dim 11 드리프트 감지.

### 신규 기능
- **Phase 0 A5 — "기본 성능 수준" 인터뷰 질문** (경제형 / 균형형(권장) / 고성능형). 답변은 Phase 5 `phase-team` 프롬프트에 `[Model Tier]` 로 전달.
- **Phase 5 모델 매트릭스** (`playbooks/agent-team.md` Step 3) — 역할 복잡도(복잡 설계 / 구현 / 단순 검증) × 티어(경제·균형·고성능)의 3×3 매트릭스로 에이전트별 모델 자동 배정. 매트릭스 이탈 시 근거를 Escalations에 기록.
- **Phase 6 완료 직후 — Model Confirmation Gate** (`.claude/rules/orchestrator-protocol.md`). 스킬 완성 후 에이전트-모델-스킬 통합 표를 1회 AskUserQuestion으로 제시: "전체 승인 / 개별 조정 / 티어 일괄 변경". 에이전트 ≥ 2 일 때만 실행, 복잡도 게이트와 무관하게 항상 실행. 상대 비용 힌트(Opus ≈ Sonnet × 5, Sonnet ≈ Haiku × 3) 표기.
- **Gate 재소환 상한 2회** + 소진 시 "수용 / 수동 편집" 2선택 (Advisor 루프 패턴 재사용).
- **재소환 후 Dim 11 한정 경량 Advisor 재실행** — 재작성된 `04-agent-team.md` / `05-skill-specs.md` 에 대해 모델 드리프트·미스매치만 재검증.
- **Red-team Dimension 11 — 모델-복잡도 미스매치** (`playbooks/design-review.md`, `.claude/agents/red-team-advisor.md`). Phase 5·6 전용. 복잡 설계에 haiku → BLOCK, 단순 검증에 opus → ASK. `04-agent-team.md` ↔ `.claude/agents/*.md` frontmatter ↔ SKILL.md 3중 드리프트 감지.
- **`05-skill-specs.md` 모델 필드 3중 일관성 검증** (`playbooks/skill-forge.md` Step 9).

### 변경
- **CLAUDE.md에 에이전트 모델 기재 금지** (`playbooks/agent-team.md` Step 6). `## 에이전트 팀 구조` 섹션은 `@import docs/{요청명}/04-agent-team.md` 한 줄만. 모델의 단일 진실(source of truth)은 `.claude/agents/{이름}.md` frontmatter `model` 필드.
- **`04-agent-team.md` frontmatter `model_confirmation` 필드** (`pending` / `confirmed` / `manual_override`). 재개 시 `confirmed` 가 아니면 Gate 재진입 대상.
- **Rejected Alternatives 누적 상한** — 최근 1개(직전 배정)만 유지, 더 오래된 이관은 한 줄 압축 주석으로 교체 (파일 비대화 방지).
- **메타 누수 정규식 보강** — `기본 성능 수준` / `모델 티어` / `Model Tier` / `Model Confirmation Gate` / `경제형 … 균형형 … 고성능형` 근접 패턴 추가. 표준 산출물은 스캔 제외.

### 비고
- Phase 0의 성능 수준 힌트는 **Phase 6 완료 후 한 번에 재조정** 가능 (Phase 5 직후 게이트 없음 — 스킬 복잡도가 드러나야 재조정 근거 성립).

---

## v0.2.2 — 2026-04-17

**한 줄 요약:** "Ask-first when uncertain" 지침 옵션 추가.

### 신규 기능
- **Q10 — Ask-first 지침 옵션** (기본 권장: Yes). `playbooks/fresh-setup.md`, `cursor-migration.md` 에 사용자 질문을 Escalations로 기록. Yes 응답 시 생성되는 CLAUDE.md에 "결정이 모호하면 AskUserQuestion으로 먼저 확인" 규약을 1~2줄 삽입.
- `playbooks/harness-audit.md` Anti-pattern 감지에 `Missing Ask-first directive` (LOW) 추가. 기존 CLAUDE.md 본문 재작성 없이 append-only로 규약을 보강하는 특례 경로 명시.

---

## v0.2.1 — 2026-04-17

**한 줄 요약:** `/harness-architect:help` 슬래시 커맨드 추가.

### 신규 기능
- `/harness-architect:help` (`commands/help.md`) — 플러그인 사용법, 9-Phase 흐름, 재개 방법, 생성 파일 트리, 문제 해결 안내를 정적 출력.

---

## v0.2.0 — 2026-04-17

**한 줄 요약:** 도메인 리서치(Phase 2.5) 도입, 슬래시 커맨드 인자 지원, 레드팀 셀프-개선(31건 반영).

### 신규 기능
- **Phase 2.5 — Domain Research (옵션)**
  - 새 에이전트 `phase-domain-research` + 플레이북 `playbooks/domain-research.md`
  - 프로젝트의 핵심 도메인에 대한 업계 표준 워크플로우·역할·툴스택을 KB 우선 + 웹 리서치 fallback 으로 수집
  - 산출물: `docs/{요청명}/02b-domain-research.md` (기존 02–07 체인 번호 보존)
  - Phase 3–6 플레이북이 Phase 2.5 산출물 존재 시 자동 참조
- **도메인 레퍼런스 KB** — `knowledge/domains/` 에 8개 시드 도메인 (full 5: deep-research, code-review, technical-docs, website-build, data-pipeline / stub 3: webtoon-production, youtube-content, marketing-campaign). stub 은 라이브 검색 자동 트리거.
- **슬래시 커맨드 인자 지원** — `/harness-architect:harness-setup /path/to/project` 로 Phase 0 경로 질문 생략, 인터뷰 바로 진입.
- **Advisor 차원 확장 (Dim 6~10)** — 보안 권한 적절성(6), 타깃 프로젝트 특이성(7), 에이전트 소유권 충돌(8), 미기록 결정 감지(9), 도메인 리서치 정합성(10). BLOCK/ASK/NOTE 에 `[Dim N]` 태그.
- **Advisor BLOCK 루프 소진 탈출구** — 재시도 한도 후 "무시 / 수동개입 / 스킵" 3지선다. 선택 시 frontmatter `status: manual_override`.
- **Phase 산출물 YAML frontmatter** — `phase / completed / status / advisor_status` 필드로 재개 판단.
- **정적 검증 스크립트** — `scripts/validate-settings.sh` (권한/비밀값/필수 deny), `scripts/validate-meta-leakage.sh` (메타 용어 regex 스캔). Phase 9 에서 자동 호출.
- **Phase 7.1 MCP 설치 실패 복구 프로토콜** — 실패 시 settings.json 롤백 + 수동 설치 Escalation.
- `examples/cli-arg-usage.md` 사용 예시 추가.

### 변경
- 도메인 식별을 Phase 0 AskUserQuestion 대신 **Phase 1-2 Escalation** 으로 이동 (Phase 0 "≤4 질문" 규칙 보존).
- **보안 감사는 복잡도 게이트 면제** — 단순 프로젝트도 `Bash(*)` / 비밀값 / 필수 deny 검사 전체 실행.
- **Phase Gate 강화** — 파일 존재뿐 아니라 필수 섹션 헤더(공통 5개 + Phase 9 전용 3개) 정규식 매칭.
- **CLAUDE.md 단일 소유자 원칙** — 본문은 Phase 1-2 만 작성, 후속 Phase 는 `@import` 링크만 추가.
- **`ownership-guard.sh` fail-closed 강화** — TPR 미설정 + 산출물 경로 쓰기 시 exit 1, 플러그인 범위 쓰기는 기여자 모드로 허용하되 stderr 감사 로그.
- **Source of Truth 규약** — 산출물 파일 > Summary. "기각된 대안(Rejected Alternatives)" 하위 항목 필수.
- **Non-blocking Escalation 보류 한계** — 다음 Phase Advisor 종료 직후까지. 2개 이상 Phase 건너뛰기 금지.
- **진행 피드백 UX** — Phase 시작 시 재시도 한도·예상 소요, Advisor 재시도 카운터, BLOCK 루프 소진 안내.
- **재개 프로토콜 강화** — 다중 작업 폴더 선택, 상류·하류 영향 평가, 비표준 파일명 엄격 매칭, 미해결 Escalation 복원.
- **메타 누수 키워드 확장** — 한국어·띄어쓰기 변형 + 정규식 힌트.
- Phase 에이전트 8종 모두 최상단 "⚠ AskUserQuestion 금지" 강조.

### 비고
- 외부 레드팀 감사(`docs/redteam-review-20260417/`) Tier 1-3 지적 31건 중 반영 범위 내 전량 처리. `.state.json` 인덱스(B-State-1)는 배포 호환 비용으로 보류.

---

## v0.1.0 — 2026-04-17

**한 줄 요약:** 최초 공개 릴리스 (soft launch).

### 초기 구성
- 플러그인 매니페스트 + 단일 마켓플레이스 (`.claude-plugin/plugin.json`, `marketplace.json`).
- 오케스트레이터 슬래시 커맨드 `/harness-architect:harness-setup`.
- **8 Phase 워커** — phase-setup, phase-workflow, phase-pipeline, phase-team, phase-skills, phase-hooks, phase-validate, red-team-advisor.
- **11 플레이북** — Agent-Playbook 분리 패턴 (HOW 파일, 메인 세션에 스킬로 노출되지 않음).
- **4 always-apply 규칙** — orchestrator-protocol, question-discipline, output-quality, meta-leakage-guard.
- **2 플러그인 훅** — `ownership-guard.sh` (PreToolUse 범위 가드), `syntax-check.sh` (PostToolUse JSON/YAML 검증).
- **14개 지식 베이스** — Claude Code 문서 기반 해설.
- **3개 검증 체크리스트** — validation, security-audit, meta-leakage-keywords.
- `strict-coding-6step` 워크플로우 프리셋 (8 에이전트 + 8 플레이북).
- 문서: `README.md`(한국어), `ARCHITECTURE.md`, Apache-2.0 라이선스.

### 알려진 제약
- 영문 README, `examples/` 시나리오 일부 미완.
- 공식 Anthropic 플러그인 마켓플레이스 등재 전 — 현재는 GitHub 호스팅 마켓플레이스 경로로 설치.

---

**참고:** 상세 변경 이력은 저장소의 [`CHANGELOG.md`](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/blob/main/CHANGELOG.md) 를 정본으로 한다.
