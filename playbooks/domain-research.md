
# Domain Research

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은 Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그와 함께 기록한다.

## Goal
대상 프로젝트의 핵심 도메인에 대해 **업계 표준 워크플로우 / 역할 분업 / 도구·스킬 스택 / 흔한 안티패턴**을 수집하고, 후속 Phase 3-6이 인용할 수 있는 형태로 산출물을 작성한다.

## Prerequisites
- Phase 1-2 완료: `docs/{요청명}/01-discovery-answers.md` 존재 (스캔 결과 + 기술 스택)
- 오케스트레이터 프롬프트에 `[Domain Hint]` 필드로 도메인명이 전달된 상태
- `[Domain Hint]`가 "해당 없음" / 공백 / 누락이면 **이 스킬을 실행하지 않아야 한다** (오케스트레이터가 호출하기 전에 판정). 만약 실수로 호출되었다면 Step 1에서 즉시 종료.

## Knowledge References
필요 시 Read:
- `knowledge/domains/README.md` — 큐레이션 KB 인덱스 + 작성 규약
- `knowledge/domains/{slug}.md` — 해당 도메인 KB (있는 경우)

## Workflow

### Step 1: 도메인 식별 + Sanitization

1. 오케스트레이터 프롬프트의 `[Domain Hint]` 수신
2. 입력 정제:
   - 영숫자/한글 명사 + 공백 + 하이픈만 허용
   - 2~5 단어, 80자 이하로 절단
   - URL/이메일/파일경로 패턴 감지 시 즉시 reject → Escalations에 `[BLOCKING] 도메인명 부적합 — {원문}` 기록하고 종료
3. 스킵 조건:
   - 값이 "해당 없음", "skip", "none", 빈 문자열, 또는 "--fast" 키워드 포함 → Summary에 "도메인 리서치 스킵됨" 기록하고 산출물을 **Step 6의 스킵 템플릿**으로 저장, Step 2-5 건너뛰기

4. 도메인 slug 매핑: 한글/자연어 → `knowledge/domains/{slug}.md` 파일명으로 변환
   - "딥 리서치" / "deep research" → `deep-research`
   - "웹사이트 제작" / "웹 빌드" → `website-build`
   - "웹툰 제작" → `webtoon-production`
   - "유튜브 콘텐츠" → `youtube-content`
   - "코드 리뷰" → `code-review`
   - "기술 문서" → `technical-docs`
   - "데이터 파이프라인" → `data-pipeline`
   - "마케팅 캠페인" → `marketing-campaign`
   - 매칭 실패 → Step 3 라이브 검색 only 모드

### Step 2: 큐레이션 KB 매칭

1. `knowledge/domains/{slug}.md` 존재 확인
2. 있으면 Read하여 frontmatter의 `quality` 필드 확인:
   - `quality: full` → 1차 패턴으로 채택, Step 3는 **보강 목적**으로만 옵션 실행 (budget의 절반만 사용)
   - `quality: stub` → 1차 자료 부족, Step 3 전체 실행 (full budget)
3. 없으면 Step 3 전체 실행

### Step 3: 라이브 웹 리서치 (조건부)

Budget: WebSearch ≤ 6 쿼리, WebFetch ≤ 3 페이지 (stub/미매칭 시 full budget, full KB 보강 시 1/2).

쿼리 템플릿 (변수 치환):
- `{domain} workflow architecture`
- `{domain} team roles and responsibilities`
- `{domain} tool stack`
- `{domain} common antipatterns`
- `{domain} production pipeline` (제작·생산형 도메인일 때)
- `{domain} quality assurance` (품질형 도메인일 때)

**금지 패턴** (보안):
- 쿼리에 대상 프로젝트 고유 식별자 포함 금지 (프로젝트명, 파일경로, 저장소 URL, API 키 등)
- 도메인명만 사용. 프로젝트 맥락은 로컬에서만 참조

각 검색 결과:
1. 제목 + URL + 요약 수집
2. 관련성 높은 1~3개를 WebFetch로 본문 수집
3. 본문에서 패턴을 추출 시 반드시 인용 발췌 (연속 50자 이상) + URL + 검색 일자 기록

### Step 4: 패턴 합성

수집된 자료(KB + 라이브)를 다음 4개 차원으로 정리:

1. **표준 워크플로우**: 3~8개의 스텝 시퀀스. 각 스텝은 이름/목적/완료조건/사용자트리거여부
2. **표준 역할/팀 분업**: 역할명 / 책임 / 필요 역량(스킬셋) / 전형적 인원수
3. **표준 도구·스킬 스택**: 카테고리별 대표 도구 (리서치/제작/검증/배포 등). 오픈소스 vs 상용 구분
4. **흔한 안티패턴**: 3~5개. 각 항목에 출처 또는 "검증되지 않은 추정" 표시

모든 패턴은 반드시 Sources 섹션의 인용과 1:1 매핑되어야 한다 (출처 없는 주장 금지).

### Step 5: 대상 프로젝트 정합성 체크

`01-discovery-answers.md`를 Read하여:
- 대상 프로젝트의 기술 스택과 표준 도구 스택의 **갭** 식별 (표준에 있는데 대상에 없는 도구)
- 대상 프로젝트의 규모(솔로/팀)와 표준 역할 분업의 **미스매치** (예: 표준은 5역할, 솔로는 통합 필요)

갭/미스매치를 Escalations에 `[ASK] 표준 스택과의 갭 — 도입 고려 / 스킵` 형태로 기록.

### Step 6: 산출물 작성

`docs/{요청명}/02b-domain-research.md` 를 Write.

정상 산출물 템플릿:
```markdown
<!-- phase: 2.5, completed: {timestamp}, status: done -->

# 02b. Domain Research — {도메인명}

## Summary
{~200단어. 어떤 도메인으로 식별했는지, KB/라이브 비율, 핵심 발견 3개}

## Domain Identification
- 입력 원문: {Domain Hint 원문}
- 정제된 slug: {slug}
- 신뢰도: high / medium / low (KB full=high, KB stub=medium, 미매칭+라이브=medium, 라이브만=low)
- KB 사용 여부: {full / stub / none}

## Reference Patterns

### 표준 워크플로우
{스텝 시퀀스 3~8개, 각 스텝: 이름/목적/완료조건/사용자트리거여부}

### 표준 역할/팀 분업
{역할명 / 책임 / 필요 역량 / 전형적 인원수}

### 표준 도구·스킬 스택
{카테고리별 도구 목록}

### 흔한 안티패턴
{3~5개, 각각 출처 또는 "검증되지 않은 추정"}

## Sources
{KB 인용 + 라이브 검색 결과}
- [KB] knowledge/domains/{slug}.md (quality: full|stub)
- [WEB] {URL} — 발췌일 {YYYY-MM-DD} — "{인용 발췌}"
- ...

## Project Fit Analysis
- 기술 스택 갭: {대상에 없는 표준 도구 목록}
- 팀 규모 미스매치: {있으면 기술}
- 권장 조정: {있으면 기술}

## Context for Next Phase
다음 Phase 3-6가 인용할 수 있는 구조화 요약:
- **Phase 3이 쓸 워크플로우 스텝**: {이름 목록}
- **Phase 4가 쓸 파이프라인 역할**: {역할명 목록}
- **Phase 5가 쓸 팀 구조 힌트**: {팀 단위}
- **Phase 6이 쓸 스킬 카테고리**: {카테고리 목록}
- **도메인 ID**: {slug}
- **신뢰도**: high/medium/low

## Escalations
- (해당 항목. 없으면 "없음")

## Next Steps
- Phase 3: phase-workflow 에이전트 소환 권장. 이 산출물의 워크플로우 패턴을 우선 적용.
```

스킵 산출물 템플릿:
```markdown
<!-- phase: 2.5, completed: {timestamp}, status: skipped -->

# 02b. Domain Research — Skipped

## Summary
사용자가 도메인 리서치를 스킵함 (입력: "{원문}" / 사유: "해당 없음" 또는 Fast Track).

## Context for Next Phase
Phase 3-6는 Phase 1-2 산출물만을 입력으로 사용한다. 본 파일의 Reference Patterns 섹션은 생성되지 않았다.

## Escalations
- 없음

## Next Steps
- Phase 3로 직행.
```

## Output Contract (필수 산출물 명세)

산출물 `docs/{요청명}/02b-domain-research.md`에 포함 필수 섹션 (정상 모드):
- [ ] `## Summary`
- [ ] `## Domain Identification` (입력 원문, slug, 신뢰도, KB 사용 여부)
- [ ] `## Reference Patterns` (워크플로우 / 역할 / 도구 스택 / 안티패턴)
- [ ] `## Sources` (모든 외부 인용 URL + 발췌일)
- [ ] `## Project Fit Analysis`
- [ ] `## Context for Next Phase` (Phase 3-6이 인용 가능한 구조)
- [ ] `## Escalations`
- [ ] `## Next Steps`

스킵 모드는 Summary + Context for Next Phase + Next Steps만 필수.

## Guardrails
- 본 도구(이 플러그인)의 메타 규칙을 산출물에 포함하지 않는다 (`.claude/rules/meta-leakage-guard.md` 준수)
- 대상 프로젝트 고유 식별자를 WebSearch 쿼리에 포함하지 않는다 (데이터 유출 방지)
- 모든 외부 주장에 출처 URL + 발췌일 (환각 차단). 기억에만 의존한 "일반 상식" 서술 금지
- `docs/{요청명}/02b-domain-research.md` 외 다른 대상 프로젝트 파일을 수정하지 않는다
- Budget 초과 시 검색 중단. 부분 결과로 Summary 작성 + Escalations에 `[NOTE] budget 소진` 기록
