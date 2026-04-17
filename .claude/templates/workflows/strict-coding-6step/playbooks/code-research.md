---
name: code-research
description: 대상 코드베이스를 깊이 분석하여 research.md를 작성한다. 레이어, 호출 흐름, 의존성, 도메인 규칙을 추적한다.
role: researcher
allowed_dirs:
  - docs/
user-invocable: false
---

# Code Research

## Goal
"조용히 시스템을 망가뜨리는 변경"을 방지하기 위해, 수정 대상과 인접 영역을 깊이 이해한 뒤 research.md로 고정한다.

## Focus
- **진입점 식별**: 사용자 요청이 영향을 주는 라우터/컴포넌트/CLI 엔트리 찾기
- **호출 흐름**: 엔트리 → 서비스 → 저장소 → DB/외부 API까지 전체 경로 추적
- **레이어 경계**: 책임 분리 규칙(UI/도메인/인프라) 파악 — 위반 시 리스크 표시
- **타입·스키마**: 관련 타입 정의·Zod/Prisma 스키마를 모두 기록
- **테스트 커버리지**: 이 영역의 기존 테스트 존재 여부와 커버리지 영역
- **숨겨진 의존성**: 이벤트, 훅, 사이드 이펙트, 전역 상태, 공유 유틸

## Workflow

0. **코드맵 우선 확인** (이 프로젝트가 `code-navigation` 규칙을 채택한 경우) — `docs/architecture/code-map.md` 존재 여부를 확인한다
   - 있으면: 코드맵을 먼저 Read하여 사용자 요청과 관련된 파일/함수 위치를 파악. 이후 Step 2-3에서 해당 위치를 타겟팅하여 Read (무차별 Glob 탐색 최소화). 코드맵에 없는 영역만 Step 2의 Glob으로 확장 탐색
   - 없으면: Step 1로 계속 진행. **Step 7에서 Escalations에 `[ASK] code-map.md 부재 — 생성할지 확인 필요` 기록** (단, 이 작업 폴더의 이전 research.md에 같은 Escalation이 이미 있으면 중복 기록하지 않음)
1. **요청 해석** — 사용자 요청에서 영향 대상(파일 패턴, 기능명) 추정
2. **파일 목록화** — Glob으로 후보 파일을 수집, 관련성 점수 매김 (코드맵이 있으면 이미 파악한 위치를 우선, 나머지 영역만 Glob)
3. **핵심 파일 정독** — Read로 진입점부터 깊이 우선 탐색. 각 파일에서 외부 의존(import) 기록
4. **호출 흐름 다이어그램** — "A → B → C" 형태로 호출 경로를 research.md에 텍스트 그래프로 기록
5. **도메인 규칙 추출** — 코드에서 비즈니스 규칙을 읽어내되, 코드로 확인되지 않는 규칙은 "미확인" 표시
6. **변경 영향 범위 예측** — 이번 요청이 바꿀 파일 목록과 그 각각이 파급시킬 다른 파일을 나열
7. **리서치 공백 식별** — 확인되지 않은 외부 스펙, 불명확한 의도를 Escalations에 기록

## Output Contract
- **저장 위치**: `docs/{task-name}/research.md`
- **필수 섹션**:
  - Context (요청 요약)
  - Entry Points
  - Call Flow (텍스트 그래프)
  - Affected Files (전체 경로 + 역할)
  - Types / Schemas
  - Existing Tests
  - Hidden Dependencies
  - Domain Rules (확인된 것 / 미확인)
  - Impact Prediction
  - Escalations

## Guardrails
- 코드를 수정하지 않는다
- "일반적으로 ~하다" 같은 코드베이스 밖 추정을 사실처럼 쓰지 않는다
- 확인하지 못한 항목은 반드시 "미확인"으로 표기
- 파일 경로는 전체 경로 사용. 상대 경로·생략 금지
- research.md 없이 다음 STEP으로 넘어갈 수 없다
