# 레드팀 피드백 수집 및 동의/반영 판단 (B = harness-architect)

원본: `C:\Users\lee880619\Downloads\harness-comparison-20260417\0{1..7}-*-red.md`
검토일: 2026-04-17

## 범례
- ✅ **반영**: 지적이 타당하고 실제 개선 가치가 높음
- 🟡 **부분 반영**: 일부 타당, 기존 설계 범위 내에서 보강
- ❌ **반영 안 함**: 트레이드오프상 현 설계 유지 / 이미 완화됨 / 본질적 한계

---

## 1. 아키텍처 (01-architecture-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-Arch-1 | 9-Phase × Advisor × Escalation 조합 폭발 (최악 27회 소환) | 🟡 | 복잡도 게이트 이미 있음. Fast Track 노출 강화 |
| B-Arch-2 | `$TARGET_PROJECT_ROOT` 미설정 시 훅 조용히 무력화 | ✅ | ownership-guard.sh를 **fail-closed**로 수정 (빈 값 → 차단) |
| B-Arch-3 | rules 자동 로딩 vs 명시적 Read 지시 중복/모순 | ✅ | `.claude/rules/*.md`는 always-apply로 작동. harness-setup.md의 "4개 파일 Read" 지시 제거 |
| B-Arch-4 | Meta-Leakage Guard 자기참조 역설 (검사자=피검사자) | 🟡 | 외부 정적 검증(CI grep) 추가로 완화. 완전 독립 검증은 구조상 어려움 |
| B-Arch-5 | Agent-Playbook 분리가 Claude Code 디스커버리 경로에 종속 | 🟡 | README/CONTRIBUTING.md에 "외부 의존성 리스크" 섹션 명시 |

## 2. UX (02-workflow-ux-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-UX-1 | 설치 2단계 진입장벽 ("GitHub-hosted marketplace" 신뢰 의심) | ❌ | 공식 마켓플레이스 승인 대기 중. README 문구 톤만 조정 |
| B-UX-2 | Phase 0 "절대 경로 즉시 입력" 마찰 | ✅ | 슬래시 커맨드 argument 지원 + `$PWD`/현재 작업 디렉터리 기본 제안 |
| B-UX-3 | 9단계 인지 부담, 예상 시간·루프 상한 미노출 | 🟡 | Phase 시작 시 예상 소요/최대 재시도 횟수 표시 |
| B-UX-4 | Escalation 일괄 처리의 맥락 손실 역설 | 🟡 | blocking은 즉시 / non-blocking은 Phase 직후(다음 Phase 시작 전) 질문으로 단축 |
| B-UX-5 | 재개 시 요청명·HTML주석 메타·미처리 Escalation 복원 절차 부재 | ✅ | 재개 시 Escalation 재검토 + status frontmatter 표준화 |

## 3. 산출물 범위 (03-output-scope-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-Out-1 | 모든 프로젝트에 9-Phase 강요 | 🟡 | 이미 Fast-Forward 존재. 단순 프로젝트의 Phase 3-5 스킵 조건 명시 |
| B-Out-2 | Phase 간 선형 실패 전파 | 🟡 | 반환 파싱 실패 시 재소환 횟수 상한 + 사용자 개입 경로 명시 |
| B-Out-3 | 에이전트별 생성 파일 품질 편차 (CLAUDE.md 중복 수정 충돌) | ✅ | CLAUDE.md **단일 소유자 원칙** (Phase 1-2만 수정) 도입 |
| B-Out-4 | knowledge/ 13개 파일 버전 드리프트 | 🟡 | knowledge에 `claude-code-version:` 프런트매터 + CI 만료 경고 |
| B-Out-5 | MCP 설치 실행 불확실성, 실패 복구 프로토콜 모호 | ✅ | 설치 실패 시 롤백 + 수동 설치 가이드 제공 절차 명시 |
| B-Out-6 | Advisor 누적 컨텍스트 비용 | 🟡 | Advisor 프롬프트에 "직전 Phase Summary만" 전달, 전 Phase 누적 제거 |

## 4. 오케스트레이션 (04-orchestration-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-Orch-1 | 서브에이전트의 AskUserQuestion 독점 위반 감지 부재 | ✅ | 에이전트 정의 Rules 최상단에 강한 금지 명시 + settings.json `deny`로 서브에이전트 AUQ 차단 검토 |
| B-Orch-2 | Escalation "없음" 반환 시 맹목 신뢰 | 🟡 | Advisor 5개 질문에 "미기록 결정 검출" 추가 |
| B-Orch-3 | Phase Gate 파일 존재만 확인, 내용 맹점 | ✅ | Phase Gate에 필수 섹션 존재 여부(정규식) 검증 추가 |
| B-Orch-4 | Advisor BLOCK 2회 루프 소진 후 동작 미정의 | ✅ | 3번째 경로: 사용자에게 "무시/재시도/수동개입" 선택지 제시 프로토콜 명시 |
| B-Orch-5 | 대상 프로젝트 `.claude/skills/` 에 오케스트레이션 로직 오염 | 🟡 | phase-skills 플레이북에 "대상 프로젝트 스킬은 도메인 로직만" 제약 명시 |
| B-Orch-6 | Summary vs 파일 내용 불일치 우선순위 미정의 | ✅ | "파일이 source of truth, Summary는 hint" 원칙 명시 |

## 5. QA & 검증 (05-qa-validation-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-QA-1 | Advisor 5개 질문에 보안/타깃 특이성/소유권 충돌 미포함 | ✅ | design-review Dimension 6~8 추가 |
| B-QA-2 | 복잡도 게이트로 Secret Detection 우회 가능 | ✅ | **보안 감사는 게이트 무관 항상 실행** 명시 |
| B-QA-3 | 메타누수 키워드 정확 매칭의 변형 표현 취약성 | ✅ | 키워드 리스트 확장 + 한국어 변형 추가 + 정규식화 |
| B-QA-4 | 보안 검증 자동화 부재 (수동 체크리스트) | ✅ | `scripts/validate-settings.sh` (jq 기반) 추가 |
| B-QA-5 | Phase 0 사전 답변 오류가 전체 오염 | 🟡 | Phase 1-2 스캔 결과와 사전 답변 일관성 교차 검증 |
| B-QA-6 | Advisor "과도한 지적 금지" 편향 | ❌ | 이 규칙 제거 시 BLOCK 남발 → 루프 교착 악화. 현 균형 유지 |

## 6. 확장성 & 유지보수 (06-extensibility-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-Ext-1 | 46개 파일 동기화 비용, Phase 추가 체크리스트 부재 | ✅ | CONTRIBUTING.md에 "Phase 추가 체크리스트" 섹션 추가 |
| B-Ext-2 | CLAUDE.md ↔ orchestrator-protocol.md 중복 유지보수 | ✅ | CLAUDE.md는 포인터만, 상세는 orchestrator-protocol에 단일화 |
| B-Ext-3 | knowledge/ 13개 파일 버전 드리프트 | 🟡 | 버전 프런트매터 + 만료 경고만 추가 |
| B-Ext-4 | 테스트 자동화 부분 공백 | 🟡 | 설정 파일 구문/스키마 CI만 우선 추가 |
| B-Ext-5 | `phase-*.md` 파일명 ↔ `subagent_type` 규칙 암묵 | ✅ | CONTRIBUTING.md에 명명 규약 1:1 명시 + CI 검증 |

## 7. 상태관리 & 재개 (07-state-mgmt-red)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| B-State-1 | 파일 번호 엇갈림 (수동편집/재생성/실험파일) | 🟡 | 실행 단계에서 판정 하향 — `.state.json` 인덱스는 배포본 호환성 비용이 크므로 유보. 대신 (a) 산출물 YAML frontmatter 격상(`phase`/`status`/`advisor_status`) (b) 비표준 파일명 `^[0-9]{2}[a-z]?-[a-z-]+\.md$` 엄격 매칭 (c) frontmatter 누락 파일은 "상태 불명"으로 사용자 확인 — 3개 규약으로 주요 시나리오(수동편집·재생성) 해결. 실험파일 완전 격리는 향후 `.state.json` 로 재평가. |
| B-State-2 | 200단어 요약 정보 손실 (근거/기각 대안 누락) | 🟡 | Context for Next Phase에 "기각된 대안" 필수 항목 추가 |
| B-State-3 | Context for Next Phase 누락 시 연쇄 실패 | ✅ | Advisor가 필수 섹션 스키마 검증, 누락 시 BLOCK |
| B-State-4 | 사용자 수동 수정 후 재개 시 이전 Advisor 결과 재검증 없음 | ✅ | 재개 프로토콜에 "수정 감지 시 Advisor 재실행" 추가 |
| B-State-5 | 재개 시 이전 결정 모순 감지 부재 | ✅ | 재개 시 `.state.json` 변경 이력 비교 |
| B-State-C2 | Phase 파일 부분 손상 조용한 오작동 | ✅ | 각 산출물에 필수 섹션 체크섬/섹션 존재 검증 |

---

## 공통 리스크 (A/B 모두 해당)

| ID | 지적 | 판단 | 비고 |
|----|------|------|------|
| C-1 | LLM 비결정성 — 프로토콜 ≠ 실행 보장 | ❌ | 본질적 한계. 파서/스키마 검증으로 부분 완화만 가능 |
| C-2 | 에이전트 정의 파일 프롬프트 인젝션 | ✅ | phase-setup 스캔 시 사용자 코드 주석을 격리된 인용 블록으로만 참조 |
| C-3 | Advisor-as-Judge 동형 편향 | ❌ | 외부 독립 검증 불가. 복수 Dimension으로만 완화 |

---

## 반영 우선순위 (Tier)

**Tier 1 — 보안/정합성 (즉시):**
- B-Arch-2 (fail-closed ownership-guard) — Phase 0 설정 누락 감지 분기 추가로 완전 반영
- B-QA-2 (보안 감사 게이트 무관 강제)
- B-QA-3 (메타누수 키워드 확장)
- B-State-1 (frontmatter 격상 + 비표준 파일명 규약 — `.state.json` 인덱스는 유보, 판정 🟡)
- B-State-3 / B-Orch-3 (섹션 스키마 검증)

**Wave 2.5 레드팀 피드백 반영 이력 (2026-04-17):**
- B-Arch-2 은 ownership-guard.sh 로직에 "TPR 미설정 + `docs/{요청명}/NN-*.md` 경로 쓰기 시도 → exit 1" 분기를 추가해 실질적으로 강화함.
- B-State-1 의 판정을 ✅→🟡 로 내림. 완전 해결(실험파일 완전 격리)은 `.state.json` 을 요구하나, 기존 배포 하네스와의 호환 비용이 크다는 판단으로 당분간 유보. 대신 frontmatter·엄격 파일명 매칭으로 주요 시나리오를 커버.
- validate-meta-leakage.sh 의 정규식에서 `Phase[ -]?[0-9]` 를 제거해 대상 프로젝트의 정당한 "Phase N" 도메인 단어 과탐을 방지.
- B-UX-4 (Escalation 일괄처리 역설)의 🟡→보완 수준: "다음 Phase 시작 전까지만 묶기" 규약이 맥락 손실을 줄이는 실질 개선이므로 🟡 유지하되 실행 완료로 기록.

**Tier 2 — 오케스트레이션 견고성:**
- B-Arch-3 (rules 로딩 중복 제거)
- B-Orch-4 (BLOCK 루프 소진 경로 정의)
- B-Orch-6 (source of truth 규칙)
- B-QA-1 (Advisor Dimension 추가)
- B-State-4/5 (재개 시 재검증)

**Tier 3 — UX/유지보수:**
- B-UX-2 (경로 argument)
- B-UX-5 (재개 UX 개선)
- B-Out-3 (CLAUDE.md 단일 소유자)
- B-Ext-1/2/5 (CONTRIBUTING 체크리스트·명명규약·중복 제거)
- B-QA-4 (validate-settings.sh)

**Tier 4 — 장기/문서:**
- B-Arch-5 / B-Out-4 / B-Ext-3 / B-Ext-4 (버전 드리프트, 리스크 명시, CI 최소화)
