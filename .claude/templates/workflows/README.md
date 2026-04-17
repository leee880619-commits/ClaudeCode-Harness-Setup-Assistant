# Workflow Templates

대상 프로젝트에 즉시 설치 가능한 **워크플로우 프리셋** 묶음. 각 템플릿은 특정 프로젝트 유형에 대한 검증된 에이전트 팀 + 방법론 + 오케스트레이터 규칙 조합을 제공한다.

## 현재 제공 템플릿

| 템플릿 | 용도 | 기본 패턴 | D-2 확장 |
|--------|------|----------|----------|
| [strict-coding-6step](strict-coding-6step/) | 복잡 코딩 프로젝트용 6단계 엄격 워크플로우 (Research → Plan → Redteam → Implement → QA) | D-1 (오케스트레이터) | 가능 (README 참조) |

## 공용 템플릿 조각 (`../common/`)

여러 워크플로우 또는 커스텀 프로젝트에서 재사용하는 규칙/훅 조각은 `.claude/templates/common/`에 둔다. 새 템플릿 작성 시 공용 조각을 참조하거나 조합하여 일관성을 유지한다.

- `../common/rules/code-navigation.md` — 코드맵 기반 탐색 + 자동 유지 (복잡 코딩 프로젝트에 권장)
- 자세한 사용 조건과 적용 시점: `../common/README.md` 참조

## 템플릿 구조 규약

새 워크플로우 템플릿을 추가할 때 다음 구조를 따른다.

### 필수 디렉터리 구조

```
{workflow-name}/
├── README.md                         # 언제 사용, 구성 파일, 단계 개요, 적용 절차, 커스터마이징
├── orchestrator-workflow.md          # D-1 패턴일 때 필수. 메인 세션이 진입 시 읽는 규칙
├── agents/                           # 에이전트 정의 (WHO)
│   ├── {role-1}-agent.md
│   └── {role-N}-agent.md
└── playbooks/                        # 방법론 (HOW) — flat 구조 권장, 10개 초과 시 카테고리 분할
    ├── {method-1}.md
    └── {method-N}.md
```

- **절대 `skills/` 디렉터리를 사용하지 않는다**. `.claude/skills/`와 혼동 위험 + 복사 시 자동 디스커버리 유발 위험.
- `agents/*.md`의 `## Playbooks` 섹션은 `playbooks/{name}.md` 경로를 참조한다 (대상 프로젝트 배치 경로 기준).
- D-2 하이브리드를 지원하려면 README에 별도 섹션으로 진입점 스킬 추가 방법을 기술한다 (strict-coding-6step README의 "D-2 하이브리드 확장" 섹션 참조).

### 패턴 선택 (D-1 vs D-2 vs D-3)

| 신호 | 권장 패턴 |
|------|----------|
| 에이전트 3개 이상 체인, 사용자가 자연어로 시작 | **D-1** (기본) |
| 에이전트 3개 이상 체인 + 명시적 진입점 `/command` 필요 | **D-2** |
| 에이전트 1-2개, 사용자가 스킬을 직접 호출해도 무방 | **D-3** — 이 경우 템플릿이 아닌 단순 스킬 묶음이 더 적합할 수 있음 |

새 템플릿 작성 전에 대상 사용자/프로젝트 유형을 특정하여 D-1/D-2/D-3 중 하나로 결정하고, README 최상단에 그 결정을 명시한다.

### 적용 절차 표준

모든 템플릿의 `README.md`에 "적용 절차 (오케스트레이터용)" 섹션을 둔다. 최소 포함 항목:

1. **감지 조건** — 어떤 신호로 이 템플릿을 사용자에게 제안할지 (Phase 1-2 fresh-setup 또는 Phase 3 workflow-design에서 체크)
2. **설치 단계** — `orchestrator-workflow.md` / `agents/*.md` / `playbooks/*.md`를 대상 프로젝트의 어느 경로에 복사하는지
3. **커스터마이징 항목** — 프로젝트 스택에 맞춰 조정해야 하는 필드 (예: `allowed_dirs`, 기동 명령, Identity의 기술 스택)
4. **절대 금지 사항** — 특히 "`playbooks/*.md`를 `.claude/skills/`로 복사하지 않는다" 경고

### 메타 누수 방지

템플릿의 에이전트/플레이북 파일에는 이 어시스턴트 프로젝트의 내부 용어(예: "Phase 1-9", "Orchestrator Pattern Decision D-1/D-2/D-3", "자동 디스커버리")를 **직접 담지 않는다**. 대신 대상 프로젝트 맥락의 용어로 서술한다 (예: "이 워크플로우의 STEP 3", "에이전트는 playbooks/ 파일을 Read한다").

`checklists/meta-leakage-keywords.md`의 금지 키워드 목록을 참조하여 템플릿 작성 후 검증한다.

## 새 템플릿 추가 체크리스트

새 워크플로우 템플릿을 추가하려면:

- [ ] `.claude/templates/workflows/{workflow-name}/` 디렉터리 생성
- [ ] README.md 작성 (언제 사용, 구성 파일, 단계 개요, 적용 절차, D-2 확장 가이드)
- [ ] `agents/*.md` 작성 — 각 에이전트의 Identity + Playbooks 섹션(`playbooks/{name}.md` 참조) + Rules
- [ ] `playbooks/*.md` 작성 — 각 방법론의 Goal + Workflow + Output Contract + Guardrails
- [ ] D-1 패턴이면 `orchestrator-workflow.md` 작성 (메인 세션 역할, 에이전트 소환 순서, AskUserQuestion 소유권)
- [ ] 이 `README.md`의 "현재 제공 템플릿" 표에 추가
- [ ] `knowledge/13-*.md` 같은 전용 knowledge 파일이 필요한지 검토
- [ ] `playbooks/fresh-setup.md` 또는 `playbooks/workflow-design.md`의 감지/제안 로직에 새 템플릿 연결 여부 검토
- [ ] 메타 누수 키워드 체크리스트 통과
