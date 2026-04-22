
# Fit Audit

## 질문 소유권
이 플레이북은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 발견 사항은 보고서의 해당 등급 섹션에 기록한다.

## Goal
대상 프로젝트 하네스의 **빌드 시점 전제** 와 **현재 프로젝트 실상** 사이의 시간축 드리프트를 6개 Dimension 으로 감사하여 DRIFT 등급별 보고서를 작성한다.

- `ops-audit` 이 "하네스 자체가 운영 건전한가" 를 묻는다면, 이 감사는 **"이 하네스가 현재 이 프로젝트에 여전히 맞는가"** 를 묻는다.
- `harness-audit` 이 구성 정합성(anti-pattern·JSON 유효성) 을 다룬다면, 이 감사는 **전제의 유통기한**을 다룬다.

## Prerequisites
- 대상 프로젝트에 `CLAUDE.md` 또는 `.claude/` 또는 `playbooks/` 중 하나 이상 존재 (Pre-flight 에서 검증 완료)
- `docs/*/01-discovery-answers.md` 존재 여부에 따라 `baseline-mode` 또는 `heuristic-only-mode` 로 진입 (오케스트레이터 프롬프트 `[Audit Mode]` 로 전달)
- 하네스·baseline·프로젝트 코드 모두 read-only 접근만 필요

## Baseline vs Current Scan

### Step A — Baseline 수집 (baseline-mode 에서만)

다음 파일을 순차 Read 하여 구조화 전제를 추출한다. 파일 부재 시 해당 항목 `null` 로 기록.

| 파일 | 추출할 필드 |
|------|-------------|
| `docs/*/00-target-path.md` | frontmatter `track` (`lightweight` / `full` / `pending`) |
| `docs/*/01-discovery-answers.md` | Pre-collected Answers (프로젝트 유형 A1-A2, 솔로/팀 A3, 성능 수준 A5, 품질 축 A6); Scan Results (소스 파일 수, 최대 디렉터리 깊이, `.env*`, CI 워크플로우 수, docker-compose 서비스 수, 루트 외 매니페스트 수); User-Declared Structure; Archetype Signals (Fast-Forward·Strict Coding·Code Navigation·Code-Researcher·Frontend Design 채택 여부) |
| `docs/*/04-agent-team.md` (존재 시) | Agent Model Table (에이전트 수·모델 티어 분포) |
| `docs/*/02-workflow-design.md` 또는 `02-lite-design.md` (존재 시) | 워크플로우 스텝 수 |

추출 결과를 `baseline` 구조체로 메모리에 보관.

### Step B — 현재 상태 스캔 (두 모드 모두 수행)

`playbooks/fresh-setup.md` Step 1 의 스캔 명령어 세트를 재사용하여 `current` 스냅샷 생성. 모두 Bash 도구로 실행하되 결과가 크면 요약만 보관.

```bash
# 소스 파일 수
find {대상} -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rs" -o -name "*.rb" -o -name "*.php" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" | wc -l

# 최대 디렉터리 깊이
find {대상} -type d -not -path "*/node_modules/*" -not -path "*/.git/*" | awk -F/ '{print NF}' | sort -n | tail -1

# CI 워크플로우 수
find {대상}/.github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l

# docker-compose 서비스 수 (간이 파싱)
test -f {대상}/docker-compose.yml && grep -cE "^  [a-zA-Z0-9_-]+:" {대상}/docker-compose.yml || echo 0

# 루트 외 추가 매니페스트
find {대상} \( -name "package.json" -o -name "pyproject.toml" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" \) -not -path "*/node_modules/*" -not -path "*/.git/*" | grep -v "^{대상}/[^/]*$" | wc -l

# .env 패턴
ls {대상}/.env* 2>/dev/null

# 루트 매니페스트 (스택 추정)
ls {대상}/package.json {대상}/pyproject.toml {대상}/Cargo.toml {대상}/go.mod {대상}/pom.xml {대상}/composer.json {대상}/Gemfile 2>/dev/null
```

하네스 인벤토리도 수집:
```bash
# 에이전트 수
find {대상}/.claude/agents -name "*.md" 2>/dev/null | wc -l
# 플레이북 수
find {대상}/playbooks -name "*.md" 2>/dev/null | wc -l
# settings 존재
test -f {대상}/.claude/settings.json && echo yes
```

### Step C — heuristic-only-mode 추정 baseline 재구성

`baseline` 이 null 인 필드에 대해, `current` 에서 **"하네스가 처음 설치될 시점의 합리적 추정"** 을 채운다. 모든 추정 필드는 `estimated: true` 플래그를 달아 보고서에 노출.

- 트랙 추정: 현재 복잡도 신호가 경량 트랙 9조건을 모두 충족하면 `lightweight (추정)`, 아니면 `full (추정)`
- 품질 축 추정: 하네스에 실제 주입된 축(Strict Coding 템플릿 존재, frontend-design 프리셋 존재 등) 을 baseline 으로 역추정

## Audit Dimensions

### MAJOR-DRIFT 서브등급 판정 (Unified Audit 대응)

`/harness-architect:audit` 통합 감사는 세 감사의 등급을 하나의 severity 축으로 병합한다. 통합 보고서의 `Critical` 버킷은 "즉시 조치" 수준이고 `Medium` 은 "개선 권장" 수준인데, fit-audit 의 MAJOR-DRIFT 는 재구축 권장(Medium 에 해당) 과 운영 방해(Critical 에 해당) 2가지 의미가 섞여 있다. 따라서 **fit-auditor 는 MAJOR-DRIFT 를 다음 2단계로 서브분류해 발행**한다.

#### `[MAJOR-DRIFT-CRITICAL]` — 즉시 조치 (운영 방해·오도)

다음 중 **하나라도** 충족:

- **Dim 1**: baseline `lightweight` 인데 현재 재평가가 `full` (하네스가 프로젝트 성장을 못 따라가 workflow 병목 초래)
- **Dim 2**: 현재 코드에 Frontend Design 신호 3건 이상인데 하네스에 프론트 관련 에이전트·프리셋 0 — 하네스가 **주요 활동 영역 미커버**
- **Dim 4**: 허용 경로의 **절반 이상이 존재하지 않거나** 모노레포 이관 감지 — 하네스가 **실제 코드 위치를 못 찾음** (Bash/Read 권한이 실제 동작 불가)
- **Dim 5**: 언어 스택·프로젝트 유형·**도메인** 중 하나라도 명백히 다름 — CLAUDE.md 가 **프로젝트를 오도** (새 세션이 잘못된 전제로 작업)
- **Dim 7-B**: 훅 스크립트 `#!/bin/bash` shebang 부재 + `chmod +x` 안됨 (훅 실행 자체 불가) — 하네스 훅이 **작동 불가 상태**
- **Dim 7-A**: 하네스가 참조하는 MCP 서버가 `.mcp.json` 에 완전히 부재하고 settings.json allow 만 stale — 기능 작동 불가

#### `[MAJOR-DRIFT-MED]` — 재구축 권장 (운영은 가능)

나머지 MAJOR-DRIFT. 대표 사례:

- **Dim 1**: baseline `full` 인데 현재 재평가가 `lightweight` (오버엔지니어링이나 운영 작동)
- **Dim 2**: Strict Coding 채택했는데 현재 코드에 신호 0 — 하네스 인프라가 놀고 있음
- **Dim 3**: 에이전트 규모 오버피팅·언더피팅 (비용·속도 영향이나 기능은 작동)
- **Dim 7**: MCP·훅이 stale 이나 치명적 실행 불능은 아님

#### 개별 커맨드(`/harness-architect:fit-audit`) 호출 시 호환성

사용자가 개별 fit-audit 커맨드를 직접 호출하면 보고서에 `[MAJOR-DRIFT-CRITICAL]` / `[MAJOR-DRIFT-MED]` 로 표기되어도 무방하다. 기존 소비자(설명 문서·테스트) 호환을 위해 본 플레이북 본문은 `[MAJOR-DRIFT]` 표기를 유지하되, **실제 발행 시**는 위 기준으로 서브등급 접미사를 자동 부여한다.

#### heuristic-only-mode 제약

`heuristic-only-mode` 에서는 `[MAJOR-DRIFT-CRITICAL]` 승격 불가 — 추정 baseline 기반이라 CRITICAL 판정의 근거가 약하다. 관찰된 강한 불일치는 `[MAJOR-DRIFT-MED (추정)]` 로 기록하고 Coverage Gaps 에 "heuristic-only 한계로 CRITICAL 판정 유보" 명시.

---

### Dim 1 — 트랙 드리프트 (Track Drift)

**스캔 대상**: `baseline.track` + `current` 스냅샷의 복잡도 신호 6종

**검사 절차**:
1. `baseline.track` 값 획득 (`lightweight` / `full` / `pending` / null)
2. `current` 기준으로 경량 트랙 9조건을 재평가 (`.claude/rules/orchestrator-protocol.md` 트랙 판별 표 기준):
   - 프로젝트 유형, 솔로/팀, 에이전트 프로젝트 여부, 에이전트 신호(3-A), Strict Coding 신호(3-B), 코드베이스 규모(소스 ≤100 AND 깊이 ≤5), 배포 복잡도(`.env.staging`/`.env.production` 부재 + CI 워크플로우 ≤1), 서비스 복잡도(compose 없음 또는 services ≤2, 루트 외 매니페스트 0), 사용자 발화 구조 신호
   - 프로젝트 유형·솔로/팀·에이전트 프로젝트·사용자 발화 축은 baseline 에서 복사 (현재 코드로 재추정 불가)
3. 재평가 결과 트랙이 baseline 과 다른지 대조

**등급 판정**:
- `[MAJOR-DRIFT]` — baseline `lightweight` 인데 현재 재평가가 `full` (코드베이스가 성장해 경량 트랙 기준을 명확히 초과)
- `[MAJOR-DRIFT]` — baseline `full` 인데 현재 재평가가 `lightweight` (프로젝트가 단순화·축소되어 풀 트랙 오버엔지니어링)
- `[MINOR-DRIFT]` — 재평가 결과는 같은 트랙이나 경계 조건 1~2개가 역전 (예: 소스 파일 수 80→120 으로 경계 초과했지만 다른 조건은 그대로)
- `[ALIGN]` — 트랙과 경계 조건 모두 유지
- heuristic-only-mode: 등급에 `(추정)` 접미사 필수

**False Positive 주의**: 최근 대형 의존성 업데이트 직후 일시적 파일 수 증가는 드리프트가 아닐 수 있음 — 가능하면 `node_modules`/`dist`/`build` 제외 후 판정.

### Dim 2 — 아키타입 / 품질축 미스핏 (Archetype & Quality-Axis Misfit)

**스캔 대상**: baseline Archetype Signals + 하네스의 실제 채택 산출물 + 현재 코드 신호

**검사 절차**:
1. `fresh-setup.md` Step 3-A~E 신호 검출 로직을 **현재 코드** 에 재실행:
   - **3-A Fast-Forward(에이전트)**: `.claude/agents/`·`playbooks/` 존재, "에이전트" 키워드 grep, LLM SDK import 검출
   - **3-B Strict Coding**: 타입 엄격 설정(tsconfig `strict`, pyproject mypy), 테스트 인프라(`__tests__/`·`tests/`·`vitest.config`·`jest.config`), 린터(`eslint`·`ruff`·`pylint`), CI 워크플로우, 사용자 의지 — 2건 이상이면 신호 강함
   - **3-C Code Navigation**: 기존 `code-map.md` 존재 또는 LoC ≥5000
   - **3-D Code-Researcher**: `src/`/`package.json` 존재 + 코드 품질 축 채택
   - **3-E Frontend Design**: React/Vue/Svelte 매니페스트 + UI 컴포넌트 디렉터리 + Tailwind/CSS 프레임워크
2. 하네스의 **실제 채택 증거** 수집:
   - Strict Coding: `.claude/templates/workflows/strict-coding-6step/` 참조 또는 `playbooks/` 내 6-Step 워크플로우
   - Code-Researcher: `.claude/agents/code-researcher.md` 존재 (또는 frontmatter 기반 대체자 — `allowed_tools` 에 읽기 도구만)
   - Frontend Design: `.claude/agents/frontend-*` 또는 `frontend-design` 프리셋
3. 현재 신호 vs 하네스 채택 매트릭스로 대조

**등급 판정**:
- `[MAJOR-DRIFT]` — 하네스가 Strict Coding 채택했는데 현재 코드에 신호 0 (test 디렉터리·린터·CI 모두 없음) — 전제 완전 오류
- `[MAJOR-DRIFT]` — 현재 코드에 Frontend Design 신호 3건 이상인데 하네스에 프론트 관련 에이전트·프리셋 0 — 주요 축 누락
- `[MINOR-DRIFT]` — 하네스 채택 vs 현재 신호가 1건 차이 (예: Strict Coding 채택, 현재 신호 2/7 — 약한 쪽이지만 완전 부재는 아님)
- `[ALIGN]` — 채택 축과 현재 신호가 모두 일관

**False Positive 주의**: 사용자 발화 기반 채택(A6) 은 코드 신호가 약해도 유효 — 채택 자체를 미스핏으로 판정하지 않음. "채택은 유효하나 인프라 구축이 지연됐다" 는 `[MINOR-DRIFT]` 로 낮춰서 기록.

### Dim 3 — 에이전트 규모 미스핏 (Agent Scale Misfit)

**스캔 대상**: `.claude/agents/*.md` 개수·모델 티어 분포 + 워크플로우 스텝 수 + 현재 소스 규모

**검사 절차**:
1. 에이전트 집계:
   - 총 수: `find {대상}/.claude/agents -name "*.md" | wc -l`
   - 모델별 분포: 각 파일 frontmatter `model` 필드 파싱 (`claude-opus-*` / `claude-sonnet-*` / `claude-haiku-*`)
2. 워크플로우 스텝 수: baseline 의 `02-workflow-design.md` 또는 `02-lite-design.md` 에서 카운트. 부재 시 CLAUDE.md 본문 grep
3. 현재 소스 규모: `current` 스냅샷의 소스 파일 수
4. 비율 기반 판정:
   - **오버피팅**: Opus 에이전트 ≥3 + 워크플로우 스텝 ≤1 + 소스 <500 파일 → 과잉 설계
   - **언더피팅**: 에이전트 ≤2 + 소스 >3000 파일 + 복수 워크플로우 → 규모 대비 부족

**등급 판정**:
- `[MAJOR-DRIFT]` — 오버피팅 또는 언더피팅 명확 (위 기준 충족)
- `[MINOR-DRIFT]` — 에이전트 수 적정하나 모델 티어가 과잉/부족 (예: 모든 에이전트 Opus 이나 워크플로우가 단순, 또는 모든 에이전트 Haiku 이나 설계 판단 요구되는 역할)
- `[ALIGN]` — 에이전트 규모·티어가 워크플로우 복잡도·소스 규모에 비례

**False Positive 주의**: 신규 프로젝트(소스 <100)인데 하네스가 풀 트랙으로 설치된 경우 오버피팅처럼 보이나, 사용자가 "앞으로 확장할 것" 이라 의도한 경우 드리프트 아님 — baseline 의 A6 답변에서 "확장 의지" 증거가 있으면 `[MINOR-DRIFT]` 로 낮춤.

### Dim 4 — 권한 경로 드리프트 + 위험 패턴 감지 (Permission Path Drift + Security Warning)

**스캔 대상**: `.claude/settings.json` `permissions.allow` + 각 agent frontmatter `allowed_dirs` (존재 시) + settings 내 위험 패턴 / 비밀값

**검사 절차 A — 경로 실존성 (적합성 감사)**:
1. `settings.json` 파싱, `permissions.allow` 의 Bash·Read·Edit 패턴에 포함된 경로 추출
2. 각 agent 파일 frontmatter 에 `allowed_dirs` 가 있으면 경로 추출
3. 추출된 모든 경로에 대해 `test -d` 로 실존 여부 확인
4. 모노레포 이관 감지: 루트 `src/` 참조가 있으나 현재 구조가 `packages/*/src/` 또는 `apps/*/src/`

**검사 절차 B — 위험 패턴·비밀값 감지 (Security Warning 전담)**:
5. `settings.json` + `.claude/settings.local.json` 본문에서 다음 패턴 grep:
   - 위험 allow 와일드카드: `Bash(*)`, `Bash(sudo *)`, `Bash(rm -rf *)`, `Bash(git push --force *)`
   - 필수 deny 누락: `permissions.deny` 섹션 자체 부재 또는 `Bash(rm -rf /)`/`Bash(sudo rm *)`/`Bash(git push --force *)` 최소 항목 누락
   - 비밀값 패턴 (11종 — MCP·클라우드 연동 프로젝트 커버):
     - Anthropic/OpenAI: `sk-[A-Za-z0-9]{20,}`, `sk-proj-[A-Za-z0-9_-]{20,}`
     - GitHub PAT/App: `ghp_[A-Za-z0-9]{30,}`, `github_pat_[A-Za-z0-9_]{80,}`
     - GitLab PAT: `glpat-[A-Za-z0-9_-]{20,}`
     - AWS: `AKIA[A-Z0-9]{16}` (Access Key ID), `ASIA[A-Z0-9]{16}` (temp credential)
     - Slack: `xoxb-[0-9]{10,}`, `xoxp-[0-9]{10,}`
     - Generic Bearer: `Bearer [A-Za-z0-9._-]{20,}`
     - JWT: `eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` (3-part dot-separated)
     - PEM Private Key: `-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----` (멀티라인 또는 JSON string escape)
     - Azure SAS URL: `sig=[A-Za-z0-9%+/]{30,}` (URL 쿼리스트링)
     - GCP Service Account: `"private_key":\s*"-----BEGIN` (JSON key 파일 임베드)
     - Google API Key: `AIza[A-Za-z0-9_-]{35}`
6. 매치된 각 항목에 대해 실제 비밀값 / 더미 플레이스홀더 구분:
   - 난수성(문자 분포·길이) 충족 + 맥락상 실키 의심 → 실제 비밀값
   - `<YOUR_API_KEY>`·`{{TOKEN}}`·`example_secret` 같은 플레이스홀더 → 더미
   - **구체 더미 판별 규칙** (FP 감소):
     - `test`·`example`·`demo`·`fake`·`placeholder`·`dummy`·`sample`·`xxxxx` 같은 예시 단어 포함 → 더미
     - 3자리 이상 연속 동일 문자(`aaaaa`, `00000`, `12345`) 포함 → 더미
     - 괄호/대괄호로 둘러싸인 변수 표기(`<...>`, `{...}`, `{{...}}`, `${...}`) → 더미
     - 위 조건 모두 불충족 + 패턴 길이 요건 충족 → 실제 비밀값 의심
   - 판정 애매 시 `Security Warning` 에 "(더미로 판단되나 재확인 권장)" 주석 부기
7. **`.gitignore` 누락 감지** (Git 레벨 방어선): `.env.*` 파일이 존재하고 `.gitignore` 에 `.env` 엔트리가 없으면 Security Warning 섹션에 "Git 레벨 비밀값 커밋 위험 — `.gitignore` 에 `.env` 추가 권장" 으로 별도 기록. Dim 7-C 훅 누락과는 분리된 Git 방어선 감지 (훅 레이어와 Git 레이어의 책임을 혼동하지 않도록)
8. 발견 항목은 **Dim 4 MAJOR/MINOR 등급과 별개**로 보고서의 `## Security Warning` 섹션에 직접 기록 (드리프트 등급으로 희석되지 않음)

**등급 판정 (절차 A 기반 드리프트 판정)**:
- `[MAJOR-DRIFT]` — 허용 경로의 절반 이상이 존재하지 않거나 모노레포 이관 감지됨 (하네스가 실제 코드 위치를 못 찾음)
- `[MINOR-DRIFT]` — 1~2개 경로가 stale 또는 신규 디렉터리(`apps/` 등) 가 allow 목록에 누락
- `[ALIGN]` — 모든 경로 실존 + 현재 구조와 일치

**Security Warning 발행 조건 (절차 B 기반, 드리프트와 독립)**:
- 위험 allow 와일드카드 1건 이상 → `Security Warning — 즉시 /harness-architect:harness-audit 또는 /harness-architect:ops-audit 실행 강권`
- 실제 비밀값(더미 아님) 1건 이상 → 동일 `Security Warning` + "파일 즉시 `.claude/settings.local.json` 으로 이관 + 비밀값 회전 권장"
- 필수 deny 누락 → Security Warning 섹션에 1줄 권고
- Security Warning 은 read-only 원칙상 **경로 명시·조치 권장만** 수행. 파일 수정 없음

**False Positive 주의**: `node_modules/` 같은 런타임 생성 디렉터리 부재는 드리프트 아님 — 리스트에서 제외 후 판정. 비밀값 패턴은 더미 판정이 애매하면 Security Warning 에 "(더미로 판단되나 재확인 권장)" 주석.

### Dim 5 — CLAUDE.md·도메인 정체성 드리프트 (Identity & Domain Drift)

**스캔 대상**: `{대상}/CLAUDE.md` 본문 + `docs/*/02b-domain-research.md` (존재 시) + `current` 스냅샷

**검사 절차**:
1. CLAUDE.md 의 **선언 섹션** grep — "언어·프레임워크·팀 크기·프로젝트 유형·도메인" 키워드:
   - 언어/스택: "Python", "TypeScript", "Go", "Rust", "Java" 등 고유명사
   - 프로젝트 유형: "CLI", "웹앱", "API 서버", "에이전트 파이프라인", "모노레포", "라이브러리" 등
   - 팀 크기: "솔로", "1인", "팀", "{N}명"
   - **도메인 키워드**: orchestrator-protocol A1 지원 유형 + 일반 도메인 명사 — "리서치", "research", "딥 리서치", "webtoon", "대시보드", "dashboard", "커머스", "commerce", "데이터 파이프라인", "data pipeline", "MLOps", "게임 빌드", "game build", "콘텐츠 자동화", "content automation", "에이전트 파이프라인", "agent pipeline", "API 서버", "API server", "REST API", "라이브러리", "library", "SDK", 그 외 CLAUDE.md 헤더·상단 문단의 고유 도메인 명사
2. `docs/*/02b-domain-research.md` 존재 시 해당 파일의 `## Summary` 또는 frontmatter 에서 도메인 ID/이름 추출
3. `current` 스냅샷의 루트 매니페스트·디렉터리 구조·소스 파일 확장자 분포·디렉터리 명명 관례(`research/`, `dashboard/`, `apps/web/`, `ml/`, `games/` 등) 와 대조
4. 의미적 불일치 탐지:
   - **스택 드리프트**: CLAUDE.md "Python CLI" vs 현재 TS 파일 다수 + `package.json`
   - **팀 크기 드리프트**: CLAUDE.md "솔로" vs `.claude/agents/` 5개 + `.github/CODEOWNERS`
   - **아키텍처 드리프트**: CLAUDE.md "단일 서비스" vs 현재 `docker-compose.yml` services 3개
   - **도메인 드리프트**: `02b-domain-research.md` 가 `deep-research` 도메인 기록 vs 현재 `src/` 가 Next.js + Tailwind + `app/dashboard/` 중심 (리서치→웹앱 피봇 신호)
   - CLAUDE.md 선언 "콘텐츠 자동화 파이프라인" vs 현재 `src/` 가 Django REST API + PostgreSQL 중심 (도메인 피봇)

**등급 판정**:
- `[MAJOR-DRIFT]` — 언어 스택·프로젝트 유형·아키텍처·**도메인** 중 하나 이상이 명백히 다름 (grep 매치 vs 파일 증거 직접 충돌)
- `[MINOR-DRIFT]` — 팀 크기·부분 스택·도메인 부수 축만 차이 (예: 리서치 도메인에 대시보드 하위 기능 추가)
- `[ALIGN]` — CLAUDE.md 선언·`02b-domain-research.md` 기록·현재 파일 증거 모두 일치

**False Positive 주의**:
- CLAUDE.md 가 "1인으로 시작해 팀으로 확장 중" 같이 **전환 의지** 를 명시했으면 현재 팀 크기가 달라도 드리프트 아님
- 도메인 드리프트 판정 시 `02b-domain-research.md` 부재는 drift 가 아니라 "당시 도메인 리서치 스킵" (Fast Track / 해당 없음) — Coverage Gaps 에 명시하되 MAJOR 승격 금지
- 도메인 키워드가 CLAUDE.md 주석·인용·과거 회고("예전엔 리서치로 시작했으나") 에만 있으면 현재 선언이 아니므로 drift 근거 아님 — 섹션 헤더 / 상단 문단 매치만 유효
- `02b-domain-research.md` 는 **baseline 참조용** (하네스 빌드 당시 도메인 기록). 파일 자체의 mtime·최신성은 감사 대상이 아님 — "지금 도메인이 뭔가" 는 현재 파일 증거로 판단하고, 02b 는 "빌드 당시 무엇이었나" 로만 사용

### Dim 6 — Baseline 부재 처리 (Heuristic-Only Mode)

**적용 시점**: `[Audit Mode] heuristic-only-mode` 일 때만 추가 Dim 으로 기록. baseline-mode 에서는 스킵.

**검사 절차**:
1. Dim 1-5 를 `추정 baseline` 으로 실행했음을 명시
2. 한계 항목 열거:
   - baseline 의 "사용자 발화 구조 신호" (A6 답변) 복원 불가 — 하네스가 실제 주입한 프리셋으로 역추정하지만 원 의도와 다를 수 있음
   - baseline 의 "프로젝트 유형·솔로/팀" 복원 불가 — CLAUDE.md 선언만이 유일한 흔적
   - 성장 속도·사용 빈도 데이터 없음 (정적 스냅샷만 감사)

**등급 판정**:
- `[MAJOR-DRIFT]` 로 승격 불가 — heuristic-only 는 본질적으로 추정이므로 MAJOR 판정의 근거가 약함. 관찰된 강한 불일치는 `[MAJOR-DRIFT (추정)]` 로 태그
- `[MINOR-DRIFT]` 기본 등급 — 추정 baseline 기반이므로 신뢰도 낮춤

### Dim 7 — 외부 인터페이스 드리프트 (MCP & Hook Drift)

**스캔 대상**: `.claude/settings.json` `mcpServers` + `.claude/settings.local.json` `mcpServers` + `.claude/hooks/hooks.json` + `.claude/hooks/*.sh`

**원칙**: 하네스의 **활성 런타임 표면**(MCP·훅) 은 선언형 문서(CLAUDE.md·에이전트 정의) 와 달리 실제 외부 의존성·실행 환경을 요구한다. 파일 내부 일관성만 검사하는 Dim 1-5 로는 이 축의 드리프트를 커버할 수 없다.

**명시적 Scope 제한** (Coverage Gaps 에 고정 문구로 반영):
- 네트워크 호출 없음 — MCP URL 은 형식 유효성·환경변수 참조만 정적 검증. 실제 엔드포인트 응답성은 감사 범위 밖
- 훅 스크립트 실행 없음 — 정적 grep 으로 경로·외부 명령 참조만 추출. 실제 실행 시 부작용·권한·환경 차이는 감사 범위 밖

#### 7-A: MCP 서버 드리프트

**검사 절차**:
1. `settings.json` 파싱 (필수). `settings.local.json` 은 **존재 시에만** 파싱 — 부재 시 해당 단계 스킵 (`.gitignore` 로 제외되어 공유 환경에 없는 것이 기본값, 부재 자체는 드리프트가 아님)
2. 각 파일의 `mcpServers` 객체에서 서버 항목별 `command` / `args` / `url` / `env` 필드 추출
3. 각 MCP 서버에 대해 유형별 정적 검증:
   - **command 기반 MCP** (`command: "python"`, `"node"` 등): `which {command}` 로 PATH 상 존재 확인. `args` 의 스크립트 경로가 있으면 `test -f` 로 실존 확인
   - **런처 기반 MCP** (`command: "npx"` / `"uvx"` / `"bunx"`): `which {launcher}` 만 확인. `args` 의 패키지명(`@modelcontextprotocol/server-postgres` 같은 npm 레지스트리 식별자) 은 파일 경로가 아니므로 `test -f` 스킵. **결과는 NOTE 등급** — "런처 존재, 패키지 설치 여부는 런타임에서만 확인 가능" 로 보고. MINOR/MAJOR 승격 금지
   - **url 기반 MCP**: URL 형식 유효성 검사(`http(s)?://`, 도메인 구조). 응답성은 확인하지 않음
   - **env 참조**: `env` 블록이 참조하는 환경 변수(`${API_KEY}` 등) 가 대상 프로젝트의 `.env`·`.env.example`·`.env.template` 에 선언되어 있는지 grep
4. 결과 분류: `실행 가능` / `PATH 없음` / `스크립트 파일 없음` / `런처 통과 (패키지 미검증)` / `env 변수 누락` / `URL 형식 오류`

**등급 판정 (7-A)**:
- `[MAJOR-DRIFT]` — 등록된 MCP 서버의 절반 이상이 검증 실패 (사실상 MCP 레이어 불능)
- `[MINOR-DRIFT]` — 1~2개 MCP 서버 실패, 또는 env 참조 누락 1건 이상
- `[ALIGN]` — 모든 MCP 정적 검증 통과

#### 7-B: 훅 실행 가능성 드리프트

**검사 절차**:
1. `.claude/hooks/hooks.json` 파싱 — 각 hook 의 `matcher` / `hooks` 배열 / 각 hook 의 `command` 또는 `type` 추출
2. 각 훅 스크립트(`.claude/hooks/*.sh`) 에 대해 정적 분석:
   - **경로 참조 유효성 — 유형별 처리**:
     - 환경변수 참조(`$CLAUDE_PROJECT_DIR/src/`·`$TARGET_PROJECT_ROOT/...`·`${CLAUDE_PLUGIN_ROOT}/...`): 변수 값이 런타임에 결정되므로 `test -d` 불가 → **NOTE 등급** ("런타임 의존, 정적 검증 불가")
     - 하드코딩 절대경로(`/Users/.../project/src/`·`/home/.../lib/`): 다른 머신 이식 불가가 기본값 → **MINOR 등급** (절대경로는 환경 이식성 원칙 위반)
     - 상대경로 / 프로젝트 기준 경로 (`src/`·`./lib/`): `test -d {대상}/{경로}` 로 실존 확인. 부재 시 MAJOR (핵심 가드 훅) 또는 MINOR (부수 훅)
   - **도구 의존성**: 스크립트가 호출하는 외부 명령(`jq`, `python3`, `curl`, `rg`, `grep`, `node`) 을 grep 후 `which` 로 존재 확인
   - **실행 권한**: `test -x {script}` 로 실행 권한 확인
3. `matcher` 관련성 점검:
   - `PreToolUse Write|Edit` 매처가 있으나 현재 하네스의 모든 에이전트가 `allowed_tools: [Read, Glob, Grep]` 같은 read-only 이면 matcher 발화 빈도 0 — NOTE 등급
   - **FP 가드**: 에이전트 frontmatter 에 `allowed_tools` 필드 자체가 **없는** 에이전트는 기본적으로 모든 도구 허용 (write-capable) 으로 간주. "모든 에이전트가 read-only" 판정은 .claude/agents/*.md 전원에 `allowed_tools` 가 명시되고 + 그 목록에 Write/Edit/Bash/NotebookEdit/MultiEdit 가 모두 부재할 때만 성립

**등급 판정 (7-B)**:
- `[MAJOR-DRIFT]` — 핵심 가드 훅(`ownership-guard.sh` 등) 이 실행 불가(실행 권한 없음·도구 의존성 실패·핵심 경로 부재)
- `[MINOR-DRIFT]` — 부수 훅 1~2개 실행 불가, 또는 matcher 관련성 약함
- `[ALIGN]` — 모든 훅 정적 검증 통과

#### 7-C: 훅 누락 (역방향 드리프트)

**원칙**: 설치된 훅이 작동하지 않는 것뿐 아니라, 현재 프로젝트 특성상 **필요한 훅이 없는** 경우도 적합성 괴리.

**검사 절차**:
1. 프로젝트 신호 기반 권장 훅 추정:
   - **비밀값 누출**: `.env.*` 파일 존재 **AND** `.gitignore` 에 `.env` 미포함 → 비밀값 누출 방지 훅 필요 (두 조건 모두 충족 시에만)
   - **force-push 보호**: `settings.json` allow 에 `Bash(git push *)` 있으나 force-push 차단 훅 부재 → 보호 훅 필요
   - **쓰기 경계**: 멀티 에이전트(`.claude/agents/` ≥2) + `allowed_dirs` 구분 있으나 `ownership-guard` 훅 부재 → 쓰기 경계 훅 필요
2. 현재 `hooks.json` 에 해당 목적의 훅이 **등록돼 있지 않으면** 누락으로 기록
3. **분리 원칙**: `.gitignore` 누락 자체는 **Git 레벨 문제** 로 Dim 7-C 가 아닌 **Security Warning (Dim 4 절차 B 확장)** 에서 별도 감지. Dim 7-C 는 "훅 레이어 방어선 부재" 에만 집중. 사용자가 조치 방향을 혼동하지 않도록 두 감지 경로를 분리

**등급 판정 (7-C)**:
- `[MAJOR-DRIFT]` — 보안 관련 필수 훅 1개 이상 누락 (force-push 차단·`.env` 다중 방어선 등). 단, `.gitignore` 누락 단독으로는 Security Warning 으로 보고하고 여기서는 MAJOR 승격 금지
- `[MINOR-DRIFT]` — 편의성 훅 1~2개 누락 (ownership-guard 등)
- `[ALIGN]` — 권장 훅 모두 존재

#### Dim 7 종합 등급

7-A / 7-B / 7-C 각 부분 등급 중 **가장 심각한 등급** 을 Dim 7 최종 등급으로 사용. 보고서에는 7-A/B/C 부분 등급도 Drift Summary Table 에 독립 행으로 표시.

**False Positive 주의**:
- 로컬 전용 MCP (개발자 개인 머신 전용) 는 공유 환경에서 검증 실패가 기본값 — `settings.local.json` 에만 선언된 MCP 는 절차 B 에서 env 누락 시 `[MINOR-DRIFT]` 로 제한 (설계 의도와 정합)
- 훅이 최근 Claude Code 버전 추가 기능(예: `SessionEnd` 이벤트) 을 사용하나 구 버전 클라이언트에서 실행되면 정적 분석으로 감지 불가 — Coverage Gaps 에 "Claude Code 버전 호환성은 감사 범위 밖" 명시

## Workflow

### Step 1: 대상 스캔 및 baseline 수집
- Pre-flight 에서 결정된 `[Audit Mode]` 확인
- baseline-mode: Step A (baseline 수집) 후 Step B (현재 스캔)
- heuristic-only-mode: Step B (현재 스캔) 후 Step C (추정 baseline 재구성)

### Step 2: Dimension 순차 실행
- Dim 1 → Dim 2 → Dim 3 → Dim 4 → Dim 5 → Dim 7 순으로 수행 (Dim 6 은 모드 의존)
- heuristic-only-mode 이면 Dim 6 추가 기록
- Dim 4 검사 절차 B (위험 패턴·비밀값 감지) 결과는 드리프트 버킷과 **별도로** Security Warning 버킷에 수집
- 각 Dim 결과를 등급별 버킷으로 수집

### Step 3: Drift Summary Table 조립
- 각 항목에 대해 (항목 이름, baseline 값, 현재 값, 드리프트 정도, 등급) 컬럼 채움

### Step 4: 보고서 조립
- MAJOR-DRIFT → MINOR-DRIFT → ALIGN 순으로 정렬
- 각 항목에 Dim 번호 태그 (`[Dim 1]` 등) 및 증거 파일·스캔 결과 참조
- Recommendation 섹션에서 `MAJOR` 카운트 기반 총평 판정:
  - MAJOR ≥2 또는 Dim 1 MAJOR → **전면 재구축 권장** (`/harness-architect:harness-setup` 재실행)
  - MAJOR 1 + MINOR 여러 건 → **부분 리팩터**
  - MAJOR 0 → **유지**

### Step 5: 반환
- 파일 생성 없음 (read-only 원칙)
- 보고서 텍스트를 오케스트레이터에 반환

## Output Contract

반환 포맷:

```
## Project-Harness Fit Audit Report — {대상 프로젝트명}

### Audit Mode
{baseline-mode | heuristic-only-mode}

### Summary
- 감사 대상: 하네스 파일 {N}개, 프로젝트 소스 파일 약 {M}개
- MAJOR-DRIFT: {N}건 / MINOR-DRIFT: {N}건 / ALIGN: {N}건
- Security Warning: {N}건 (발견 시에만 표시)
- 종합 판정: {유지 / 부분 리팩터 / 전면 재구축 권장}

**카운트 집계 규칙 (Recommendation 판정 입력)**:
- Dim 1·2·3·4·5·6 은 각 1건으로 집계
- **Dim 7 은 종합 등급 1건으로 집계** (7-A/B/C 세부는 Drift Summary Table 에만 표시되며 카운트에 중복 포함하지 않음). 종합 등급은 7-A/7-B/7-C 중 가장 심각한 등급
- Security Warning 건수는 드리프트 카운트와 **독립** (MAJOR-DRIFT 카운트에 합산 금지). Recommendation 의 "재구축/부분 리팩터/유지" 판정은 드리프트 카운트만 사용

### Security Warning (발견 시에만 표시)
(Dim 4 절차 B 결과 — 드리프트 등급과 독립)
- ⚠ settings.json `permissions.allow` 에 `Bash(*)` 와일드카드 1건 → `/harness-architect:harness-audit` 또는 `/harness-architect:ops-audit` 즉시 실행 강권
- ⚠ settings.local.json:{N}번 라인에서 실제 비밀값 의심 패턴(`sk-...`) 발견 → 비밀값 회전 + `.gitignore` 확인 권장
- ⚠ permissions.deny 섹션 부재 → 최소 deny 목록(`Bash(rm -rf /)`·`Bash(sudo rm *)`·`Bash(git push --force *)`) 추가 권장

### Drift Summary Table
| 항목 | Baseline | 현재 | 드리프트 | 등급 |
|------|---------|------|---------|------|
| [Dim 1] 트랙 | lightweight | full 초과 | 3/9 조건 역전 | MAJOR |
| [Dim 2] Strict Coding 채택 | yes | 인프라 0/5 | 완전 공백 | MAJOR |
| [Dim 3] 에이전트 규모 | 2 agents·mixed | Opus 3 + 스텝 1 | 티어 과잉 | MINOR |
| [Dim 4] 권한 경로 | src/ | packages/*/src/ | 모노레포 이관 | MINOR |
| [Dim 5] 도메인 선언 | deep-research | 현재 Next.js 대시보드 | 도메인 피봇 | MAJOR |
| [Dim 7-A] MCP 서버 | 3개 선언 | 2개 실행 가능 | postgres-mcp PATH 없음 | MINOR |
| [Dim 7-B] 훅 실행 | ownership-guard | src/ 경로 실패 | 핵심 가드 불능 | MAJOR |
| [Dim 7-C] 훅 누락 | — | secret-scan 훅 없음 | .env 파일 존재 | MAJOR |
| ... |

### MAJOR-DRIFT — 하네스 재설계 권장
- [Dim 1] 트랙 드리프트: lightweight baseline 인데 현재 소스 420파일·깊이 8·compose 3서비스 로 full 트랙 기준 초과
  → 권장 조치: `/harness-architect:harness-setup` 재실행으로 풀 트랙 재설계
  → 증거 파일: `{대상}/docs/{요청명}/00-target-path.md`, `{대상}/docker-compose.yml`

### MINOR-DRIFT — 부분 수정 권장
(동일 구조)

### ALIGN — 드리프트 없음
(간단 요약만)

### Coverage Gaps
- 프로젝트 성장 속도·사용 빈도 데이터 없이 정적 스냅샷만 감사 — 드리프트의 시간적 추세는 추정 불가
- 소스 파일 본문 내용은 읽지 않음 — 로직 복잡도·아키텍처 정합성은 검사 범위 밖
- (heuristic-only-mode 인 경우) baseline 의 원래 사용자 의도는 추정이며, 당시 발화 증거는 복원 불가
- **MCP 엔드포인트 실제 응답성** 은 감사 범위 밖 (네트워크 호출 없음) — URL 형식·PATH 존재·env 참조만 정적 검증. 서버가 연결 가능한지는 실 세션에서만 확인 가능
- **훅 런타임 동작** 은 감사 범위 밖 (스크립트 실행 없음) — 정적 grep 으로 경로·외부 명령 참조만 확인. 환경 변수 주입·권한·실제 호출 시 부작용은 실 세션에서만 검증 가능
- **Claude Code 버전 호환성** 은 감사 범위 밖 — 훅이 최근 이벤트 타입을 사용하나 구 클라이언트에서 실행되는 경우 정적 분석으로 감지 불가

### Recommendation
- **판정**: {전면 재구축 / 부분 리팩터 / 유지}
- **근거**: {MAJOR 카운트 + 핵심 드리프트 1~2건 요약}
- **다음 단계**: {구체 커맨드·수정 대상}

### Rejected Alternatives (설계 결정 기록)
- ops-audit 와 병합 기각: 파일 기반 감사와 프로젝트 대조 감사는 데이터 소스·오탐 패턴이 달라 등급 기준이 흐려짐
- harness-audit 확장 기각: 구성 진단 포지셔닝 훼손
- 4등급(MISFIT-HIGH/MED/LOW/ALIGN) 기각: HIGH vs MED 경계가 주관적, 3등급(MAJOR/MINOR/ALIGN)이 재구축 여부 이분 의사결정에 정합
- 프로젝트 코드 본문 스캔 기각: 비용·프라이버시·맥락 폭증 — 파일 수·경로·구조 신호로 충분
- Dim 7 네트워크 호출 기각: MCP URL 실제 응답성 확인은 권한·비용·flakiness 유발. 정적 검증만으로도 "PATH 부재·env 누락" 같은 확정 실패는 감지 가능
- Dim 7 훅 스크립트 실행 기각: 부작용·환경 차이·권한 이슈. 정적 grep 으로 경로·명령 참조 추출이 충분
- Security Warning 을 MAJOR-DRIFT 로 승격 기각: "드리프트 등급" 은 적합성 괴리의 크기, "Security Warning" 은 즉시 조치 필요 사안. 개념적으로 분리해야 보고서의 의사결정 흐름이 명확 (드리프트 해소 vs 보안 대응은 별도 조치)
- 도메인 드리프트를 별도 Dimension 으로 신설 기각 (Dim 7 은 외부 인터페이스 용도로 별도 사용 중): Dim 5 의 CLAUDE.md 선언 대조 로직과 95% 겹침. 키워드·파일 참조만 확장하면 되므로 Dim 5 통합이 경제적. 도메인 축은 언어·스택·팀 크기와 함께 "정체성" 범주로 묶이므로 의미적으로도 Dim 5 정합
```

## Guardrails
- 이 플레이북은 하네스·baseline·프로젝트 코드를 **수정·생성하지 않는다** (read-only 감사)
- AskUserQuestion 금지 — 발견 사항은 반환 보고서로만 전달
- `MAJOR-DRIFT` 등급은 "하네스 재설계가 유지보수 누적 비용보다 저렴한 수준의 괴리" 에만 부여 (남발 금지)
- heuristic-only-mode 에서는 모든 등급에 "(추정)" 접미사 의무
- 프로젝트 소스 파일 본문은 읽지 않는다 — 파일 수·경로·구조 신호만 사용
- Dim 1~7 의 범위 밖(시간적 추세, 사용 빈도, 로직 복잡도, MCP 엔드포인트 응답성, 훅 런타임 동작, Claude Code 버전 호환성) 은 "Coverage Gaps" 섹션에 명시
- Security Warning 은 드리프트 등급과 **독립 버킷** 이며 파일 수정 없이 "경로 명시·조치 권장"만 수행 (read-only 원칙)
- Dim 7 은 **정적 검증만** — 네트워크 호출·스크립트 실행·실제 엔드포인트 ping 금지
