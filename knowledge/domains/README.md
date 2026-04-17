
# knowledge/domains/ — 도메인 레퍼런스 KB

이 디렉터리는 `phase-domain-research` (Phase 2.5)가 참조하는 **도메인별 표준 패턴** KB다.

## 목적

대상 프로젝트의 핵심 도메인(딥 리서치, 웹툰 제작, 코드 리뷰 등)에 대해 업계에서 실제로 사용되는 워크플로우·역할·도구 스택을 큐레이션하여, Phase 3-6 설계 시 인용할 수 있게 한다.

## 파일 명명 규칙

- 파일명: `{slug}.md` (kebab-case 영문)
- 매칭 slug는 `playbooks/domain-research.md` Step 1의 slug 매핑 테이블과 일치해야 한다

## 품질 등급 (frontmatter)

각 파일은 YAML frontmatter에 `quality` 필드가 필수:

```yaml
---
name: {Domain Title}
slug: {slug}
quality: full | stub
sources_count: {N}
last_verified: {YYYY-MM-DD}
---
```

- `quality: full` — 아래 작성 규약을 모두 만족. Phase 2.5가 KB 단독으로 패턴 합성 가능.
- `quality: stub` — 스켈레톤만 있음. Phase 2.5가 자동으로 라이브 검색 모드로 전환하여 보강.

## Full 등급 작성 규약

다음을 모두 만족해야 `quality: full`:

1. **최소 3개 1차 출처** — URL + 발췌일(YYYY-MM-DD) + 한 줄 요약 포함
   - 우선순위: 업계 백서 / 표준 단체 / 인지도 있는 컨퍼런스·저널 / 1차 사례 연구
   - **금지**: SEO 블로그, ChatGPT 응답, 광고성 매체, 검증 불가한 개인 미디엄 글
2. **필수 4개 섹션**:
   - `## 표준 워크플로우` — 스텝 3~8개, 각각 이름/목적/완료조건
   - `## 표준 역할/팀 분업` — 역할명 / 책임 / 필요 역량 / 전형적 인원수
   - `## 표준 도구·스킬 스택` — 카테고리별, 오픈소스/상용 구분
   - `## 흔한 안티패턴` — 3~5개, 각각 출처 또는 "검증되지 않은 추정" 명시
3. **Reference Sources 섹션** — 위 주장들과 1:1 매핑. 출처 없는 주장 금지.
4. **메타 누수 금지** — 이 플러그인의 행동 규칙(Phase, Orchestrator, Escalation, Playbook 등의 용어)을 KB 본문에 포함하지 않는다. 순수하게 해당 도메인의 업계 용어만 사용.

## Stub 등급

규약 일부를 만족하지 못한 경우 `quality: stub`로 표기하고, 가능한 한 채워둔다. Phase 2.5는 라이브 검색으로 보강한다.

Stub에 최소 포함:
- frontmatter
- `## 표준 워크플로우` 초안 (출처 없는 가설이어도 OK, `검증되지 않은 추정` 명시)
- `## TODO` — 채워야 할 항목 리스트

## 확장

새 도메인을 추가하려면:
1. `knowledge/domains/{slug}.md` 생성
2. `playbooks/domain-research.md` Step 1의 slug 매핑 테이블에 라인 추가
3. full로 시작하지 않아도 됨 — stub로 먼저 추가, 후속 PR로 승격

## 현재 시드 KB

| Slug | Quality | 비고 |
|------|---------|------|
| deep-research | full | 멀티 에이전트 조사 팀 패턴 |
| code-review | full | 병렬 다차원 감사 |
| technical-docs | full | 코드베이스 분석 기반 문서화 (Diataxis) |
| website-build | full | 풀스택 빌드 파이프라인 |
| data-pipeline | full | 엔드투엔드 데이터 워크플로우 |
| webtoon-production | stub | 에피소드 콘텐츠 크리에이티브 팀 |
| youtube-content | stub | 엔드투엔드 영상 기획 |
| marketing-campaign | stub | 캠페인 에셋 제작 및 테스트 |
