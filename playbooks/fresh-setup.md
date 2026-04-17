
# Fresh Project Setup

## Goal
Generate a complete, project-specific Claude Code harness based on the user's explicit answers and automated project scanning.

## Prerequisites
- Target project path has been provided and validated
- No existing `.claude/` directory in the target (otherwise suggest /harness-audit)
- Scan results from CLAUDE.md Session Start Protocol are available

## Knowledge References
When you need file format specs, use the Read tool:
- `knowledge/03-file-reference.md` — All 18 Claude Code file specifications
- `knowledge/05-skills-system.md` — SKILL.md format and patterns
- `knowledge/06-hooks-system.md` — Hooks configuration patterns
- `knowledge/02-composition-rules.md` — Settings merge rules (for permission design)

Load these ON-DEMAND with Read tool. Never load all at once.

## 질문 소유권 (매우 중요)

이 스킬은 **서브에이전트에서 실행**된다. 서브에이전트는 AskUserQuestion을 사용할 수 없다.
모든 "사용자에게 확인"은 반드시 **Escalations 섹션 기록**으로 구현한다. 오케스트레이터가
Phase 완료 후 Escalations를 취합하여 AskUserQuestion으로 사용자에게 일괄 질문한다.

## 오케스트레이터가 프롬프트로 전달하는 사전 수집 답변

Phase 0에서 오케스트레이터가 AskUserQuestion으로 이미 수집한 답변이 프롬프트에 포함되어
전달된다. 이 스킬은 그 답변을 **받아서 사용**한다. 재질문 금지.

사전 수집 답변(프롬프트에 포함):
- A1. 프로젝트 이름 + 한 줄 설명
- A2. 프로젝트 유형 (웹 앱 / CLI / 에이전트 파이프라인 / 데이터 / 콘텐츠 자동화 / 기타)
- A3. 솔로 / 팀 여부 (팀이면 대략 인원)
- A4. Fast-Forward 요청 여부 (선택)
- A5. **기본 성능 수준** — `경제형` / `균형형` / `고성능형` 중 택1. Phase 5 에서 에이전트 모델 기본 배정에 사용됨. 누락 시 `균형형` 기본값으로 진행하고 Escalations에 `[NOTE] A5 미응답 → 균형형 기본값` 기록.

프롬프트에 A1~A3 답변이 **누락**된 항목이 있으면 Escalations에 `[BLOCKING] A{N} 답변 누락`으로 기록하여
오케스트레이터가 재수집하도록 요청한다. 스킬이 직접 사용자에게 묻지 않는다.

**A5 값은 산출물(`01-discovery-answers.md`) "Pre-collected Answers" 에 원값(예: `균형형`) 그대로 기록한다.** 라벨 전문("경제형 - Haiku 위주...")을 CLAUDE.md·rules·agents 등 대상 프로젝트 생성물에 복제하지 않는다(메타 누수 회피).

## Fast Track Mode

프롬프트에 `--fast` 또는 "빠르게 해줘"가 포함된 경우:

1. 스캔 결과 자동 수집 (아래 Step 1)
2. 사전 수집 답변(A1~A3) + 스캔 결과만으로 기본 하네스 생성:
   - CLAUDE.md (스캔 기반)
   - settings.json (기본 deny + 감지된 빌드 명령 allow)
   - .gitignore 업데이트
3. 이후 질문(Q5~Q9)은 **합리적 기본값으로 채우고** 각 기본값을 Escalations에 `[NON-BLOCKING]`으로 기록
4. Phase 1-2만 수행, Next Steps에 "Phase 3 진행 여부 확인 필요" 기록

Fast Track 완료 목표: 10분 이내.

## Full Mode

### Step 1: 프로젝트 자동 스캔

대상 프로젝트 루트에서 다음을 수집한다 (AskUserQuestion 금지, Read/Glob/Grep/Bash 사용):

```
[Target Project Scan Results]
- Path: {path}
- Key files: package.json, pyproject.toml, go.mod, Cargo.toml, composer.json 등
- Language(s): 확장자/설정으로 감지
- Framework: package.json/requirements.txt 등에서 감지
- Build tool: npm/yarn/pnpm, make, cargo 등
- Test setup: jest/vitest/pytest 등
- Git: .git 존재 여부, .gitignore 내용
- Existing Claude/Cursor: .claude/, .cursor/, AGENTS.md, CLAUDE.md 존재 여부
```

스캔 결과를 산출물(`docs/{요청명}/01-discovery-answers.md`)에 구조화하여 기록한다.

### Step 2: 사전 수집 답변과 스캔의 일치 여부 확인

오케스트레이터가 전달한 A1~A3과 스캔 결과를 비교:
- 사용자가 말한 기술 스택과 스캔 감지가 일치하는가?
- 유형(A2)과 실제 프로젝트 구조(src/client/ 등)가 일치하는가?

**일치하지 않는 경우** Escalations에 `[ASK] 유형 혹은 스택 불일치 — 스캔: X, 답변: Y` 형식으로 기록하여
오케스트레이터가 사용자에게 확인하도록 한다. 스킬은 자체 판단으로 덮어쓰지 않는다.

### Step 3: 프로젝트 아키타입 신호 수집 (Fast-Forward / Strict-Coding 판별)

A1의 한 줄 설명과 스캔 결과에서 두 가지 독립 신호를 수집한다.

#### 3-A. 에이전트 프로젝트 신호 (Fast-Forward 판별)
- 설명 키워드: "에이전트", "agent", "자동 생성", "파이프라인", "pipeline", "워크플로우 자동화", "LLM", "AI가 ~하는", "콘텐츠 자동화"
- 구조 신호: `.claude/agents/`, `.claude/skills/`, `playbooks/`, `agents/`, 스킬/플레이북 중심 디렉터리

신호가 감지되면 Escalations에 `[ASK] 에이전트 프로젝트 감지: Fast-Forward(Phase 3-5 통합) 경로 권장` 기록.

#### 3-B. 복잡 코딩 프로젝트 신호 (Strict Coding 6-Step 판별)
- 프레임워크 감지: Next.js, Nest, Express, Django, Rails, Spring Boot, FastAPI 등
- 테스트 인프라: vitest.config, jest.config, pytest.ini, playwright.config, cypress.config
- DB/ORM: prisma/, typeorm 의존성, models/, migrations/ 디렉터리
- 타입 엄격: tsconfig의 `"strict": true`, mypy strict, ruff strict
- CI 존재: `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`
- 규모: `find -type f` 결과 ≥ 100 또는 LoC ≥ 5,000
- 사용자 의지: A1 설명에 "엄격", "정석", "프로덕션 품질", "production-ready" 등 표현

**2개 이상 해당** + **에이전트 프로젝트가 아님**이면 Escalations에
`[ASK] 복잡 코딩 프로젝트 감지: Strict Coding 6-Step 워크플로우 적용 권장` 기록.
감지된 신호를 함께 기록하여 사용자가 판단 근거를 볼 수 있게 한다.

예: `[ASK] Strict Coding 6-Step 권장 — 감지: Next.js + TS strict + Prisma + vitest (4/7). 템플릿 경로: .claude/templates/workflows/strict-coding-6step/`

스킬 자체는 자동 전환하지 않는다. 오케스트레이터가 사용자에게 확인 후 결정.
두 신호가 동시에 감지되면 에이전트 프로젝트(3-A) 경로를 우선하고, Strict Coding은 참고로만 기록.

#### 3-C. 코드맵 신호 (Code Navigation 규칙 채택 판별)

공용 규칙 `.claude/templates/common/rules/code-navigation.md`는 대상 프로젝트에 코드맵(`docs/architecture/code-map.md` 또는 유사 파일)이 있거나, 사용자가 이 규칙을 원할 때 채택한다.

스캔 신호:
- 기존 코드맵 파일 감지: `docs/architecture/code-map.md`, `docs/architecture.md`, `docs/code-map.md`, `docs/code-structure.md`, `ARCHITECTURE.md` 중 하나 이상
- 복잡 코딩 프로젝트(3-B) 또는 중~대형 코드베이스(LoC ≥ 5,000, 파일 ≥ 100)

기록 규칙:
- **코드맵 파일이 이미 존재**: Escalations에 `[ASK] code-navigation 규칙 채택 — 기존 {감지된 경로} 발견. 이 규칙을 설치하면 research/implement 에이전트가 이 파일을 활용/유지한다` 기록
- **파일 없음 + 복잡 코딩/중대형 신호 감지**: Escalations에 `[ASK] code-navigation 규칙 채택 + code-map.md 생성 고려 — 대형/복잡 코드베이스에서 탐색 효율 향상. 지금 생성하지 않아도 규칙만 설치 가능 (나중에 실제 구현 작업 중 필요 시 생성 제안 Escalation이 발생함)` 기록
- **단순 프로젝트**: 기록하지 않음 (과잉)

스킬 자체는 자동 설치하지 않는다. 오케스트레이터가 사용자 선택을 받은 뒤 후속 Phase에서 다음을 수행:
1. `.claude/templates/common/rules/code-navigation.md` → 대상 `.claude/rules/code-navigation.md`로 복사 (경로는 프로젝트 구조에 맞게 조정)
2. 사용자가 code-map.md 신규 생성을 승인하면 별도 리서치 작업(이 스킬의 범위 밖)으로 생성

### Step 4: 나머지 설계 입력 수집 (Q5~Q9 → Escalations)

아래 항목은 오케스트레이터가 사전 수집하지 **않은** 정보다. 스킬은 각 항목을 **Escalations의 ASK 항목으로 기록**한다
(직접 사용자에게 묻지 않는다). 스캔으로 답이 명확히 추정되면 그 추정을 후보로 포함한다.

- Q5. 핵심 개발 원칙 (예: TDD, 성능 우선, 가독성 우선)
- Q6. Git 커밋 메시지 규칙 (Conventional Commits 여부, 한글 커밋 허용 등) — 감지된 .gitmessage/.commitlintrc 있으면 후보로 제시
- Q7. Claude 자동 허용 명령 — `package.json/scripts`에서 감지된 script를 후보로 제시
- Q8. Claude 절대 금지 명령 — 기본 deny에 더해 필요한 추가 사항
- Q9. 특별 요구사항 (Windows 한글 인코딩, 보안 정책, MCP 서버, 도메인별 스킬 필요성 등)
- Q10. **"모호하면 먼저 질문하기" 지침 포함 여부 (권장: Yes)** — CLAUDE.md에
  "워크플로우·파이프라인과 무관하게, 대화 중 결정이 불확실하거나 선택지가 둘 이상이면
  AskUserQuestion 도구로 사용자에게 먼저 확인한다" 규약을 삽입할지 여부.
  기본 권장값은 **Yes**. Escalations에 다음 형식으로 기록:
  `[ASK] Q10. 'Ask-first when uncertain' 지침 포함? (권장: Yes) — CLAUDE.md에 범용 질문 규약 1~2줄 삽입`

솔로 프로젝트(A3=솔로)이면 Q5의 팀 협업 관련 세부 질문을 생략. 빌드 도구가 없으면 Q7에서 빌드 관련 후보 생략.

### Step 5: 생성 계획 초안 작성

모든 Escalations가 해결되기 전에도 스캔+사전 답변만으로 만들 수 있는 **초안**은 산출물에 작성한다:

```
[생성 계획 초안]
├── CLAUDE.md (XX줄) — 프로젝트 정체성, 기술 스택, 개발 원칙
├── .claude/settings.json — 권한: allow N개, deny N개
├── .claude/rules/
│   ├── {rule-1}.md (항상 적용) — {설명}
│   └── {rule-2}.md (paths: {pattern}) — {설명}
├── CLAUDE.local.md — 개인 설정 템플릿
├── .claude/settings.local.json — 개인 권한 템플릿
└── .gitignore 업데이트
```

생성 계획 초안을 산출물에 포함하고 Escalations에 `[ASK] 생성 계획 승인 — 진행/수정`으로 기록.
오케스트레이터가 사용자 승인을 받은 후 Step 6으로 진행.

### Step 6: 파일 생성 (오케스트레이터 승인 후)

승인 후 다음 순서로 직접 Write. 개별 파일 승인 대기는 하지 않는다(서브에이전트는 AskUserQuestion 불가).
오케스트레이터가 Advisor 리뷰 후 전체 승인을 이미 부여한 상태다.

1. **CLAUDE.md** (≤200줄):
   - 프로젝트 이름/목적(A1), 기술 스택(스캔+사전답변), 개발 원칙(Q5), 빌드/테스트 명령(스캔)
   - 팀 프로젝트이면 사용자 확인 요구사항
   - 존재하는 프로젝트 문서에 대한 @import
   - **메타 누수 금지**: 이 도구/어시스턴트에 대한 언급, Claude Code 아키텍처 설명 포함 금지
   - **AskUserQuestion 규율 포함**: 다중 에이전트 프로젝트이면 생성 CLAUDE.md에도
     "서브에이전트는 AskUserQuestion 금지, Escalations로 기록" 규약을 1줄 삽입
   - **Ask-first 지침 (Q10 = Yes인 경우, 기본 권장)**: CLAUDE.md의 "협업 규약" 또는
     유사 섹션에 다음 취지의 1~2줄을 삽입한다 (대상 프로젝트 문맥으로 재작성, 본 도구 언급 금지):
     > "작업 중 결정이 모호하거나 합리적 선택지가 둘 이상이면, 가정하지 말고
     > AskUserQuestion 도구를 사용해 먼저 사용자에게 확인한다. 명시적 답변이나
     > 코드에서 확인된 사실에만 근거해 진행한다."
     Q10 = No이면 이 줄을 생략

2. **.claude/settings.json**:
   - permissions.allow: Q7 + 감지된 build/test 스크립트
   - permissions.deny: 기본 deny + Q8 추가 + 필수 deny 3종(rm -rf /, sudo rm *, git push --force *)
   - env: 사용자가 명시한 환경변수만
   - hooks: Q9에서 요청된 자동 검사만

3. **.claude/rules/*.md**:
   - 커밋 규칙(Q6) → always-apply (frontmatter 없음)
   - 한글 인코딩(Q9에 해당 시) → always-apply
   - 경로별 규칙(server/ vs client/ 등) → `paths:` frontmatter
   - **다중 에이전트 프로젝트일 때 자동 생성**: `rules/question-discipline.md` —
     "AskUserQuestion은 오케스트레이터 전용, 서브에이전트는 Escalations 기록" 원칙 (본 도구의 것을 복제하지 말고, 대상 프로젝트 문맥으로 재작성)
   - **에이전트 프로젝트일 때 자동 생성**: `rules/meta-leakage-guard.md` (대상 프로젝트 기준)

4. **CLAUDE.local.md** 템플릿: 응답 언어/현재 초점/디버그 단축 — TODO 주석

5. **.claude/settings.local.json** 템플릿: 빈 allow 배열 + 설명 주석

6. **.gitignore**: `CLAUDE.local.md`, `.claude/settings.local.json` 없으면 추가

### Step 7: 자체 검증

생성 직후 스킬이 수행(파일 검증만, 사용자 질문 없음):
1. 생성 파일 목록 + 크기 수집
2. JSON 파일 parse 검증
3. CLAUDE.md 줄 수 ≤200 확인
4. rules의 paths 패턴이 실제 파일과 매칭되는지 glob 확인
5. 자연어 효과 요약 생성: "이 설정으로 Claude는 X를 자동 실행하고, Y는 매번 확인합니다."

실패 항목은 Escalations에 `[BLOCKING]`으로 기록.

### Step 8: 다음 Phase 전환 안내

Next Steps에 기록:
- Fast-Forward 경로: "Phase 3-5 통합 실행 권장 (에이전트 프로젝트 감지됨)"
- 기본 경로: "Phase 3: phase-workflow 에이전트 소환 권장"
- 중단 요청 시: "대상 프로젝트 폴더에서 Claude Code를 실행하면 이 설정이 적용됩니다."

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/01-discovery-answers.md`에는 다음을 **반드시** 포함한다.
누락 시 Phase 3 에이전트가 필요한 컨텍스트를 확보할 수 없다.

### 필수 섹션
- [ ] `## Summary` — 이 Phase 핵심 결정사항 (~200단어)
- [ ] `## Scan Results` — Step 1의 스캔 결과 전체 덤프
- [ ] `## Pre-collected Answers` — A1~A3(+A4) 원문
- [ ] `## Context for Next Phase` — 아래 필드 전부 포함
  - 프로젝트 유형 (웹앱/CLI/에이전트/데이터/콘텐츠/기타)
  - 기술 스택 (언어, 프레임워크, 빌드/테스트 도구)
  - 솔로/팀 및 인원
  - **에이전트 프로젝트 여부** (Fast-Forward 권장 여부 포함)
  - 디렉터리 구조 요약 (핵심 경로 목록)
  - 기존 .claude/.cursor 설정 존재 여부
- [ ] `## Files Generated` — 작성된 모든 파일 절대경로 + 한 줄 설명
- [ ] `## Escalations` — `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그된 항목 (없으면 "없음")
- [ ] `## Next Steps` — Phase 3 또는 Fast-Forward 권장

## Guardrails

- 사용자에게 직접 질문하지 않는다 (AskUserQuestion 사용 금지). 모든 확인은 Escalations에 기록.
- CLAUDE.md 200줄 초과 금지
- `Bash(*)` 절대 permissions.allow에 넣지 않음
- 비밀값(sk-, ghp_, AKIA, xoxb-, Bearer) 감지 시 settings.json에서 제거하고 settings.local.json으로 이동
- 생성 CLAUDE.md에 이 도구(Project Architect)의 메타 규칙이나 Claude Code 아키텍처 설명 포함 금지
- 답변 누락 항목에는 `# TODO: 사용자 확인 필요` 주석 남기고 추측 금지
