# 개선 사항 5: 실사용 예시 및 온보딩 마찰 제거

---

## 문제 정의

현재 `harness-architect` 플러그인은 기술적으로 완성도가 높지만, 처음 접하는 사용자 입장에서는 다음 5가지 마찰이 존재한다.

1. **예시 부재**: `examples/` 디렉터리에 `web-app-setup.md`, `agent-project-setup.md`, `cli-arg-usage.md` 3개 파일이 있지만, 이는 "시나리오 예상 진행"(텍스트 시뮬레이션)이지 실제 9단계를 실행한 후 *생성된 산출물*이 아니다. 사용자는 "이 플러그인이 실제로 무엇을 만드는가"를 확인할 수 없다.

2. **복잡도 미리 보기 없음**: `examples/web-app-setup.md`에 "Fast Track 10-15분", `examples/agent-project-setup.md`에 "30-40분"이 적혀 있지만, 플러그인을 설치하고 `/harness-architect:harness-setup`을 실행하기 전에 이 정보를 접할 경로가 없다. `commands/help.md`의 `/harness-architect:help`도 9-Phase 목록만 제시하고 소요 시간을 명시하지 않는다.

3. **트랙 선택 UX 없음**: `ARCHITECTURE.md` 4.3항에 Fast Track(10분)·Fast-Forward(에이전트 프로젝트)·복잡도 게이트의 3가지 경로가 정의되어 있지만, 사용자가 Phase 0 진입 전에 이 선택지의 차이와 트레이드오프를 파악하고 능동적으로 선택할 방법이 없다.

4. **CLAUDE.md가 기여자용으로만 쓰여짐**: `CLAUDE.md` 첫 줄은 "이 파일은 기여자(Contributor)용 가이드입니다"라고 명시한다. 플러그인을 설치하고 사용하는 최종 사용자(end-user)를 위한 별도 퀵스타트 가이드가 없다. `commands/help.md`가 그 역할을 하지만 `README.md`에서의 진입 경로가 약하다.

5. **생성된 하네스의 사용법 안내 없음**: Phase 9 완료 후 오케스트레이터는 파일 목록을 제시하지만, "이제 어떻게 쓰나요?"—새 에이전트를 어떻게 호출하는지, SKILL.md를 어떻게 활용하는지, 생성된 훅이 언제 동작하는지—에 대한 안내가 없다.

---

## 도메인 전문가 제안 (DX Engineer 임채은)

### 배경 인식

DX(Developer Experience) 관점에서 온보딩 마찰은 크게 세 구간에서 발생한다:
- **Pre-flight**: 플러그인 설치 전 "이게 뭐지?" 단계
- **Takeoff**: 첫 실행 (~Phase 0) 단계
- **Landing**: Phase 9 완료 후 "이제 뭐 하지?" 단계

현재 `harness-architect`는 Takeoff 구간의 UX(Phase 0 AskUserQuestion 흐름, 진행 피드백)는 잘 설계되어 있으나, Pre-flight와 Landing이 거의 비어있다.

---

### 제안 1: 사용자가 처음 플러그인을 접했을 때 이해해야 할 핵심 정보 3가지

처음 접하는 사용자가 5분 안에 파악해야 할 것:

1. **무엇이 만들어지는가**: 플러그인이 최종적으로 대상 프로젝트에 생성하는 파일 구조. 현재 `commands/help.md`의 "📦 생성되는 대상 프로젝트 파일" 섹션이 있지만, 이것이 `README.md`에서 보이지 않는다.

   ```
   your-project/
   ├── CLAUDE.md            ← Claude의 프로젝트 이해 기반
   ├── .claude/
   │   ├── settings.json    ← 권한·환경변수·훅·MCP
   │   ├── rules/           ← 항상 적용되는 규칙
   │   ├── agents/          ← 에이전트 정의 (에이전트 프로젝트만)
   │   └── skills/          ← 재사용 가능한 슬래시 커맨드
   └── docs/{요청명}/       ← 설계 산출물 (참고용)
   ```

2. **어느 경로로 얼마나 걸리는가**: 프로젝트 유형별 예상 소요 시간 표. Phase 0 인터뷰 첫 질문 전에 이것을 볼 수 있어야 한다.

   | 프로젝트 유형 | 경로 | 예상 소요 |
   |---|---|---|
   | 솔로 웹앱/CLI | Fast Track | 10-15분 |
   | 팀 웹앱 | 표준 | 30-45분 |
   | 에이전트 파이프라인 | Fast-Forward | 30-40분 |

3. **완료 후 어떻게 쓰는가**: 생성된 하네스를 통해 Claude Code가 어떤 식으로 다르게 동작하는지 1-2문장 요약. 예: "생성된 SKILL.md는 `/my-skill-name`으로 호출할 수 있고, agents/*.md에 정의된 에이전트는 `Agent(subagent_type: ...)` 패턴으로 자동 소환됩니다."

---

### 제안 2: 실사용 예시 형식과 프로젝트 유형

**형식**: 시나리오 예상 진행(텍스트 시뮬레이션)보다 **실제 산출물 스냅샷**이 훨씬 강력하다. 사용자가 "아, 이런 CLAUDE.md가 만들어지는구나"를 직접 보는 것.

**구체적 구조안** (`examples/` 하위에 프로젝트 유형별 디렉터리):

```
examples/
├── web-app-setup.md          # 기존: 시나리오 시뮬레이션 (유지)
├── agent-project-setup.md    # 기존: 시나리오 시뮬레이션 (유지)
├── cli-arg-usage.md          # 기존: 커맨드 인자 사용법 (유지)
└── generated/
    ├── web-app-solo/         # React + Node 솔로 프로젝트 산출물 스냅샷
    │   ├── README.md         # 이 예시가 어떤 조건으로 생성되었는지 설명
    │   ├── CLAUDE.md
    │   ├── .claude/
    │   │   ├── settings.json
    │   │   └── rules/
    │   │       └── dev-conventions.md
    │   └── docs/example-setup/
    │       └── 01-discovery-answers.md   # 핵심 산출물만
    └── agent-pipeline/       # 멀티에이전트 리서치 파이프라인 스냅샷
        ├── README.md
        ├── CLAUDE.md
        ├── .claude/
        │   ├── settings.json
        │   ├── agents/
        │   │   ├── researcher.md
        │   │   └── writer.md
        │   └── skills/
        │       └── research/SKILL.md
        └── docs/example-setup/
            └── 04-agent-team.md
```

**커버할 프로젝트 유형 우선순위**:
1. **솔로 웹앱** (Fast Track): 가장 많은 사용자가 해당. 결과물이 단순해서 이해하기 쉬움.
2. **에이전트 파이프라인** (Fast-Forward): 플러그인의 고급 기능을 보여줄 수 있음.
3. 팀 웹앱은 3순위 (복잡도가 높아 오히려 진입 장벽이 될 수 있음).

**유지보수 전략**: 각 `generated/*/README.md`에 생성 조건(플러그인 버전, 입력 답변)을 명시. CHANGELOG에 "예시 업데이트 필요" 항목 추가. 예시는 의도적으로 단순하게 유지—복잡한 예시가 오히려 혼란을 줌.

---

### 제안 3: 복잡도를 Phase 0 이전에 전달하는 방법

**현재 흐름**: `/harness-architect:harness-setup` 실행 → Phase 0 AskUserQuestion(경로, 이름, 유형, 성능 수준) → Phase 1-2 시작

**제안**: Phase 0 AskUserQuestion의 **첫 번째 질문 전에** 예상 소요를 텍스트로 출력한다. AskUserQuestion 사용이 아니라 일반 텍스트 출력이므로 `question-discipline.md` 위반이 아니다.

```
[harness-architect] 시작합니다.

이 플러그인은 대상 프로젝트에 Claude Code 하네스를 구축합니다.
예상 소요: 솔로 웹앱 10-15분 / 팀 프로젝트 30-45분 / 에이전트 파이프라인 30-40분
지금 "빠르게" 또는 "--fast"를 답하면 Fast Track(10분)으로 진행됩니다.

도중에 중단해도 docs/{요청명}/에 진행 상황이 저장되어 나중에 재개할 수 있습니다.
```

이 텍스트를 `commands/harness-setup.md`의 Phase 0 시작 직전에 출력 지시로 추가한다.

**트랙 선택을 Phase 0 AskUserQuestion에 통합**: 현재 Phase 0 질문은 경로·이름·유형·성능 수준 4개인데, "진행 방식" 옵션을 1개 추가하는 것을 검토:

```
진행 방식:
  A. 표준 (권장) — 단계별 검토, 최적 결과
  B. 빠르게 — 추천값 자동 사용, 10분 완료
```

단, `question-discipline.md`의 "≤4개 질문" 규약이 있으므로, 기존 4개 중 하나를 Phase 1-2 Escalation으로 이동하거나, 경로를 `$ARGUMENTS`로 받아 질문 수를 줄인 후 추가하는 방식이 적합하다.

---

### 제안 4: 9단계 완료 후 사용법 안내

Phase 9 완료 시 오케스트레이터가 출력하는 완료 메시지에 "다음 단계" 섹션 추가:

```
✅ 하네스 구축 완료!

생성된 파일:
  CLAUDE.md, .claude/settings.json, .claude/rules/3개, ...

이제 대상 프로젝트 디렉터리에서 claude를 열면:
  - CLAUDE.md가 자동 로딩되어 프로젝트 컨텍스트가 주입됩니다
  - .claude/rules/*.md가 항상 적용됩니다
  - 생성된 스킬은 /skill-name으로 호출합니다 (예: /smart-fix)
  - 에이전트는 Agent(subagent_type: "agent-name") 패턴으로 소환됩니다

하네스 수정이 필요하면: /harness-architect:harness-setup {경로} (재실행)
```

이 안내문은 `commands/harness-setup.md`의 Phase 9 완료 후 처리 절차에 추가한다.

또한 `examples/generated/*/README.md`에 "이 하네스를 활용하는 방법" 섹션을 포함해, 예시를 보는 사용자도 사용 방법을 이해할 수 있게 한다.

---

### 제안 5: CONTRIBUTING.md와 사용자용 문서 분리

**현재**: `CLAUDE.md`는 명시적으로 기여자용. `README.md`는 사용자용이나 한국어 전용이고 영어(`README_EN.md`)와 내용 동기화가 불분명.

**제안 구조**:

| 파일 | 대상 | 내용 |
|------|------|------|
| `README.md` | 최종 사용자 | 설치법 + 30초 퀵스타트 + 생성 파일 목록 + 소요 시간 |
| `README_EN.md` | 영어권 최종 사용자 | README.md 영어 번역 |
| `CLAUDE.md` | 기여자 | 현재와 동일 |
| `CONTRIBUTING.md` | 기여자 | 현재와 동일 |
| `ARCHITECTURE.md` | 기여자 | 현재와 동일 |
| `examples/generated/*/README.md` | 최종 사용자 | 예시별 컨텍스트 + 사용법 |

`README.md` 최상단에 "→ 개발자(기여자)라면 CLAUDE.md를 참조하세요" 링크를 추가해 두 문서를 연결한다.

---

## 레드팀 비판 (Cognitive Load Analyst 신민서)

임채은의 제안을 인지 부하 분석 관점에서 검토한다.

### 비판 1: 예시 파일 증가 → 유지보수 부채와 구식 예시의 역효과

`examples/generated/` 구조를 도입하면 플러그인이 버전업될 때마다 예시 파일을 업데이트해야 한다. 현재 CHANGELOG를 보면 v0.1.0→v0.3.3까지 4일 만에 대규모 변경이 반복됐다. 이 속도로 개발이 진행되면 예시 파일은 항상 구식이 된다.

**구식 예시의 역효과**: 사용자가 예시의 `settings.json` 구조를 보고 자신의 프로젝트에서 직접 복사했다가, 실제 플러그인이 생성하는 구조와 달라 혼란을 겪는 경우. 예시가 없는 것보다 구식 예시가 더 나쁘다.

**대안 제시**: 정적 파일 예시 대신, `examples/generated/`를 스냅샷이 아닌 **생성 스크립트(generate-example.sh)**로 대체. 플러그인을 실제 실행해 산출물을 자동 생성하는 CI/CD 파이프라인을 구성하면 항상 최신 상태를 유지할 수 있다. 그러나 이는 테스트 인프라 투자가 필요하며, `CONTRIBUTING.md`의 "테스트" 섹션을 보면 현재 "스모크 테스트 시나리오"가 `examples/` 확장 항목으로 로드맵에만 있을 뿐 CI가 없다.

### 비판 2: "60분 걸린다"는 사전 고지 → 시작 전 이탈률 상승

임채은은 Phase 0 시작 전 소요 시간 텍스트 출력을 제안했다. 그러나 "팀 프로젝트 30-45분"이라는 숫자를 보는 순간 일부 사용자는 "나중에 해야지"라고 판단하고 이탈한다. 이는 **공지의 역설(announcement paradox)**—중요한 정보가 오히려 참여를 막는 현상—이다.

실제로 사용자가 "빠르게"를 선택하면 10분 만에 완료된다. 즉, 소요 시간은 사용자의 선택에 달려있다. 시간을 고정값으로 먼저 제시하는 것보다, **Phase 0 트랙 선택 직후 해당 트랙의 예상 소요를 보여주는 방식**이 인지 부하를 낮추면서 이탈도 방지한다.

### 비판 3: 실사용 예시의 민감도 문제

`examples/generated/` 산출물이 실제 플러그인 실행으로 만들어진다면, 해당 실행에 사용된 가상 프로젝트라도 내부 경로명, 가상 API 키, 가상 팀 구성이 포함될 수 있다. `CLAUDE.md`의 메타 누수 가드와 마찬가지로, 예시 파일이 "가상" 민감 정보를 담고 공개 레포지토리에 올라가는 것은 `output-quality.md`의 "Secret Detection" 원칙과 충돌할 수 있다.

실제 경로(`/Users/실제이름/...`)가 예시 파일에 하드코딩된 채로 커밋되는 것도 위험하다. 임채은의 제안은 이 문제에 대한 sanitization 전략이 없다.

### 비판 4: 온보딩 문서는 사용자가 읽지 않는다

현실: 대부분의 개발자는 문서를 읽지 않고 일단 실행한다. `/harness-architect:harness-setup`을 실행하면 Phase 0 AskUserQuestion이 나온다. 사용자는 그 질문에 답한다. 문서가 있어도 보지 않는다.

임채은의 제안 중 `README.md` 개선, `examples/generated/` 구조는 "문서를 읽는 사용자"를 가정한다. 실제 온보딩 개선 효과는 **문서 밖, 플로우 안**에서 발생한다.

### 비판 5: Phase 0 UX 자체 개선이 문서보다 ROI가 높다

현재 Phase 0는 경로·이름·유형·성능 수준을 1-2회 AskUserQuestion으로 수집한다. 사용자가 처음 보는 질문이 "성능 수준 — 경제형/균형형/고성능형"이라면 대부분은 "균형형"을 선택하지만, 이 선택의 의미(비용·속도 트레이드오프)를 이해하지 못한 채 넘어간다.

**문서로 사전 교육 vs. Phase 0 질문의 options.description 개선**: `AskUserQuestion`의 `options` 배열에 각 옵션의 `description`이 있다. 현재 "경제형 — Haiku 위주, 응답 빠르고 비용 낮음" 수준인데, 이것으로 충분하다. 별도 문서보다 질문 안에 컨텍스트를 담는 것이 실제 의사결정 품질을 높인다.

**가장 효과적인 온보딩은 "설명 없이도 작동하는 플로우"다.** Phase 0 UX를 개선해 사용자가 자연스럽게 올바른 선택을 하도록 유도하는 것이, 별도 문서 작성보다 유지보수 비용이 낮고 효과는 높다.

---

## 수렴: 임채은의 반론과 조정

신민서의 비판 중 타당한 것과 재반론이 필요한 것을 구분한다.

### 수용: 유지보수 부채 → 예시 범위 축소

신민서의 "구식 예시가 오히려 해롭다"는 지적을 수용한다. `examples/generated/`에 전체 하네스 파일 구조를 넣는 것은 유지보수 부채가 크다.

**조정**: 예시의 범위를 **핵심 파일 2개**(CLAUDE.md + settings.json 스켈레톤)로 제한하고, 나머지는 "Phase가 생성한 실제 파일은 이런 구조입니다"라는 **주석 처리된 템플릿** 형태로 제공. 완성된 산출물이 아닌 "참조 구조"이므로 버전 변화에 덜 민감하다.

또한 각 예시 파일 최상단에 `generated-with: v{버전}` 메타데이터를 추가해 "이 예시는 v0.3.3 기준"임을 명시. 구식 예시가 아니라 "해당 버전의 정확한 예시"임을 선언.

### 수용: 소요 시간 고지 방식 → Phase 0 트랙 선택 후 표시

"시작 전 이탈"을 막으려면 소요 시간을 트랙 선택 **이후**에 표시하는 것이 낫다는 신민서 지적을 수용한다.

**조정**: Phase 0 진입 시 텍스트 출력을 아래로 변경:

```
[harness-architect] 시작합니다.
프로젝트 유형을 알려주시면 최적 경로를 안내합니다.
중단 시 docs/{요청명}/에 저장되어 나중에 재개 가능합니다.
```

소요 시간 예시는 트랙이 결정된 후(Phase 0 AskUserQuestion 완료 직후) 표시:

```
Fast Track 선택됨. 예상 소요: 10-15분.
Phase 1/9 시작합니다...
```

### 수용: 민감도 문제 → sanitization 규약 추가

`examples/generated/*/`에 경로·팀 이름·키 관련 값을 넣지 않는 규약을 명시. `CONTRIBUTING.md`의 "테스트" 섹션에 예시 파일 커밋 전 체크리스트 추가:

- `$HOME`, `~`, `/Users/` 등 실제 경로 없음
- `sk-`, `ghp_` 등 키 패턴 없음
- 팀원 이름/이메일 없음

### 부분 수용: Phase 0 UX 개선 우선

신민서의 "플로우 개선이 문서보다 ROI 높다"는 지적에 동의하되, 둘은 병렬 추진 가능하다. 신민서가 제안한 "options.description 개선"은 구현 비용이 낮다. Phase 0 AskUserQuestion의 성능 수준 옵션 description을 더 실용적으로 개선하는 것을 구현 방법론에 포함시킨다.

### 유지: README.md 개선

신민서의 "사용자는 문서를 읽지 않는다"는 지적에도 불구하고, `README.md`의 개선은 GitHub/마켓플레이스 첫 인상에 영향을 준다. 설치 여부 결정 단계에서 문서는 읽힌다. 단, 내용을 최소화(30초 퀵스타트 + 생성 파일 목록 + 소요 시간 한 줄)하여 유지보수 부담을 낮춘다.

---

## 최종 합의된 개선 방향성

두 사람이 합의한 원칙:

1. **플로우 내 컨텍스트 우선**: 별도 문서보다 Phase 0 AskUserQuestion의 description·hint 개선이 실제 사용자 경험에 더 직접적으로 영향을 미친다.

2. **예시는 최소·버전 명시**: 전체 산출물 스냅샷 대신 핵심 파일 2개(CLAUDE.md 패턴 + settings.json 스켈레톤)로 제한. 버전 메타데이터로 구식 혼란 방지.

3. **소요 시간은 트랙 선택 후 표시**: Phase 0 진입 전 "30-45분" 고지는 이탈을 유발. 트랙이 결정된 직후 해당 트랙의 예상 소요를 표시.

4. **Phase 9 완료 후 사용법 안내는 필수**: Landing 구간이 현재 완전히 비어있다. 구현 비용 낮고 효과 높음.

5. **README.md는 최소화**: 30초 퀵스타트에 집중. 상세 문서 링크로 연결.

---

## 구현 방법론 (단계별 + 구체적 파일 변경 포함)

### Step 1: Phase 0 진입 텍스트 개선 (`commands/harness-setup.md`)

**변경 위치**: `commands/harness-setup.md`의 `## 시작` 섹션, Phase 0 AskUserQuestion 호출 직전.

**추가할 내용**:
```
시작 전 안내 (텍스트 출력 — AskUserQuestion 아님):
"[harness-architect] 대상 프로젝트의 Claude Code 하네스를 구축합니다.
 중단 시 docs/{요청명}/에 저장되어 나중에 재개 가능합니다."
```

소요 시간은 Phase 0 AskUserQuestion 완료 직후 오케스트레이터가 텍스트로 출력:
```
if fast-track 선택 또는 "빠르게":
  "Fast Track으로 진행합니다. 예상 소요: 10-15분."
elif 에이전트 프로젝트:
  "에이전트 파이프라인 경로로 진행합니다. 예상 소요: 30-40분."
else:
  "표준 경로로 진행합니다. 예상 소요: 20-45분 (프로젝트 복잡도에 따라)."
```

### Step 2: Phase 0 AskUserQuestion options.description 강화

**변경 위치**: `commands/harness-setup.md`의 Phase 0 AskUserQuestion 성능 수준 옵션.

**현재**:
```
- 경제형 — Haiku 위주, 응답 빠르고 비용 낮음
- 균형형 (권장) — Sonnet 중심, 복잡 설계만 Opus
- 고성능형 — Opus 중심, 비용 높고 응답 다소 느림
```

**개선안**:
```
- 경제형 — Haiku 위주. 빠르고 저렴 (Opus 대비 ~1/15 비용). 단순 프로젝트 적합.
- 균형형 (권장) — Sonnet 중심, 복잡 설계 판단만 Opus 사용. 대부분 프로젝트에 최적.
- 고성능형 — Opus 중심. 균형형 대비 ~5배 비용, 복잡한 에이전트 설계에 적합.
```

### Step 3: Phase 9 완료 후 안내 텍스트 추가 (`commands/harness-setup.md`)

**변경 위치**: `commands/harness-setup.md`의 Phase 9 완료 처리 절차 마지막.

**추가할 내용**:
```markdown
## Phase 9 완료 후 오케스트레이터 출력 (텍스트)

✅ 하네스 구축 완료! ({요청명})

생성된 파일: [Files Generated 목록]

**이제 어떻게 사용하나요?**
1. 대상 프로젝트 디렉터리에서 `claude` 실행 → CLAUDE.md와 rules가 자동 로딩됩니다.
2. 생성된 스킬은 `/{skill-name}`으로 호출합니다.
3. 에이전트가 생성된 경우 `Agent(subagent_type: "{agent-name}")` 패턴으로 소환합니다.
4. 훅은 파일 저장(Write/Edit) 또는 세션 종료 시 자동 실행됩니다.

하네스 수정/추가가 필요하면: `/harness-architect:harness-setup {대상경로}` 재실행
문제 발생 시: `/harness-architect:help` 참조
```

### Step 4: 예시 파일 추가 (`examples/generated/`)

두 개 예시 디렉터리 생성. 각각 핵심 파일 2개 + README.

**`examples/generated/web-app-solo/`**:
- `README.md`: 생성 조건(플러그인 버전·입력 답변·Fast Track 선택)
- `CLAUDE.md`: 실제 생성 패턴을 보여주는 참조 파일 (실제 경로·팀명 없음)
- `settings.json`: 기본 permissions·deny 구조 참조

**`examples/generated/agent-pipeline/`**:
- `README.md`: 생성 조건(에이전트 파이프라인·Fast-Forward 경로)
- `CLAUDE.md`: 에이전트 참조가 포함된 패턴
- `settings.json`: WebSearch·WebFetch 허용 패턴 포함
- `.claude/agents/researcher.md`: 에이전트 정의 참조 패턴

각 파일 최상단:
```yaml
<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->
```

**sanitization 규약** (`CONTRIBUTING.md` "테스트" 섹션에 추가):
- 실제 경로(`/Users/`, `~`) 없음: 가상 경로 `/your-project/` 사용
- API 키 패턴 없음: `your-api-key-here` placeholder 사용
- 팀원 이름/이메일 없음

### Step 5: README.md 30초 퀵스타트 강화

**변경 위치**: `README.md` 상단부.

현재 README.md 구조를 확인해 "빠른 시작" 섹션에 다음을 추가·강화:
1. 생성 파일 목록 (4-5줄 트리)
2. 소요 시간 표 (3행)
3. "기여자라면 → CLAUDE.md" 링크

### Step 6: CONTRIBUTING.md 예시 유지보수 규약 추가

`CONTRIBUTING.md`의 "Phase / 규칙 변경 체크리스트" 섹션에 항목 추가:

```markdown
### 예시 파일 업데이트 체크리스트 (examples/generated/ 변경 시)
- [ ] 상단 `generated-with: v{버전}` 업데이트
- [ ] 실제 경로·API키·이름 없음 확인
- [ ] CHANGELOG에 예시 변경 기록
```

---

## 예상 효과 및 성공 지표

| 개선 항목 | 예상 효과 | 성공 지표 |
|-----------|-----------|-----------|
| Phase 0 진입 텍스트 | "이게 뭘 하는 거지?" 혼란 감소 | Phase 0 완료율 향상 |
| 소요 시간 → 트랙 선택 후 표시 | 시작 전 이탈 감소 | 첫 실행 완료율 향상 |
| options.description 강화 | 성능 수준 선택의 이해도 향상 | "균형형" 선택 후 불만족 감소 |
| Phase 9 완료 안내 | "이제 뭐 하지?" 혼란 해소 | 생성 후 첫 사용 시간 단축 |
| examples/generated/ (핵심 2파일) | "실제로 뭐 만들어지나?" 의문 해소 | GitHub star, 이슈 "예시 없음" 감소 |
| README.md 30초 퀵스타트 | 설치 전 결정에 필요한 정보 제공 | 설치 후 첫 실행율 향상 |

---

## 잔여 리스크 및 완화 방안

| 리스크 | 가능성 | 완화 방안 |
|--------|--------|-----------|
| examples/generated/ 파일이 버전 업그레이드 후 구식 상태로 방치 | 높음 | `CONTRIBUTING.md` 체크리스트 + CHANGELOG "예시 업데이트 필요" 항목 |
| Phase 0 텍스트 출력이 `commands/harness-setup.md` 실행 흐름과 충돌 (오케스트레이터가 무시) | 중간 | 텍스트 출력은 AskUserQuestion 전 명시적 지시로 작성. 실행 테스트 필수 |
| sanitized 예시가 실제와 너무 달라 "이게 실제 결과가 맞나?" 의심 유발 | 중간 | 각 예시 README에 "이 파일은 공개용으로 단순화된 참조 예시입니다" 명시 |
| options.description 변경이 Phase 0 AskUserQuestion 글자수 제한(header 12자) 위반 | 낮음 | header 12자 제한은 header 필드만 해당. description 필드는 제한 없음 |
| Phase 9 완료 안내 텍스트가 에이전트 프로젝트/비에이전트 프로젝트에 따라 내용이 달라야 하는데 일원화하면 오류 안내 | 중간 | 에이전트 파일이 생성된 경우에만 "Agent 소환 패턴" 라인 포함하도록 조건부 출력 |
