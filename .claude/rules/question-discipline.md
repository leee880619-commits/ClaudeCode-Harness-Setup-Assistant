# Question Discipline

## AskUserQuestion 소유권
- AskUserQuestion은 Orchestrator(메인 세션)만 사용
- 서브에이전트는 Escalations에 기록, Orchestrator가 취합 처리
- 정보 전달은 텍스트, 의사결정은 반드시 AskUserQuestion

## AskUserQuestion 사용법
- questions 배열에 1~4개 질문 (5개 초과 금지)
- 각 질문: question, header(12자 이내), options(2~4개, 각각 label+description), multiSelect
- "(권장)" 라벨 부착은 **"Recommended Label Discipline" 규칙을 따른다** (아래 섹션). 모델 자체 판단으로 부착 금지.
- preview 필드: 시각적 비교 필요 시 사용
- 관련 질문은 하나의 호출로 묶는다

## Recommended Label Discipline

AskUserQuestion 옵션 라벨에 `(권장)` / `(Recommended)` 표기는 사용자 자율 결정을 잠식할 수 있는 강한 시그널이다. v0.10.x 까지 모델이 자체 판단으로 "(권장)" 을 부착한 사례 (예: incident 의 Phase 0 Q1 "에이전트 파이프라인 (권장)") 가 있어 명시적 규율을 둔다.

### 부착 허용 조건 (AND — 둘 중 하나만 충족하면 허용)
- (a) **슬래시 커맨드 정의 또는 플레이북 본문에 라벨이 명시적으로 박혀있는 경우** — 예: `commands/harness-setup.md` 의 "균형형 (권장)". 인용 근거는 해당 파일 경로.
- (b) **플러그인 규칙·플레이북·도메인 KB 가 명시적으로 권장 옵션을 정의한 경우** — 인용 근거를 옵션 description 본문에 표기 의무. 예: "(권장 — `playbooks/skill-forge.md` Step 4-A 매트릭스 기준)"

### 부착 금지 조건
- **모델 자체 판단**으로 "도메인 적합도가 높다" / "일반적으로 좋다" / "사용자가 좋아할 것 같다" 라고 느낀 경우 → 라벨 부착 금지. 추정 표현은 옵션 description 본문에 "AI 추정: 이 선택지가 {X} 사유로 적합" 식으로 명시.
- **트레이드오프 차원이 다른 옵션 간** 비교 (시간 vs 규모, 단순 vs 안전, 비용 vs 품질) → "(권장)" 비교 금지. 사용자 자율 결정 영역.
- **사용자 발화에서 키워드 추출만으로** "추정 의도에 부합" 이라고 판단 (예: 사용자가 "에이전트" 라고 말했으니 "에이전트 파이프라인 옵션" 에 권장 부착) → 금지. 사용자가 어떤 트레이드오프를 의식한 발화인지 모르므로 라벨 마킹 대신 description 으로 트레이드오프 노출.

### 권장 위반 시 결과
- Phase 1-2 Advisor 가 `01-discovery-answers.md` 의 사용자 응답 흔적을 보고 "(권장)" 자체 부착이 의심되면 `[NOTE]` 발행. 사용자 자율성 침해 패턴 감시.
- Phase 0 진행 중 자체 부착이 감지되면 (예: thinking 안에서 "추정 의도에 부합하므로 권장 표기" 같은 사유 인용) 오케스트레이터는 라벨을 제거하고 description 으로 이동.

### 추론 표현은 옵션 description 본문에
AI 가 사용자에게 추정 적정선을 전달하고 싶을 때의 올바른 방식:
- **잘못된 예**: `label: "에이전트 파이프라인 (권장)"` — 자체 부착, 라벨로 시그널
- **올바른 예**: `label: "에이전트 파이프라인"`, `description: "AI 추정 근거: 사용자 발화에 '에이전트' 명시 + 도메인 = 멀티-스텝 → 이 옵션이 도메인 적합도 높음. 트레이드오프: 산출물 규모 ~30%↑, 소요 ~50%↑. 슬림 운영을 원하면 단일 Skill 묶음 옵션도 고려."` — description 으로 추정 사유·트레이드오프 노출, 라벨은 중립

## 의사결정 원칙
- 모든 설정값은 명시적 답변 또는 스캔 결과 확인 필요
- "common default"도 옵션으로 제시하고 선택받아야 함
- 불확실할 때 "더 일반적인" 쪽을 선택하지 말 것 — 트레이드오프와 함께 제시
- "모르겠어요"는 유효한 답변 → `# TODO:` 마크 후 스킵
- "알아서 해줘" → 후보 목록을 AskUserQuestion으로 제시하고 선택받아야 함
- 모델, 권한, 훅, 환경변수, 스킬 범위, 프로젝트 설명 등은 절대 암묵적 결정 금지

## Free-form Utterance Inference Discipline — 자유 발화 추론 규율

사용자가 슬래시 커맨드 호출과 함께 자유 발화로 정보를 제공할 때 (예: `/harness-architect:harness-setup 리서치 에이전트 만들거야. brightdata mcp 사용. 빠르게 설정`), 발화에서 추출한 값은 **답변이 아니라 추정** 이다. 모델이 추정을 답변으로 승격 처리하면 사용자에게 보이지 않는 silent inference 가 되어 "암묵적 합의 금지" 원칙을 우회한다.

### 정의 분리
- **명시적 답변 (explicit answer)**: 오케스트레이터가 호출한 AskUserQuestion 의 옵션 선택 또는 "Other" 자유 텍스트 입력 응답. `tool_result` 로 모델 컨텍스트에 도달.
- **암묵적 추정 (implicit inference)**: 사용자의 슬래시 커맨드 인자, 자유 발화, 이전 대화 맥락에서 모델이 추출한 값.

**규율**: 설정값·인터뷰 답변·설계 결정의 입력으로 **명시적 답변만 인정**. 암묵적 추정은 (a) AskUserQuestion 옵션 description 의 "AI 추정 근거" 표기, 또는 (b) 옵션 prefill 후보 노출 — 둘 중 하나의 용도로만 사용 가능하며, 그 자체로 답변 슬롯을 채우지 않는다.

### 금지 패턴 (Forbidden)
- 사용자 발화에 "에이전트 파이프라인" 키워드가 있다고 A6 (품질 축) 을 AskUserQuestion 없이 `에이전트 파이프라인` 으로 자체 기록
- "빠르게" 키워드가 있다고 A1~A10 항목 중 일부를 AskUserQuestion 발화에서 제외
- `$ARGUMENTS` 가 자유 발화 텍스트일 때 그 텍스트에서 프로젝트 이름·유형·도메인을 추출하여 A1·A2·도메인 답변으로 기록
- 사용자 발화에서 "솔로" / "팀" 단어 추출 후 A3 답변으로 기록
- thinking 내부에서 "사용자가 발화로 X 라고 했으니 옵션 발화 생략" 같은 사유 인용

### 허용 패턴 (Allowed)
- 자유 발화에서 추출한 "리서치 에이전트, brightdata mcp 사용" 을 A2 (유형) 옵션의 `에이전트 파이프라인` description 본문에 "AI 추정 근거: 사용자 발화 '리서치 에이전트' 명시" 로 노출 (옵션은 정상 발화)
- A10 옵션 label / description 의 정량 견적 (에이전트 수·파일 수·소요) 을 발화에서 추출한 사용 강도·복잡도로 보정 (옵션 *내용* 보정은 OK, 옵션 *생략* 은 금지)
- `$ARGUMENTS` 가 **유효 디렉터리 경로** 일 때 "경로" 항목만 prefill 로 생략 (값 자체가 명확하고 사용자가 의도적으로 입력했으므로 — A1~A10 발화는 그대로)

### description ≠ 답변 (Patch D-4 — QA HIGH 반례 차단)

옵션 description 본문의 "AI 추정 근거: ..." 표기는 **사용자가 옵션을 명시 선택하지 않은 상태로는 답변으로 인정되지 않는다**. `tool_result` 의 명시 선택 (옵션 선택 또는 "Other" 자유 텍스트 응답) 만 답변 슬롯을 채운다. 모델이 "description 에 답이 다 있으니 사용자가 응답 안 해도 description = 답변" 으로 해석하는 것은 silent inference 의 변형이며 금지. AskUserQuestion 호출의 `tool_result` 가 비어있는 채로 Phase 0 자기점검 표를 작성하면 표의 "답변" 열도 비어있어야 하고, 빈 항목은 추가 발화 대상이다.

### 빈 `tool_result` / 부분 응답 / dismiss 처리

AskUserQuestion 의 `tool_result` 가 다음 상태로 반환된 경우의 처리 (silent fill 금지):

| `tool_result` 상태 | 의미 | 처리 |
|--------------------|------|------|
| 정상 응답 (모든 question 에 answer 존재) | 사용자가 모든 항목 선택 완료 | 정상 진행. 표 "답변" 열 채움 |
| 일부 question 만 응답 (부분 응답) | 사용자가 일부만 선택 (UI 가 허용한 경우) | **빈 슬롯은 발화 추정 채움 금지** — 미응답 항목만 추려 새 AskUserQuestion 추가 호출. 표는 미응답 항목을 빈 셀로 두지 않고 새 응답 기다림 |
| 전체 dismiss / 빈 응답 (사용자가 ESC 또는 취소) | 사용자가 응답 거부 의사 | **silent fill 금지**. 다음 텍스트 안내 후 동일 호출 재시도: "Phase 0 인터뷰가 응답 없이 종료됐습니다. 이 인터뷰는 silent inference 차단의 핵심이므로 응답이 필요합니다. 작업을 일시 중단하시거나 모든 항목에 응답해주세요." 그 다음 동일 question 들로 AskUserQuestion 재발화. 사용자가 명시적으로 "작업 중단" 응답 시 작업 폴더에 partial state 만 저장하고 정상 종료 |
| `tool_result` 자체가 누락된 컨텍스트로 다음 액션 (모델 컨텍스트 파싱 버그 가능성) | 도구 호출 자체 실패 | 동일 호출 1회 재시도. 재시도 실패 시 사용자에게 "도구 호출 응답 누락 — Claude Code 세션 재시작 권장" 텍스트 안내 |

**금지 명시**: 모델이 thinking 안에서 "사용자가 ESC 눌렀으니 description 기반으로 추정 채워 진행" / "부분 응답이니 나머지는 사용자 발화에서 추출" 같은 사유로 빈 슬롯을 채우는 것은 silent inference 의 변형이며 금지. 위반 시 phase-setup 의 Step 0 검증에서 출처 토큰 누락으로 BLOCKING 자동 검출 (3중 게이트).

### Auto Mode 의 자체 회피와의 관계
사용자가 Auto Mode 활성화 상태로 본 슬래시 커맨드를 호출한 경우, Auto Mode 의 "Bias toward working without stopping for clarifying questions" 가 silent inference 를 유인할 수 있다. 그러나 Auto Mode 자체가 명시한 예외 조항 — *"If the user, a skill, or the shape of the task suggests they want you to ask, do so"* — 에 본 슬래시 커맨드의 task shape (Phase 0 압축 인터뷰 A1~A10 발화 요구) 이 정확히 해당. **Auto Mode 활성 상태에서도 A1~A10 명시 발화는 의무**.

### 위반 시 결과
- Phase 0 자기점검 표 (`commands/harness-setup.md` "Phase 0 완료 자기점검") 에서 출처가 "AskUserQuestion#N" 또는 "$ARGUMENTS prefill" 이 아닌 항목이 발견되면 phase 전환 중단하고 즉시 추가 AskUserQuestion 발화
- Phase 1-2 의 `phase-setup` 이 산출물 `01-discovery-answers.md` 의 "Pre-collected Answers" 표에서 출처 열이 "AskUserQuestion#N" 이 아닌 항목을 감지하면 `[BLOCKING]` Escalation (출처 검증 의무)

## 금지 패턴
- 텍스트로 질문 출력하고 응답 대기
- 질문 없이 기본값 가정하고 진행
- 여러 질문을 텍스트로 나열
- 사용자 자유 발화에서 추출한 값을 AskUserQuestion 응답으로 위장 (silent inference)

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
