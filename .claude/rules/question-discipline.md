# Question Discipline

## AskUserQuestion 소유권
- AskUserQuestion은 Orchestrator(메인 세션)만 사용
- 서브에이전트는 Escalations에 기록, Orchestrator가 취합 처리
- 정보 전달은 텍스트, 의사결정은 반드시 AskUserQuestion

## AskUserQuestion 사용법
- questions 배열에 1~4개 질문 (5개 초과 금지)
- 각 질문: question, header(12자 이내), options(2~4개, 각각 label+description), multiSelect
- 권장 옵션은 첫 번째에 "(권장)" 표기
- preview 필드: 시각적 비교 필요 시 사용
- 관련 질문은 하나의 호출로 묶는다

## 의사결정 원칙
- 모든 설정값은 명시적 답변 또는 스캔 결과 확인 필요
- "common default"도 옵션으로 제시하고 선택받아야 함
- 불확실할 때 "더 일반적인" 쪽을 선택하지 말 것 — 트레이드오프와 함께 제시
- "모르겠어요"는 유효한 답변 → `# TODO:` 마크 후 스킵
- "알아서 해줘" → 후보 목록을 AskUserQuestion으로 제시하고 선택받아야 함
- 모델, 권한, 훅, 환경변수, 스킬 범위, 프로젝트 설명 등은 절대 암묵적 결정 금지

## 금지 패턴
- 텍스트로 질문 출력하고 응답 대기
- 질문 없이 기본값 가정하고 진행
- 여러 질문을 텍스트로 나열

## 재질문 트리거
다음 상황 발생 시 즉시 AskUserQuestion으로 재질문:
- 이전 답변과 모순 발견 (모순을 텍스트로 지적 후 AskUserQuestion)
- 합리적 선택지가 여러 개인 설계 분기점
- 사용자 의도 불명확
- 파일 생성 중 예상 밖 상황 (디렉터리 부재, 기존 파일 충돌 등)

## Auto-Detection Shortcut
스캔으로 명확한 신호 발견 시:
1. 결과를 텍스트로 제시
2. AskUserQuestion으로 확인/수정 요청
