# 13. Strict Coding 6-Step Workflow Preset

복잡한 코딩 프로젝트(프로덕션 품질 추구, 규모 있는 코드베이스, 테스트/DB/CI 인프라 보유)에서
"무지한 변경"과 "잘못된 변경"을 체계적으로 차단하는 빡빡한 개발 워크플로우 preset.

템플릿 위치: `.claude/templates/workflows/strict-coding-6step/`

## 적용 판단 기준

Phase 1-2에서 다음 신호를 수집한다. **2개 이상** 해당 + 에이전트 프로젝트 아님 → 제안.

| # | 감지 신호 | 스캔 방법 |
|---|-----------|-----------|
| 1 | 웹/백엔드 프레임워크 | package.json/requirements.txt의 의존성 |
| 2 | 테스트 인프라 | vitest/jest/pytest/playwright 설정 파일 존재 |
| 3 | DB/ORM 사용 | prisma/, models/, migrations/, typeorm 의존성 |
| 4 | 타입 엄격 모드 | tsconfig `strict: true`, mypy/ruff strict |
| 5 | CI/CD | `.github/workflows/`, `.gitlab-ci.yml` |
| 6 | 규모 | 파일 ≥ 100개 또는 ≥ 5,000 LoC |
| 7 | 사용자 의지 | "엄격", "정석", "프로덕션", "production-ready" 표현 |

## 6단계 요약

| STEP | Agent | Skill | 산출물 |
|------|-------|-------|--------|
| 0 | (오케스트레이터) | — | `docs/{task}/` 폴더 |
| 1 | researcher-agent | code-research | `research.md` |
| 1-1 | web-researcher-agent | web-research | `web_research.md` (조건부) |
| 2 | planner-agent | implementation-planning | `plan.md` |
| 3 | (오케스트레이터) + question-drafter-agent | question-drafting | `questions-draft.md` |
| 4 | redteam-agent | design-redteam | `redteam-review.md` |
| 5 | implementer-agent | code-implementation | 코드 + `implementation-log.md` |
| 6.0 | qa-whitebox-agent | qa-whitebox | `qa-whitebox.md` (항상) |
| 6.1 | qa-blackbox-agent | qa-blackbox | `qa-blackbox.md` (조건부) |

## 정체성 원칙 (이 preset만의 특징)

1. **문제는 정면 돌파** — 우회, 증상 억제, 임시 패치 금지
2. **Agent Teams 필수** — 모든 단계가 전용 에이전트로 실행, 암묵적 컨텍스트 전달 금지
3. **사용자가 결정** — 구현 방향은 사용자 권한
4. **불명확하면 즉시 정지** — 임의 판단 금지, Escalations에 기록

## 적용 절차 (오케스트레이터 관점)

1. Phase 1-2 fresh-setup에서 신호 2개 이상 감지 → Escalations에 `[ASK] Strict Coding 6-Step 권장`
2. 오케스트레이터가 사용자에게 AskUserQuestion으로 확인 (적용 / 커스텀 설계 / 단순 워크플로우)
3. 적용 승인 시, Phase 3~6에서 다음 순서로 설치:
   a. **Phase 3 (workflow-design)**: `orchestrator-workflow.md`를 대상 `.claude/rules/`로 복사. 02-workflow-design.md 산출물은 템플릿의 6단계를 그대로 채택
   b. **Phase 4 (pipeline-design)**: 에이전트-플레이북 매핑 그대로 채택, 프로젝트 스택별 커스터마이징 항목만 Escalation으로 확인. **Orchestrator Pattern Decision은 D-1 고정** (이 템플릿의 전제)
   c. **Phase 5 (agent-team)**: `agents/*.md` 8개를 대상 `.claude/agents/`로, `playbooks/*.md` 8개를 대상 `playbooks/`로 복사. 각 Identity 섹션의 기술 스택·프로젝트명 치환. 절대 `playbooks/*.md`를 대상 `.claude/skills/` 하위로 복사하지 않는다 (메인 세션 우회 방지)
   d. **Phase 6 (skill-forge)**: 플레이북의 `allowed_dirs`를 프로젝트 실제 경로에 맞춰 조정 (특히 code-implementation). qa-blackbox의 "서버 기동 명령"을 실제 명령으로 교체
4. Phase 7-8에서 ownership-guard 훅이 필요한 경우 추가 (솔로 + 단일 구현 에이전트면 불필요할 수도)
5. Phase 9 validation에서 체크리스트: 템플릿 8개 에이전트 + 8개 플레이북 설치 여부, `orchestrator-workflow.md` 위치, `.claude/skills/`에 잘못 배치된 파일이 없는지

## 커스터마이징 체크리스트

각 대상 프로젝트마다 조정해야 하는 항목:

- [ ] `orchestrator-workflow.md` STEP 6.0의 "스크립트 게이트" → 실제 명령으로 치환
- [ ] `playbooks/qa-blackbox.md`의 기동 명령 → 실제 dev 명령 (예: `npm run dev`, `python manage.py runserver`)
- [ ] `playbooks/code-implementation.md`의 `allowed_dirs` → 프로젝트 구조에 맞춰 (기본 `src/`, `tests/`)
- [ ] 각 에이전트의 Identity 섹션 → 프로젝트명·기술 스택 반영
- [ ] CLAUDE.md의 "Agent Team Structure" 섹션 → 이 템플릿 기준으로 재작성

## 이 preset을 쓰지 말아야 할 때

- 프로토타입/POC/학습 프로젝트 — 속도가 더 중요
- 단일 스크립트 또는 소규모 CLI — 오버헤드만 증가
- 콘텐츠 자동화/데이터 파이프라인 — 별도 워크플로우 패턴이 더 적합
- 이미 에이전트 프로젝트 (Fast-Forward 경로 우선)

## 관련 파일

- 템플릿: `.claude/templates/workflows/strict-coding-6step/` (README + 8 agents + 8 playbooks + orchestrator-workflow.md)
- 감지 로직: `playbooks/fresh-setup.md` Step 3-B
- 제안 로직: `playbooks/workflow-design.md` Step 0
