# harness-architect (plugin development context)

> 이 파일은 **이 레포에서 Claude Code 세션을 열고 플러그인 자체를 수정**하는 기여자(Contributor)용 가이드입니다. 최종 사용자는 `/harness-architect:harness-setup` 슬래시 커맨드만으로 플러그인을 쓰면 되며 이 파일을 볼 필요가 없습니다.

## 이 레포가 무엇인가

Claude Code용 **Apache-2.0 오픈소스 플러그인**인 `harness-architect`의 소스 저장소입니다. 설치 후 사용자는 `/harness-architect:harness-setup` 으로 9-Phase 오케스트레이션을 시작해 대상 프로젝트의 Claude Code 하네스를 구축합니다.

## 이 레포에서 개발 시 (contributors only)

```bash
claude --plugin-dir .
```

`--plugin-dir` 를 쓰면 `${CLAUDE_PLUGIN_ROOT}` 가 이 레포 절대 경로로 치환되어, 실제 플러그인 설치 환경과 동일하게 동작합니다.

## 수정 시 참고할 문서

- 설계 철학·디렉터리 맵·Phase 상세: [ARCHITECTURE.md](./ARCHITECTURE.md)
- 기여 규칙·코드 스타일·테스트: [CONTRIBUTING.md](./CONTRIBUTING.md)
- 변경 이력: [CHANGELOG.md](./CHANGELOG.md)
- 항상 적용 규칙: `.claude/rules/*.md` (meta-leakage-guard, orchestrator-protocol, output-quality, question-discipline)

## 중요 원칙 (요약 — 상세는 `.claude/rules/*.md` 참조)

아래 5개 원칙은 런타임 규칙(`.claude/rules/orchestrator-protocol.md`, `question-discipline.md`, `output-quality.md`, `meta-leakage-guard.md` — always-apply)에 **권위 있는 전체 명세**가 있다. 이 섹션은 기여자가 빠르게 확인할 수 있는 요약이며, 세부 프로토콜(Phase 전환, Escalation 처리, 복잡도 게이트, 재개 등)은 규칙 파일을 정본으로 삼는다.

1. **AskUserQuestion은 Orchestrator 전용** — 서브에이전트는 `Escalations`에 기록. 상세: `orchestrator-protocol.md` "AskUserQuestion 소유권" 및 "Escalations 병합 프로토콜".
2. **Agent-Playbook 분리** — 방법론은 `playbooks/` 에만. `.claude/skills/`·`commands/` 에 두지 마세요 (자동 디스커버리되어 서브에이전트 소환을 우회함).
3. **Target Project Guardrail** — 이 레포에서 세션을 열었더라도 플러그인이 하네스를 만드는 중에는 대상 프로젝트 경로 밖에 쓰기 금지. `ownership-guard.sh` 훅이 강제.
4. **No Meta-Leakage** — 이 플러그인이 생성하는 산출물이 Claude Code 아키텍처 설명이나 이 플러그인의 행동 규칙을 포함하지 않도록. `checklists/meta-leakage-keywords.md` 로 검증. 정규식 기반 정적 스캔은 `scripts/validate-meta-leakage.sh`.
5. **경로 변수 사용** — 플러그인 내부 참조는 `${CLAUDE_PLUGIN_ROOT}` 절대 필수.

이 요약이 `.claude/rules/` 내용과 어긋나면 **항상 규칙 파일이 우선**한다. 요약 수정 시 규칙 파일의 관련 섹션도 함께 갱신해야 한다(드리프트 방지 — CONTRIBUTING.md "Phase/규칙 변경 체크리스트" 참조).

## 금지 / 필수 패턴

- 금지: `Skill(skill: "fresh-setup")` — 방법론을 메인 세션이 직접 실행.
- 필수: `Agent(subagent_type: "phase-setup", ...)` — 서브에이전트 소환 후 playbook을 서브에이전트가 Read하여 실행.

## 언어

한국어로 응답. 코드/파일명은 영어.
