
# Ops Audit

## 질문 소유권
이 플레이북은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 발견 사항은 보고서의 해당 등급 섹션에 기록한다.

## Goal
대상 프로젝트 하네스의 **런타임 가정·운영 부채·실패 복구 미비**를 6개 Dimension으로 감사하여 RISK 등급별 보고서를 작성한다.

Phase 9 final-validation이 "구조가 올바른가"를 묻는다면, 이 감사는 "실제 실행 시 어디서 문제가 생기는가"를 묻는다.

## Prerequisites
- 대상 프로젝트에 CLAUDE.md 또는 `.claude/` 또는 `playbooks/` 가 존재 (Pre-flight에서 이미 검증됨)
- read-only 접근만 필요 (파일 수정 금지)

## Audit Dimensions

### Dim A: 세션 연속성 & 상태 지속성

**스캔 대상**: `CLAUDE.md + .claude/agents/*.md + playbooks/*.md + .claude/rules/*.md` 통합

**Pre-check — 경량 트랙 면제**: 아래 중 하나라도 감지되면 **Dim A는 즉시 `[RISK-LOW] — 경량 트랙 / 단일 패스 설계 (복구 불필요)`** 로 자동 분류하고 이후 절차를 스킵한다:
- `docs/*/00-target-path.md` frontmatter의 `track: lightweight`
- `docs/*/02-lite-design.md` frontmatter의 `session_recovery: not_applicable` 또는 `phase: L`
- 대상 하네스 파일 내 `grep -rEn "single-pass|단일 패스|session_recovery: *not_applicable|단일 세션 완결"` 매치 존재

**검사 절차 (면제 불해당 시)**:
1. **명시적 Session Recovery Protocol 섹션 탐지**:
   - `grep -l "Session Recovery\|세션 복구\|재개 프로토콜\|resume protocol\|single-pass\|단일 패스" {대상}/CLAUDE.md {대상}/.claude/agents/*.md {대상}/playbooks/*.md`
   - 발견 파일 수 기록
2. **체크포인트 메커니즘 탐지**:
   - `grep -rn "checkpoint\|체크포인트\|\.state\.\|docs/.*-state\|status:" {대상}/.claude/ {대상}/playbooks/ {대상}/CLAUDE.md`
   - `docs/` 디렉터리의 번호 순서 산출물 패턴(`[0-9]{2}-.*\.md`) 존재 여부
3. **리더 가정 탐지**:
   - `grep -rn "리더\|leader\|orchestrator\|메인 세션" {대상}` 로 리더 지정 흔적 수집
   - 있으면 해당 위치로부터 ±20줄 내에 재개 프로토콜 언급이 있는지 확인

**등급 판정**:
- `[RISK-HIGH]` — 멀티 에이전트·오케스트레이터 구조인데 Session Recovery Protocol 섹션·체크포인트 메커니즘 **둘 다** 미탐지. 세션 재시작 시 처음부터 재실행 필요.
- `[RISK-MED]` — 체크포인트는 있으나 재개 절차가 문서화되지 않음 (파일은 쌓이지만 어디서 재시작할지 불명)
- `[RISK-LOW]` — Session Recovery 섹션 존재 + 체크포인트 메커니즘 명시. 이상 없음.
- `[RISK-LOW]` (경량 트랙 분기) — Pre-check 면제 조건 충족: 단일 세션 완결 워크플로우로 명시 (복구 불필요). **경량 트랙 하네스에 RISK-HIGH가 발행되는 것은 설계 오분류이므로 Pre-check를 먼저 수행한다.**

### Dim B: 실패 복구 완결성

**원칙**: 패턴 그렙만으로 로직 기반 재시도 루프를 놓칠 수 있다. **구조적 검사 우선** + 그렙 보조.

**검사 절차**:
1. **구조적 검사 (Primary)**:
   - `.claude/agents/*.md` 및 `playbooks/*.md` 에서 `## Failure Recovery`, `## Error Handling`, `## 실패 복구`, `## 재시도` 같은 **명시적 섹션 헤더** 존재 여부 확인
   - 각 섹션에 `max_retries`·`timeout`·escalation 언급 여부 grep
2. **그렙 기반 보조 검사**:
   - `grep -rn "재시도\|retry\|실패 시\|on failure\|반복\|loop\|until" {대상}/.claude/agents/ {대상}/playbooks/`
   - 각 매치 ±5줄 내에 `max_`·`상한`·`횟수`·`N회`·`timeout` 키워드가 **없으면** 개방형 루프 후보로 기록
3. **금지 문구 탐지**:
   - `grep -rn "재설계 요청\|다시 검증\|Builder에게 넘김" {대상}`
   - 이 문구들은 종료 조건 없는 개방형 서술의 대표 패턴

**등급 판정**:
- `[RISK-HIGH]` — 실패 복구 섹션 0개 + 금지 문구 1건 이상 (무한 루프 가능)
- `[RISK-MED]` — 섹션은 있으나 `max_retries` 명시 없음 (운영 중 루프 제어 불가)
- `[RISK-LOW]` — 섹션 존재 + `max_retries`·escalation 분기 명시

**False Positive 주의**: "retry" 키워드가 설명용 주석·금지 사례 문구에만 있는 경우는 제외. 매치 주변 문맥이 설계 명세인지 단순 언급인지 에이전트가 판단.

### Dim C: Agent-Skill 이중 관리 부채 (W5 재정의)

**BLOCK 반영**: 단순 파일 페어 카운팅이 아니라 **정의 중복** 탐지.

**검사 절차**:
1. **에이전트 파일 내 방법론 인라인 탐지**:
   - `.claude/agents/*.md` 각 파일의 줄 수 측정. **50줄 초과** 에이전트는 인라인 방법론 포함 의심군
   - 해당 파일에 `## Workflow`, `## Steps`, `## Procedure`, `## 단계`, `### Step` 같은 방법론 섹션 헤더 존재 여부 확인
   - 발견 시 해당 에이전트의 `Playbooks` / `Skills` 섹션에서 참조하는 외부 스킬 파일과 내용 중복 여부 추정 (섹션명 일치율)
2. **스킬 파일 내 에이전트 정체성 중복 탐지**:
   - `playbooks/*.md` 및 `.claude/skills/*/SKILL.md` 에서 `## Identity`, `## Persona`, `## Role`, `## 정체성` 섹션 존재 여부 확인
   - 있으면 이 스킬을 소유한 에이전트 파일의 Identity 섹션과 중복 여부 확인
3. **드리프트 리스크 추정**:
   - 동일 설정 키(`model:`, `allowed_dirs:`, `description:`)가 agent 파일과 skill 파일 두 곳에 존재하는 페어 카운팅
   - **3쌍 이상**이면 드리프트 누적 위험

**등급 판정**:
- `[RISK-MED]` — 에이전트 파일에 방법론 인라인 + 대응 스킬에 동일 섹션 존재 (drift 발생 시 수정 누락 리스크 직접적)
- `[RISK-LOW]` — 동일 설정 키가 3쌍 이상 존재 (관리 부하 증가, 현재는 동기화 상태지만 변경 시 취약)
- `[RISK-LOW]` — 스킬 파일에 Identity 섹션 존재 (경미한 중복)

### Dim D: 산출물 덮어쓰기 위험

**스캔 대상**: `docs/` 디렉터리 + Phase 4 산출물이 있으면 `docs/{요청명}/03-pipeline-design.md`

**Pre-check — 경량 트랙 idempotent 선언**: `docs/*/02-lite-design.md` frontmatter의 `artifact_versioning: idempotent` 또는 대상 하네스에 `grep -rEn "artifact_versioning: *idempotent"` 매치가 존재하면 **Dim D는 즉시 `[RISK-LOW] — 경량 트랙 idempotent 선언 (docs/{요청명}/ 번호 기반 고정 경로, 덮어쓰기 안전)`** 로 자동 분류한다. 경량 트랙은 Phase L 단일 산출물만 생성하므로 버저닝 전략이 구조적으로 고정.

**검사 절차 (면제 불해당 시)**:
1. **파이프라인 설계 산출물 확인**:
   - 대상 프로젝트에 `docs/*/03-pipeline-design.md` 존재 여부 확인
   - 존재 시 `## Failure Recovery & Artifact Versioning` 섹션 유무 확인
2. **산출물 경로 분석**:
   - 에이전트·스킬 파일에서 `docs/`·`output/`·`artifacts/` 로 시작하는 출력 경로 추출
   - 각 경로가 **타임스탬프·버전·archive 패턴**을 포함하는지 확인 (`{YYYY-MM-DD}`, `v{N}`, `archive/`, `current/` 등)
3. **재실행 시나리오 추적**:
   - 동일 에이전트가 여러 번 실행될 때 이전 출력을 덮어쓰는지 추정
   - `docs/analysis/report.md` 같은 고정 경로 + 버저닝 미기재 = 오염 리스크

**등급 판정**:
- `[RISK-HIGH]` — 3개 이상의 파이프라인 출력이 고정 경로·버저닝 미기재 (재실행 시 이전 결과 모두 유실 가능)
- `[RISK-MED]` — 1~2개 파이프라인만 해당, 또는 Phase 4 산출물에 Failure Recovery 섹션 누락
- `[RISK-LOW]` — 모든 출력이 타임스탬프/버전/archive 전략 중 하나를 따름 / 또는 경량 트랙 idempotent 선언

### Dim E: 크로스 워크플로우 구조 중복

**SSoT 참조**: 이 Dimension은 `playbooks/final-validation.md` #16과 **동일 Jaccard 70% 기준**을 사용한다. 기준값 변경 시 양쪽 동시 수정.

**검사 절차**:
1. **헤더 추출**:
   - 모든 `playbooks/*.md` 및 `.claude/skills/*/SKILL.md` 에 대해 `grep -n "^##\|^###" {파일}` 로 ATX 헤더 목록 추출
2. **쌍별 Jaccard 유사도 계산**:
   - 헤더 문자열을 소문자화·공백 정규화한 집합으로 변환
   - 모든 파일 쌍에 대해 Jaccard = |A ∩ B| / |A ∪ B|
3. **임계값 판정**:
   - 70% 이상 → 중복 후보로 기록

**등급 판정**:
- `[RISK-LOW]` — Jaccard 70~85% (공통 패턴 추출 검토 권장)
- `[RISK-MED]` — Jaccard 85% 이상 (거의 동일 구조 — 기반 템플릿 또는 공통 모듈 권장)
- RISK-HIGH 없음 (정보성 Dimension)

**False Positive 주의**: 헤더 이름이 유사해도 본문이 프로젝트 특성을 반영한 고유 내용이면 중복 아님. 보고서에 "섹션 구조 기반 추정치이며 내용 중복 여부는 수동 확인 필요" 주석 추가.

### Dim F: 오케스트레이터 라우팅 프로토콜 + 코드 리서처 베이스라인

**원칙**: 생성된 하네스가 사용자 요청을 무조건 풀 파이프라인으로 태우는 구조이면 단순 요청에도 과도한 비용·문서 생산이 누적된다(실측 $18.29 오버런 사례 근거). 라우팅 프로토콜 섹션이 CLAUDE.md 에 존재하고, 오케스트레이터가 코드 확인 시 직접 Read 대신 경유할 `code-researcher` 에이전트가 베이스라인으로 존재하는지 점검한다.

**Pre-check — 코드 프로젝트 여부 판별**:
다음 OR 조건 중 하나라도 충족 시 코드 프로젝트로 분류. 모두 불충족이면 Dim F 전체 스킵, `[RISK-LOW] — 비코드 프로젝트 / 해당 사항 없음` 으로 자동 분류:
- 루트에 소스 디렉터리 존재: `src/`, `lib/`, `app/`, `backend/`, `frontend/`, `server/`, `client/` 중 하나 이상
- 패키지 매니페스트 존재: `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `pom.xml`, `composer.json`, `build.gradle` 중 하나 이상
- `.claude/agents/` 에 역할이 코드 관련(구현·리뷰·리팩터)인 에이전트 존재 (파일명 또는 description grep)

**검사 절차 (코드 프로젝트일 때)**:

1. **F-1: 라우팅 프로토콜 섹션 존재**
   - ATX 헤더 확인: `grep -En "^## 오케스트레이터 라우팅 프로토콜|^## Orchestrator Routing" {대상}/CLAUDE.md`
   - 헤더가 아닌 평문 언급은 인정하지 않음 (FP 가드)
   - 섹션 본문에 `{등급 기준}`·`{경로}` 같은 placeholder 잔존 시 "미완성" 으로 간주

2. **F-2: code-researcher 에이전트 존재 (frontmatter 기반 대체자 감지)**
   - 기본 경로: `test -f {대상}/.claude/agents/code-researcher.md`
   - **부재 시 대체자 감지**: 각 `{대상}/.claude/agents/*.md` 의 YAML frontmatter 를 파싱하여
     - `allowed_tools` 필드가 존재하고
     - 쓰기 도구(`Write`, `Edit`, `Bash`, `NotebookEdit`, `MultiEdit`) 가 **포함되지 않고**
     - 읽기 도구(`Read`, `Glob`, `Grep`) 중 1개 이상 **포함된** 에이전트가 1개 이상이면 F-2 통과
   - grep 기반 키워드 매칭(`"리서치"`, `"read-only"`) 은 오탐이 많으므로 사용하지 않음

3. **F-3: 라우팅 프로토콜이 code-researcher 를 참조**
   - 섹션 본문에 `code-researcher` 문자열 포함 여부 확인
   - 미포함 시 "프로토콜은 있으나 리서처 경유 원칙이 문서화되지 않음" 으로 부분 감점

4. **F-4: 리뷰 게이트 우회 가드 문구 (BLOCK 방지)**
   - 섹션 본문에 다음 중 하나라도 매치되어야 함:
     - `리뷰 게이트 우회 금지` / `리뷰 게이트를 우회` / `mandatory_review` / `영구 산출`
   - 미매치 시 "라우팅 프로토콜이 mandatory_review 파이프라인 우회를 허용할 수 있음" 으로 추가 RISK 발행

**등급 판정**:
- `[RISK-HIGH]` — 코드 프로젝트 + F-1 실패 (라우팅 프로토콜 섹션 완전 부재). 모든 요청이 풀 체인 강제 — 구조적 오버엔지니어링 직결.
- `[RISK-MED]` — F-1 통과 + F-2 실패 (리서처/대체자 부재). 오케스트레이터 직접 Read 로 컨텍스트 오염 리스크.
- `[RISK-MED]` — F-1 통과 + placeholder 잔존. 프로토콜 미완성.
- `[RISK-MED]` — F-1/F-2 통과 + F-4 실패 (리뷰 게이트 우회 가드 문구 부재). 생성·결정·설계 파이프라인이 S 등급으로 우회 가능.
- `[RISK-LOW]` — F-1/F-2/F-4 통과 + F-3 누락 (프로토콜에 code-researcher 참조 없음). 관례 미문서화.
- `[RISK-LOW]` (면제) — Pre-check 에서 비코드 프로젝트로 분류.

**False Positive 주의**: `.claude/templates/workflows/strict-coding-6step/` 같은 **템플릿 소스 경로** 존재는 채택 증거가 아님. 실제 대상 프로젝트의 CLAUDE.md 또는 생성된 에이전트 파일에 채택 기록이 있어야 유효. 또한 비코드 프로젝트의 경우 `.claude/agents/` 가 있어도 역할이 콘텐츠·문서 관련이면 코드 프로젝트로 분류하지 않음(grep 시 파일명·description 확인).

**Coverage Gap 명시**: 이 Dim 은 **구조적 존재** 만 검사한다. 실제 오케스트레이터가 요청 시 라우팅 프로토콜을 따르는지, code-researcher 를 실제 선호출하는지 **런타임 동작** 은 감사하지 않는다. 보고서 Coverage Gaps 에 "라우팅 프로토콜 런타임 준수 여부는 실 세션 관찰로만 검증 가능" 명시.

## Workflow

### Step 1: 대상 하네스 스캔
- `{대상}/CLAUDE.md`, `.claude/`, `playbooks/`, `docs/` 디렉터리 구조 파악
- 파일 수·디렉터리 깊이 기록

### Step 2: 6개 Dimension 순차 실행
- Dim A → B → C → D → E → F 순으로 수행
- 각 Dimension 결과를 등급별 버킷으로 수집

### Step 3: 보고서 조립
- RISK-HIGH 항목 먼저, RISK-MED, RISK-LOW 순으로 정렬
- 각 항목에 해당 Dimension 번호 태그 (`[Dim A]`, `[Dim B]` 등)
- 발견 위치(파일명·줄번호)를 구체적으로 명시

### Step 4: 반환
- 파일 생성 없음 (read-only 원칙)
- 보고서 텍스트를 오케스트레이터에 반환

## Output Contract

반환 포맷:

```
## Runtime & Ops Audit Report — {대상 프로젝트명}

### Summary
- 감사 대상: {하네스 파일 수}개
- RISK-HIGH: {N}건 / RISK-MED: {N}건 / RISK-LOW: {N}건
- 종합 평가: {양호/주의/위험}

### RISK-HIGH — 프로덕션 운영 시 실패·데이터 손실 위험
- [Dim A] {발견 내용}: {파일:줄번호}
  → 권장 조치: {구체적 수정안}
  → 참고: {관련 playbook 경로}

### RISK-MED — 운영 고통이 점차 누적
(동일 구조)

### RISK-LOW — 정보성 / 선택적 개선
(동일 구조)

### Coverage Gaps
이 감사가 검사하지 못한 항목 (예: 실제 런타임 시뮬레이션, 실행 중 상태 레이스 등). 사용자가 수동 확인이 필요한 영역 명시.

### Rejected Alternatives (설계 결정 기록)
- Phase 9 final-validation 통합 기각: 신규 harness-setup 플로우 내부에서만 실행되므로 기존 하네스 사후 감사에 부적합. 분리 커맨드로 유지.
- 단일 범용 리뷰어 재귀 기각: 본 에이전트 자체가 리뷰어 역할이며 `pipeline-review-gate.md` 재귀 금지 원칙 준수.
- Jaccard 기준값 별도 상수 파일화 기각: 2개 위치 동기화만 유지하면 드리프트 리스크 낮음. 각 위치에 SSoT 주석 명시로 대체.
- Dim F 를 Dim B (실패 복구) 에 병합 기각: 실패 복구와 복잡도 라우팅은 다른 문제 영역 (전자는 에이전트 내부 재시도, 후자는 파이프라인 진입 시 취사선택). 혼합 시 등급 판정 기준이 흐려짐.
- Dim F 를 Advisor Dim 12 에 위임 기각: Advisor 는 build-time (harness-setup Phase 산출물 리뷰), ops-audit 는 post-deployment audit (이미 배포된 하네스 진단). 실행 시점이 다르므로 독립 Dim 으로 분리.
- Dim F F-2 를 grep 키워드 기반으로 구현 기각: `read-only` / `리서치` 같은 키워드는 FP 가 많다 (무관한 문서가 매칭). 에이전트 YAML frontmatter 의 `allowed_tools` 필드에서 쓰기 도구 부재를 확인하는 구조적 검사로 전환.
- Complexity Gate (S/M/L) 구조 강제 검사 기각: 오케스트레이터 재량 부여 방식(라우팅 프로토콜)이 동일 목적을 달성하며, 구조 강제는 스킬·워크플로우 계약 대수술을 유발함. Dim F 는 프로토콜 섹션 존재 여부만 검사.
- 스킬 레벨 lite 모드 검사 기각: 오케스트레이터가 에이전트를 안 부르면 문서도 안 생김. 스킬 계약 자체를 변경하지 않는 방향으로 문제 해결.
```

## Guardrails
- 이 플레이북은 하네스 파일을 **수정·생성하지 않는다** (read-only 감사)
- AskUserQuestion 금지 — 발견 사항은 반환 보고서로만 전달
- False positive 가능성이 있는 항목은 반드시 "추정치" 명시
- RISK-HIGH 등급은 "실제 실행 시 실패·데이터 손실 직결"에만 부여 (남발 금지)
- Dim A~E의 범위 밖인 런타임 동작(실제 세션 리셋 시뮬레이션, 동시성 레이스)은 "Coverage Gaps" 섹션에 명시
