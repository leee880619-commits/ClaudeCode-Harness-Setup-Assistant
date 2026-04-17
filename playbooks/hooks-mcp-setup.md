
# Hooks & MCP Setup

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. 모든 확인 사항은
Escalations 섹션에 `[BLOCKING]`/`[ASK]`/`[NOTE]` 태그로 기록한다.

## Goal
프로젝트의 워크플로우와 에이전트 팀 구조에 맞는 훅(PreToolUse/PostToolUse/Stop)을 설계하고,
프로젝트에 유용한 MCP 서버를 제안하여 승인 시 설치를 지원한다.

## Prerequisites
- Phase 6 완료: 모든 에이전트 스킬 작성 완료
- 소유권 가드 필요 여부 결정 완료 (Phase 5)
- 대상 프로젝트의 `.claude/settings.json` 존재

## Knowledge References
필요 시 Read 도구로 로딩:
- `knowledge/06-hooks-system.md` — 훅 완전 명세, 실제 프로젝트 패턴 (3개 프로젝트)
- `knowledge/03-file-reference.md` — settings.json 훅/MCP 필드 명세

## Part 1: Hooks 설계 (Phase 7)

### Step 1: allowed_dirs 정합성 검증

Phase 6 산출물의 **Context for Next Phase** 섹션에서 스킬별 allowed_dirs 종합 목록 + 각 스킬의 저장 위치 케이스(A/B)를 확인한다.
이 목록과 실제 생성된 스킬 파일의 `allowed_dirs` frontmatter를 대조하여 불일치가 없는지 검증한다. 위치별 확인 대상:
- 케이스 A: `.claude/skills/{skill-name}/SKILL.md`
- 케이스 B: `playbooks/{skill-name}.md`

1. 각 스킬의 allowed_dirs가 실제 프로젝트 디렉터리 구조와 일치하는지 확인
2. 두 에이전트의 스킬이 동일 디렉터리에 쓰기 권한을 가지는 경우 충돌 여부 확인 (공유 영역 제외)
3. 불일치 발견 시 Escalations에 기록

### Step 2: 훅 필요성 진단

**Agent-Skill 분리 모델(모델 D) 적용 시**: 소유권 정보는 각 스킬 파일의 `allowed_dirs`를 참조한다. 에이전트 정의(`.claude/agents/*.md`)에는 소유권 정보가 없으므로 훅이 참조할 원본은 스킬 파일(`.claude/skills/*/SKILL.md` 또는 `playbooks/*.md`)이다.

**다중 에이전트 프로젝트 기본 권장 훅 (자동 설치 후보):**
- `ownership-guard.sh` (PreToolUse Write|Edit): 각 에이전트의 쓰기 범위를 SKILL.md allowed_dirs에 따라 강제. 본 어시스턴트 프로젝트의 `.claude/hooks/ownership-guard.sh`를 **대상 프로젝트 컨텍스트로 재작성**하여 템플릿으로 제공 (복사 금지 — 메타 누수). 핵심 구조: `$CLAUDE_TOOL_INPUT`에서 file_path 추출 → 심볼릭 링크/`..` 차단 → allow 리스트와 매칭.
- `syntax-check.sh` (PostToolUse Write|Edit): JSON parse, YAML frontmatter 닫힘, settings.json 위험 패턴 감지. 동일하게 템플릿으로 제공.

두 훅 모두 Escalations에 `[ASK] 기본 훅 설치 제안 — 설치/스킵` 항목으로 기록. 단독 에이전트나 솔로 프로젝트에서는 훅을 **자동 제안하지 않는다**.

프로젝트 상황에 따라 추가 훅 유형을 식별:

| 상황 | 훅 유형 | 목적 |
|------|---------|------|
| 멀티 에이전트 + 파일 충돌 위험 | PreToolUse (Write\|Edit) | 소유권 가드 |
| 코드 품질 자동 검증 | PostToolUse (Bash) | 품질 게이트 |
| 위험 명령 실행 방지 | PreToolUse (Bash) | 명령 가드 |
| 세션 종료 시 정리 | Stop | 클린업 |
| 파일 저장 후 자동 검사 | PostToolUse (Write\|Edit) | 구문/린트 |

각 훅의 필요 여부를 Escalations에 기록하여 오케스트레이터가 확인한다.
모든 프로젝트에 훅이 필요한 것은 아님 — 불필요하면 Phase 7을 건너뛴다.

### Step 3: 훅 스크립트 설계

필요한 각 훅에 대해:
1. 스크립트 언어 선택 (bash 권장, node도 가능)
2. 환경변수 사용 계획:
   - `$CLAUDE_TOOL_NAME`: 실행된 도구 이름
   - `$CLAUDE_TOOL_INPUT`: 도구 입력 JSON
   - `$CLAUDE_TOOL_OUTPUT`: (PostToolUse만) 도구 실행 결과
3. 성공/실패 기준: 종료 코드 0 = 통과, ≠ 0 = 차단/경고
4. stderr 피드백 메시지 (Claude에게 전달됨)

스크립트 초안을 산출물에 포함하여 오케스트레이터가 승인 처리.

### Step 4: settings.json에 훅 등록

`.claude/settings.json`의 `hooks` 섹션에 등록:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/ownership-guard.sh"
          }
        ]
      }
    ]
  }
}
```

변경된 settings.json 전체를 산출물에 포함하여 오케스트레이터가 승인 후 작성.

### Step 5: 훅 스크립트 파일 생성

승인된 스크립트를 `.claude/hooks/` 디렉터리에 생성한다.
실행 권한(`chmod +x`)을 부여한다.
`set -euo pipefail`을 기본 포함한다.

## Part 2: MCP 서버 제안 (Phase 8)

### Step 6: MCP 서버 후보 식별

프로젝트 유형과 기술 스택에 따라 유용한 MCP 서버를 제안:

| 프로젝트 유형 | MCP 서버 후보 | 용도 |
|--------------|-------------|------|
| 웹 앱 | @anthropic/mcp-server-fetch | HTTP 요청 |
| DB 사용 | mcp-server-sqlite, -postgres | DB 직접 쿼리 |
| 파일 시스템 | @modelcontextprotocol/server-filesystem | 파일 관리 |
| GitHub 연동 | @anthropic/mcp-server-github | PR/이슈 관리 |
| 웹 검색 | mcp-server-brave-search | 웹 검색 |

각 MCP 서버의 필요 여부를 Escalations에 기록하여 오케스트레이터가 확인한다.
관심 없으면 즉시 건너뛴다 — 모든 프로젝트에 MCP가 필요한 것은 아님.

### Step 7: MCP 서버 설치 지원

승인된 MCP 서버에 대해:
1. settings.json의 `mcpServers` 섹션에 설정 추가
2. 필요한 패키지 설치 명령 안내 또는 직접 실행
3. 인증/토큰이 필요한 경우:
   - **절대** settings.json(git-committed)에 직접 넣지 않음
   - `.claude/settings.local.json`(gitignored) 또는 환경변수 사용 안내
   - `sk-`, `ghp_`, `AKIA`, `xoxb-` 등 비밀값 패턴 감지
4. 설치 후 동작 확인

### Step 8: Phase 9로 전환

훅과 MCP 설정이 완료되면 Phase 9 검증으로 전환한다.
전체 하네스의 구문/일관성/시뮬레이션 검증을 수행하고 최종 보고서를 제시한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/06-hooks-mcp.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Hooks Installed` — 각 훅: 이벤트, matcher, 스크립트 경로, 목적
- [ ] `## MCP Servers` — 설치된 MCP 서버 목록과 용도 (없으면 "없음")
- [ ] `## Settings.json Changes` — hooks/mcpServers 섹션 변경 diff 요약
- [ ] `## Verification Targets` — Phase 9가 검증할 파일 목록
- [ ] `## Context for Next Phase` — Phase 9가 필요한 정보:
  - 설치된 훅 파일 경로 + 실행 권한 상태
  - MCP 서버 목록
  - 검증 대상 파일 목록 (훅, settings.json, 규칙, 에이전트, 스킬)
- [ ] `## Files Generated`
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 9: phase-validate 에이전트 소환 권장"

### 대상 프로젝트 반영
- `.claude/hooks/*.sh` — 훅 스크립트 파일 (해당 시)
- `.claude/settings.json` 업데이트 — hooks 섹션, mcpServers 섹션
- 동작 요약: "PreToolUse에서 X를 검증하고, PostToolUse에서 Y를 실행합니다"

## Guardrails
- 모든 훅/MCP 결정은 Escalations에 기록. 묻지 않고 설치하지 않음.
- 비밀값(API 키, 토큰)은 절대 settings.json에 포함하지 않음.
- 훅 스크립트 실행 시간 2초 이내 권장. 과도한 검증은 개발 흐름을 방해.
- MCP 서버가 불필요하면 Phase 8 건너뜀.
