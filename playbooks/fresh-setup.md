
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
- **복잡도 신호 (경량 트랙 판별용)**:
  - 소스 파일 수: `find {루트} -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rs" \) | wc -l`
  - 최대 디렉터리 깊이: `find {루트} -type d | awk -F/ '{print NF}' | sort -n | tail -1`
  - 환경 파일 목록: `.env*` 파일 열거 (`.env.staging`, `.env.production` 존재 여부 확인)
  - CI 워크플로우 수: `.github/workflows/*.yml` 파일 수 카운트
  - docker-compose 서비스 수: `docker-compose.yml` 존재 시 `services:` 블록 하위 항목 수
  - 루트 외 추가 `package.json`/`requirements.txt`: `find {루트} -name "package.json" -not -path "*/node_modules/*" | grep -v "^{루트}/package.json" | wc -l`
```

스캔 결과를 산출물(`docs/{요청명}/01-discovery-answers.md`)에 구조화하여 기록한다.

### Step 1.5: 사용자 발화 구조 추출 (User-Declared Structure)

대상 폴더가 비어있거나 신규(greenfield) 프로젝트인 경우, 파일 아티팩트만으로는 사용자 의도·구조를 파악할 수 없다. A1 자유 서술과 Phase 0 초기 발화에서 **구조·규모 신호**를 추출하여 산출물 `## Context for Next Phase` 에 `User-Declared Structure` 항목으로 기록한다. 이 정보는 후속 Phase(3-workflow / 4-pipeline)에서 구조 누락을 방지하며, 오케스트레이터의 트랙 판별 9번째 조건의 입력으로도 사용된다.

**추출 카테고리**:
- **에이전트 체인 언급**: "A→B→C", "리서처→라이터→에디터", "N 단계 파이프라인" 등
- **서비스 분할**: "웹+백엔드+모바일", "프론트+API+모니터링", "모노레포 N 서비스" 등 3개 이상 컴포넌트
- **외부 의존**: "외부 API", "LLM 체인", "MCP 서버", 특정 SaaS 이름 등
- **마이그레이션·리라이트 동사**: "옮기다", "포팅", "migrate", "리라이트", "rewrite", "기존 X를 Y로"
- **규모·팀 힌트**: "대규모", "N 명 팀", "모노레포" 등

**추출 방식**: A1 설명과 초기 발화(오케스트레이터가 `[Initial User Utterance]` 로 프롬프트에 전달)를 읽고 위 카테고리에 해당하는 요소를 불릿으로 기록. 해당 없으면 `User-Declared Structure: 특별한 구조 신호 없음` 으로 기록. **추론이 아닌 발화 증거 기반** — 사용자가 실제로 말하지 않은 구조를 지어내지 않는다.

**기록 예시**:
```
### User-Declared Structure
- 마이그레이션: Python Windows GUI 툴 → 웹앱(Streamlit 등) 포팅 — "옮기고" 동사 명시
- 멀티 워크플로우: 최소 3개 워크플로우 분리 요구 (포팅·UI 개선·코드 최적화)
- 외부 의존: 없음
- 에이전트 체인: 없음
```

**트랙 판별과의 연계**: 오케스트레이터는 이 섹션에서 "대규모 마이그레이션/리라이트/3개 이상 서비스/에이전트 체인" 신호가 하나라도 있으면 9번째 트랙 조건을 불충족으로 판정하여 풀 트랙을 강제한다.

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

**에이전트 프로젝트가 아닌** 전제에서, 감지된 신호 개수에 따라 이원화하여 기록한다:

- **2개 이상 해당** → Escalations에 `[ASK] 복잡 코딩 프로젝트 감지: Strict Coding 6-Step 워크플로우 적용 권장` 기록 (의사결정 요청).
  - 예: `[ASK] Strict Coding 6-Step 권장 — 감지: Next.js + TS strict + Prisma + vitest (4/7). 템플릿 경로: .claude/templates/workflows/strict-coding-6step/`
- **정확히 1개 해당** → Escalations에 `[NOTE] Strict Coding 6-Step 워크플로우 소개 — 감지 신호 1/7: {신호명}. 현재는 경량 워크플로우가 적합해 보이지만, 사용자가 원하면 Phase 3에서 채택 가능` 기록 (정보 전달만, 의사결정 요청 아님).
  - 예: `[NOTE] Strict Coding 6-Step 소개 — 감지: TS strict (1/7). 단일 신호라 자동 제안은 보류, Phase 3에서 사용자가 원하면 채택 가능`
- **0개 해당** → 기록하지 않음.

**예외 규칙 — 신호 #7 단독 승격**: 감지된 단일 신호가 **#7(사용자 의지 발화 — "엄격", "정석", "프로덕션", "production-ready")** 인 경우, `[NOTE]`가 아닌 `[ASK]`로 승격하여 기록한다. 사용자가 명시적으로 품질 의지를 표현한 경우 질문을 떼지 않는 것이 사용자 경험을 해치기 때문. 예: `[ASK] Strict Coding 6-Step 권장 — 감지: 사용자 의지 발화(1/7, 신호#7 단독). 스캔 신호는 없으나 사용자가 명시적 품질 의지를 표명했으므로 의사결정 요청.`

**A6 품질 축 답변 승격 규칙** — 오케스트레이터가 프롬프트에 전달한 `[User Quality Axes]` 에 `Strict Coding` 이 포함된 경우, 위 스캔 신호 개수와 무관하게 Escalations에 `[ASK] Strict Coding 6-Step 권장 — 사용자 품질 축 답변(A6)에 명시. 스캔 신호: {N}/7` 로 **[ASK] 즉시 승격**한다. A6 답변은 Phase 0에서 구조화된 사용자 선택이므로 키워드 파싱(신호 #7)이나 아티팩트 스캔보다 우선한다. 이는 greenfield 빈 폴더에서 사용자가 품질 의지를 구조화된 답변으로 명시했음에도 스캔 점수 0점으로 스킵되던 맹점을 제거한다.

감지된 신호를 함께 기록하여 사용자가 판단 근거를 볼 수 있게 한다. 스킬 자체는 자동 전환하지 않는다. 오케스트레이터는 `[ASK]`는 AskUserQuestion으로 확인, `[NOTE]`는 텍스트 보고만 수행한다.

에이전트 프로젝트(3-A)가 동시 감지되면 Fast-Forward 경로를 우선하고, Strict Coding 신호는 개수와 무관하게 참고(`[NOTE]`)로 강등하여 기록.

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

#### 3-D. 코드 프로젝트 감지 (code-researcher 베이스라인 설치 판별)

오케스트레이터가 사용자 요청을 라우팅할 때 코드 확인이 필요한 경우 **메인 세션이 직접 Read하지 않고** `code-researcher` 에이전트를 경유하도록 하기 위해, 코드 프로젝트로 감지되면 베이스라인 리서치 에이전트를 자동 설치한다.

**감지 기준 (OR — 하나라도 충족 시 코드 프로젝트로 분류)**:
- 루트에 소스 디렉터리 존재: `src/`, `lib/`, `app/`, `backend/`, `frontend/`, `server/`, `client/` 중 하나 이상
- 패키지 매니페스트 존재: `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `pom.xml`, `composer.json`, `build.gradle` 중 하나 이상
- Step 1 스캔에서 Language 감지 결과가 비어있지 않음
- **A6 품질 축 답변에 코드 개발 축 포함** — `[User Quality Axes]` 에 `Strict Coding` / `프론트엔드 디자인·UX` / `보안·컴플라이언스` 중 하나 이상 포함. 빈 폴더라도 사용자가 코드 작업 의지를 구조화된 답변으로 명시했으면 코드 프로젝트로 분류
- **Step 1.5 User-Declared Structure 에 마이그레이션·리라이트 신호 존재** — "포팅", "옮기다", "migrate", "리라이트", "rewrite", "기존 X를 Y로" 중 하나 이상. 사용자 발화가 향후 코드 작업을 예고하면 빈 폴더라도 코드 프로젝트로 분류

**비코드 프로젝트 분류 조건 (AND — 모두 충족 시)**:
- 위 감지 기준 5개 모두 불충족
- 또는 A2(프로젝트 유형)가 "콘텐츠 자동화" 이며 소스 디렉터리·매니페스트 미검출 이며 A6 에 코드 개발 축 없음

**기록 규칙**:
- 코드 프로젝트: 별도 Escalation 없이 Step 6 에서 자동으로 `.claude/templates/common/agents/code-researcher.md` 를 대상 프로젝트 `.claude/agents/code-researcher.md` 로 복사. 별도 사용자 확인 불필요(베이스라인 기본값).
- 비코드 프로젝트: Escalations에 `[NOTE] code-researcher 설치 스킵 — 비코드 프로젝트로 감지` 기록. 오케스트레이터 라우팅 프로토콜 섹션도 CLAUDE.md 에서 생략.

산출물 `## Context for Next Phase` 에 `코드 프로젝트 여부: yes|no` + 감지 근거 1줄 포함.

#### 3-E. 프론트엔드 디자인 프리셋 신호 (frontend-design 프리셋 주입 판별)

대상 프로젝트가 **UI 레이어 중심 웹 프론트엔드**로 판별되면, 디자인 품질을 끌어올리기 위한 프리셋(`frontend-designer` + `frontend-ux-reviewer` 에이전트, `frontend-design` 스킬)을 선택적으로 주입한다. 백엔드 중심 프로젝트에 프리셋을 기본 주입하면 과도하므로, **감지 신호가 충분히 쌓였을 때만 사용자 확인**으로 넘긴다.

**A6 품질 축 답변 우선 규칙 (greenfield 맹점 방지)** — 오케스트레이터가 프롬프트에 전달한 `[User Quality Axes]` 에 `프론트엔드 디자인·UX` 가 포함된 경우, 아래 아티팩트 기반 점수 계산을 **건너뛰고** Escalations에 다음을 즉시 기록한다:

```
[ASK] 프론트엔드 디자인 프리셋 주입 — 사용자 품질 축 답변(A6)에 `프론트엔드 디자인·UX` 명시. frontend-designer + frontend-ux-reviewer 에이전트와 frontend-design 진입점 스킬을 대상 프로젝트에 설치할까요? (옵션: 설치 / 스킵)
```

동시에 도메인 후보로 `frontend-design` 을 함께 제시한다(사용자가 승인 시 `[Domain Hint] frontend-design` 으로 Phase 2.5 트리거). 이는 빈 폴더(`package.json` 없음 등 아티팩트 부재) 에서 사용자가 명시적으로 프론트엔드 디자인 의도를 표명했음에도 스캔 점수 0점으로 묵살되던 구조적 맹점을 제거한다. A6 답변은 구조화된 사용자 선택이므로 아티팩트 기반 가중치 계산보다 우선한다.

A6 에 `프론트엔드 디자인·UX` 가 포함되지 않은 경우에만 아래 아티팩트 기반 점수 계산을 진행한다.

**감지 기준 (가중 점수 — 합 3 이상이면 주입 후보)**:

| 신호 | 가중치 | 확인 방법 |
|------|--------|-----------|
| UI 프레임워크 의존: `react`, `vue`, `svelte`, `solid`, `qwik`, `preact` | +2 | `package.json` `dependencies`/`devDependencies` |
| 메타 프레임워크: `next`, `nuxt`, `remix`, `sveltekit`, `astro`, `@tanstack/start` | +2 | 동일 |
| 스타일링 도구: `tailwindcss`, `@emotion/*`, `styled-components`, `panda-css`, `@vanilla-extract/*`, `unocss` | +1 | 동일 |
| UI 컴포넌트 계열: `@radix-ui/*`, `@headlessui/*`, `@ariakit/*`, `@mui/*`, `@chakra-ui/*`, shadcn 증거(`components/ui/` + `components.json`) | +1 | 동일 + 디렉터리 glob |
| 모션·아이콘 라이브러리: `framer-motion`, `motion`, `lucide-react`, `@phosphor-icons/*`, `react-icons`, `@heroicons/*` | +1 | 동일 |
| 디자인 시스템 디렉터리: `components/`, `ui/`, `design-system/`, `tokens/`, `src/styles/`, `.storybook/` 중 **둘 이상** 존재 | +1 | Glob |
| 외부 디자인 스킬 의존 신호: `.interface-design/`, `design-tokens.json`, `tokens/*.json` | +1 | 파일 존재 |
| **역가중치** — 백엔드 중심 모노레포 신호 | | |
| 루트에 `server/` 또는 `backend/` 디렉터리 존재 | −1 | Glob |
| 루트에 `Dockerfile` + `docker-compose.yml` (services ≥ 2) 동시 존재 | −1 | 파일 존재 + YAML 파싱 |
| 루트 외 `package.json`·`requirements.txt`·`go.mod` 추가 존재 (백엔드 패키지 증거) | −1 | Find |

합산 점수·검출 증거(가중·역가중 세부 포함)를 Step 1 스캔 결과 아래 `[Frontend Signal Score]` 섹션으로 산출물에 기록한다. **위 A6 우선 규칙으로 이미 `[ASK]` 가 승격된 경우에는 이 점수 계산을 생략하고 승격 근거만 기록한다.**

**기록 규칙 (A6 에 `프론트엔드 디자인·UX` 없는 경우에만 적용)**:
- 점수 ≥ 3 : Escalations에 `[ASK] 프론트엔드 디자인 프리셋 주입 — 감지 점수 {N}. frontend-designer + frontend-ux-reviewer 에이전트와 frontend-design 진입점 스킬을 대상 프로젝트에 설치할까요? (옵션: 설치 / 스킵)` 기록. 동시에 도메인 후보로 `frontend-design` 을 함께 제시한다(사용자가 승인 시 `[Domain Hint] frontend-design` 으로 Phase 2.5 트리거).
- 점수 1~2 : `[NOTE] 프론트엔드 신호 {N}점 — 주요 신호 부족으로 프리셋 자동 주입은 제안하지 않음. 필요 시 사용자가 수동 요청 가능` 기록.
- 점수 0 : 아무 기록 없음. (단, 사용자가 A6 에 `프론트엔드 디자인·UX` 를 선택한 경우에는 이 단계 이전에 이미 `[ASK]` 가 승격되었으므로 이 분기에 도달하지 않는다.)

**승인 시 Step 6 동작** (수행 주체: `phase-setup` 에이전트):
1. `${CLAUDE_PLUGIN_ROOT}/.claude/templates/frontend-design/agents/frontend-designer.md` → 대상 프로젝트 `.claude/agents/frontend-designer.md`
2. `${CLAUDE_PLUGIN_ROOT}/.claude/templates/frontend-design/agents/frontend-ux-reviewer.md` → 대상 프로젝트 `.claude/agents/frontend-ux-reviewer.md`
3. `${CLAUDE_PLUGIN_ROOT}/.claude/templates/frontend-design/skills/frontend-design/` 디렉터리 전체 → 대상 프로젝트 `.claude/skills/frontend-design/`
4. **`allowed_dirs` 자동 재조정**: `phase-setup` 에이전트가 대상 프로젝트 루트에서 `src/`, `app/`, `components/`, `styles/`, `public/`, `tailwind.config.*`, `postcss.config.*` 중 실제 존재하는 경로만 Glob으로 확인하여 `frontend-designer.md` frontmatter의 `allowed_dirs` 를 Edit로 재작성. 해당 경로가 하나도 없으면 산출물 `Escalations`에 `[ASK] 프론트엔드 에이전트의 쓰기 경로를 자동 판단 불가 — 어떤 디렉터리에 쓰기 권한을 줄까요?` 기록하고 `allowed_dirs` 는 템플릿 기본값 그대로 둔다 (읽기만 가능, 쓰기는 사용자 확인 후 조정).
5. **자가 완결성**: 프리셋은 이 3개 파일만으로 완결하도록 설계되어 있다. `color-expert` 등 외부 스킬은 심화 색상 분석이 필요할 때 선택적으로 활용하는 옵션이며, 자동 설치·CLAUDE.md 설치 가이드 추가는 하지 않는다.
6. **Phase 5·6 소유권 보호**: 주입된 3개 파일은 **프리셋 단일 소유자** 로 간주한다. 후속 Phase 5(`phase-team`) / Phase 6(`phase-skills`)는 산출물의 `프론트엔드 프리셋 주입 여부: yes` 를 감지하면 `.claude/agents/frontend-designer.md`, `.claude/agents/frontend-ux-reviewer.md`, `.claude/skills/frontend-design/` 을 재작성·덮어쓰기 대상에서 제외한다. 필요 시 다른 에이전트·스킬을 추가하거나 보완 문서를 별도 파일로 붙인다 (예: `.claude/skills/frontend-design/references/*`).

산출물 `## Context for Next Phase` 에 `프론트엔드 프리셋 주입 여부: yes|no|skipped` + 감지 점수 + `allowed_dirs 재조정 결과` (자동/사용자확인대기) 를 기록. Phase 5·6 에이전트는 이 값을 의무적으로 확인하고 소유권 보호 규칙을 따른다.

#### 3-F. Intent Gate 베이스라인 설치 (무조건·판별 없음)

모든 대상 프로젝트에 다음 2개 파일을 **무조건** 설치한다. 복잡도·도메인·에이전트 여부와 무관. 이 2개는 대상 프로젝트의 메인 세션이 작업 요청을 받았을 때 첫 턴에 사용자 의도·맥락을 확인하게 만드는 **가장 강력한 권위의 지침**이다.

**설치 대상 1: 항상적용 규칙 파일**
- 소스: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/rules/intent-gate.md`
- 대상: `{target}/.claude/rules/intent-gate.md`
- 복사 방법: Read → Write 그대로 (내용 수정 금지)
- 이미 존재 시: 내용이 동일하면 스킵, 다르면 Escalations에 `[ASK] 기존 intent-gate.md 발견 — 덮어쓰기 / 보존` 기록

**설치 대상 2: 질문 진행 스킬**
- 소스 디렉터리: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/skills/intent-clarifier/`
- 대상 디렉터리: `{target}/.claude/skills/intent-clarifier/`
- 복사 방법: 디렉터리 전체를 그대로 복사 (최소 `SKILL.md` 1 파일)
- 이미 존재 시: 위 규칙과 동일

**Escalation 기록**: 별도 `[ASK]` 발행 없음. 설치 자체는 사용자 확인 불필요 (베이스라인). 단 `[NOTE] Intent Gate 베이스라인 설치 — intent-gate.md 규칙 + intent-clarifier 스킬 2개 파일` 을 기록하여 사용자가 추적 가능하게 한다.

**이유**: 사용자가 하네스 세팅 결과물로 작업할 때 Claude 가 첫 턴에 잘못된 방향을 암묵적으로 고정하는 것을 막는다. 규칙은 "언제 호출할지" 를 정의하고, 스킬은 "어떻게 질문할지(= AskUserQuestion 도구로 분기별 질문)" 를 정의한다. 둘 다 있어야 강제력이 성립.

산출물 `## Context for Next Phase` 에 `Intent Gate 베이스라인 설치: yes` 를 기록.

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
│   └── (코드 프로젝트) 오케스트레이터 라우팅 프로토콜 섹션 포함
├── .claude/settings.json — 권한: allow N개, deny N개
├── .claude/rules/
│   ├── intent-gate.md (항상 적용, 무조건) — 작업 요청 첫 턴에 의도 확인 강제
│   ├── {rule-2}.md (항상 적용) — {설명}
│   └── {rule-3}.md (paths: {pattern}) — {설명}
├── .claude/skills/
│   └── intent-clarifier/ (무조건) — 의사결정 분기 분석 + AskUserQuestion 질문 루프
├── .claude/agents/
│   └── code-researcher.md (코드 프로젝트만) — 베이스라인 리서치 에이전트
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
   - **최상단에 "작업 시작 전" 섹션 (무조건 삽입)**: Step 3-F 에서 설치되는 `intent-gate.md` 규칙을 상단에서 참조한다. 아래 템플릿을 그대로 삽입 (본 도구 언급 금지 — 대상 프로젝트 문맥의 일반 지침으로 작성됨):

     ```markdown
     ## 작업 시작 전

     새 작업 요청을 받으면 리서치·계획·파일 수정 **이전에** 사용자 의도를 먼저 확인한다.
     상세 절차는 `.claude/rules/intent-gate.md` 규칙이 강제하며, 맥락 부족 시
     `.claude/skills/intent-clarifier/` 스킬을 호출하여 `AskUserQuestion` 도구로 질문한다.

     요약:
     - 생성·포팅·설계·결정·스코프 모호 요청은 의도 확인 필수
     - 질문은 `AskUserQuestion` 도구로만 (텍스트 질문 후 대기 금지)
     - 확인 전에는 파일 쓰기·외부 리서치·계획 확정 금지
     ```

   - 프로젝트 이름/목적(A1), 기술 스택(스캔+사전답변), 개발 원칙(Q5), 빌드/테스트 명령(스캔)
   - 팀 프로젝트이면 사용자 확인 요구사항
   - 존재하는 프로젝트 문서에 대한 @import
   - **메타 누수 금지**: 이 도구/어시스턴트에 대한 언급, Claude Code 아키텍처 설명 포함 금지
   - **AskUserQuestion 규율 포함**: 다중 에이전트 프로젝트이면 생성 CLAUDE.md에도
     "서브에이전트는 AskUserQuestion 금지, Escalations로 기록" 규약을 1줄 삽입
   - **Ask-first 지침 (Q10 = Yes인 경우, 기본 권장)**: 위 "작업 시작 전" 섹션과는 별도로, "협업 규약" 또는 유사 섹션에 다음 취지의 1~2줄을 삽입한다 (대상 프로젝트 문맥으로 재작성, 본 도구 언급 금지):
     > "작업 중 결정이 모호하거나 합리적 선택지가 둘 이상이면, 가정하지 말고
     > AskUserQuestion 도구를 사용해 먼저 사용자에게 확인한다. 명시적 답변이나
     > 코드에서 확인된 사실에만 근거해 진행한다."
     Q10 = No이면 이 줄을 생략. 단 "작업 시작 전" 섹션은 Q10 과 무관하게 무조건 유지.
   - **오케스트레이터 라우팅 프로토콜 섹션 (Step 3-D 에서 코드 프로젝트로 감지된 경우만 삽입, 비코드는 생략)**:
     CLAUDE.md 워크플로우 섹션 바로 앞에 아래 템플릿을 그대로 삽입한다. 프로젝트 규모 특성상 `.claude/agents/` 에 에이전트가 1개 이하일 것으로 예상되는 경우에도 섹션은 유지하되 "취사선택" 표현을 "직접 처리 vs 에이전트 소환" 으로 축소.

     ```markdown
     ## 오케스트레이터 라우팅 프로토콜

     사용자 요청이 들어오면 본 워크플로우를 무조건 풀 스텝으로 타지 않는다. 오케스트레이터(메인 세션)는 다음 순서로 판단한다.

     ### 1. 코드 확인이 필요한가?
     요청을 이해하려면 코드를 읽어야 한다면, 오케스트레이터는 **직접 Read 하지 않고** `code-researcher` 에이전트를 선호출하여 요약을 받는다. (메인 세션 컨텍스트 오염 방지 — 라우팅 판단 품질 유지)

     ### 2. 작업 복잡도 평가
     리서처 결과 + 요청 원문으로 다음 3등급 중 하나로 분류한다.

     | 등급 | 기준 | 경로 |
     |------|------|------|
     | S (소형) | 파일 ≤3개 변경, 해법 자명, 외부 의존 없음 | 오케스트레이터 직접 처리 또는 1개 에이전트만 소환 |
     | M (중형) | 파일 5~15개, 설계 결정 1~2개 | 워크플로우 중 필요한 스텝만 취사선택 |
     | L (대형) | 신규 기능, 외부 의존 도입, 복잡 의존 | 전체 워크플로우 실행 |

     ### 3. 리뷰 게이트 우회 금지
     다음 중 하나라도 해당하면 **S 등급 금지, 최소 M 등급 이상으로 상향**:
     - 출력이 코드 커밋 / 영구 산출물 / 외부 공개 문서
     - 해당 파이프라인이 `mandatory_review` 로 분류됨
     - 생성·결정·설계·계획·리서치 성격의 파이프라인

     S 등급은 "일회성 조회·질의응답·설명" 처럼 **영구 산출이 없는 작업** 에만 허용.

     ### 4. 등급 애매 / 다운그레이드 규칙
     등급 애매 시 M 기본. 매우 애매 시 L. 다운그레이드(L→M, M→S)는 사용자 명시 요청 시에만.

     ### 5. 취사선택 범위
     이 하네스의 `.claude/agents/` 에 존재하는 에이전트 중에서만 고른다. 외부 에이전트 즉석 생성 금지.

     ### 6. 사용자 명시 오버라이드
     사용자가 "풀 워크플로우로 가자" 또는 "가볍게 처리해" 를 명시하면 판단을 스킵하고 지시대로. 단 Section 3 (리뷰 게이트 우회 금지) 는 사용자 오버라이드로도 깨지 않는다.
     ```

     **비코드 프로젝트**: 위 섹션 전체 생략. 파일 수 기준 M/L 등급이 의미 없고 비대칭 처리로 혼란 유발.

2. **.claude/settings.json**:
   - permissions.allow: Q7 + 감지된 build/test 스크립트
   - permissions.deny: 기본 deny + Q8 추가 + 필수 deny 3종(rm -rf /, sudo rm *, git push --force *)
   - env: 사용자가 명시한 환경변수만
   - hooks: Q9에서 요청된 자동 검사만

3. **.claude/rules/*.md**:
   - **무조건 설치 (Step 3-F)**: `rules/intent-gate.md` — 소스 `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/rules/intent-gate.md` 를 Read → Write 그대로 복사 (내용 수정 금지). alwaysApply: true 규칙이므로 모든 요청 수신 시 작동.
   - 커밋 규칙(Q6) → always-apply (frontmatter 없음)
   - 한글 인코딩(Q9에 해당 시) → always-apply
   - 경로별 규칙(server/ vs client/ 등) → `paths:` frontmatter
   - **다중 에이전트 프로젝트일 때 자동 생성**: `rules/question-discipline.md` —
     "AskUserQuestion은 오케스트레이터 전용, 서브에이전트는 Escalations 기록" 원칙 (본 도구의 것을 복제하지 말고, 대상 프로젝트 문맥으로 재작성)
   - **에이전트 프로젝트일 때 자동 생성**: `rules/meta-leakage-guard.md` (대상 프로젝트 기준)

3-bis. **.claude/agents/code-researcher.md** (Step 3-D 에서 코드 프로젝트로 감지된 경우만):
   - 소스: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/agents/code-researcher.md`
   - 대상: `{target}/.claude/agents/code-researcher.md`
   - 복사 방법: Read 로 소스 읽은 뒤 Write 로 대상에 그대로 기록 (내용 수정 금지 — 베이스라인 정체성 보존)
   - **이미 `.claude/agents/code-researcher.md` 가 존재하면**: 덮어쓰지 않고 스킵. Escalations에 `[NOTE] 기존 code-researcher.md 존재 — 보존` 기록
   - **strict-coding-6step 채택 프로젝트**: `researcher-agent.md` 와 공존 허용. 두 에이전트는 역할이 다름(researcher-agent 는 파일 산출, code-researcher 는 채팅 반환). phase-team 에서 역할 중복 확인 Escalation 발생 가능
   - 비코드 프로젝트에는 복사하지 않음

3-ter. **.claude/skills/intent-clarifier/** (Step 3-F 무조건 설치 — 판별 없음):
   - 소스 디렉터리: `${CLAUDE_PLUGIN_ROOT}/.claude/templates/common/skills/intent-clarifier/`
   - 대상 디렉터리: `{target}/.claude/skills/intent-clarifier/`
   - 복사 방법: 디렉터리 전체를 Read → Write (최소 `SKILL.md` 1 파일). 내용 수정 금지 — 스킬 정체성 보존.
   - **이미 존재 시**: 내용 동일이면 스킵. 다르면 Escalations에 `[ASK] 기존 intent-clarifier 스킬 발견 — 덮어쓰기 / 보존` 기록.
   - 모든 대상 프로젝트에 설치 (복잡도·도메인·에이전트 여부 무관).

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
  - 디렉터리 구조 요약 (핵심 경로 목록, **소스 파일 수 [N]개**, **최대 디렉터리 깊이 [N]레벨** 포함)
  - 기존 .claude/.cursor 설정 존재 여부 (**환경 파일 목록 [.env, .env.staging, .env.production 등]**, **CI 워크플로우 수 [N]개**, **docker-compose 서비스 수 [N]개** 또는 없음, **루트 외 추가 package.json 수 [N]개** 포함)
  - **코드 프로젝트 여부**: yes|no + 감지 근거 1줄 (Step 3-D 결과)
  - **code-researcher 에이전트 설치 여부**: installed|skipped + 사유 (코드 프로젝트면 자동 설치, 비코드면 스킵)
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
