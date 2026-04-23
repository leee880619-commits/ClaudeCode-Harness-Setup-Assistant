---
description: harness-architect 플러그인 사용법, 제공 커맨드, 9-Phase 흐름, 주요 옵션을 안내한다.
---

# harness-architect — 사용법

이 플러그인은 대상 프로젝트를 분석해 Claude Code 하네스(CLAUDE.md, settings, rules, agents, playbooks, hooks, MCP)를 **9-Phase 오케스트레이션**으로 구축합니다.

아래 내용을 사용자에게 **있는 그대로 출력**하세요. AskUserQuestion/Agent 소환 없이 정적 안내만 수행합니다.

---

## 🚀 빠른 시작

```
/harness-architect:harness-setup
/harness-architect:harness-setup /absolute/path/to/project
```

- 인자 없이 호출하면 Phase 0에서 대상 프로젝트 경로를 물어봅니다.
- 인자로 절대 경로를 주면 경로 질문을 생략하고 바로 인터뷰로 진입합니다.
- "빠르게" 또는 `--fast` 를 초기 발화에 포함하면 도메인 리서치(Phase 2.5)를 스킵합니다.

---

## 📋 주요 커맨드 (대부분 여기서 끝남)

| 커맨드 | 역할 | 언제 쓰는가 | 출력 등급 |
|--------|------|------------|----------|
| `/harness-architect:harness-setup [경로]` | **9-Phase 하네스 구축** (메인 진입점) | 신규 프로젝트 | BLOCK / ASK / NOTE |
| `/harness-architect:audit [경로]` | **기존 하네스 통합 감사** — 구성 정합성 + 런타임 부채 + 프로젝트 적합성을 3개 auditor 로 **병렬** 실행 후 단일 통합 보고서 | 기존 하네스 | 통합 Critical/High/Medium/Low/Aligned |
| `/harness-architect:update` | **버전 확인 및 업데이트 안내** — 현재 설치 버전과 최신 릴리즈를 비교, 변경사항 표시 | 업데이트 확인 | — |
| `/harness-architect:help` | 이 사용법 안내 | — | — |

> **두 시나리오**:
> - **시나리오 A — 완전 신규 설치**: `/harness-architect:harness-setup` 만 실행. Phase 9 final-validation 이 빌드 직후 보안·실패 복구 섹션·라우팅 규약·개방형 루프 금지 문구를 모두 검증하므로 추가 감사 불필요.
> - **시나리오 B — 기존 하네스 점검**: `/harness-architect:audit` 한 번. 3개 감사가 병렬 실행되어 통합 보고서 제공.

---

## 🔧 개별 감사 커맨드 (고급 사용자)

특정 축만 깊게 보고 싶을 때 사용합니다. 대부분의 경우 위 `/harness-architect:audit` 하나로 충분합니다.

| 커맨드 | 근본 질문 | 출력 등급 |
|--------|----------|----------|
| `/harness-architect:harness-audit [경로]` | "파일 구조가 올바른가" (구성 정합성·JSON·anti-pattern·매핑) | CRITICAL / HIGH / MEDIUM / LOW |
| `/harness-architect:ops-audit [경로]` | "실행할 때 실패하는가" (세션 연속성·실패 복구·덮어쓰기·Jaccard 중복·라우팅) | RISK-HIGH / RISK-MED / RISK-LOW |
| `/harness-architect:fit-audit [경로]` | "이 프로젝트에 여전히 맞는가" (트랙·아키타입·권한 드리프트·MCP/훅) | MAJOR-DRIFT-CRITICAL / MAJOR-DRIFT-MED / MINOR-DRIFT / ALIGN |

**언제 개별 커맨드가 유용한가**:
- 대규모 하네스 (에이전트 30+ 개·CLAUDE.md 다중 @import) 에서 통합 감사가 메인 세션 컨텍스트를 과도하게 점유할 때 → 개별 커맨드 순차 실행
- CI 파이프라인에서 특정 축만 자동 검사할 때
- 감사 결과 재현 · 비교가 필요해 단일 축의 보고서를 따로 저장하고 싶을 때

**축 → 커맨드 매핑**:
- **권한 안전성** (`Bash(*)` / `sudo *` / 비밀값 노출 / 필수 deny 부재) → `/harness-architect:harness-audit` (CRITICAL 등급이 보안 침해 직결 케이스를 독립 커버)
- **운영 중 무한 루프·세션 복구 실패·산출물 덮어쓰기** → `/harness-architect:ops-audit`
- **하네스가 프로젝트와 여전히 맞는지** (솔로→팀 전환, CLI→모노레포, 도메인 피봇, MCP 엔드포인트 변경) → `/harness-architect:fit-audit`
- **anti-pattern·JSON 파싱·에이전트↔플레이북 매핑** → `/harness-architect:harness-audit`

SSoT 공유 항목(W4 절대 경로·W16 Jaccard 중복) 에서 판정 충돌 시 **ops-audit 결과 우선** 규약이 두 감사 모두에 적용됩니다.

---

## 🔁 9-Phase 워크플로우

| Phase | 내용 | 산출물 |
|-------|------|--------|
| 0 | 경로 수집 + 요청명 생성 | `docs/{요청명}/00-target-path.md` |
| 1-2 | 스캔 + 인터뷰 + 기본 하네스 | `01-discovery-answers.md`, `CLAUDE.md`, `settings.json`, `rules/` |
| 2.5 | (선택) 도메인 리서치 | `02b-domain-research.md` |
| 3 | 워크플로우 설계 | `02-workflow-design.md` |
| 4 | 파이프라인 설계 | `03-pipeline-design.md` |
| 5 | 에이전트 팀 편성 | `04-agent-team.md`, `.claude/agents/` |
| 6 | SKILL/Playbook 작성 | `05-skill-specs.md`, `.claude/skills/` |
| 7-8 | 훅/MCP 설치 | `06-hooks-mcp.md`, `.claude/hooks/` |
| 9 | 최종 검증 보고 | `07-validation-report.md` |

각 Phase 직후 **Red-team Advisor** 가 BLOCK/ASK/NOTE로 리뷰합니다.

---

## 🧭 주요 특징

- **Agent-Playbook 분리**: WHO(.claude/agents/) vs HOW(playbooks/)
- **Escalation 시스템**: 서브에이전트는 불확실성을 Escalations로 반환, 메인 세션이 AskUserQuestion으로 일괄 질문
- **Phase Gate**: 이전 Phase 산출물 없으면 다음 Phase 차단, 재개 지원
- **중단/재개**: `docs/{요청명}/` frontmatter로 언제든 재진입
- **Meta-Leakage Guard**: 생성물에 플러그인 자체 규칙이 새지 않도록 검증
- **경량 트랙 (Phase L)**: 8개 AND 조건 충족 시 Phase 3-6을 단일 에이전트가 25-35분에 처리. 단일 패스 설계이므로 세션 중단 시 재개 불가 — 처음부터 재실행
- **런타임/운영 가드** (신규): 대상 프로젝트가 에이전트 파이프라인 구조인 경우 Phase 3·4 산출물에 Session Recovery Protocol·Failure Recovery & Artifact Versioning 섹션 필수. Advisor Dim 13이 세션 연속성·실패 복구 종료 조건·에이전트-스킬 이중 관리·산출물 덮어쓰기·환경 이식성을 검증. 일반 웹앱/CLI 프로젝트는 스킵 (메타 누수 방지)
- **사후 감사 통합**: 빌드 후 운영 중 문제는 `/harness-architect:audit` 이 3개 auditor(harness-auditor · ops-auditor · fit-auditor) 를 병렬 실행하여 단일 통합 보고서로 제공. 경량 트랙 하네스는 `session_recovery: not_applicable` / `artifact_versioning: idempotent` 공식 선언으로 RISK-LOW 자동 분류. 특정 축만 깊게 보려면 개별 커맨드(`harness-audit`·`ops-audit`·`fit-audit`) 직접 호출 가능

---

## 🔧 재개(Resume) 사용법

이미 작업 폴더(`<대상>/docs/{요청명}/`)가 있는 상태에서 `/harness-architect:harness-setup` 을 다시 실행하면:

1. 기존 작업 폴더 감지 → "계속 / 새로 시작?" 질문
2. 계속 선택 시 마지막 완료 Phase 다음부터 재개
3. 사용자가 산출물을 직접 편집한 경우 해당 Phase Advisor 재실행

---

## 📦 생성되는 대상 프로젝트 파일

```
<target>/
├─ CLAUDE.md
├─ CLAUDE.local.md
├─ .claude/
│  ├─ settings.json
│  ├─ settings.local.json
│  ├─ rules/*.md
│  ├─ agents/*.md          (에이전트 프로젝트일 때)
│  ├─ skills/*/SKILL.md
│  └─ hooks/*.sh
├─ playbooks/*.md           (에이전트 전용 방법론)
└─ docs/{요청명}/*.md       (Phase 산출물 + 상태)
```

---

## 🛟 문제 해결

- **Phase 진행이 막힘** → Advisor가 BLOCK 2회 반환 시 "무시 / 수동 개입 / 스킵" 선택지 제공
- **Phase 3·4 Dim 13 BLOCK 루프** → 에이전트 파이프라인 프로젝트에서 운영 가드 섹션(Session Recovery Protocol / Failure Recovery & Artifact Versioning) 누락 시 재실행 루프 발생. Phase당 +5~8분 추가 가능. 루프 한도 초과 시 사용자 선택지 제공
- **기존 하네스 점검** → `/harness-architect:audit` 로 통합 감사 (구성 + 런타임 + 적합성 병렬, read-only). 특정 축만 보려면 개별 커맨드 직접 호출
- **경로 오류** → 절대 경로 필수. 공백·한글 경로도 지원
- **플러그인 자체 수정** → `claude --plugin-dir .` 로 개발 모드 진입 (기여자 전용, `CLAUDE.md` 참조)

---

## 🔗 참고

- 레포지토리: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
- 설계 문서: `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- 라이선스: Apache-2.0
