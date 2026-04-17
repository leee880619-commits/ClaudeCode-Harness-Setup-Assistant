---
name: question-drafting
description: plan.md를 읽고 사용자에게 물어야 할 질문 초안을 4개 유형(가정/의사결정/도메인/범위)으로 체계화한다.
role: question-drafter
allowed_dirs:
  - docs/
user-invocable: false
---

# Question Drafting

## Goal
STEP 3 질문 사이클에서 오케스트레이터가 사용자에게 **빠짐없이, 한 번에** 물을 수 있도록 질문 초안을 구조화한다.

## Focus
- **완전성**: 설계가 뒤집힐 수 있는 모든 항목을 빠짐없이 추출
- **비중복**: docs/{task-name}/ 내 기존 산출물에서 이미 답변된 항목은 제외
- **기본값 명시**: 각 질문에 "현재 가정하고 있는 답"을 함께 제시
- **유형 분류**: 가정 검증 / 의사결정 / 도메인 규칙 / 범위 경계

## Workflow

1. **입력 Read** — plan.md + research.md + (있으면) web_research.md + 이전 답변 기록
2. **가정 식별** — plan.md에서 "~라고 가정", "~일 것이다" 표현을 찾고, 틀렸을 때 plan이 달라지는 항목만 후보로
3. **의사결정 분기 식별** — plan.md의 선택지(A vs B), 트레이드오프 섹션에서 사용자 권한 항목 추출
4. **도메인 규칙 갭 식별** — research.md의 "미확인" 도메인 규칙을 전부 질문화
5. **범위 경계 식별** — Scope In/Out 경계가 모호한 항목
6. **중복 제거 및 우선순위** — 이미 확인된 항목 제거, BLOCK/NICE-TO-KNOW 분류
7. **질문 카드 작성** — 각 질문을 오케스트레이터 AskUserQuestion에 바로 투입 가능한 형태로

## Output Contract
- **저장 위치**: `docs/{task-name}/questions-draft.md`
- **필수 섹션**: 4개 유형별로 그룹화
- **각 질문 필수 필드**:
  - 번호 (Q1, Q2, ...)
  - 유형 (가정/의사결정/도메인/범위)
  - 질문 본문 (한 문장)
  - 현재 기본값 (planner가 가정한 답)
  - 영향 범위 (plan.md의 어느 단계가 달라지는가)
  - 우선순위 (BLOCKING / NICE)
- **헤더**:
  - 총 질문 수
  - BLOCKING 개수
  - 이전 사이클에서 재질문되는 항목 표시

## Guardrails
- 직접 사용자에게 묻지 않는다 — 초안만 작성
- "예쁘게", "최적으로" 같은 모호한 질문 금지. 선택지로 구체화
- plan.md에 이미 사용자 답변이 반영된 항목을 재질문하지 않는다
- 한 질문당 한 가지 결정만 — 복합 질문 금지
- BLOCKING이 아닌 항목은 NICE로 분류하여 오케스트레이터가 스킵 가능하게
