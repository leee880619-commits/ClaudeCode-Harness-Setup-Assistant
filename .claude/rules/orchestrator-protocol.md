# Orchestrator Protocol — Full Agent Team Model

## 원칙
메인 세션은 순수 오케스트레이터다. 직접 스킬/knowledge 파일을 로드하거나, 직접 대상 프로젝트를 분석하지 않는다.
모든 실질 작업은 Agent 도구로 소환한 서브에이전트에 위임한다.

## 메인 세션이 하는 일
1. Phase 0: 프로젝트 경로 수집 + 기존 작업 감지 + 요청명 생성 (AskUserQuestion 직접 사용)
2. 라우팅: 대상 프로젝트 상태에 따라 첫 스킬 결정 (.cursor/ → cursor-migration, .claude/ → harness-audit, 신규 → fresh-setup)
3. Phase 전환: 이전 에이전트 결과 수신 → 요약 추출 → 다음 에이전트 소환
4. Escalation 처리: 에이전트가 반환한 Escalations를 취합하여 AskUserQuestion으로 사용자에게 일괄 질문
5. 사용자 확인: Phase 간 계속 진행 여부 (AskUserQuestion)

### Phase 0 상세 프로토콜 (최대 1~2회 AskUserQuestion)

1. AskUserQuestion으로 대상 프로젝트 경로 수집
   - 사용자가 초기 요청에 경로를 포함했으면 이 질문 생략
2. 경로 존재 여부 검증 (Bash ls)
3. 기존 작업 감지: 대상 프로젝트의 docs/ 아래에 기존 작업 폴더가 있는지 확인
   - 있으면: AskUserQuestion "이전 작업 발견. 계속 진행 / 새로 시작?"
   - 없으면: 자동으로 새 작업 시작
4. 요청명 자동 생성: 프로젝트 폴더 이름 + 날짜 (별도 질문 없음)
5. 작업 폴더 생성: `docs/{요청명}/` + 쓰기 권한 테스트
6. 00-target-path.md 작성: 대상 경로, 요청명, 시작 시간 기록
7. $TARGET_PROJECT_ROOT 환경변수 설정 (ownership-guard 훅이 참조)

### Phase 0에서 인터뷰 사전 수행

서브에이전트는 AskUserQuestion을 사용할 수 없으므로, fresh-setup의 핵심 질문(Q1~Q4)은
오케스트레이터가 Phase 0에서 사전 수행하고, 답변을 서브에이전트 프롬프트에 전달한다.

**사전 인터뷰 질문** (Phase 0의 AskUserQuestion에 포함):
- 프로젝트 이름 + 한 줄 설명
- 프로젝트 유형 (웹 앱 / CLI / 에이전트 파이프라인 / 데이터 / 콘텐츠 자동화 / 기타)
- 솔로 / 팀 여부
- **기본 성능 수준** (A5) — 생성될 에이전트들의 모델 기본 배정 힌트. header: `성능 수준`. 옵션:
  1. `경제형` — Haiku 위주, 응답 빠르고 비용 낮음
  2. `균형형 (권장)` — Sonnet 중심, 복잡 설계만 Opus
  3. `고성능형` — Opus 중심, 비용 높고 응답 다소 느림
  이 값은 Phase 5 `phase-team` 프롬프트의 `[Model Tier]` 로 전달된다. 최종 조정은 Phase 6 완료 직후 "Model Confirmation Gate"에서 한 번 더 수행.
- **품질 축** (A6) — 하네스에 주입될 에이전트·스킬·규칙의 축. header: `품질 축`. **멀티 선택 가능**. 옵션:
  1. `프론트엔드 디자인·UX` — `frontend-designer` + `frontend-ux-reviewer` 에이전트와 `frontend-design` 스킬 자동 주입 대상
  2. `Strict Coding` — 타입·린트·테스트 엄격. `strict-coding-6step` 워크플로우 채택 제안 승격
  3. `보안·컴플라이언스` — 설정·훅 레벨 가드 강화 (deny 강화, 비밀값 패턴 감시)
  4. `에이전트 파이프라인` — Fast-Forward(Phase 3-5 통합) 경로 우선 고려
  5. `해당 없음` — 자동 주입 없음
  **용도** — 이 답변은 `phase-setup` 에이전트 프롬프트의 `[User Quality Axes]` 로 전달되어 `fresh-setup.md` Step 3-B/3-D/3-E 자동 판별의 **공식 입력**이 된다. 빈 폴더(greenfield) 라서 스캔 신호가 0점이어도 이 답변에 해당 축이 포함되면 해당 프리셋·워크플로우가 `[ASK]` 로 승격된다. "사용자가 말했지만 아티팩트가 없어 스킵되는" 맹점을 구조적으로 제거하는 레이어다. 답변은 트랙 판별 9번째 조건의 입력으로도 사용된다.

나머지 질문(Q5~Q9 + 도메인 후보)은 서브에이전트가 스캔 결과를 기반으로 Escalations에 기록하고,
오케스트레이터가 Phase 1-2 완료 후 일괄 처리한다.

**도메인 식별은 Phase 0 질문에 포함하지 않는다.** phase-setup이 스캔 결과로 후보 1~3개를 추정해 Escalations에 `[ASK] 핵심 도메인 식별 — 후보 ...`로 기록 → 오케스트레이터가 AskUserQuestion으로 확인. 답변은 Phase 2.5 소환 여부와 `[Domain Hint]` 값이 된다.

### Fast-Forward 경로 처리 (에이전트 프로젝트)

fresh-setup이 Escalation에 "에이전트 프로젝트 감지: Fast-Forward 경로 권장"을 반환하면:
1. 오케스트레이터가 사용자에게 확인: "에이전트 프로젝트로 감지됨. Phase 3-5 통합 진행?"
2. 승인 시: (Phase 2.5가 실행되는 경우 먼저 완료한 뒤) Phase 3(workflow) → Phase 4(pipeline) → Phase 5(team)를 순차 실행하되,
   각 Phase 에이전트에 "에이전트 프로젝트" 맥락과 Phase 2.5 산출물(있으면) 경로를 전달하여 설계 방향을 사전 안내
3. Advisor는 Phase 3-5 통합 완료 후 1회만 실행 (매 Phase가 아닌 통합 리뷰)

### Phase 2.5 도메인 리서치 소환 분기

Phase 1-2 Escalation 처리 후 오케스트레이터는 도메인 답변을 검사하여 Phase 2.5 소환 여부를 결정한다:

| 도메인 답변 / 컨텍스트 | Phase 2.5 소환 | 비고 |
|-----------------------|----------------|------|
| 유효한 도메인명 (예: "딥 리서치", "webtoon") | 소환 | `[Domain Hint]` 프롬프트로 전달 |
| "해당 없음" / 공백 / 사용자가 스킵 선택 | 소환 안 함 | Phase 3로 직행 |
| Phase 0 초기 발화 또는 사전 답변에 "--fast" / "빠르게" | 소환 안 함 | Fast Track |
| 도메인명에 URL/비밀키/내부경로 포함 (sanitization 실패) | 소환 안 함 | Escalation으로 재확인 요청 |

Phase 2.5 소환 시 다음 프롬프트 템플릿을 사용:

```
Agent(
  subagent_type: "phase-domain-research",
  description: "Phase 2.5: 도메인 리서치",
  prompt: "[Two Project Paths]
    어시스턴트 프로젝트: {어시스턴트 경로}
    대상 프로젝트: {대상 경로}

    [Phase] 2.5 — 도메인 리서치
    [Domain Hint] {사용자가 확인한 도메인명}
    [이전 Phase 결과 요약] {Phase 1-2 Summary ~200단어}
    [Artifacts Directory] {대상 경로}/docs/{요청명}/02b-domain-research.md",
  mode: "auto"
)
```

## AskUserQuestion 소유권

오케스트레이터 전용. 서브에이전트는 Escalations에 기록만. 상세: `question-discipline.md`.

## 메인 세션이 하지 않는 일
- 플레이북 파일(playbooks/*.md) 직접 로드 (→ 에이전트 prompt에 "해당 플레이북을 Read하여 따라라" 지시)
- knowledge/ 파일 직접 Read (→ 에이전트에 위임)
- 대상 프로젝트 파일 직접 Write/Edit (→ 에이전트에 위임)
- 파일 스캔, 인터뷰, 설계 등 실질 작업

## Phase 실행 프로토콜

### 에이전트 소환 템플릿 (Agent-Playbook 분리)

이 프로젝트는 Agent-Playbook 분리 패턴을 따른다:
- **WHO**: `.claude/agents/phase-*.md` — 에이전트 정체성, 규칙 (소환 시 자동 로딩)
- **HOW**: `playbooks/*.md` — 방법론 (에이전트가 Read하여 실행)

> **경로가 `.claude/skills/`가 아닌 이유**: `.claude/skills/` 아래 파일은 Claude Code가 자동 디스커버리하여 메인 세션에 "사용 가능한 스킬"로 노출시킨다. 메인 세션이 이를 Skill 도구로 직접 호출하면 서브에이전트 소환을 우회하게 되므로, 방법론 파일을 `playbooks/`에 둔다.

각 Phase 에이전트는 `subagent_type`으로 정의된 에이전트를 소환한다:

```
Agent(
  subagent_type: "phase-setup",
  description: "Phase 1-2: 스캔 + 인터뷰",
  prompt: 아래 프롬프트 템플릿,
  mode: "auto"
)
```

프롬프트 템플릿 (동적 컨텍스트만 전달 — 정체성/규칙은 에이전트 정의에 포함):
---
[Two Project Paths — 반드시 구분]
- 어시스턴트 프로젝트: {어시스턴트 절대 경로} (스킬/knowledge 읽기 전용)
- 대상 프로젝트: {대상 프로젝트 절대 경로} (산출물/하네스 파일 쓰기 대상)

[Phase] {N} — {phase 이름}

[이전 Phase 결과 요약]
{이전 에이전트가 반환한 핵심 결정사항, ~200단어 이내}

[Artifacts Directory]
Phase 산출물을 대상 프로젝트에 저장 (절대 경로 사용):
{대상 프로젝트 절대 경로}/docs/{요청명}/{NN}-{phase-name}.md

[Output Contract — Write 도구 호출 직전 자기 확인]
산출물 파일을 Write하기 전, 다음 항목을 순서대로 확인하라:
1. YAML frontmatter에 phase / completed / status / advisor_status 4개 필드가 있는가?
2. ## Summary 섹션이 있는가? (200단어 이내)
3. ## Files Generated 섹션에 실제 기록된 파일의 절대 경로가 있는가?
4. ## Context for Next Phase 섹션에 이 Phase의 필수 항목이 있는가?
5. ## Escalations 섹션이 있고, 항목 없으면 "없음"이 명시되어 있는가?
6. ## Next Steps 섹션이 있는가?
누락 항목이 있으면 Write 전에 보완한다. 이 체크리스트는 오케스트레이터의 외부 스크립트 검증(validate-phase-artifact.sh)을 보조하는 선의 예방 레이어다.
---

에이전트 정의(`.claude/agents/phase-*.md`)에 이미 포함된 내용은 프롬프트에서 생략:
- Playbook 참조 (에이전트 정의의 Playbooks 섹션)
- Knowledge 참조 (에이전트 정의의 Playbooks 섹션)
- 공통 Rules (AskUserQuestion 금지, 쓰기 범위, 반환 포맷)

### 트랙 판별 프로토콜 (Phase 1-2 완료 직후)

Phase 1-2 에이전트가 반환되면 오케스트레이터는 산출물 `01-discovery-answers.md`를 Read하여
아래 9개 조건을 모두 AND로 확인한다. **모든 조건이 충족될 때만 경량 트랙**이다.
하나라도 불충족이면 풀 트랙. **솔로 프로젝트라도 복잡도가 높을 수 있다 — "솔로 = 단순"으로 가정하지 않는다.**

| 조건 | 확인 위치 | 경량 트랙 값 |
|------|-----------|-------------|
| 프로젝트 유형 | `## Context for Next Phase` → 프로젝트 유형 | 웹앱 또는 CLI |
| 솔로/팀 | `## Context for Next Phase` → 솔로/팀 | 솔로 |
| 에이전트 프로젝트 여부 | `## Context for Next Phase` → 에이전트 프로젝트 여부 | 아니오 |
| 에이전트 신호 (3-A) | `## Escalations` → [ASK] 에이전트 프로젝트 감지 항목 | 없음 (NOTE도 없음) |
| Strict Coding 신호 (3-B) | `## Escalations` → [ASK]/[NOTE] Strict Coding 항목 | NOTE 이하 (ASK 없음) |
| 코드베이스 규모 | `## Context for Next Phase` → 디렉터리 구조 요약 | 소스 파일 ≤100개 AND 최대 디렉터리 깊이 ≤5 — 초과 시 풀 트랙 강제 |
| 배포/환경 복잡도 | `## Context for Next Phase` → 기존 설정 존재 여부 | `.env.staging`·`.env.production` 없음, `.github/workflows/` 파일 ≤1개 |
| 서비스 복잡도 | `## Context for Next Phase` → 기술 스택 | 단일 서비스 (docker-compose 없음 또는 services ≤2, 루트 외 추가 `package.json`/`requirements.txt` 없음) |
| **사용자 발화 의도 (A6 + User-Declared Structure)** | `## Context for Next Phase` → User-Declared Structure + A6 품질 축 답변 | **A6 답변에 품질 축 선택이 0~1개 (`해당 없음` 포함) AND User-Declared Structure 에 "대규모 마이그레이션/리라이트/멀티 서비스(3개 이상)/에이전트 체인" 신호 없음**. 초과 시 풀 트랙 강제 — 빈 폴더라도 사용자 발화에서 구조적 복잡도가 드러나면 경량 트랙이 부적합 |

**Strict Coding 신호 판별 세부 규칙**:
- `[ASK] Strict Coding 6-Step 권장` 항목이 1건이라도 있으면 → 풀 트랙 (사용자 확인 필요)
- `[NOTE] Strict Coding 6-Step 소개` 항목만 있으면 → 경량 트랙 허용 (단순 참고)
- 항목 없음 → 경량 트랙 허용

**판별 후 처리**:

1. `00-target-path.md` frontmatter의 `track` 필드를 `lightweight` 또는 `full`로 Edit하여 기록
   (Phase 0에서 `track: pending`으로 초기 작성, 여기서 확정)
2. AskUserQuestion으로 사용자에게 트랙 결정을 고지:
   - 경량 트랙: "스캔 결과 8개 경량 트랙 기준을 모두 충족합니다 (솔로, 비에이전트, 코드베이스 규모·배포·서비스 복잡도 신호 없음). 경량 트랙을 제안합니다 (약 25~35분, 8~10회 LLM 호출). 풀 트랙(60분+, 18회+ 호출)보다 빠르게 MVP 하네스를 완성합니다. **주의**: 경량 트랙은 단일 에이전트 단일 패스 설계이므로 세션 중단(`/clear`·프로세스 종료) 시 재개 불가 — 처음부터 재실행 필요."
     옵션: `경량 트랙으로 진행 (권장)` / `풀 트랙으로 전환`
   - 풀 트랙: 별도 고지 없이 기존 Phase 3 진행
3. 경량 트랙 선택 시 → `phase-setup-lite` 에이전트 소환 (Phase L)
   풀 트랙 선택 시 → 기존 Phase 2.5/3 분기 로직으로 진행

경량 트랙 Phase L 완료 후 흐름:
- `02-lite-design.md`의 `Phase 7-8 스킵 가능: true`이면 → Phase 9 직행
- `Phase 7-8 스킵 가능: false`이면 → Phase 7-8(`phase-hooks`) 실행 후 Phase 9

### Phase-to-Agent 매핑

| Phase | Agent Name | Playbook (playbooks/*.md) | 비고 |
|-------|-----------|--------------------------|------|
| 0 | (메인 세션) | N/A | 경로 수집만 |
| 1-2 | phase-setup | fresh-setup | 또는 cursor-migration, harness-audit |
| **L** | **phase-setup-lite** | **setup-lite** | **경량 트랙 전용. Phase 1-2 완료 후 트랙 판별 결과가 lightweight인 경우만 실행. Phase 3-6을 단일 에이전트로 대체.** |
| 2.5 | phase-domain-research | domain-research | 옵션. 도메인 답변이 "해당 없음"/Fast Track이면 스킵 |
| 3 | phase-workflow | workflow-design | Phase 2.5 산출물 있으면 Read |
| 4 | phase-pipeline | pipeline-design | Phase 2.5 산출물 있으면 Read |
| 5 | phase-team | agent-team | Phase 2.5 산출물 있으면 Read |
| 6 | phase-skills | skill-forge | Phase 2.5 산출물 있으면 Read. 복수 에이전트 SKILL 생성 시 TeamCreate 고려 |
| 7-8 | phase-hooks | hooks-mcp-setup | |
| 9 | phase-validate | final-validation | |

## Red-team Advisor 프로토콜

### 실행 시점
Phase 1-2 에이전트 완료 직후부터 Phase 9까지, 매 Phase 에이전트 완료 직후 실행한다.
Phase 2.5가 실행된 경우에도 산출물 직후 Advisor 리뷰를 수행 (단순 프로젝트는 경량 게이트).
Phase 0은 오케스트레이터 직접 처리이므로 Advisor 불필요.

### 복잡도 게이트 (경량 트랙 프로젝트 Advisor 경량화)
`track: lightweight`로 분류된 프로젝트 (9개 판별 기준 모두 충족 — 솔로·비에이전트·코드베이스·배포·서비스 복잡도·사용자 발화 의도 신호 없음):
- Phase 1-2, 2.5, 7-8, 9: Advisor 경량 실행 (NOTE만 수집, BLOCK/ASK 없으면 자동 통과)
- Phase 3-6: Advisor 전체 실행 (설계 품질이 중요)
- Phase L (경량 트랙): Advisor 경량 실행. 단, Dim 6(보안 권한 적절성)·Dim 12(파이프라인 리뷰 게이트 준수)는 항상 전체 실행
- Fast-Forward 통합 실행 시: 통합 완료 후 1회만 전체 실행

**보안 항목과 파이프라인 리뷰 게이트는 복잡도 게이트와 무관하게 항상 전체 실행한다.** 구체적으로 Advisor의 Dimension 6(보안 권한 적절성), Dimension 12(파이프라인 리뷰 게이트 준수), `final-validation` 플레이북의 Step 5(보안 감사 — `Bash(*)` / `Bash(sudo *)` 등 위험 allow 패턴, 필수 deny 존재, 비밀값 패턴)는 단순 프로젝트·경량 트랙에서도 경량화하지 않는다. 경량화는 "설계 질 평가"에만 적용되며, 보안 가드와 Dim 12 파이프라인 리뷰 가드는 게이트 우회가 금지된다.

**Dim 6 시행 시점 localization (v0.8.1~)**: Dim 6 의 "항상 전체 실행" 원칙은 유지하되, **시행 지점**은 Phase 7-8 (실제 `settings.json`/`hooks.json` 확정) 과 Phase 9 (final-validation Step 5) 로 localize 되었다. Phase 3-6 Advisor 는 설계 마크다운의 **서술적 언급**을 `[NOTE]` 로 기록하며 `[BLOCK]` 으로 승격하지 않는다 — 이는 경량화가 아닌 **시행 시점 명확화**. 실제 하드 텍스트 JSON 위반과 실제 비밀값 패턴은 여전히 어디서든 즉시 `[BLOCK]`. 매트릭스 상세는 `playbooks/design-review.md` Dimension 6 본문.

**Phase 9 security-auditor 병렬 소환 (v0.8.1~)**: Phase 9 진입 시 오케스트레이터는 다음을 병렬 소환할 수 있다:
- `phase-validate` (Sonnet) — `final-validation.md` 풀 워크플로우
- `security-auditor` (Haiku) — Dim 6 패턴 매칭만 (저비용 1차 필터)

소환 템플릿:
```
Agent(
  subagent_type: "security-auditor",
  description: "Phase 9 Dim 6 pattern audit",
  prompt: "[Target]
    대상 프로젝트: {대상 경로}
    검사 파일: .claude/settings.json, .claude/settings.local.json, .claude/agents/*.md,
              .claude/skills/**/SKILL.md, .claude/hooks/hooks.json, .claude/hooks/*.sh
    [Scope] Dim 6 패턴 매칭 전용.
    [Output] BLOCK/ASK/NOTE 구조화 리포트. 판정 애매 시 [BLOCK] 대신 [ASK] 사용."
)
```

security-auditor 결과는 phase-validate 가 `## Security Audit` 섹션에 통합한다. 소환 실패(타임아웃·미지원·에러) 시 phase-validate 는 자체 수동 체크(Step 5-B) + 자동 도구(Step 5-C) 로 Dim 6 완수. security-auditor 는 **보조 저비용 경로**이며 Phase 9 완결성은 `phase-validate` 가 최종 책임.

### Advisor Skip Gate (풀 트랙 Phase 3-8 한정 비용 절감)

풀 트랙에서도 Phase N 에이전트의 반환이 "매우 깨끗"한 경우 Advisor 전체 실행을 생략하고 **경량 Advisor(Dim 6+12만 검사)** 로 대체한다. 비용 절감 효과: Phase당 ~$0.6~0.8, 세션당 최대 $2.9 (세션당 Advisor 6회 실행 기준).

**Skip Gate 진입 조건 (AND — 하나라도 불충족 시 전체 Advisor 실행)**:
1. Phase N은 `{3, 4, 7-8}` 중 하나 (Phase 5·6은 설계 품질이 중요하므로 skip 금지)
2. Phase N 에이전트 산출물의 `## Escalations` 섹션이 "없음" 또는 `[NOTE]` 항목만 존재 (`[BLOCKING]`/`[ASK]` 0건)
3. 산출물 구조 검증(`validate-phase-artifact.sh`)이 1회차에 exit 0 통과
4. 이전 Phase들의 누적 Advisor 결과에 미해결 `manual_override` 가 없음
5. 해당 Phase 산출물이 `review_exempt: false` (Phase 4의 경우) 또는 파이프라인 리뷰 게이트 관련 변경을 도입하지 않음

**경량 Advisor 동작**:
- `[Scope] Dim 6 (보안) + Dim 12 (파이프라인 리뷰 게이트, Phase 4에만) 만 검사. 나머지 Dimension은 pass 간주.` 프롬프트로 호출
- Phase 1-2, 2.5, 5, 6, 9는 Skip Gate 대상이 아님 — 항상 전체 Advisor 실행 (설계 질 + 보안 모두 검증)

**감사 기록**: Skip Gate를 통과해 경량 Advisor로 대체했으면 해당 Phase 산출물 frontmatter의 `advisor_status` 뒤에 `:skip-gate` 접미사를 붙인다 (예: `advisor_status: pass:skip-gate`). 이후 재개 시 "경량 검증만 받았음"을 식별 가능.

**솔로 / 에이전트 프로젝트에서의 효과**: 이런 프로젝트는 보통 Phase 3 Escalation이 적어 Skip Gate 진입률이 높다 (예상 40~60%). 이를 통해 기존 풀 트랙의 Advisor 비용 ~$4.3 → ~$2.0 수준으로 경감.

### 실행 흐름

```
[Phase N Agent]
      ↓ 산출물
[Red-team Advisor] ← 산출물 + 이전 Phase 맥락 + 원래 사용자 요구사항
      ↓ 리뷰 리포트
[Orchestrator]
      ↓
  BLOCK 항목 있으면 → AskUserQuestion → Phase N 재실행 가능
  ASK 항목만 있으면 → AskUserQuestion → 답변 기록 → 다음 Phase
  NOTE만 있으면 → 텍스트 보고 → 다음 Phase
```

### 소환 템플릿

```
Agent(
  subagent_type: "red-team-advisor",
  description: "Red-team Review: Phase {N}",
  prompt: "[Review Target]
    Phase {N} 산출물: docs/{요청명}/{NN}-{phase-name}.md

    [Paths]
    어시스턴트 프로젝트: {어시스턴트 절대 경로}
    대상 프로젝트: {대상 프로젝트 절대 경로}

    [User's Original Request]
    {Phase 0에서 수집한 사용자 요구사항 원문}

    [Confirmed User Decisions]
    이전 Phase들에서 AskUserQuestion을 통해 사용자가 이미 확정한 결정 목록.
    Advisor는 이 항목들에 대해 BLOCK/ASK를 발행하지 않는다 (발행 시 재작업을 유발하나 이미 사용자가 승인한 사항).
    포맷:
    - [Phase {M}] {결정 주제}: {채택 값} (사유: {사용자 답변 요약})
    - (예: [Phase 0] 성능 수준: 균형형(Sonnet 중심), [Phase 1-2] 도메인: "딥 리서치", [Phase 5] specialist redteam 6개 신설 대신 체크리스트 통합)
    오케스트레이터가 Phase 0부터 직전 Phase까지의 AskUserQuestion 답변을 누적하여 전달.

    [직전 Phase Summary]
    {N-1 Phase의 Summary ~200단어만 포함. 누적 금지.}
    필요 시 Advisor가 직접 docs/{요청명}/ 의 이전 산출물을 Read하여 상세 컨텍스트 확보.

    [Output]
    Red-team review report (BLOCK/ASK/NOTE 구분). Confirmed User Decisions에 포함된 사항은 재질문하지 않는다."
)
```

### [Confirmed User Decisions] 누적 관리

오케스트레이터는 Phase 0부터 모든 AskUserQuestion 응답을 내부 컨텍스트에 누적한다:
- Phase 0 사전 인터뷰 답변(A1~A5, 도메인 후보 확정)
- Phase 1-2 Escalation 처리 응답(Strict Coding, code-navigation 등)
- 각 Phase의 Advisor 결과 처리 응답
- Model Confirmation Gate 응답

Red-team 소환 직전 이 목록을 구조화하여 `[Confirmed User Decisions]` 필드로 전달한다.
이렇게 하지 않으면 Advisor가 오케스트레이터 맥락을 보지 못해 이미 결정된 사항에 BLOCK을 발행하고, 루프 재작업 비용(실측 ~$0.8/세션)이 발생한다.

### Advisor 결과 처리

1. BLOCK 항목이 1건 이상:
   a. 오케스트레이터가 사용자에게 BLOCK + ASK 항목을 AskUserQuestion으로 일괄 제시
   b. 사용자 응답에 따라:
      - "반영해" → Phase N 에이전트를 피드백과 함께 재소환
      - "괜찮아, 넘어가" → 다음 Phase 진행
   c. 재소환 후 Advisor도 다시 실행 (최대 2회 루프)
   d. **루프 소진 후에도 동일 BLOCK이 반환되는 경우** (교착 탈출):
      - 오케스트레이터는 AskUserQuestion으로 **3개 선택지**를 제시한다:
        1) "무시하고 진행" — BLOCK을 수용 불가능한 제약으로 간주하지 않음
        2) "수동 개입" — 사용자가 산출물 파일을 직접 편집 후 "편집 완료" 응답
        3) "해당 Phase 스킵" — Phase를 건너뛰고 이후 Phase를 제한된 맥락으로 진행
      - 선택 결과를 해당 Phase 산출물의 `## Escalations` 에 `[MANUAL OVERRIDE] 사용자 선택: {1|2|3}, 미해결 BLOCK: {요약}` 로 기록
      - "수동 개입" 선택 시 재개 프로토콜에 따라 산출물 frontmatter의 `advisor_status`를 `manual_override`로 갱신

2. ASK 항목만 존재:
   a. AskUserQuestion으로 확인
   b. 사용자 답변을 다음 Phase 에이전트 프롬프트에 포함

3. NOTE만 존재:
   a. 텍스트로 간략 보고 후 다음 Phase 진행

## Model Confirmation Gate (Phase 6 완료 직후)

### 목적
Phase 5에서 `phase-team`이 `[Model Tier]` 힌트로 에이전트 모델을 자동 배정한 뒤, Phase 6에서 스킬 복잡도가 드러난다. 사용자가 스킬 복잡도를 반영해 모델을 최종 재조정할 수 있는 **단일 게이트**를 Phase 6 Advisor 통과 직후에 실행한다. Phase 5 직후에는 실행하지 않는다 — 스킬이 아직 보이지 않아 재조정 근거가 부족하기 때문.

### 실행 조건
- Phase 6 Advisor 리뷰가 `pass` / `note` 로 종료 (또는 `manual_override` 수락)
- `04-agent-team.md` 의 Agent Model Table 에이전트 수 **≥ 2** (단독 에이전트면 스킵)
- Phase 6 병렬 SKILL 제작(TeamCreate)이 **완전히 종료**된 상태 (레이스 방지)
- 복잡도 게이트와 무관하게 항상 실행 (단순 프로젝트도 적용) — 모델 비용·성능은 복잡도 독립 이슈

### 동작

1. 오케스트레이터가 `docs/{요청명}/04-agent-team.md` Agent Model Table + `docs/{요청명}/05-skill-specs.md` Final Agent-Skill Mapping을 Read하여 통합 표 조립:
   `| 에이전트 | 역할 | 사용 스킬 | 모델 | 상대 비용 힌트 |`
   (상대 비용: Opus ≈ Sonnet × 5, Sonnet ≈ Haiku × 3 정도의 표기로 사용자 판단 지원)
2. Phase 6 Advisor 가 `manual_override` 인 경우 표 상단에 경고: "⚠ Advisor가 {N}건 우려를 제기했고 사용자가 수용함. 재조정 시 Advisor 재실행 권장."
3. AskUserQuestion (header: `모델 확정`, 문구: "스킬 완성 후 최종 재조정 — 한 번만 실행"):
   - `전체 승인` — 현재 배정 확정 (권장)
   - `개별 에이전트 조정` — 특정 에이전트만 모델 변경
   - `티어 일괄 변경` — Phase 0과 동일 3선택으로 전체 재배정
4. "개별 조정" 선택 시 해당 에이전트를 AskUserQuestion 으로 한 번 더 (최대 4개씩) → 변경 내역을 `phase-team` 재소환 프롬프트의 `[Model Overrides]` 필드로 전달
5. "티어 일괄 변경" 선택 시 Phase 0과 동일 3선택 제시 → 새 티어를 `phase-team` 재소환 프롬프트의 `[Model Tier]` 로 전달 → `phase-team` 이 매트릭스로 전체 재배정 + `04-agent-team.md` Rejected Alternatives 갱신 + `.claude/agents/*.md` frontmatter `model` 필드 Edit. 이후 `phase-skills` 재소환 → `05-skill-specs.md` 및 SKILL.md `model` 필드 동기화
6. 재소환 상한: **2회**. 소진 시 "현재 배정 수용 / 수동 편집" 2선택 (Advisor 루프 패턴과 동일)
7. **재소환 후 Dim 11 한정 경량 Advisor 재실행 (필수)**: `phase-team` / `phase-skills` 재소환으로 `04-agent-team.md` 또는 `05-skill-specs.md` 가 재작성되면, 오케스트레이터는 `red-team-advisor` 를 **Dim 11 전용 프롬프트**(`[Scope] Dim 11 only — 모델 배정 드리프트 및 복잡도 미스매치만 검사`)로 1회 재소환한다. 결과가 `pass`/`note` 면 통과, `block` 이면 Gate 재진입. 다른 Dimension은 Phase 6 본 Advisor가 이미 커버했으므로 중복 실행하지 않음
8. 확정 후 `04-agent-team.md` frontmatter에 `model_confirmation: confirmed` 를 기록. 재개 시 이 필드로 게이트 스킵 판단

### 재개 시 안전 체크
재개 프로토콜에서 `04-agent-team.md` 를 감지하면 다음을 수행:
- Agent Model Table의 각 에이전트 model 필드와 실제 `.claude/agents/{이름}.md` frontmatter `model` 이 일치하는지 1회 sanity check
- 불일치 발견 시 "사용자가 에이전트 파일을 수동 편집한 것 같음. 테이블 기준 재동기화 / 에이전트 파일 기준 테이블 갱신 / 그대로 두고 재컨펌" 3선택 AskUserQuestion

### 변경 흔적 기록
재소환 시 `phase-team` 은 `04-agent-team.md` 의 `### 기각된 대안 (Rejected Alternatives)` 섹션을 **갱신 의무**가 있다. 이전 배정을 기각 이유와 함께 이관하고 새 배정을 본문으로 이동. 누락 시 재개 상태 혼선 유발.

## Phase Gate

다음 Phase 시작 전 이전 Phase 산출물 존재를 확인한다:

| 시작 Phase | 필수 산출물 |
|-----------|-----------|
| Phase 2.5 | docs/{name}/01-discovery-answers.md (+ 도메인 답변 확정) |
| Phase 3 | docs/{name}/01-discovery-answers.md (Phase 2.5 실행 시 02b-domain-research.md 도 선택적 입력) |
| Phase 4 | docs/{name}/02-workflow-design.md |
| Phase 5 | docs/{name}/03-pipeline-design.md |
| Phase 6 | docs/{name}/04-agent-team.md (에이전트 프로젝트일 때) |
| **Phase L (경량 트랙)** | **docs/{name}/01-discovery-answers.md + `00-target-path.md`의 `track: lightweight` 확인 + `01-discovery-answers.md` 의 `## Context for Next Phase` 에 `Intent Gate 베이스라인 설치: yes` 필드 존재 확인 (Phase 1-2 Step 3-F 설치 완료 보장; 누락 시 phase-setup 재소환 후 Phase L 진입)** |
| Phase 7-8 (풀 트랙) | docs/{name}/05-skill-specs.md |
| **Phase 7-8 (경량 트랙)** | **docs/{name}/02-lite-design.md** |
| Phase 9 | docs/{name}/06-hooks-mcp.md (경량 트랙에서 MCP가 0개이면 02-lite-design.md 허용) |

### 파일 존재 + 섹션 스키마 검증

산출물 파일 존재 확인만으로는 "에이전트가 작성 중 실패했는데 부분 파일이 남은" 경우를 거르지 못한다. 각 산출물에 대해 **필수 섹션 헤더와 frontmatter 필드**가 실제로 존재하는지를 외부 스크립트로 자동 검증한다.

#### Phase Gate 검증 절차 (오케스트레이터 실행 순서)

1. 산출물 파일 존재 확인 (`Bash(ls <artifact_file>)`)
   - 미존재 시: 이전 Phase 에이전트 재소환
2. **구조 검증** (Bash 직접 호출):
   ```
   Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase-artifact.sh <artifact_file>)
   ```
   - exit 0 → Step 3(Advisor)으로 진행
   - exit 1 → stderr의 누락 항목을 에이전트에게 전달하며 "다음 항목을 Edit으로 보완 후 재저장" 지시 → 1회만 재검증
     - 재검증 exit 0 → Advisor 진행
     - 재검증 exit 1 → `AskUserQuestion` "수동 편집 / Phase 스킵" (2선택)
3. Advisor 실행 (기존 Red-team Advisor 프로토콜 유지)

**포맷 실패와 Advisor BLOCK은 완전히 분리된 루프**다. 포맷 재검증이 Advisor 루프에 진입하지 않으며, Advisor BLOCK이 포맷 재검증을 유발하지 않는다.

검증 항목 (스크립트 내부 — 오케스트레이터는 종료 코드만 소비):
- frontmatter 필드 4개: `phase`, `completed`, `status`, `advisor_status`
- 필수 섹션 헤더 5개: `## Summary`, `## Files Generated`, `## Context for Next Phase`, `## Escalations`, `## Next Steps`
- Phase 9 전용 추가 3개: `## File Inventory`, `## Security Audit`, `## Simulation Trace`
- Escalations 섹션 비어있음: 경고(exit 0 유지) — 오케스트레이터가 참고 후 수동 확인

산출물 미존재 시: 이전 Phase 에이전트를 재소환한다.
사용자가 "Phase N으로 바로 가자" 요청 시 → 누락된 Phase를 안내하고 순서대로 진행.

### CLAUDE.md 단일 소유자 원칙

Phase 1-2(`phase-setup`)가 대상 프로젝트의 `CLAUDE.md` **본문을 단독으로 작성**한다. 후속 Phase(3~6)는 자신들의 산출물(`02-workflow-design.md`, `03-pipeline-design.md` 등)에 대해 CLAUDE.md에 `@import docs/{요청명}/NN-*.md` 참조 링크 **추가**만 할 수 있고, **본문 재작성·섹션 덮어쓰기는 금지**한다. 이는 여러 Phase가 CLAUDE.md를 경쟁 수정하여 문체·용어가 충돌하는 것을 방지한다. 소유권을 벗어난 수정 시도는 `ownership-guard`/`final-validation`에서 일관성 검증 실패로 잡혀야 한다.

**적용 시점**: 이 원칙은 신규 `fresh-setup` 으로 생성되는 하네스에만 적용된다. **기존에 배포된 하네스를 `harness-audit` 로 재진입**하는 경우, 기존 CLAUDE.md 구조가 이 원칙을 따르지 않더라도 자동 재작성하지 않는다. `harness-audit` 플레이북은 사용자에게 "기존 CLAUDE.md가 여러 Phase에 걸쳐 수정된 구조입니다. 단일 소유자 원칙으로 재구성하시겠습니까?" 를 Escalation으로 올려 확인받는다.

## 에이전트 반환 포맷

각 에이전트는 완료 시 반드시 다음 5개 섹션으로 구조화하여 반환한다:

```
## Summary
핵심 결정사항 (~200단어)

## Files Generated
- path/to/file1.md — 설명
- path/to/file2.json — 설명

## Context for Next Phase
다음 Phase가 작업을 시작하기 위해 반드시 알아야 하는 정보를 구조화하여 기록.
이 섹션은 산출물 파일(docs/{요청명}/NN-*.md)에도 동일하게 포함된다.

## Escalations
- [확인 필요] {불확실 사항 설명} — 선택지 A vs B
- (없으면 "없음")

## Next Steps
다음 Phase에 대한 제안
```

Context for Next Phase의 Phase별 필수 항목은 아래 표 참조. Escalations는 오케스트레이터가 AskUserQuestion으로 일괄 확인.

### Phase별 Context for Next Phase 필수 항목

각 Phase는 산출물 파일과 반환의 Context for Next Phase에 다음 정보를 **반드시** 포함한다:

| Phase | Context for Next Phase 필수 항목 |
|-------|-------------------------------|
| 1-2 | 프로젝트 유형, 기술 스택, 솔로/팀, 에이전트 프로젝트 여부, 디렉터리 구조 요약 (소스 파일 수·최대 디렉터리 깊이 숫자 포함), 기존 설정 존재 여부 (환경 파일 목록·CI 워크플로우 수·docker-compose 서비스 수·루트 외 package.json 수 포함), **도메인 후보 추정 (Escalation에 포함)** |
| 2.5 | 도메인 ID(slug), 신뢰도(high/medium/low), 표준 워크플로우 스텝 목록, 표준 역할 분업, 표준 도구 스택, 안티패턴, 프로젝트 정합성 갭, KB 사용 여부(full/stub/none) |
| 3 | 워크플로우 스텝 목록 (이름, 목적, 사용자 트리거 여부), 스텝 간 의존성, 완료 조건 |
| 4 | 에이전트 목록 (이름, 역할, 모델, 쓰기 범위), 에이전트별 스킬 매핑, 실행 순서/패턴, 소통 포인트, **메인 세션 역할 (라우터 only / 직접 실행 가능)** |
| 5 | 에이전트-스킬 소유권 테이블 (각 스킬의 예상 저장 위치 포함), 각 에이전트의 Identity/원칙 요약, 팀 구조, 소유권 가드 범위, **Orchestrator Pattern Decision (D-1/D-2/D-3)** |
| 6 | 스킬별 allowed_dirs 종합 목록, **저장 위치 결정 (케이스 A `.claude/skills/` / 케이스 B `playbooks/`)**, 에이전트-스킬 최종 매핑 (경로 포함) |
| 7-8 | 설치된 훅 목록, MCP 서버 목록, 검증 대상 파일 목록 |

### 공통 필수: 기각된 대안(Rejected Alternatives)

모든 Phase는 위 표의 고유 항목에 더해, Context for Next Phase 섹션에 **"기각된 대안"** 하위 항목을 포함한다. 형식:

```
## Context for Next Phase
...
### 기각된 대안 (Rejected Alternatives)
- {대안 A}: 기각 이유 — {근거}
- {대안 B}: 기각 이유 — {근거}
- (검토한 대안이 없으면 "검토된 대안 없음")
```

이유: 후속 Phase가 이미 기각된 대안을 재제안하거나 채택 결정과 충돌하는 설계를 펼치는 것을 방지.

### 상태의 단일 진실 (Single Source of Truth)

서브에이전트 반환의 Summary와 산출물 파일(`docs/{요청명}/NN-*.md`) 내용이 불일치하는 경우 **산출물 파일을 항상 우선**한다. Summary는 다음 에이전트 프롬프트에 포함되는 힌트일 뿐이며 정보 손실을 전제한다.

오케스트레이터의 책임:
1. Phase 전환 직전 산출물 파일의 `## Context for Next Phase` 섹션이 Summary와 모순되지 않는지 1회 눈으로 검증 (해당 섹션 상단 50줄 Read).
2. 모순 발견 시 해당 Phase 에이전트 재소환하여 파일을 권위 있는 상태로 재정비. Summary 갱신이 아닌 **파일 기준 재작성**을 지시.
3. 다음 Phase 에이전트에게는 "파일이 source of truth, Summary는 지표"임을 프롬프트로 강조하지 않아도 되지만, 산출물을 Read해 `## Context for Next Phase` 블록 전체를 참조하도록 설계한다.

## 상태 전달 규약

### 작업 폴더 관례

Phase 간 산출물은 `docs/{요청명}/` 디렉터리에 번호 순서로 저장한다:

```
docs/myapp-setup/
  00-target-path.md          ← Phase 0: 오케스트레이터가 작성
  01-discovery-answers.md    ← Phase 1-2: 스캔/인터뷰 결과
  02b-domain-research.md     ← Phase 2.5 (선택): 도메인 레퍼런스 패턴
  02-lite-design.md          ← Phase L (경량 트랙, Phase 3-6 대체)
  02-workflow-design.md      ← Phase 3: 워크플로우 설계
  03-pipeline-design.md      ← Phase 4: 파이프라인 설계
  04-agent-team.md           ← Phase 5: 팀 편성
  05-skill-specs.md          ← Phase 6: 스킬 명세
  06-hooks-mcp.md            ← Phase 7-8: 훅/MCP 설계
  07-validation-report.md    ← Phase 9: 최종 검증
```

### 전달 흐름

1. 각 에이전트는 완료 시 산출물을 `docs/{요청명}/` 에 파일로 저장하고, **반환 포맷**에 맞춰 결과를 반환한다
2. 산출물 파일에는 **Context for Next Phase** 섹션이 포함되어, 다음 Phase가 필요한 모든 구조화된 컨텍스트를 담는다
3. 오케스트레이터는 반환의 Summary (~200단어)를 다음 에이전트의 `[이전 Phase 결과 요약]`에 포함
4. 다음 에이전트는 `docs/{요청명}/` 의 이전 파일을 Read하여 **Context for Next Phase** 섹션에서 상세 컨텍스트를 확보한다
5. 이렇게 하면 프롬프트에는 요약만, 상세는 산출물 파일의 구조화된 섹션에서 온디맨드 로딩 — 컨텍스트 효율 극대화 + 누락 방지

## TeamCreate 사용 기준

- 기본: 각 Phase는 단일 Agent로 실행 (오버헤드 최소화)
- TeamCreate 사용 시점:
  - Phase 6에서 다수 에이전트의 SKILL.md를 병렬 생성할 때
  - Phase 내에서 독립적인 하위 작업이 3개 이상일 때
  - 에이전트 간 실시간 소통이 필요할 때

## Escalations 병합 프로토콜

에이전트 반환의 Escalations를 처리하는 절차:

### 1. 분류
각 Escalation을 카테고리별로 분류:
- **blocking**: 다음 Phase 진행 불가, 즉시 사용자 확인 필요
- **non-blocking**: 기본값으로 진행했으나, 사용자 검토 권장
- **informational**: 참고 사항 (질문 불필요, 텍스트로 보고)

### 2. 중복 제거
동일 주제의 Escalation이 여러 Phase에서 반복되면 병합:
- 최신 Phase의 내용을 우선
- 이전 Phase에서 이미 해결된 항목은 제거

### 3. 일괄 질문 (AskUserQuestion)
- blocking 항목: 즉시 AskUserQuestion (최대 4개씩)
- non-blocking 항목: **다음 Phase의 Advisor 리뷰 종료 직후까지만** 묶어서 AskUserQuestion (즉 "Phase N Advisor 결과 처리 직후, Phase N+1 에이전트 소환 이전" 지점). 2개 이상의 Phase를 건너뛰며 보류하지 않는다 — 사용자가 원래 맥락을 잃고 답변 품질이 떨어진다.
- informational: 텍스트로 보고만

### 4. 검증 (서브에이전트의 AskUserQuestion 우회 감지 포함)
Escalations와 생성된 파일의 일관성 확인:
- Escalation에서 "미결정"이라고 했는데 파일에 이미 값이 있으면 → 재확인
- Escalation 수가 0인데 산출물(Summary / `## Context for Next Phase` / 본문)에 **사용자 확인 없이 임의 결정**한 흔적이 있거나, 대화 흐름에 "사용자 답변 반영" 문구가 있지만 오케스트레이터가 해당 답변을 AskUserQuestion으로 받은 기록이 없으면 → 서브에이전트의 AskUserQuestion 직접 호출을 의심.
  - 이 경우 오케스트레이터는 해당 결정을 `[재확인]` 태그로 AskUserQuestion에 올려 사용자에게 직접 확인한다.
  - 불일치가 확인되면 해당 Phase 에이전트를 재소환하면서 프롬프트에 "AskUserQuestion 절대 금지 — 불확실 시 Escalations에 기록만" 문구를 강조한다.

## 에이전트 실패 처리

- 불완전 결과: 피드백과 함께 동일 Phase 에이전트 재소환
- 사용자 중단: 현재까지 생성된 파일 목록 정리, 재개 가능 상태 안내
- 충돌: 이전 Phase 결정과 모순 발견 시 → AskUserQuestion으로 사용자에게 해결 요청

## 진행 상황 피드백

각 Phase 전환 시 오케스트레이터가 표시. 사용자가 "멈춘 건 아닐까" 반복 질문하지 않도록 **재시도 상한과 예상 소요**를 함께 노출한다.

Phase 시작:
"📍 Phase {N}/9: {phase 이름} — 최대 재시도 2회, 예상 소요 {1~3분 / 에이전트 소환 규모에 비례}"

Phase 완료:
"✅ Phase {N} 완료. Advisor 리뷰 중..."

Advisor 재소환(교착 가능):
"🔁 Advisor 재검토 ({M}/2회차). 한도 소진 시 사용자 개입을 요청합니다."

Advisor 완료:
- BLOCK 있으면: "⚠️ Advisor가 {건수}건 BLOCK 발견. 확인이 필요합니다."
- ASK 있으면:  "💬 Advisor가 {건수}건 추가 확인을 제안합니다."
- NOTE만:      "✅ Advisor 리뷰 통과. 다음 Phase로 진행합니다."
- 루프 한도 초과: "🛑 Advisor BLOCK 2회 재시도 후에도 해소되지 않음. '무시/수동개입/스킵' 중 선택을 요청합니다."

## 중단/재개 프로토콜

### 세션 시작 시 감지
오케스트레이터가 대상 프로젝트 경로를 받으면:
1. `docs/` 디렉터리에 기존 작업 폴더 목록 수집 (여러 개 가능)
2. 작업 폴더가 1개: 곧바로 마지막 완료 Phase 판별
   작업 폴더가 2개 이상: AskUserQuestion으로 "어느 요청을 재개할까요? 또는 새로 시작할까요?" 선택지 제시
3. 재개 대상 폴더 내 파일들을 아래 "상태 판별" 절차로 분석
4. AskUserQuestion: "이전 작업 발견 (Phase {N}까지 완료, 미해결 BLOCK/ASK {K}건). 계속 / 새로 시작?"
5. 계속 선택 시: 마지막 완료 Phase 다음부터 재개. 단 수정 감지/Advisor 미해결 항목이 있으면 해당 Phase부터 재실행.

### 상태 판별 (재개 시 매번 수행)

1. **산출물별 frontmatter 파싱** (frontmatter 없으면 HTML 주석으로 fallback — 역호환):
   ```yaml
   ---
   phase: 3
   completed: 2026-04-17T14:32:00Z
   status: done | in_progress | manual_override
   advisor_status: pass | block | ask | note | manual_override
   ---
   ```
2. **수정 감지**: 각 파일의 `mtime` > `completed` 필드면 "마지막 완료 이후 사용자가 편집함"으로 간주 → 해당 Phase Advisor를 재실행 대상에 포함. 추가로 **편집된 Phase 의 번호보다 큰 모든 하류 Phase (예: Phase 3 편집 시 Phase 4, 5, 6, ...)의 산출물**도 "상류 전제 변경" 상태로 표시하여 재개 시 사용자에게 "하류 Phase 산출물을 어떻게 처리할까요? 유지 / 해당 Phase부터 재실행" 선택지를 AskUserQuestion으로 묻는다. 상류 편집이 하류 설계에 구조적 영향을 주는 경우를 놓치지 않기 위함.
3. **미해결 Escalation 수집**: 각 산출물의 `## Escalations` 섹션에서 `[BLOCKING]` / `[ASK]` 태그를 읽어 미해결 목록 구성. 재개 직후 사용자에게 일괄 AskUserQuestion으로 해소 요청.
4. **Advisor 리포트 확인**: 산출물에 `advisor_status: block | manual_override` 가 있으면 해당 Phase는 "미완" 상태로 간주 — "계속 선택 시 이 Phase부터 재개"로 분기.

### Phase 완료 시 저장
각 Phase 완료 시 산출물 파일 최상단에 **YAML frontmatter** 를 기록한다 (기존 HTML 주석은 역호환을 위해 두어도 무방하나, 신규 파일부터는 frontmatter를 기본으로):

```yaml
---
phase: 3
completed: 2026-04-17T14:32:00Z
status: done
advisor_status: pass
---

# Phase 3 — Workflow Design
...
```

frontmatter 필드 정의:
- `phase`: Phase 번호 (0, 1-2 → 2, 2.5, 3, ... 9)
- `completed`: 에이전트가 반환을 마친 ISO8601 timestamp
- `status`: `done` | `in_progress` (에이전트 실행 중 중단) | `manual_override` (BLOCK 루프 소진 후 사용자가 수동 개입)
- `advisor_status`: `pass` | `block` | `ask` | `note` | `manual_override`
- `model_confirmation` (Phase 5 산출물 `04-agent-team.md` 에만 기록): `pending` (기본) | `confirmed` (Model Confirmation Gate 통과) | `manual_override` (재소환 상한 소진 후 사용자가 수동 편집 선택). 재개 시 `confirmed` 가 아니면 Gate 재진입 대상

재개 시 오케스트레이터는 이 필드를 **재개 판단의 단일 소스**로 사용한다. HTML 주석만 있는 구형 파일은 frontmatter 없이 존재 여부만으로 Phase 완료로 취급(레거시 호환).

#### 00-target-path.md 전용 track 필드

`00-target-path.md`는 일반 Phase frontmatter 외에 `track` 필드를 추가로 포함한다:

```yaml
---
phase: 0
completed: 2026-04-17T14:00:00Z
status: done
track: pending    # Phase 1-2 완료 직후 오케스트레이터가 lightweight | full 로 Edit
---
```

- `pending`: Phase 1-2 완료 전 초기값 (Phase 0에서 작성)
- `lightweight`: 경량 트랙 (Phase L 경로)
- `full`: 풀 트랙 (Phase 3-9 경로)

재개 시 오케스트레이터는 이 필드를 읽어 경량/풀 트랙 Phase Gate를 선택한다.
`track` 필드 없음 → 풀 트랙으로 처리 (레거시 하위 호환).

### 비표준 파일명 처리 (`01-discovery-answers-v2.md` 등)

사용자가 실험적으로 만든 파일(예: `02-workflow-design-alt.md`, `01-discovery-answers-v2.md`)이나 에이전트가 다른 이름으로 저장한 파일은 **권위 있는 Phase 산출물로 취급하지 않는다.**

- 재개 시 `docs/{요청명}/` 스캔은 정규식 `^[0-9]{2}[a-z]?-[a-z-]+\.md$` 로 엄격 매칭되는 파일만 권위 있는 산출물로 인정한다.
- 매칭되지 않는 `.md` 파일이 있으면 오케스트레이터는 "비표준 파일 {N}건 발견: {목록}. 무시하고 재개 / 사용자가 편집할 파일로 간주 / 정리" 를 AskUserQuestion으로 묻는다.
- 매칭된 파일 중에서도 YAML frontmatter가 **누락된 파일**은 "존재는 하되 상태 불명"으로 분류 — `status` 를 사용자에게 확인받아 결정.

이 규약으로 "파일 번호 엇갈림" 위험(수동 재작성·재생성·실험 파일 혼입)을 부분 완화한다. 완전 해결은 `docs/{요청명}/.state.json` 인덱스 도입이 필요하나, 도입 시 하네스 배포본 호환성 이슈가 커지므로 이 단계에서는 도입을 유보한다.
