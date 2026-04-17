---
name: implementation-planning
description: research.md를 기반으로 구현 계획 plan.md를 작성한다. 코드 스니펫, 파일 목록, 트레이드오프를 포함한다.
role: planner
allowed_dirs:
  - docs/
user-invocable: false
---

# Implementation Planning

## Goal
"잘못된 변경"을 방지하기 위해, 실제 코드베이스를 기반으로 한 검증 가능한 구현 계획을 plan.md로 고정한다.

## Focus
- **순서성**: 각 단계가 이전 단계 완료에 의존하는 구조. 병렬 가능 단계는 명시
- **검증 가능성**: 각 단계에 `verify:` 명령을 포함 (테스트/타입체크/수동 확인)
- **코드 스니펫**: 단순 파일 이름이 아니라 실제 변경 예시 스니펫을 포함
- **트레이드오프**: 선택한 접근 vs 대안 2~3개를 비교
- **범위 경계**: 포함/제외를 명시 — "이번에는 X만, Y는 별도 작업"

## Workflow

1. **research.md 내재화** — Read하여 제약·영향 파일·도메인 규칙을 파악
2. **목표 분해** — 사용자 요청을 독립 검증 가능한 작업 단위로 쪼갬
3. **각 단계 상세화**:
   - 제목
   - 변경 파일 경로
   - 구현 방법 (코드 스니펫 포함)
   - 의존 단계
   - 검증 명령 (`verify:`)
   - 소유 에이전트 힌트 (운영 중인 오너십 가드가 있는 경우)
4. **Acceptance Criteria** — 사용자 확인 가능한 완료 기준 3~5개
5. **트레이드오프 기록** — 선택 이유, 버린 대안, 미래 재고려 조건
6. **리뷰 플래그** — UI/보안/UX 리뷰가 필요한 경우 `[design-review]`, `[security-review]`, `[ux-review]` 키워드 삽입

## Output Contract
- **저장 위치**: `docs/{task-name}/plan.md`
- **필수 섹션**:
  - Goal
  - Scope (In / Out)
  - Steps (번호·제목·파일·스니펫·verify·dependency)
  - Acceptance Criteria (체크박스)
  - Trade-offs
  - Risk / Escalations

## Guardrails
- 코드를 수정하지 않는다
- 추정으로 파일 경로를 쓰지 않는다. Read로 실제 존재를 확인
- research.md의 "미확인" 항목에 기반한 가정은 반드시 Escalations에 명시
- 스니펫은 실제 실행 가능한 수준의 구체성 유지
- 모호한 표현("적절히", "필요 시") 금지
