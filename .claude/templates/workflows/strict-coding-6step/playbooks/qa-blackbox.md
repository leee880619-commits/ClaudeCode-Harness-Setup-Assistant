---
name: qa-blackbox
description: 실제 런타임/브라우저에서 기능·UX·네트워크 동작을 사용자 관점에서 검증한다. 조건부 실행.
role: qa
allowed_dirs:
  - docs/
user-invocable: false
---

# Blackbox QA

## Goal
실제 앱을 기동하여 사용자 시나리오로 동작·UX·통신·엣지 케이스를 검증한다.

## Focus
- **기능 시나리오**: plan.md Acceptance Criteria를 사용자 동작 순서로 재현
- **시각 검증**: 레이아웃, 색상, 상태 표시, 반응형
- **상호작용**: 키보드, 마우스, 폼, 단축키
- **네트워크**: HTTP/WebSocket/SSE 메시지·에러 상태·재연결
- **엣지 케이스**: 빈 데이터, 에러 상태, 느린 네트워크, 중단·재시작

## Workflow

1. **사전 조건 확인** — STEP 6.0(화이트박스)이 PASS 했는가. FAIL이면 실행하지 않음
2. **환경 준비** — 프로젝트 기동 명령 실행 (기본: `npm run dev`, 포트/URL은 프로젝트별 설정)
3. **시나리오 목록** — plan.md Acceptance Criteria 각각을 사용자 동작 시퀀스로 변환
4. **각 시나리오 실행**:
   - 초기 상태 확인
   - 사용자 동작 (클릭/입력/네비게이션)
   - 기대 결과 확인 (화면/네트워크/상태)
   - 스크린샷·콘솔 로그·네트워크 로그 기록
5. **엣지 케이스 시나리오**:
   - 빈 입력 / 매우 긴 입력
   - 네트워크 끊김·재연결
   - 빠른 연속 클릭 (race)
   - 권한 없는 상태 접근
6. **회귀 확인** — 이번 변경과 인접한 기능이 여전히 동작하는가
7. **Verdict 결정** — PASS / FAIL
8. **보고서 작성**

## Output Contract
- **저장 위치**: `docs/{task-name}/qa-blackbox.md`
- **필수 섹션**:
  - Verdict (PASS / FAIL)
  - Environment (기동 명령, 버전, OS/브라우저)
  - Test Matrix (시나리오별 PASS/FAIL)
  - Visual Observations
  - Network Observations
  - Regressions (인접 기능 영향)
  - Screenshots / Logs (있다면 경로)
  - Action Items (FAIL일 때)

## Guardrails
- 코드를 수정하지 않는다
- STEP 6.0 FAIL 상태에서는 실행 금지
- 시나리오를 플래닝한 대로 실행하고, 즉흥 변경 시 보고서에 명시
- 회귀 발견 시 별도 섹션에 명확히 기록 — 사용자에게 즉시 보고되어야 함
- 브라우저 자동화 도구가 있다면 활용(Playwright 등), 없으면 수동 단계를 명시
