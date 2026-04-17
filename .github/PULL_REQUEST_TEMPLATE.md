<!--
  PR 제출 전 CONTRIBUTING.md의 '변경 원칙'을 한 번만 확인해 주세요.
  특히:
  - Agent-Playbook 분리 준수 (새 방법론은 playbooks/, .claude/skills나 commands/에 두지 말 것)
  - 플러그인 내부 참조는 ${CLAUDE_PLUGIN_ROOT} 사용
  - 메타 누수 방지 (.claude/rules/meta-leakage-guard.md)
-->

## Summary

<!-- 이 PR이 해결하는 문제/시나리오를 2-3줄로. -->

## Changes

<!-- 수정한 파일/영역. 체크박스로 구조화하면 리뷰가 빠릅니다. -->

- [ ] `.claude/agents/` 변경
- [ ] `playbooks/` 변경
- [ ] `.claude/rules/` 변경
- [ ] `commands/harness-setup.md` 변경
- [ ] `.claude/hooks/` 변경
- [ ] `knowledge/` 변경 (Source 주석 유지 확인)
- [ ] 문서만 (`README`, `ARCHITECTURE`, `CHANGELOG`, `CONTRIBUTING`)
- [ ] 템플릿 프리셋 (`.claude/templates/`)

## How to test

<!--
  로컬 검증 절차. CONTRIBUTING.md "테스트" 섹션의 체크와 이 변경 특유의 확인이 섞여도 좋습니다.
  예:
  1. `claude --plugin-dir .`
  2. `/harness-setup`
  3. Phase 3에서 Fast-Forward 분기 확인
-->

## CHANGELOG

- [ ] 사용자 가시 영역 변경입니다 — `CHANGELOG.md` [Unreleased] 섹션에 항목 추가함
- [ ] 내부 리팩토링/문서 수정이라 CHANGELOG 갱신 불필요

## Related issues

<!-- "Closes #123" 또는 "Refs #45" -->
