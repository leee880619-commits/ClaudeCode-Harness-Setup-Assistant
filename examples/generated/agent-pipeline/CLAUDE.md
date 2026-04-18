<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# deep-research-pipeline

주제를 입력받아 멀티에이전트 파이프라인으로 심층 리서치 보고서를 생성하는 자동화 시스템.
메인 에이전트가 리서처·분석가·작가 에이전트를 순차 소환하여 최종 보고서를 작성한다.

## 기술 스택

- **런타임**: Claude Code (멀티에이전트 모드)
- **도구**: WebSearch, WebFetch, Read, Write
- **출력**: Markdown 보고서 (`output/reports/`)

## 에이전트 팀

| 에이전트 | 역할 | 소환 방법 |
|----------|------|-----------|
| researcher | 주제 탐색·출처 수집 | `Agent(subagent_type: "researcher")` |
| analyst | 수집 정보 분류·평가 | `Agent(subagent_type: "analyst")` |
| writer | 최종 보고서 작성 | `Agent(subagent_type: "writer")` |

## 파이프라인 흐름

```
사용자 요청 (주제)
  → researcher (웹 검색·출처 수집)
  → analyst (정보 평가·구조화)
  → writer (보고서 초안)
  → research-redteam (출처·편향 검증)
  → 최종 보고서 저장
```

## 개발 원칙

- 각 에이전트는 자신의 쓰기 범위(`allowed_dirs`) 밖에 파일을 생성하지 않는다
- 외부 URL 인용 시 발췌일을 함께 기록한다
- 보고서는 항상 리뷰어 에이전트를 거친 후 최종 저장된다

## 설계 문서

@import docs/example-setup/03-pipeline-design.md
@import docs/example-setup/04-agent-team.md
<!-- 위 파일들은 하네스 생성 시 docs/{요청명}/ 에 자동 생성됩니다. 이 예시에서는 참조 패턴만 표시합니다. -->
