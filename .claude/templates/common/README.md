# Common Templates

여러 워크플로우 템플릿 또는 커스텀 프로젝트에서 **재사용 가능한 규칙/훅/참조 조각** 모음. 특정 워크플로우에 종속되지 않는 공통 자산을 둔다.

## 현재 제공 조각

### Rules

| 파일 | 용도 | 대상 프로젝트 배치 | 조건 |
|------|------|------------------|------|
| `rules/intent-gate.md` | 작업 요청 첫 턴에 의사결정 분기 분석 + 맥락 부족 시 intent-clarifier 스킬 호출 강제. 모든 파일 쓰기·외부 리서치·계획 확정 이전에 의도 확인. | `.claude/rules/intent-gate.md` | **무조건** (베이스라인) — fresh-setup Step 3-F 가 모든 대상 프로젝트에 복사 |
| `rules/code-navigation.md` | 코드맵(`docs/architecture/code-map.md`) 기반 탐색 + 구조 변경 시 자동 유지 | `.claude/rules/code-navigation.md` | 대상 프로젝트에 `docs/architecture/code-map.md` 또는 유사 코드맵 파일이 이미 존재하거나, 사용자가 이 규칙을 원할 때 |

### Skills

| 파일 | 용도 | 대상 프로젝트 배치 | 조건 |
|------|------|------------------|------|
| `skills/intent-clarifier/SKILL.md` | 사용자 요청 정제 → 의사결정 분기 열거 → 맥락 공백 식별 → AskUserQuestion 도구로 질문 루프 | `.claude/skills/intent-clarifier/` | **무조건** (베이스라인) — intent-gate 규칙이 호출하는 실행 스킬. fresh-setup Step 3-F 가 복사 |

## 사용 원칙

- **조각은 복사 대상**. 적용 시 대상 프로젝트의 맥락(경로, 용어)에 맞춰 필요한 부분을 조정한다
- **메타 누수 금지**: 각 조각은 이 어시스턴트의 내부 용어(`Phase N`, `D-1/D-2/D-3`, `Orchestrator Pattern Decision`)를 포함하지 않는다. 이미 범용 어휘로 작성되어 있으나 수정 시에도 이 원칙을 유지한다
- **Opt-in**: 공용 조각은 대상 프로젝트에 유용할 때만 복사한다. 단순 프로젝트에 조각을 일괄 적용하지 않는다

## 언제 적용하는가

Phase 흐름상 다음 시점에 이 디렉터리의 조각들을 채택할지 판단한다:

1. **Phase 1-2 (fresh-setup) Step 3-F**: `rules/intent-gate.md` + `skills/intent-clarifier/` **무조건 설치** (베이스라인, 사용자 확인 불필요)
2. **Phase 1-2 (fresh-setup)**: 프로젝트 스캔 시 관련 파일 감지
   - `docs/architecture/code-map.md` 또는 유사 파일 존재 → `code-navigation.md` 채택 제안
3. **Phase 3 (workflow-design)**: 워크플로우 설계 시 공용 규칙 채택 여부 Escalation
4. **Phase 7-8 (hooks-mcp-setup)**: 공용 훅이 필요한 경우

Intent Gate 를 제외한 나머지 조각은 Escalation으로 사용자에게 채택 여부를 확인한다.

## 새 조각 추가 시

새로운 재사용 가능한 규칙/훅을 이 디렉터리에 추가할 때:

- [ ] 규범 위치: `common/rules/*.md`, `common/hooks/*.sh`, `common/references/*.md` 등 카테고리별 하위 디렉터리
- [ ] 이 README의 "현재 제공 조각" 표에 추가
- [ ] 적용 조건(언제 복사하는지) 명시
- [ ] 메타 누수 키워드 체크 (`checklists/meta-leakage-keywords.md` 기준)
- [ ] Phase 어디에서 감지/제안되는지 연결점 확인 (필요 시 해당 플레이북 업데이트)
