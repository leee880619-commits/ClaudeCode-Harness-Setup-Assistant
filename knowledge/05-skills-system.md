<!-- File: 05-skills-system.md | Source: architecture-report Section 6 -->
## SECTION 6: Skills 시스템 완전 명세

### 6.1 스킬 디렉터리 구조

스킬(Skill)은 Claude Code에게 특정 역할과 워크플로우를 부여하는 모듈이다. 각 스킬은 독립적인 디렉터리에 정의되며, 사용자가 슬래시 명령(`/skill-name`)으로 호출하거나 Claude가 작업 맥락에 따라 자동으로 활성화한다.

```
.claude/skills/
└── skill-name/
    ├── SKILL.md              ← 스킬 정의 본체 (필수)
    └── references/           ← 보조 문서 (선택)
        ├── guide.md          ← 상세 가이드
        ├── patterns.md       ← 코드 패턴 예시
        ├── checklist.md      ← 검증 체크리스트
        └── templates/        ← 출력 템플릿
            └── report.md
```

**디렉터리 명명 규칙:**

- 소문자, 대시(`-`) 구분: `co-optris-tech-lead`, `bright-data-serp-analyzer`
- 프로젝트 접두사 권장: 동일 프로젝트의 스킬은 접두사를 통일하여 그룹화
- 디렉터리명이 곧 스킬 식별자: `/co-optris-tech-lead`로 호출

**references/ 디렉터리:**

`SKILL.md` 본체의 컨텍스트 윈도우 부담을 줄이면서도 깊은 참조 자료를 제공하기 위한 구조이다. SKILL.md에서 `@references/guide.md`로 임포트하거나, Claude가 필요할 때 Read 도구로 온디맨드 로딩한다. bright-data-test 프로젝트에서는 40페이지 이상의 복잡한 스킬에서 이 패턴이 활용되었다.

### 6.2 SKILL.md 포맷

**YAML Frontmatter (메타데이터):**

```yaml
---
name: co-optris-tech-lead
description: Co-optris 아키텍처 결정, 상태 경계 설계, 의존성 규율 강제
model: opus                    # 선택. opus|sonnet|haiku. 복잡한 설계 → opus, 반복 작업 → haiku
role: tech-lead                # 선택. 멀티 에이전트에서 역할 식별
requires:                      # 선택. 스킬 실행 전 필요한 파일
  - docs/architecture/code-map.md
  - docs/game-design/master_plan.md
allowed_dirs:                  # 선택. 쓰기 가능 범위 제한
  - docs/architecture/
  - docs/operations/
  - shared/
user-invocable: true           # 선택. false면 다른 스킬에서만 호출 가능 (내부 유틸리티)
---
```

각 frontmatter 필드의 상세 설명:

| 필드 | 필수 | 설명 | 실전 가이드 |
|---|---|---|---|
| `name` | 필수 | 스킬 식별자. 디렉터리명과 일치 권장 | `co-optris-tech-lead` |
| `description` | 필수 | 한 줄 목적. 트리거 매칭에 사용됨 | 구체적으로. "아키텍처" → "Co-optris 상태 경계 설계 및 의존성 규율" |
| `model` | 선택 | 권장 모델. 설계/분석 → opus, 구현 → sonnet, 검증 → haiku | 비용 최적화에 핵심 |
| `role` | 선택 | 멀티 에이전트 시나리오에서 역할 구분 | ownership-guard hook과 연동 |
| `requires` | 선택 | 사전 로딩 필요 파일 목록 | @import과 유사하지만 선언적 |
| `allowed_dirs` | 선택 | 쓰기 권한 범위 | 스킬 간 파일 충돌 방지. hook과 연동 가능 |
| `user-invocable` | 선택 | 사용자 직접 호출 가능 여부 (기본: true) | 내부 유틸리티 스킬은 false |

**본체 섹션 (권장 구조):**

```markdown
# Skill Title

## Goal
이 스킬의 한 문장 미션. 모든 의사결정의 기준점이 된다.

## Focus
- 집중 영역 1: 구체적 설명
- 집중 영역 2: 구체적 설명
- 집중 영역 3: 구체적 설명
- 집중 영역 4: 구체적 설명
- (선택) 집중 영역 5

## Workflow
1. 첫 번째 단계 — 무엇을, 어떤 도구로
2. 두 번째 단계 — 판단 기준 포함
3. 세 번째 단계 — 분기 조건 명시
4. 검증 단계 — 어떻게 확인하는가

## Output Contract
스킬이 생산하는 결과물의 형식, 필수 섹션, 저장 위치를 명시한다.
- 형식: Markdown 보고서 | JSON 상태 파일 | 코드 변경 + 테스트
- 필수 섹션: [섹션 목록]
- 저장 위치: [경로]

## Guardrails
- 절대 하지 말아야 할 것 1: 이유
- 절대 하지 말아야 할 것 2: 이유
- 절대 하지 말아야 할 것 3: 이유
```

### 6.3 Co-optris 스킬 변환 예시 (6개)

Co-optris 프로젝트의 6개 Cursor 에이전트 스킬을 Claude Code 스킬로 완전 변환한다. 원본은 `.agents/skills/*/SKILL.md`에 위치하며, 변환 대상은 `.claude/skills/*/SKILL.md`이다.

#### 스킬 1: co-optris-tech-lead

**원본 위치:** `.agents/skills/co-optris-tech-lead/SKILL.md`
**변환 위치:** `.claude/skills/co-optris-tech-lead/SKILL.md`

```yaml
---
name: co-optris-tech-lead
description: Co-optris 아키텍처 결정, 상태 경계 설계, 의존성 규율, 마일스톤 시퀀싱
model: opus
role: tech-lead
requires:
  - docs/architecture/code-map.md
  - docs/game-design/master_plan.md
allowed_dirs:
  - docs/architecture/
  - docs/operations/
  - shared/
  - server/
user-invocable: true
---
```

```markdown
# Co-optris Tech Lead

## Goal
Co-optris를 출시 가능한 상태로 유지하는 최소한의 기술 설계를 수행한다.

## Focus
- **상태 경계(State Boundaries)**: 서버 권위 모델(authoritative model)과 클라이언트 예측(prediction)의 경계를 명확히 정의. 어떤 데이터가 서버에서만 변경 가능한지, 클라이언트가 낙관적(optimistic)으로 갱신할 수 있는 범위는 어디까지인지 규정
- **의존성 규율(Dependency Discipline)**: 새로운 npm 패키지, 프레임워크, 빌드 도구 도입 시 반드시 승인 필요. 기존 도구로 해결 가능한 문제에 새 의존성을 추가하지 않음. package.json 변경은 반드시 rationale 첨부
- **마일스톤 시퀀싱(Milestone Sequencing)**: Phase 1(단일 보드) → Phase 2(멀티플레이어) → Phase 3(폴리싱) 순서 엄수. 후속 Phase의 기능을 선행 Phase에서 구현하지 않음
- **리스크 경감(Risk Reduction)**: 되돌릴 수 없는(irreversible) 결정을 식별하고 명시적으로 알림. 데이터 스키마 변경, 프로토콜 변경, 외부 서비스 연동은 항상 되돌릴 수 없는 결정으로 분류

## Workflow
1. **상태 경계 식별**: 요청된 기능이 서버/클라이언트/공유(shared) 중 어디에 속하는지 판단
   - `server/` → 권위 게임 로직 (방 관리, 보드 상태, 점수)
   - `web/` → 렌더링, 입력 처리, 예측 보간
   - `shared/` → 양쪽에서 사용하는 타입 정의, 상수, 유틸리티
   - Grep 도구로 관련 import 경로를 추적하여 의존 방향 확인
2. **단순 인프라 우선**: 문제를 해결하는 가장 단순한 접근법을 먼저 제시. WebSocket 대신 Server-Sent Events로 충분한가? 상태 관리 라이브러리 대신 단순 객체로 충분한가?
3. **되돌릴 수 없는 결정 경고**: 다음 중 하나에 해당하면 "⚠️ IRREVERSIBLE" 태그를 붙여 명시
   - 네트워크 프로토콜 메시지 형식 변경
   - 서버 상태 스키마 변경 (기존 세션과 호환 불가)
   - 외부 서비스(인증, 매치메이킹 등) 연동
4. **검증 정의**: 아키텍처 결정이 올바르게 구현되었는지 확인할 수 있는 구체적 검증 명령 제시
   - 예: `npm run check:phase12 && node --check server/room.js`

## Output Contract
아키텍처 권고안은 다음 형식으로 출력한다:

```
### Architecture Recommendation: [제목]

**Rationale**: 이 결정을 내리는 이유 (2-3문장)

**Affected Files**:
- `server/room.js` — 방 상태에 [X] 필드 추가
- `shared/types.d.ts` — [X] 타입 정의
- `web/board.js` — 렌더링 로직 갱신

**Risks**:
- [IRREVERSIBLE] 메시지 프로토콜 변경: 기존 클라이언트 호환 불가
- [REVERSIBLE] CSS 레이아웃 변경: 롤백 용이

**Verification**:
npm run check:phase12
node --check server/room.js
curl -s http://localhost:3000/api/health | jq .status
```

## Guardrails
- **무거운 프레임워크 금지**: React, Vue, Angular 등 SPA 프레임워크를 사용자 승인 없이 도입하지 않는다. Co-optris는 바닐라 JS + 최소 빌드 도구 철학을 따른다
- **권위 모델 침해 금지**: 클라이언트에서 게임 상태를 직접 변경하는 코드를 절대 작성하지 않는다. 모든 상태 변경은 서버를 통해야 한다. `web/` 디렉터리의 코드가 `gameState`를 직접 수정하는 패턴이 발견되면 즉시 경고
- **LAN 관심사 격리**: 네트워크 관련 코드는 `server/net/` 또는 `shared/protocol/`에 격리한다. 게임 로직(`server/game/`)에 소켓 코드가 침투하지 않도록 한다
- **Phase 건너뛰기 금지**: Phase 2 기능(멀티플레이어 동기화)을 Phase 1(단일 보드)에서 구현하지 않는다. "나중에 쓸 것 같으니까 미리"는 금지
```

#### 스킬 2: co-optris-gameplay

**변환 위치:** `.claude/skills/co-optris-gameplay/SKILL.md`

```yaml
---
name: co-optris-gameplay
description: Co-optris 보드 감각, 플레이 가능한 슬라이스, 수직 분할 구현
model: sonnet
role: gameplay
requires:
  - docs/game-design/master_plan.md
  - docs/architecture/code-map.md
allowed_dirs:
  - server/game/
  - shared/constants/
  - shared/types/
  - web/game/
user-invocable: true
---
```

```markdown
# Co-optris Gameplay

## Goal
Co-optris의 보드 감각(board feel)을 만드는 플레이 가능한 최소 슬라이스를 수직 분할(vertical slicing)로 구현한다.

## Focus
- **보드 감각(Board Feel)**: 테트리스 블록의 낙하 속도, 회전 반응성, 바닥 도착 시 잠금 지연(lock delay)이 "기분 좋은" 수준인지 지속적으로 검증. 숫자로 튜닝 가능하도록 모든 타이밍을 `shared/constants/gameplay.js`에 분리
- **플레이 가능한 슬라이스(Playable Slice)**: 기능을 수평(레이어별)이 아닌 수직(사용자가 체감 가능한 단위)으로 분할. "입력 처리 전체"가 아니라 "블록 하나를 떨어뜨려서 줄을 지울 수 있다"가 하나의 슬라이스
- **수직 분할(Vertical Slicing)**: 각 슬라이스는 독립적으로 데모 가능해야 한다. 서버 로직 + 클라이언트 렌더링 + 입력 처리가 한 슬라이스에 모두 포함
- **공유 보드 역학**: Co-optris 특유의 "공유 보드" 메커니즘 — 두 플레이어가 하나의 보드에서 동시에 블록을 조작. 충돌 해결, 동시 줄 제거 판정의 정확성

## Workflow
1. **마스터 플랜 확인**: `docs/game-design/master_plan.md`에서 현재 Phase의 목표 슬라이스 확인
2. **슬라이스 분해**: 요청된 기능을 가장 작은 플레이 가능 단위로 분해
   - 예: "블록 회전" → (a) 시계방향 회전 (b) 벽차기(wall kick) (c) 반시계 회전
   - 각 단위가 독립 데모 가능한지 검증
3. **서버-클라이언트 동시 구현**: 슬라이스 하나를 서버 로직(`server/game/`)과 클라이언트 렌더링(`web/game/`) 동시에 구현. 한쪽만 구현하고 "나중에 연결"하지 않음
4. **상수 분리 검증**: 모든 숫자 값(낙하 속도, 잠금 지연, 점수 가중치)이 `shared/constants/`에 있는지 확인. 하드코딩된 매직 넘버 발견 시 즉시 상수로 추출
5. **플레이 테스트**: `npm run dev`로 실행하여 브라우저에서 실제 플레이 검증

## Output Contract
- 변경된 파일 목록 + 각 파일의 변경 사유
- 새로 도입된 상수: 이름, 값, 단위, 범위 (예: `LOCK_DELAY_MS: 500, range: [200, 1000]`)
- 데모 명령: 슬라이스를 확인할 수 있는 구체적 단계
- 슬라이스 완료 기준: "줄 제거 시 점수 증가가 화면에 표시된다" 같은 관찰 가능한 기준

## Guardrails
- **매직 넘버 금지**: 게임플레이 관련 숫자를 코드에 직접 기재하지 않는다. 반드시 named constant로 분리
- **수평 분할 금지**: "입력 모듈 전체 구현" 같은 레이어 단위 작업을 하지 않는다. 항상 사용자가 체감 가능한 수직 슬라이스로
- **비결정적 로직 주의**: 게임 로직은 동일 입력에 동일 결과를 보장해야 한다. `Math.random()` 사용 시 시드(seed) 기반으로 전환
- **네트워크 코드 침투 금지**: `server/game/` 디렉터리에 소켓, 메시지 직렬화 등 네트워크 관련 코드를 작성하지 않는다. 게임 로직은 순수 함수로 유지
```

#### 스킬 3: co-optris-netcode

**변환 위치:** `.claude/skills/co-optris-netcode/SKILL.md`

```yaml
---
name: co-optris-netcode
description: Co-optris 방 생명주기, 권위 상태 동기화, 멀티플레이어 프로토콜
model: opus
role: netcode
requires:
  - docs/architecture/code-map.md
  - shared/protocol/messages.d.ts
allowed_dirs:
  - server/net/
  - server/room/
  - shared/protocol/
  - web/net/
user-invocable: true
---
```

```markdown
# Co-optris Netcode

## Goal
Co-optris의 방(Room) 생명주기와 권위 상태(authoritative state) 동기화를 관리하는 멀티플레이어 프로토콜을 설계하고 구현한다.

## Focus
- **방 생명주기(Room Lifecycle)**: 방 생성 → 플레이어 참가 → 게임 시작 → 진행 → 종료 → 정리의 전체 흐름. 각 상태 전이(transition)에서의 유효성 검증
- **권위 상태(Authoritative State)**: 서버가 유일한 진실의 원천(source of truth). 클라이언트는 서버 상태의 시각적 표현만 담당. 상태 불일치 발생 시 서버가 항상 우선
- **멀티플레이어 프로토콜**: WebSocket 메시지 형식, 직렬화/역직렬화, 메시지 순서 보장, 재연결 처리
- **지연 보상(Lag Compensation)**: 네트워크 지연이 있어도 게임이 자연스럽게 느껴지도록 클라이언트 측 예측(prediction)과 서버 보정(reconciliation) 구현
- **LAN 최적화**: Co-optris는 LAN 환경을 주 타겟으로 하므로, 인터넷 수준의 복잡한 보상보다 단순하고 낮은 지연의 프로토콜 우선

## Workflow
1. **프로토콜 메시지 정의**: `shared/protocol/messages.d.ts`에서 현재 메시지 타입 확인. 새 메시지 추가 시:
   - 메시지 이름: `PascalCase` (예: `PlayerMove`, `BoardSync`)
   - 필수 필드: `type`, `seq` (시퀀스 번호), `timestamp`
   - 페이로드는 최소한으로, 델타(변경분)만 전송
2. **방 상태 머신 갱신**: `server/room/` 디렉터리에서 방 상태 전이 로직 확인. 상태 전이 다이어그램을 코드 주석으로 유지
3. **서버-클라이언트 동기화 구현**: 서버에서 상태 변경 → 직렬화 → WebSocket 전송 → 클라이언트 역직렬화 → 렌더링 갱신의 파이프라인 구현
4. **재연결 핸들링**: 플레이어 연결 끊김 시 방 상태 보존, 재연결 시 전체 상태 스냅샷 전송, 유예 시간(grace period) 경과 후 자동 항복 처리
5. **프로토콜 검증**: 메시지 형식이 `shared/protocol/`의 타입 정의와 일치하는지 `npm run check:phase12`로 검증

## Output Contract
- 변경/추가된 메시지 타입 목록 + 각 메시지의 페이로드 명세
- 상태 전이 다이어그램 (텍스트 형식)
- 대역폭 추정: 초당 메시지 수, 평균 메시지 크기
- 검증 명령: `node --check server/net/*.js && npm run check:phase12`

## Guardrails
- **클라이언트 신뢰 금지**: 클라이언트에서 보내온 게임 상태를 그대로 적용하지 않는다. 클라이언트는 "입력(input)"만 전송, 서버가 "결과(result)"를 계산
- **게임 로직 침투 금지**: `server/net/`, `shared/protocol/`에 게임 규칙(줄 제거 조건, 점수 계산 등)을 구현하지 않는다. 네트워크 계층은 데이터 전달만 담당
- **프로토콜 하위 호환성**: 메시지 형식 변경은 반드시 tech-lead 스킬의 "IRREVERSIBLE" 리뷰를 거침
- **과도한 동기화 금지**: LAN 환경에서는 매 프레임 전체 상태를 보내도 대역폭이 충분할 수 있지만, 습관적으로 델타 동기화를 유지하여 인터넷 환경으로의 확장 가능성 보존
```

#### 스킬 4: co-optris-ux

**변환 위치:** `.claude/skills/co-optris-ux/SKILL.md`

```yaml
---
name: co-optris-ux
description: Co-optris HUD 명확성, 공유보드 가독성, 소유권 시각적 구분
model: sonnet
role: ux
requires:
  - docs/game-design/master_plan.md
allowed_dirs:
  - web/ui/
  - web/styles/
  - web/assets/
  - shared/constants/
user-invocable: true
---
```

```markdown
# Co-optris UX

## Goal
공유 보드에서 두 플레이어의 블록 소유권이 즉시 구분되고, HUD가 게임 상태를 방해 없이 전달하는 인터페이스를 구현한다.

## Focus
- **HUD 명확성(HUD Clarity)**: 점수, 레벨, 다음 블록 미리보기, 연결 상태 등의 정보를 게임 보드를 가리지 않으면서 즉시 인지 가능하도록 배치. 정보 위계(hierarchy): 보드 > 다음 블록 > 점수 > 기타
- **공유 보드 가독성(Shared-Board Readability)**: 두 플레이어의 블록이 하나의 보드에 공존할 때, 시각적 혼란 없이 각자의 블록을 구분할 수 있어야 함. 색상만으로 구분하지 않음 (색맹 접근성)
- **소유권 시각화(Ownership Visibility)**: 각 블록이 어느 플레이어의 것인지 색상 + 패턴(줄무늬, 점선 등) 이중 인코딩으로 표현. 현재 활성 블록(낙하 중)은 추가적인 시각적 강조
- **반응성(Responsiveness)**: 입력에서 화면 갱신까지의 지연이 인지 불가능한 수준 (16ms 이내). CSS 애니메이션은 `transform`과 `opacity`만 사용하여 리플로우 최소화
- **최소주의**: 불필요한 장식, 그라데이션, 그림자를 배제. Co-optris는 기능적 미니멀리즘을 추구

## Workflow
1. **현재 UI 상태 확인**: `web/ui/`와 `web/styles/`의 기존 코드를 읽어 현재 구현 수준 파악
2. **정보 위계 설계**: 요청된 UI 요소가 정보 위계의 어디에 위치하는지 결정. 보드 영역을 침범하는 요소는 거부
3. **접근성 검증**: 색상 대비 비율 4.5:1 이상 확보. 색상만으로 정보를 전달하지 않음 (형태/패턴 병용)
4. **성능 검증**: `web/styles/`의 CSS에서 `width`, `height`, `top`, `left` 애니메이션이 없는지 확인. 있으면 `transform`으로 전환
5. **브라우저 테스트**: 크롬 DevTools의 Performance 탭에서 프레임 드롭 없이 60fps 유지되는지 확인

## Output Contract
- UI 변경 명세: 어떤 요소가 어디에 어떤 크기로 배치되는지
- 색상 팔레트: hex 코드 + 대비 비율 + 용도
- 접근성 체크리스트: WCAG 2.1 AA 기준 충족 여부
- 스크린샷 촬영 명령: 검증을 위한 브라우저 접속 URL 및 확인 포인트

## Guardrails
- **보드 영역 침범 금지**: HUD 요소가 게임 보드 렌더링 영역을 가리거나 줄이지 않는다
- **색상 단독 구분 금지**: 모든 시각적 구분은 색상 + 형태(패턴, 크기, 위치)의 이중 인코딩 필수
- **무거운 애니메이션 금지**: CSS 애니메이션은 `transform`과 `opacity`만 사용. JavaScript 애니메이션은 `requestAnimationFrame` 필수
- **외부 UI 라이브러리 금지**: Bootstrap, Tailwind 등 CSS 프레임워크를 도입하지 않는다. 바닐라 CSS로 구현
```

#### 스킬 5: co-optris-qa-whitebox

**변환 위치:** `.claude/skills/co-optris-qa-whitebox/SKILL.md`

```yaml
---
name: co-optris-qa-whitebox
description: Co-optris 정적 분석, 코드 리뷰, 게이트 테스트, 임시 패치 탐지
model: sonnet
role: qa-whitebox
requires:
  - docs/architecture/code-map.md
allowed_dirs:
  - docs/operations/
user-invocable: true
---
```

```markdown
# Co-optris QA Whitebox

## Goal
코드 수준의 품질 게이트를 운영하여 구문 오류, 타입 불일치, 임시 패치, 테스트 누락을 배포 전에 차단한다.

## Focus
- **정적 분석(Static Analysis)**: `node --check`로 구문 검증, `npm run check:phase12`로 프로젝트 수준 검증. 모든 .js 파일이 파싱 가능한 상태인지 확인
- **코드 리뷰(Code Review)**: 변경된 파일에 대해 가독성, 네이밍, 관심사 분리, 에러 처리를 검토. 특히 서버-클라이언트 경계를 넘는 변경에 주의
- **게이트 테스트(Gate Tests)**: 빌드 검증, 구문 검증, 린트 검사를 통과해야만 커밋/배포 가능. 실패 시 구체적 원인과 수정 방향 제시
- **임시 패치 탐지(Temp Patch Detection)**: `TODO`, `FIXME`, `HACK`, `TEMPORARY`, `WORKAROUND` 주석을 추적. 2주 이상 존재하는 임시 패치는 기술 부채로 에스컬레이션
- **의존 방향 검증**: `web/` → `shared/` ✓, `server/` → `shared/` ✓, `web/` → `server/` ✗ (금지). 의존 방향 위반 탐지

## Workflow
1. **전체 구문 검증**: 모든 .js 파일에 대해 `node --check` 실행
   ```bash
   find server/ web/ shared/ -name '*.js' -exec node --check {} \;
   ```
2. **프로젝트 수준 검증**: `npm run check:phase12` 실행. 실패 시 오류 메시지 분석 및 수정 방향 제시
3. **임시 패치 스캔**: Grep 도구로 `TODO|FIXME|HACK|TEMPORARY|WORKAROUND` 패턴 탐지. `git blame`으로 작성일 확인. 2주 경과 항목 목록화
4. **의존 방향 검증**: `web/` 디렉터리의 import 문에서 `server/` 경로가 있는지 검색. `shared/`를 거치지 않는 직접 참조 탐지
5. **변경 파일 집중 리뷰**: `git diff --name-only HEAD~1`로 최근 변경 파일을 특정하고, 해당 파일에 대해 심층 리뷰

## Output Contract
QA 보고서 형식:

```
### QA Whitebox Report — [날짜]

**Syntax**: ✅ PASS (N files checked)  또는  ❌ FAIL (errors listed)
**Project Check**: ✅ PASS  또는  ❌ FAIL (output)
**Temp Patches**: N items (M items over 2 weeks — escalation needed)
**Dependency Direction**: ✅ CLEAN  또는  ❌ VIOLATION (files listed)
**Code Review**: [파일별 소견]
```

저장 위치: `docs/operations/qa-whitebox-[날짜].md`

## Guardrails
- **코드 수정 금지**: 이 스킬은 분석과 보고만 수행한다. 문제를 발견해도 직접 수정하지 않고 보고서에 기록한다. 수정은 해당 역할(gameplay, netcode 등)의 스킬이 담당
- **거짓 양성(False Positive) 최소화**: `TODO: 이 패턴은 의도적임` 같은 명시적 주석이 있으면 임시 패치로 분류하지 않음
- **빌드 환경 가정 금지**: 특정 Node 버전, OS, 글로벌 패키지 설치를 가정하지 않는다. `package.json`의 scripts만 사용
```

#### 스킬 6: co-optris-qa-blackbox

**변환 위치:** `.claude/skills/co-optris-qa-blackbox/SKILL.md`

```yaml
---
name: co-optris-qa-blackbox
description: Co-optris 브라우저 라이브 테스트, 기능/시각/상호작용 검증
model: sonnet
role: qa-blackbox
requires:
  - docs/game-design/master_plan.md
allowed_dirs:
  - docs/operations/
user-invocable: true
---
```

```markdown
# Co-optris QA Blackbox

## Goal
실제 브라우저에서 게임을 실행하여 기능, 시각적 요소, 사용자 상호작용이 기대대로 작동하는지 검증한다.

## Focus
- **브라우저 라이브 테스트(Browser Live Test)**: `npm run dev`로 개발 서버를 실행하고, 실제 브라우저(또는 Puppeteer/Playwright)에서 게임을 로드하여 동작 확인
- **기능 검증(Feature Verification)**: 마스터 플랜에 명시된 현재 Phase의 기능이 모두 작동하는지 체계적으로 확인. "블록이 떨어진다" → "줄이 지워진다" → "점수가 올라간다" 등 각 기능의 end-to-end 흐름
- **시각 검증(Visual Verification)**: 블록 색상, 보드 레이아웃, HUD 위치, 텍스트 가독성이 디자인 의도와 일치하는지 확인. 화면 깨짐, 겹침, 잘림 탐지
- **상호작용 검증(Interaction Verification)**: 키보드 입력(화살표, 회전, 하드드롭)에 대한 응답이 즉각적이고 정확한지 확인. 동시 키 입력, 빠른 연타 등 엣지 케이스 포함
- **멀티플레이어 시나리오**: 두 개의 브라우저 탭/창을 열어 동시 접속 시 동기화 상태 확인 (Phase 2 이후)

## Workflow
1. **개발 서버 실행 확인**: `npm run dev`가 정상적으로 서버를 시작하는지 확인. 포트 충돌, 의존성 누락 등 사전 오류 해결
2. **기능 체크리스트 생성**: `docs/game-design/master_plan.md`에서 현재 Phase의 기능 목록을 추출하여 체크리스트 생성
3. **기능별 수동 테스트**: 각 기능에 대해:
   - 정상 경로(happy path) 테스트
   - 경계 조건(edge case) 테스트 (보드 가장자리에서 회전, 꽉 찬 보드에서 새 블록 등)
   - 실패 경로(error path) 테스트 (서버 중단 시 클라이언트 동작 등)
4. **시각 검증**: 브라우저 DevTools에서:
   - 콘솔 에러 없음 확인
   - 네트워크 탭에서 실패한 요청 없음 확인
   - Performance 탭에서 프레임 레이트 60fps 유지 확인
5. **결과 기록**: 테스트 결과를 구조화된 형태로 기록

## Output Contract
QA 블랙박스 보고서 형식:

```
### QA Blackbox Report — [날짜]

**Environment**: Node [version], Chrome [version], [OS]
**Server Status**: ✅ Running on port [N]

**Feature Tests**:
| Feature | Status | Notes |
|---------|--------|-------|
| 블록 낙하 | ✅ PASS | 정상 속도, 부드러운 애니메이션 |
| 좌우 이동 | ✅ PASS | 벽 충돌 정상 |
| 회전 | ⚠️ PARTIAL | 벽차기 미구현 |
| 줄 제거 | ✅ PASS | 동시 다중 줄 제거 확인 |

**Visual Issues**: [스크린샷/설명]
**Console Errors**: [에러 목록 또는 "None"]
**Performance**: [fps 평균/최저]
**Multiplayer Sync**: [해당 시 — 동기화 상태]
```

저장 위치: `docs/operations/qa-blackbox-[날짜].md`

## Guardrails
- **코드 수정 금지**: whitebox QA와 마찬가지로, 발견된 문제를 직접 수정하지 않고 보고만 한다
- **자동화 테스트와 혼동 금지**: 이 스킬은 수동/반자동 브라우저 테스트이다. 유닛 테스트나 통합 테스트 작성은 이 스킬의 범위가 아니다
- **환경 의존성 최소화**: 특정 브라우저 확장, 글로벌 도구 설치를 요구하지 않는다. 기본 브라우저 + DevTools만으로 검증
- **주관적 평가 명시**: "보드가 예쁘다/안 예쁘다" 같은 주관적 판단은 하지 않는다. "대비 비율 3.1:1로 WCAG AA 미달" 같은 객관적 기준으로만 판단
```

### 6.4 스킬 설계 패턴 (실제 프로젝트에서 발견된 패턴)

실제 프로젝트에서 발견된 스킬 설계 패턴을 분석한다. 이 패턴들은 새 프로젝트에서 스킬을 설계할 때 참조 아키텍처로 활용할 수 있다.

#### 패턴 1: GUI2WEBAPP (22 스킬) — 도메인 + 검증 + 최적화 삼중 구조

```
.claude/skills/
├── analyze-gui/SKILL.md              ← 도메인: 분석
├── analyze-layout/SKILL.md           ← 도메인: 분석
├── analyze-components/SKILL.md       ← 도메인: 분석
├── design-responsive/SKILL.md        ← 도메인: 설계
├── design-architecture/SKILL.md      ← 도메인: 설계
├── build-html/SKILL.md               ← 도메인: 구현
├── build-css/SKILL.md                ← 도메인: 구현
├── build-javascript/SKILL.md         ← 도메인: 구현
├── build-components/SKILL.md         ← 도메인: 구현
├── validate-design/SKILL.md          ← 검증: 설계 검증
├── validate-port/SKILL.md            ← 검증: 포팅 검증
├── validate-accessibility/SKILL.md   ← 검증: 접근성 검증
├── validate-responsive/SKILL.md      ← 검증: 반응형 검증
├── optimize-responsive/SKILL.md      ← 최적화: 반응형
├── optimize-performance/SKILL.md     ← 최적화: 성능
├── optimize-accessibility/SKILL.md   ← 최적화: 접근성
├── ... (기타 도메인별 스킬)
```

**설계 원칙:**

- **3계층 분리**: 도메인(Domain) → 검증(Validation) → 최적화(Optimization)
- **도메인 스킬은 행동한다**: 분석, 설계, 구현을 수행
- **검증 스킬은 판단한다**: 도메인 스킬의 결과물이 기준을 충족하는지 확인
- **최적화 스킬은 개선한다**: 검증을 통과한 결과물을 더 나은 수준으로 끌어올림
- **스킬 깊이: 중간(7-10페이지)**: 각 스킬이 한 가지 잘 정의된 작업에 집중. 워크플로우는 5-8단계

**호출 패턴 예시:**

```
사용자: "이 데스크톱 앱의 설정 화면을 웹앱으로 포팅해줘"

1. /analyze-gui → 기존 GUI 구조 분석
2. /analyze-components → 컴포넌트 식별 및 분류
3. /design-responsive → 반응형 레이아웃 설계
4. /build-html + /build-css + /build-javascript → 구현
5. /validate-port → 원본과의 일치도 검증
6. /validate-responsive → 다양한 화면 크기 검증
7. /optimize-performance → 성능 최적화 (필요 시)
```

#### 패턴 2: Project-Integration-Agent (14 스킬) — 선형 파이프라인 구조

```
.claude/skills/
├── 01-analyze-projects/SKILL.md      ← 1단계: 분석
├── 02-analyze-dependencies/SKILL.md  ← 1단계: 분석
├── 03-strategy-merge/SKILL.md        ← 2단계: 전략
├── 04-strategy-conflicts/SKILL.md    ← 2단계: 전략
├── 05-design-unified/SKILL.md        ← 3단계: 설계
├── 06-design-interfaces/SKILL.md     ← 3단계: 설계
├── 07-implement-core/SKILL.md        ← 4단계: 구현
├── 08-implement-adapters/SKILL.md    ← 4단계: 구현
├── 09-implement-tests/SKILL.md       ← 4단계: 구현
├── 10-validate-integration/SKILL.md  ← 5단계: 검증
├── 11-validate-independence/SKILL.md ← 5단계: 검증
├── 12-validate-tests/SKILL.md        ← 5단계: 검증
├── 13-optimize-bundle/SKILL.md       ← 6단계: 최적화
└── 14-optimize-docs/SKILL.md         ← 6단계: 최적화
```

**설계 원칙:**

- **번호 접두사**: 스킬 실행 순서를 디렉터리명으로 명시. 이전 단계 미완료 시 다음 단계 진입 불가
- **단계 내 병렬 가능**: 같은 번호 접두사의 스킬은 병렬 실행 가능 (예: 07, 08, 09는 동시 진행 가능)
- **단계 간 의존성**: 각 단계의 출력이 다음 단계의 입력. `_state.json` 파일로 단계 간 상태 전달
- **스킬 깊이: 상세(10-15페이지)**: 각 스킬이 복잡한 분석/설계를 수행. 워크플로우는 8-12단계
- **독립성 검증 특화**: 통합 후 원본 프로젝트 경로를 참조하지 않는지 검증하는 전용 스킬 존재 (`11-validate-independence`)

**핵심 차별점 — 독립성 게이트:**

```markdown
## validate-independence 스킬의 핵심 규칙
- integrated/ 디렉터리의 코드가 projects/ 디렉터리를 참조하면 실패
- import 경로에 '../projects/' 또는 절대 경로가 포함되면 실패
- 통합된 코드는 integrated/ 내에서만 의존성이 완결되어야 함
```

#### 패턴 3: bright-data-test (20 스킬) — 인프라 + 핵심 연구 + 분석 + 특화 계층

```
.claude/skills/
├── infrastructure/                    ← 인프라 계층
│   ├── bright-data-setup/SKILL.md    ← API 초기 설정, 인증
│   ├── bright-data-monitor/SKILL.md  ← 비용 모니터링, 사용량 추적
│   └── bright-data-fixtures/SKILL.md ← 테스트 데이터 관리
├── core-research/                     ← 핵심 연구 계층
│   ├── web-scraper-test/SKILL.md     ← Web Scraper API 테스트
│   ├── serp-test/SKILL.md            ← SERP API 테스트
│   ├── dataset-test/SKILL.md         ← Dataset API 테스트
│   └── comparison-test/SKILL.md      ← API 간 비교 테스트
├── analysis/                          ← 분석 계층
│   ├── data-quality/SKILL.md         ← 수집 데이터 품질 분석
│   ├── cost-analysis/SKILL.md        ← 비용 대비 효과 분석
│   ├── reliability-analysis/SKILL.md ← 안정성/가용성 분석
│   └── performance-analysis/SKILL.md ← 응답 시간/처리량 분석
├── specialized/                       ← 특화 계층
│   ├── nlm-scraper/SKILL.md          ← NLM 특화 스크래핑
│   ├── pubmed-parser/SKILL.md        ← PubMed 논문 파싱
│   └── citation-network/SKILL.md     ← 인용 네트워크 구축
└── references/                        ← 공유 참조 (스킬이 아님)
    ├── api-docs/                      ← API 문서 캐시
    ├── sample-responses/              ← 실제 API 응답 샘플
    └── schema-definitions/            ← JSON Schema 정의
```

**설계 원칙:**

- **4계층 + 참조**: 인프라 → 핵심 연구 → 분석 → 특화, 그리고 공유 참조 디렉터리
- **하위 디렉터리 패턴**: 스킬이 20개를 넘으면 기능별로 하위 디렉터리로 분류. `.claude/skills/infrastructure/bright-data-setup/SKILL.md` 형태
- **공유 참조(references/) 패턴**: 여러 스킬이 공통으로 참조하는 문서를 별도 디렉터리에 배치. 스킬이 아닌 데이터이므로 SKILL.md가 없음
- **스킬 깊이: 최대(40페이지 이상)**: 복잡한 API 테스트 스킬은 요청/응답 예시, 엣지 케이스, 트러블슈팅 가이드까지 포함하여 40페이지 이상

**스킬 깊이 스펙트럼 요약:**

| 프로젝트 | 스킬 수 | 평균 깊이 | 특징 |
|---|---|---|---|
| GUI2WEBAPP | 22 | 중간 (7-10p) | 각 스킬이 좁은 범위에 집중, 조합으로 복잡성 달성 |
| Project-Integration-Agent | 14 | 상세 (10-15p) | 파이프라인 구조, 단계 간 의존성 상세 기술 |
| bright-data-test | 20 | 최대 (40+p) | API 명세, 응답 예시, 트러블슈팅까지 자체 완결 |
| Co-optris | 6 | 상세 (10-15p) | 역할 기반, 게임 도메인 특화 |

**패턴 선택 가이드:**

- 넓은 도메인을 다수의 좁은 작업으로 분해 → **GUI2WEBAPP 패턴** (도메인+검증+최적화)
- 명확한 단계적 절차가 있는 작업 → **PIA 패턴** (선형 파이프라인)
- 깊은 도메인 전문성이 필요한 연구/분석 → **bright-data-test 패턴** (계층+참조)
- 팀 역할 시뮬레이션 → **Co-optris 패턴** (역할 기반, 소유권 분리)

---

