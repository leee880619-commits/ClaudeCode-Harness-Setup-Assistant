# 개선 사항 3: 재개 프로토콜 신뢰성 강화

## 문제 정의

현재 `orchestrator-protocol.md` "중단/재개 프로토콜" 섹션의 상태 판별 메커니즘은 세 가지 레이어로 구성된다:

1. **YAML frontmatter** — 에이전트가 산출물 파일 최상단에 `phase`, `completed`, `status`, `advisor_status` 필드를 기록
2. **mtime 비교** — `completed` 필드와 실제 파일 수정 시간을 비교해 사용자 편집 감지
3. **레거시 호환** — frontmatter가 없는 구형 파일은 파일 존재 = Phase 완료로 취급

이 구조에는 다음 취약점이 있다:

| # | 취약점 | 현재 프로토콜 위치 | 위험 수준 |
|---|--------|-------------------|----------|
| V1 | 에이전트가 frontmatter를 빠뜨리거나 `status: in_progress` 로 종료하면 상태 불명 | "상태 판별" Step 1 | 높음 |
| V2 | WSL2/Windows 환경에서 mtime이 부정확하거나 타임존이 어긋남 | "상태 판별" Step 2 | 중간 |
| V3 | 레거시 호환 로직이 부분 실패 파일을 "완료"로 마스킹 | "상태 판별" Step 1 | 높음 |
| V4 | 복수 `docs/{요청명}/` 폴더에서 사용자가 잘못된 폴더 선택 시 상태 혼란 | "세션 시작 시 감지" Step 2 | 중간 |
| V5 | 비표준 파일명 정규식 탐지의 불완전성 | "비표준 파일명 처리" 섹션 | 낮음 |

---

## 도메인 전문가 제안 (State Machine Architect 오태양)

### 핵심 관점

재개 프로토콜은 본질적으로 **분산 상태 기계 복구(distributed state machine recovery)** 문제다. 개별 파일의 frontmatter에 전적으로 의존하는 것은 "각 노드가 자기 상태를 스스로 선언하는" 설계이고, 이는 클래스텀 장애(Byzantine failure)에 취약하다. 신뢰할 수 있는 재개를 위해서는 **상태 저장 레이어를 분리**해야 한다.

### 제안 1: `.state.json` 인덱스 도입 (보조 진실 원천)

`docs/{요청명}/` 아래에 `.state.json` 을 두어 오케스트레이터가 직접 관리한다.

```json
{
  "request_name": "myapp-setup",
  "target_path": "/absolute/path/to/target",
  "started_at": "2026-04-18T10:00:00Z",
  "phases": {
    "1-2": {
      "artifact": "01-discovery-answers.md",
      "artifact_sha256": "a3f2c...",
      "completed_at": "2026-04-18T10:15:00Z",
      "advisor_status": "pass",
      "status": "done"
    },
    "3": {
      "artifact": "02-workflow-design.md",
      "artifact_sha256": "b7d9e...",
      "completed_at": "2026-04-18T10:45:00Z",
      "advisor_status": "pass",
      "status": "done"
    }
  },
  "current_phase": "4",
  "unresolved_escalations": []
}
```

**핵심 설계 결정**:
- `.state.json` 은 오케스트레이터(메인 세션)만 기록. 서브에이전트는 읽기만 허용.
- `artifact_sha256`: 에이전트 반환 직후 오케스트레이터가 `Bash(sha256sum {file})` 로 계산하여 기록. mtime에 의존하지 않음.
- 재개 시 현재 sha256 != 저장된 sha256 이면 "파일이 수정됨" 판정. mtime보다 환경 독립적.

### 제안 2: "Phase 완료"의 다층 검증 (Defense in Depth)

"에이전트가 frontmatter를 썼다"는 필요조건이지 충분조건이 아니다. 오케스트레이터가 에이전트 반환 직후 다음을 순서대로 검증한다:

```
Step A: 파일 존재 확인 (Bash ls)
Step B: 필수 섹션 헤더 5개 정규식 확인 (orchestrator-protocol.md "파일 존재 + 섹션 스키마 검증" 기존 규정)
Step C: frontmatter status == "done" 확인
Step D: .state.json 에 sha256 + completed_at 기록
```

A~D 중 하나라도 실패하면 해당 Phase는 "미완"으로 처리한다. Step D는 오케스트레이터가 직접 수행하므로 에이전트 실수에 영향받지 않는다.

### 제안 3: 레거시 호환 제거 대신 "명시적 레거시 태그"

기존 호환 로직(`frontmatter 없으면 파일 존재 = 완료`)은 부분 실패 파일을 완료로 마스킹할 위험이 있다. 단순 제거 대신:

- frontmatter가 없는 기존 파일에 대해 `.state.json` 의 해당 Phase를 `status: "legacy_assumed_done"` 으로 기록
- 재개 시 이 Phase를 "완료로 간주하되 Advisor 재실행 권장" 상태로 표시
- 사용자에게 "레거시 파일 발견. 섹션 검증만 수행함. 신뢰도: 중간" 으로 고지

이렇게 하면 구형 파일을 깨뜨리지 않으면서도 불확실성을 명시한다.

### 제안 4: 복수 작업 폴더 UX 개선

현재 프로토콜: "2개 이상이면 AskUserQuestion으로 선택지 제시"

개선안:
- 각 폴더의 `.state.json` 에서 `request_name`, `current_phase`, `started_at`, `target_path` 를 읽어 선택지에 풍부한 정보 제공
- 예시 선택지 레이블: `"myapp-setup (2026-04-17 Phase 3까지 완료, 미해결 Escalation 2건)"`
- 선택한 폴더의 `target_path` 와 현재 사용자가 제공한 경로가 다르면 경고: "이 작업은 다른 경로({이전 경로})에서 시작됨"

### 제안 5: 실패한 Phase vs 부분 성공한 Phase 구분

현재 status 값: `done | in_progress | manual_override`

`in_progress` 는 "에이전트가 실행 중에 중단된 것"과 "에이전트가 파일을 시작했으나 완성하지 못한 것"을 구분하지 못한다. 추가 상태값 제안:

| status | 의미 | 재개 시 동작 |
|--------|------|------------|
| `done` | 완료, 검증 통과 | 스킵 |
| `partial` | 파일 있으나 필수 섹션 일부 누락 | 해당 Phase 에이전트 재소환 |
| `in_progress` | 에이전트 실행 중 세션 중단 | 해당 Phase 에이전트 재소환 |
| `manual_override` | BLOCK 루프 소진, 사용자 수동 처리 | Advisor 재실행 권장으로 스킵 |
| `legacy_assumed_done` | frontmatter 없는 구형 파일 | 섹션 검증만, Advisor 재실행 권장 |

`partial` 판정은 섹션 스키마 검증(Step B)에서 5개 헤더 중 일부만 있을 때 자동으로 부여한다.

---

## 레드팀 비판 (Failure Mode Analyst 정하은)

### 비판 1: `.state.json` 이 신규 단일장애점이 된다

`.state.json` 이 손상되거나 비어 있으면 기존보다 **더 심각한 상태**가 된다. 현재는 frontmatter가 없어도 파일 존재로 fallback이 되지만, `.state.json` 에 의존하는 구조에서 이 파일이 없으면 모든 재개 로직이 실패한다.

구체적 장애 시나리오:
- 사용자가 `docs/{요청명}/` 폴더를 다른 머신에 복사했는데 `.state.json` 만 빠진 경우
- 에디터/IDE 의 자동 포매터가 `.state.json` 을 건드려 JSON 파싱 실패
- 오케스트레이터가 `.state.json` 기록 직전 세션이 끊기면 이 파일이 아예 없음

결론: **`.state.json` 도 신뢰하지 못하는 상황이 오면 frontmatter + .state.json 두 레이어 모두 불신해야 한다.** 상태 저장 복잡도만 두 배가 된다.

### 비판 2: 오케스트레이터 코드 복잡도의 급격한 증가

오태양의 제안대로 하면 `orchestrator-protocol.md` 의 "상태 판별" 섹션이 현재 4 Step에서 **12+ Step** 으로 증가한다. LLM이 실행하는 "코드"이므로 복잡도 증가는 지시를 놓치거나 잘못 해석하는 확률의 증가와 직결된다.

특히 `.state.json` 관리 규칙(언제 쓰는가, 누가 쓰는가, 파싱 실패 시 fallback은 무엇인가)을 명세에 추가하면, 오케스트레이터가 이를 지키지 않는 "조용한 이탈" 이 더 자주 발생할 수 있다.

### 비판 3: mtime 포기 시 사용자 수동 편집 감지 대안의 실효성

sha256 비교로 mtime을 대체하면 WSL2 타임존 문제는 해결된다. 그런데 sha256 계산을 "에이전트 반환 직후 오케스트레이터가 수행"한다면, **오케스트레이터가 세션 중 중단된 경우** sha256 기록이 빠진다. 이 경우 `.state.json` 에는 해당 Phase의 `artifact_sha256` 이 없고, 파일은 있다. 이 상태를 어떻게 처리하는가?

"sha256 없으면 mtime으로 fallback" 이라고 하면 결국 mtime 의존성이 남는다. "sha256 없으면 partial 로 처리"하면 오히려 더 보수적이 되어 사용자에게 불필요한 재실행을 강제한다.

### 비판 4: LLM 기반 상태 추적의 근본적 한계

더 근본적인 질문: **LLM 오케스트레이터가 상태를 "신뢰할 수 있게" 추적할 수 있는가?**

오케스트레이터는 매 세션마다 컨텍스트를 재구성한다. 오케스트레이터가 Phase 4를 완료 후 `.state.json` 을 기록했다는 사실 자체가 다음 세션의 오케스트레이터에게 **파일 읽기로만** 전달된다. 즉, `.state.json` 을 더 복잡하게 만들어도 "오케스트레이터가 이 파일을 정확히 읽고 해석한다"는 새로운 가정이 필요하다. 이 가정도 LLM 실행에서는 완벽하지 않다.

결국 신뢰성 문제를 완전히 제거하는 것은 불가능하고, **신뢰성 향상 vs 복잡도 증가의 트레이드오프** 에서 어느 수준에서 멈출 것인지를 결정하는 것이 핵심이다.

### 비판 5: 재개 복잡도 투자의 ROI 문제

실제 사용 패턴을 고려하면: 9-Phase 오케스트레이션이 완전히 완료되는 데 수십 분에서 수 시간이 걸린다. 그러나 **세션 중단이 발생하는 경우는 얼마나 자주인가?** 오케스트레이터 세션이 중간에 끊기는 빈도, 그 중 재개를 시도하는 비율, 그 중 현재 프로토콜로 실패하는 비율 — 이 데이터 없이 재개 복잡도에 대규모 투자를 하는 것은 과도할 수 있다.

오히려 많은 사용자는 중단 후 **"새로 시작하는" 경험이 더 간단하다고 느낄 수 있다**. 재개 프로토콜 강화가 실제 사용자 문제를 해결하는지, 아니면 공학적 완벽주의를 충족하는지 검증이 필요하다.

---

## 수렴: 오태양의 반론과 조정

### 반론 1에 대한 반론: `.state.json` 은 보조(supplement), 대체(replace)가 아니다

정하은의 비판이 정확하다. `.state.json` 을 **단일 진실 원천**으로 만들면 안 된다. 설계를 수정한다:

- `.state.json` 은 **오케스트레이터의 메모장**이지 권위 있는 상태가 아니다
- 재개 시 판별 우선순위: `① 파일 존재 + 섹션 검증 (불변) → ② frontmatter (에이전트 자가 선언) → ③ .state.json (오케스트레이터 메모)`
- `.state.json` 이 없거나 파싱 실패해도 기존 frontmatter 기반 판별로 graceful fallback
- sha256 은 "변경 감지 보조 힌트"로만 사용. 없으면 "변경 여부 불명"으로 처리하되 재실행 강제 안 함

### 반론 2에 대한 반론: 복잡도를 "단계적 채택"으로 완화

오케스트레이터 프로토콜을 한 번에 복잡하게 만들지 않는다. **3단계 점진 도입**:

- Phase 1 (즉시): `partial` 상태값 추가 + 섹션 검증 강화 → orchestrator-protocol.md 수정량 최소
- Phase 2 (선택적): `.state.json` 보조 메모장 → orchestrator가 여건이 되면 기록
- Phase 3 (장기): sha256 기반 변경 감지 → 환경 검증 후 도입

### 반론 4에 대한 반론: "완전한 신뢰성" 대신 "실패를 명시적으로"

LLM 기반 상태 추적의 근본 한계는 인정한다. 그러나 목표를 수정한다: **상태를 완벽히 추적하는 것이 아니라, 불확실한 상태를 사용자에게 명시적으로 노출하는 것**.

현재 레거시 호환 로직의 문제는 "불확실한 상태를 확실한 것처럼 처리"한다는 점이다. `legacy_assumed_done` 태그처럼 **불확실성을 명시**하는 것만으로도 사용자가 더 나은 결정을 내릴 수 있다.

### 반론 5에 대한 반론: ROI는 "에러 발생 시 비용"으로 계산

재개 실패의 실제 비용: 9-Phase 중 Phase 7까지 완료 후 중단된 경우, 재개 실패로 처음부터 다시 시작하면 1~2시간 재작업이다. 이 비용을 고려하면 재개 신뢰성 향상의 ROI는 낮지 않다. 다만 **복잡한 재개 vs 간단한 재시작** 선택지를 사용자에게 명확히 제시하는 UX 개선이 우선이다.

---

## 최종 합의된 개선 방향성

두 전문가가 합의한 핵심 원칙:

> **"신뢰할 수 없는 상태를 신뢰할 수 있는 것처럼 다루지 말고, 불확실성을 명시적으로 관리하라."**

이를 위한 4가지 방향:

1. **불확실성 명시화** — `legacy_assumed_done`, `partial` 상태값으로 모호한 상태를 드러냄
2. **단일장애점 회피** — `.state.json` 은 보조 메모장, frontmatter는 에이전트 선언, 섹션 검증은 불변 기준 — 세 레이어가 **독립적으로 기여**
3. **점진적 도입** — orchestrator-protocol.md 최소 수정부터 시작, 복잡도는 검증 후 추가
4. **UX 우선** — 복잡한 상태 복구보다 "지금 상태가 어떤지 사용자가 이해하기 쉽게"

---

## 구현 방법론 (단계별 + 구체적 파일 변경)

### Phase 1: 즉시 적용 (orchestrator-protocol.md 최소 수정)

**변경 파일**: `.claude/rules/orchestrator-protocol.md`

**변경 위치**: "Phase 완료 시 저장" 섹션 — frontmatter `status` 필드 정의 확장

현재:
```yaml
status: done | in_progress | manual_override
```

변경 후:
```yaml
status: done | partial | in_progress | manual_override | legacy_assumed_done
```

각 값 정의 추가:
- `partial`: 파일 존재하나 필수 섹션 헤더(5개) 중 1개 이상 누락. 에이전트가 기록하지 않고, 오케스트레이터가 섹션 검증 실패 시 부여.
- `legacy_assumed_done`: frontmatter 없는 구형 파일. 파일 존재 + 섹션 검증 통과 시 부여. 사용자에게 "신뢰도: 중간" 고지.

**변경 위치**: "상태 판별" Step 1 — frontmatter 파싱 후 섹션 검증 연계

기존 Step 1 (frontmatter 파싱) 에 다음을 추가:
```
frontmatter 없는 파일:
  → 섹션 검증 5개 헤더 확인
  → 통과: status = "legacy_assumed_done" (오케스트레이터가 .state.json 에 기록)
  → 실패: status = "partial" (해당 Phase 에이전트 재소환 권장)

frontmatter 있고 status == "done":
  → 섹션 검증 통과 필수
  → 실패: status를 "partial"로 재분류 (파일 기록은 오케스트레이터가 Edit)
```

**변경 위치**: "세션 시작 시 감지" Step 4 — AskUserQuestion 선택지 개선

현재: "계속 / 새로 시작?"
변경 후: "계속 (Phase {N}부터) / 새로 시작 / 현재 상태 상세 확인"

`partial` 또는 `legacy_assumed_done` Phase가 있으면 경고 추가:
"⚠ Phase {N} 상태가 불명확합니다 (partial/legacy). 해당 Phase부터 재실행이 권장됩니다."

### Phase 2: 선택적 적용 (`.state.json` 보조 메모장)

**변경 파일**: `.claude/rules/orchestrator-protocol.md`

**변경 위치**: "작업 폴더 관례" 섹션 — `.state.json` 추가

```
docs/myapp-setup/
  .state.json               ← (신규) 오케스트레이터 보조 메모장 (보조, 권위 없음)
  00-target-path.md
  ...
```

**`.state.json` 규약 추가**:
- 기록 주체: 오케스트레이터(메인 세션)만. 서브에이전트 기록 금지.
- 기록 시점: 각 Phase 에이전트 반환 직후, 섹션 검증 통과 후.
- 파싱 실패 시: 무시하고 frontmatter 기반 판별로 fallback. 오류 고지 불필요.
- 복수 폴더 선택 UX: `.state.json` 의 `current_phase`, `started_at` 를 읽어 선택지 레이블 보강.

**변경 위치**: "복수 작업 폴더" 처리 — 선택지 레이블 풍부화

현재: 폴더 이름만 표시
변경 후: `.state.json` 존재 시 `"myapp-setup (2026-04-17, Phase 3까지 완료)"`, 없으면 `"myapp-setup (상태 불명, 파일 {N}개)"` 표시

### Phase 3: 장기 검토 (sha256 기반 변경 감지)

**조건**: WSL2/Windows 환경에서 mtime 부정확 사례가 실제로 보고된 경우에만 도입.

**변경 파일**: `.claude/rules/orchestrator-protocol.md`

**변경 위치**: "상태 판별" Step 2 (mtime 비교)

```
mtime 비교 대신 sha256 비교 (환경 가용 시):
  오케스트레이터가 Phase 완료 시 sha256을 .state.json 에 기록
  재개 시 현재 sha256 != 저장값 → "파일 변경됨" 판정
  .state.json 없거나 sha256 미기록 → "변경 여부 불명" (mtime 비교 fallback)
  mtime도 불가 → 사용자에게 "파일 변경 여부를 확인할 수 없음" 고지
```

---

## 예상 효과 및 성공 지표

| 지표 | 현재 | Phase 1 후 | Phase 2 후 |
|------|------|-----------|-----------|
| 부분 실패 파일의 "완료" 오판율 | 높음 (레거시 호환 로직) | 낮음 (partial 감지) | 낮음 |
| 사용자가 재개 상태를 이해하는 정확도 | 중간 | 높음 (상태 레이블 명시) | 높음 |
| orchestrator-protocol.md 복잡도 증가 | 기준 | +15% (status 값 + 섹션 연계) | +25% (.state.json 규약) |
| 복수 폴더 선택 UX 품질 | 낮음 (이름만) | 낮음 | 높음 (메타 정보 포함) |
| WSL2 mtime 오판 가능성 | 중간 | 중간 | 낮음 (Phase 3) |

**성공 지표**:
- Phase 5 이상 완료 후 중단 시 재개 성공률 > 90%
- 재개 시 오케스트레이터가 잘못된 Phase부터 시작하는 경우 0건
- `legacy_assumed_done` 또는 `partial` Phase에 대해 사용자가 명시적 선택을 받는 경우 100%

---

## 잔여 리스크 및 완화 방안

| 리스크 | 발생 조건 | 완화 방안 |
|--------|----------|----------|
| **`.state.json` + frontmatter 모두 불신** | 두 레이어 모두 손상 또는 누락 | 섹션 검증(불변 기준)으로 최소 판별. 불명 Phase는 "재실행 권장"으로 표시 |
| **오케스트레이터가 status 재분류를 빠뜨림** | 섹션 검증 실패 후 Edit 호출 누락 | "상태 판별" Step 체크리스트를 orchestrator-protocol.md에 numbered list로 명시. 순서 이탈 시 다음 Step 진입 불가 설계. |
| **사용자가 레거시 파일을 "완료"로 강제 선언** | "계속" 선택 후 legacy Phase 재실행 거부 | `legacy_assumed_done` Phase는 Advisor 재실행을 "권장"으로 제안하되 사용자가 스킵 가능. 스킵 선택 시 `## Escalations` 에 `[SKIPPED] legacy Phase {N} Advisor 재실행 스킵` 기록. |
| **Phase 1 변경이 기존 배포된 플러그인과 비호환** | `partial`, `legacy_assumed_done` 값이 구버전에서 `unknown` 처리 | 구버전 오케스트레이터는 `unknown status` → `in_progress` 로 fallback하도록 "알 수 없는 status는 재실행 필요로 처리" 규칙 추가. 역호환 유지. |
| **`.state.json` 을 서브에이전트가 잘못 기록** | 에이전트가 프롬프트를 오해 | 오케스트레이터 소환 프롬프트에 "`.state.json` 수정 금지" 명시. `ownership-guard.sh` 에서 서브에이전트의 `.state.json` Write 차단 검토. |
