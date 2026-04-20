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

## 중요 원칙 (요약 — 정본은 `.claude/rules/*.md`)

1. **AskUserQuestion은 Orchestrator 전용** — 서브에이전트는 `Escalations`에 기록.
2. **Agent-Playbook 분리** — 방법론은 `playbooks/`에만 (`.claude/skills/` 금지 — 자동 디스커버리되어 서브에이전트 소환 우회).
3. **Target Project Guardrail** — 대상 프로젝트 경로 밖에 쓰기 금지. `ownership-guard.sh` 훅이 강제.
4. **No Meta-Leakage** — 산출물에 플러그인 자체 규칙/Claude Code 아키텍처 설명 포함 금지. 검증: `scripts/validate-meta-leakage.sh`.
5. **경로 변수** — 플러그인 내부 참조는 `${CLAUDE_PLUGIN_ROOT}` 필수.

요약이 규칙 파일과 어긋나면 규칙 파일이 우선. 요약 수정 시 규칙 파일 동반 갱신 (CONTRIBUTING.md 체크리스트 참조).

## 금지 / 필수 패턴

- 금지: `Skill(skill: "fresh-setup")` — 방법론을 메인 세션이 직접 실행.
- 필수: `Agent(subagent_type: "phase-setup", ...)` — 서브에이전트 소환 후 playbook을 서브에이전트가 Read하여 실행.

## 릴리즈 워크플로우

**트리거**: 사용자가 "main에 강제 푸쉬 허용" / "릴리즈 진행" / "태깅하고 릴리즈" 등 원격 강제 푸쉬를 명시적으로 승인하는 발화를 하면, 아래 단계를 순서대로 자동 수행한다. 중간에 확인 없이 전 단계를 완주한다.

### 자동 수행 순서

1. **버전 결정** — 사용자가 명시하면 그 버전 사용. 미명시 시 현재 `plugin.json` 버전에서 patch +1.

2. **CHANGELOG.md 업데이트** — `## [Unreleased]` 바로 아래에 `## [X.Y.Z] - YYYY-MM-DD` 섹션 삽입. 이번 세션에서 수정된 파일과 변경 내용을 기준으로 Added/Changed/Fixed 항목 작성.

3. **`.claude-plugin/plugin.json` 버전 범프** — `"version"` 필드를 새 버전으로 Edit.

4. **커밋** — 수정된 파일 전체(코드 변경분 + CHANGELOG.md + plugin.json)를 스테이징 후 커밋.
   - 커밋 메시지 형식: `feat: vX.Y.Z — 변경 내용 한 줄 요약`

5. **태깅** — `git tag vX.Y.Z`

6. **푸쉬** — `git push origin main` → `git push origin vX.Y.Z --force`

7. **GitHub Release 생성** — `gh release create vX.Y.Z --title "vX.Y.Z — 한 줄 요약" --notes "변경 내용 마크다운"`

8. **Confluence 위키 업데이트** — 페이지 ID `1004308574` ("harness-architect 사용 가이드")의 `## 업데이트 히스토리` 섹션에 새 버전 항목을 기존 최신 버전 앞에 삽입.
   - `get_page` → 버전 확인 → 새 섹션 prepend → `update_page(version_number: 현재+1)`
   - 삽입 형식: `<h3>vX.Y.Z &mdash; YYYY-MM-DD</h3>` + 한 줄 요약 + 변경 bullet + GitHub Release 링크

### 주의
- plugin.json 버전 범프를 빠뜨리면 `/plugin` 업데이트 시 최신 버전으로 인식되지 않는다. **반드시 포함.**
- 태그는 plugin.json 버전 범프 커밋까지 포함한 최신 커밋에 달아야 한다.

## 언어

한국어로 응답. 코드/파일명은 영어.
