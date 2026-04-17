---
name: web-research
description: 외부 라이브러리/API/표준 규격을 조사하여 web_research.md를 작성한다. 출처 URL과 버전을 명시한다.
role: researcher
allowed_dirs:
  - docs/
user-invocable: false
---

# Web Research

## Goal
내부 코드로 답이 나오지 않는 외부 스펙(라이브러리 동작, API 계약, 표준)을 확정하여 plan.md의 근거로 삼는다.

## Focus
- **공식 문서 우선**: 라이브러리 공식 사이트, GitHub README, RFC
- **버전 정확성**: 코드베이스의 package.json/requirements.txt 버전과 일치하는 문서 참조
- **대안 비교**: 복수 라이브러리가 있으면 공식 비교 기준(성능, 유지보수 상태, 라이선스)으로 비교
- **Deprecation 확인**: 사용하려는 API가 deprecated인지 현재 권장 방식인지
- **호환성**: 다른 라이브러리와의 알려진 충돌, peer dependency 이슈

## Workflow

1. **조사 대상 명시** — research.md의 "미확인" 항목 또는 계획 수립에 필요한 외부 스펙 리스트 작성
2. **출처 우선순위** — 공식 문서 > RFC > GitHub Issue > 블로그
3. **버전 핀 확인** — 코드베이스의 현재 버전을 먼저 확인하고, 해당 버전 문서만 인용
4. **인용** — 각 주장에 URL + 접근 날짜 + 버전을 명시
5. **충돌 해소** — 자료 간 모순이 있으면 모두 나열 + 최종 선택 근거
6. **요약 및 권고** — plan.md에 직접 가져올 수 있는 형태의 권고사항으로 정리

## Output Contract
- **저장 위치**: `docs/{task-name}/web_research.md`
- **필수 섹션**:
  - Scope (무엇을 조사했는가)
  - Findings (항목별: 주장 + 출처 URL + 날짜 + 버전)
  - Conflicts & Resolution
  - Recommendations (planner가 바로 쓸 수 있는 형태)
  - Open Questions (Escalations)

## Guardrails
- 출처 없는 일반론 금지
- 블로그/튜토리얼만 근거로 삼지 않는다. 공식 문서로 교차 확인
- 라이브러리 버전이 코드베이스와 다르면 명시적으로 경고
- 자신 없는 정보는 Open Questions로 넘긴다
- 과거 지식에 의존하지 않고 가능한 최신 자료를 참조
