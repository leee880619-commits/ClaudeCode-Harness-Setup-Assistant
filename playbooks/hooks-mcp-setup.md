
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
- `knowledge/03-file-reference.md` — settings.json 훅 필드 명세 (MCP는 settings.json 필드 아님 — `.mcp.json`/`claude mcp add` 참조)

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

> **훅 계약 (틀리면 훅이 조용히 무동작한다)** — 상세는 `knowledge/06-hooks-system.md` 7.1 / 7.2.1.
> - 입력은 **stdin JSON** (`{"tool_input":{"file_path":"..."}}`). `$CLAUDE_TOOL_INPUT` 환경변수는 **없다.**
> - 차단은 **`exit 2`**. `exit 1`은 도구를 막지 못한다.
> - 훅에 전달되는 환경변수는 `$CLAUDE_PROJECT_DIR` · `$CLAUDE_PLUGIN_ROOT` 등 정해진 것뿐이다. 임의 변수를 `export` 해도 훅은 못 받는다. **상태는 파일로 넘긴다.**
> - 모든 훅에 `"timeout"` 과 `"shell": "bash"` 를 명시한다. 생략 시 기본 timeout 600초 — 훅이 쌓여 CPU를 태운다.
> - Windows `file_path` 는 `C:\\Users\\...` 형태다. `/` 로 시작하는지로 절대경로를 판별하면 가드가 열린다.

**다중 에이전트 프로젝트 기본 권장 훅 (자동 설치 후보):**
- `ownership-guard.sh` (PreToolUse Write|Edit): 각 에이전트의 쓰기 범위를 SKILL.md allowed_dirs에 따라 강제. 대상 프로젝트 컨텍스트에 맞춰 **새로 작성**한다. 핵심 구조: stdin JSON에서 file_path 추출 → 백슬래시 정규화 → 심볼릭 링크/`..` 차단 → allow 리스트와 매칭 → 위반 시 `exit 2`.

  **필수 포함 — Complexity Gate S 등급 예외 (ORCHESTRATOR_DIRECT, 보안 강화형)**: 대상 프로젝트 워크플로우에 Complexity Gate(workflow-design Step 4-B)가 포함된 경우 아래 블록을 삽입한다. 단순 환경변수 플래그는 세션 시작 시 1회 설정하면 세션 전체가 무방비가 되는 순환 고리 취약점이 있으므로 **per-task 토큰 + 민감 파일 블랙리스트 + deny 선처리** 3중 가드로 구성한다.

  ```bash
  # 1) deny 패턴 선처리 — S 등급 여부와 무관하게 파괴적 액션은 항상 차단
  case "$FILE_PATH" in
    *.env|*.env.*|*/.env|*/.env.*|*/.git/*|*/secrets/*|*/credentials/*|*/private-keys/*)
      echo "denied: sensitive path ($FILE_PATH) — S-grade override disabled for sensitive paths" >&2
      exit 2
      ;;
  esac

  # 2) S-grade Complexity Gate 예외 — per-task 토큰 매칭 필수
  # 토큰 생성: Complexity Gate 판정 시점에 사용자가 AskUserQuestion으로 S 등급을 승인하면
  # 오케스트레이터가 $(uuidgen || head -c 16 /dev/urandom | xxd -p) 로 1회성 토큰을 발급하고,
  # docs/complexity-gate.lock 파일에 해시만 기록한 뒤 해당 작업 완료 시 파일을 삭제한다.
  if [ -n "${ORCHESTRATOR_DIRECT_TOKEN:-}" ] && [ -f docs/complexity-gate.lock ]; then
    expected_hash=$(cat docs/complexity-gate.lock 2>/dev/null)
    actual_hash=$(printf '%s' "$ORCHESTRATOR_DIRECT_TOKEN" | sha256sum | awk '{print $1}')
    if [ "$expected_hash" = "$actual_hash" ]; then
      exit 0
    fi
    echo "denied: ORCHESTRATOR_DIRECT_TOKEN mismatch" >&2
    exit 2
  fi
  ```

  > **미해결 — `ORCHESTRATOR_DIRECT_TOKEN` 은 훅에 도달하지 않는다.** 훅은 별도 프로세스로 실행되므로 다른 도구 호출에서 `export` 한 임의 환경변수를 받지 못한다. 따라서 위 S 등급 예외 분기는 **현재 절대 성립하지 않는다** (토큰이 항상 빈 값 -> 일반 가드로 낙하). 동작은 fail-closed 라 안전하지만 예외 기능은 죽어 있다. 토큰을 파일로 넘기면 락 파일과 같은 신뢰 경계에 놓여 해시 검증이 무의미해지므로, **이 예외를 실제로 쓰려면 전달 경로를 다시 설계해야 한다.** 그때까지 S 등급 예외는 "설계됐으나 미가동" 으로 간주하고, Escalations 에 `[ASK] S 등급 예외 미가동 — 현행 유지 / 재설계` 로 올린다.

  **보안 설계 근거**:
  - 1) deny 선처리가 `.env` · `.git/config` · secrets 경로를 S 등급 여부와 무관하게 **항상** 차단 (ownership-guard가 유일 방어선인 경로들).
  - 2) 단순 `ORCHESTRATOR_DIRECT=1` 환경변수는 메인 세션 또는 프롬프트 인젝션으로 자가 설정 가능한 취약점이 있어 per-task 토큰 + 락 파일 기반으로 변경. 락 파일 생성/해제 시점을 Complexity Gate 판정 플로우가 유일하게 소유하도록 오케스트레이터 프로토콜에 명시.
  - 3) S 등급 판정은 반드시 AskUserQuestion 경유 사용자 명시 승인 — "작은 작업인 것 같으니 직접 가겠다" 같은 메인 세션 자가 판단은 금지.

  이 예외가 없거나 보안 설계를 누락하면 S 등급 작은 패치(파일 5개 이하)도 에이전트 소환이 강제되어 실측 $18/세션 수준의 비용이 발생하거나, 반대로 보안이 형해화된다.
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
2. 입력 파싱 계획: **stdin JSON 1개** 를 읽어 `tool_name` · `tool_input.file_path` · `cwd` 를 꺼낸다.
   Windows 경로의 이스케이프된 백슬래시(`C:\\Users\\...`)를 슬래시로 정규화한 뒤 판정한다.
3. 성공/실패 기준: `exit 0` = 통과, `exit 2` = 차단(stderr가 Claude에게 전달). **`exit 1` 은 차단이 아니다.**
4. stderr 피드백 메시지 (Claude에게 전달됨)
5. **비용 계획**: 이 훅이 매 도구 호출마다 프로세스를 하나 띄운다는 전제로, 검사 대상이 아니면 인터프리터를 부르기 전에 `exit 0` 한다. `timeout` 값을 정한다 (가드 5초 / 검사 10초 / 빌드·테스트 30초 이상).

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
            "shell": "bash",
            "timeout": 5,
            "command": "bash .claude/hooks/ownership-guard.sh"
          }
        ]
      }
    ]
  }
}
```

`timeout` 과 `shell` 은 **생략 금지**다. `timeout` 을 빼면 기본값 600초가 적용되어, 머신이 느려진 순간 훅이 끝나지 못하고 10분간 살아남으며 그 사이 새 훅이 계속 쌓인다. `shell` 을 빼면 Windows에서 `bash` 가 PATH에서 WSL 런처로 해석될 수 있다.

변경된 settings.json 전체를 산출물에 포함하여 오케스트레이터가 승인 후 작성.

### Step 5: 훅 스크립트 파일 생성

승인된 스크립트를 `.claude/hooks/` 디렉터리에 생성한다.
실행 권한(`chmod +x`)을 부여한다.

`set -uo pipefail` 을 기본 포함한다. **`set -e` 는 넣지 않는다** — `grep -c` 처럼 "찾지 못함"을 종료 코드 1로 알리는 명령이 흔한데, `-e` 가 걸리면 훅이 그 지점에서 exit 1로 죽는다. exit 1은 차단도 아니고 Claude에게 전달되지도 않으므로, 훅이 조용히 무동작하는 상태가 된다.

## Part 2: MCP 서버 추천 (Phase 8)

> **중요 — MCP 설정은 `settings.json`에 쓰지 않는다.** Claude Code는 `settings.json`에서 MCP 설정을 읽지 않는다(`settings.json`은 hooks·permissions·env·plugins 전용). MCP 등록 정답은 project 스코프 = 프로젝트 루트 `.mcp.json`, local/user 스코프 = `claude mcp add --scope` CLI다.

> **이 Phase는 "리스트 + 설정 스니펫" 모델이다.** Phase 8 에이전트는 적합한 MCP 서버를 **조사·추천**하고, 사용자가 바로 복붙해 쓸 수 있는 `.mcp.json` 스니펫 / `claude mcp add` 명령 / 환경변수·인증 안내를 산출물에 기록한다. **MCP 등록 실행 자체는 사용자가 직접 수행한다** — 에이전트는 `claude mcp add` 를 호출하거나 패키지를 설치하지 않는다. 책임 경계: 조사·추천 = 에이전트, 등록·인증·비밀값 관리 = 사용자.

### Step 6: MCP 서버 후보 발굴 (웹 검색 기반)

#### Step 6 첫 단계 — 기존 MCP 인벤토리 (중복 제거)

후보를 제안하기 전 `claude mcp list`를 실행해 이미 등록된 MCP 서버 목록(모든 스코프)을 확보한다.
1. 후보와 이름이 같은 서버가 이미 있으면 후보에서 제외하고 `[NOTE] {서버명} 이미 등록됨 — 추천 생략` 기록.
2. 같은 용도의 다른 서버가 이미 있으면 `[ASK] {용도} MCP 중복 가능 — 기존 {기존명} 유지 vs 후보 {후보명} 추가` 기록.
3. `claude mcp list` 실행 실패 시 `[NOTE] 기존 MCP 조회 실패 — 중복 확인 없이 진행` 기록 후 계속한다 (침묵 실패 금지).

#### Step 6 두 번째 단계 — 웹 검색 기반 후보 발굴

프로젝트 유형·기술 스택을 신호로 추출하여 **현재 시점의 npm·MCP 생태계**에서 적합한 서버를 조사한다. 하드코딩된 후보 테이블은 사용하지 않는다 — 생태계 변동성이 크고 패키지명·네임스페이스가 자주 바뀐다.

신호 → 검색 쿼리 → 검증된 후보로 좁히는 절차:

1. **신호 추출** — Phase 1-2 산출물(`01-discovery-answers.md`)의 기술 스택·프로젝트 유형·도메인을 1차 신호로 사용. 예시:
   - 프로젝트 유형 "웹 앱" + 기술 스택 "PostgreSQL" → `postgres MCP`, `database MCP`
   - 프로젝트 유형 "에이전트 파이프라인" + 도메인 "딥 리서치" → `web search MCP`, `fetch MCP`, `documentation MCP`
   - "GitHub 워크플로우 자동화" → `github MCP`
   - "팀 공유 문서" → `slack MCP`, `confluence MCP`, `notion MCP`

2. **웹 검색 실행** — 각 신호에 대해 WebSearch 또는 WebFetch 로 조사:
   - 쿼리 예: `"MCP server" {신호}` / `"@modelcontextprotocol" {신호}` / `claude code MCP {신호} npm`
   - 1차 출처 우선순위: (a) `modelcontextprotocol.io` 공식 디렉터리 / (b) `github.com/modelcontextprotocol/servers` 레포 / (c) Anthropic 공식 문서 / (d) 명확한 1st-party 조직(`@anthropic-ai/`·도구 공식 조직) / (e) 외부 커뮤니티 레퍼런스
   - 검색 결과에서 **정확한 패키지명**(`@스코프/이름` 또는 무스코프 이름) 과 **1차 출처 URL**(레포 또는 공식 페이지) 을 수집

3. **후보 검증** — 수집한 각 후보에 대해:
   - 1차 출처 URL이 실존하고 README가 MCP 서버임을 명확히 설명하는가
   - 네임스페이스가 신뢰 가능한가 (Step 6.5 공급망 점검과 동일 기준 — 1차 출처 URL 확인은 이 단계로 통합)
   - 동일 용도의 후보가 여러 개면 1차 출처 신뢰도·README 품질·최근 활동을 기준으로 1~2개로 좁힘

4. **검색 실패 처리** — WebSearch/WebFetch 가 실패하거나 신뢰 가능한 후보가 0건이면 `[NOTE] MCP 후보 검색 실패 — 사용자 직접 탐색 권장 ({신호} 기준)` 기록. Step 6 말미의 0건 경로로 진행.

> 패키지명·네임스페이스를 본 플레이북에 하드코딩하지 않는다. 후보는 항상 실행 시점의 웹 검색 결과로 결정된다 — 이는 stale-on-arrival 문제의 구조적 차단이다.

#### Step 6 말미 — 후보 가시성 게이트 (형해화 차단)

후보 발굴 + Step 6.5 공급망 검토를 마친 뒤:
- **후보가 1건 이상이면, 에이전트는 반드시 `[ASK] MCP 서버 추천 — 후보 {N}건: {서버명 목록}. 채택할 항목 선택 / 전부 거절` Escalation을 발행한다 (`[NOTE]` 금지).** 오케스트레이터가 이를 AskUserQuestion으로 사용자에게 노출한다. "관심 없으면 즉시 건너뛴다"가 아니라 "후보를 제시하고 사용자가 명시 거절"로 처리한다 — 사용자 결정 없이 흘러가지 않는다.
- **후보가 0건이거나 사용자가 위 `[ASK]`에서 전부 거절하면**: Escalations에 `[NOTE] MCP 0건 — 프로젝트에 필요한 MCP 서버 없음으로 완료` 기록. Output Contract의 `## MCP Servers` 섹션은 **생략하지 않고** 본문에 `없음`으로 명시한다 (섹션 헤더 유지 — `validate-phase-artifact.sh` false positive 방지).

### Step 6.5: MCP 공급망 경량 검토

후보 확정 직전, 각 MCP 후보에 대해 경량 점검을 수행한다 (풀 보안 감사가 아닌 "출처 1줄 점검 + 사용자 고지" 게이트):

1. **네임스페이스 신뢰성** — 패키지 네임스페이스가 신뢰 가능한가: `@modelcontextprotocol/`, `@anthropic-ai/`, 또는 명확한 1st-party 조직 스코프인가. 무네임스페이스이거나 오타 유사 네임스페이스(typosquatting 의심)가 아닌가.
2. **1차 출처 URL 확인** — Step 6 두 번째 단계에서 수집한 1차 출처 URL이 실존하고 해당 패키지의 권위 있는 공급원인가. 외부 블로그·미러 사이트는 1차 출처로 인정하지 않는다.
3. **임의 코드 실행 고지** — stdio MCP는 사용자가 등록·실행 시 임의 코드 실행 권한을 가진다는 점을 Escalation `[NOTE]`로 사용자에게 고지한다.
4. **출처 불명 시 확인** — 출처가 불명(개인 계정 publish, 검증 불가 네임스페이스, 1차 출처 URL 없음)이면 `[ASK] MCP 출처 확인 — {서버명} 네임스페이스 {ns}, 1차 출처 {url 또는 "없음"}, 신뢰 가능 여부 확인` 기록.

### Step 7: 추천 산출물 생성 (설치 안 함)

> Phase 8 에이전트는 등록 실행을 수행하지 않는다. 사용자가 본인 환경에서 직접 `claude mcp add` 또는 `.mcp.json` 편집을 수행하도록 산출물에 필요한 모든 정보(스니펫·명령·환경변수)를 제공한다.

사용자가 Step 6 말미 `[ASK]` 에서 승인한 각 MCP 후보에 대해 산출물 `## MCP Servers` 섹션에 다음 항목을 모두 기록한다:

#### 7-1. 서버 메타

```
- 이름: <name>
- 용도: <한 줄 설명>
- 1차 출처: <레포 URL 또는 공식 페이지 URL>
- npm 네임스페이스: <@scope/pkg 또는 무스코프 패키지명> (HTTP 서버면 "HTTP, 패키지 없음")
- 권장 스코프: project | local | user (선택 사유 1줄)
```

스코프 선택 기준 (사용자 안내용 — 에이전트가 결정 후 사유 기록):
- **project**: 팀 전체가 공유해야 하는 도구(`postgres`, `github` 등 프로젝트 컨텍스트 의존)
- **local** (기본): 본인만 현재 프로젝트에서 사용하는 개인 도구
- **user**: 모든 프로젝트에서 쓰는 범용 개인 도구(`brave-search`, `filesystem` 등)

#### 7-2. project 스코프 후보 — `.mcp.json` 스니펫

권장 스코프가 `project` 인 후보는 사용자가 프로젝트 루트 `.mcp.json` 에 복붙할 수 있는 JSON 스니펫을 다음 형태로 기록한다 (이미 `.mcp.json` 이 있으면 `mcpServers` 객체 안에 병합):

```json
{
  "mcpServers": {
    "<name>": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "<pkg>"],
      "env": { "<VAR>": "${<VAR>}" }
    }
  }
}
```

HTTP 서버는:

```json
{
  "mcpServers": {
    "<name>": {
      "type": "http",
      "url": "<url>",
      "headers": { "Authorization": "Bearer ${<VAR>}" }
    }
  }
}
```

인증이 필요 없는 서버는 `env` 키를 생략하거나 빈 객체(`"env": {}`)로 둔다. 비밀값은 절대 평문으로 기록하지 않고 `${VAR}` 환경변수 치환 참조만 사용한다.

#### 7-3. local/user 스코프 후보 — `claude mcp add` 명령 한 줄

권장 스코프가 `local` 또는 `user` 인 후보는 사용자가 본인 터미널에서 실행할 명령을 한 줄로 기록한다:

```
# stdio 서버
claude mcp add --scope {local|user} <name> -- npx -y <pkg>

# HTTP 서버
claude mcp add --scope {local|user} --transport http <name> <url>
```

#### 7-4. 인증·환경변수 안내

서버가 토큰·API 키를 요구하면 다음을 기록한다:
- 필요한 환경변수 이름 (예: `GITHUB_PERSONAL_ACCESS_TOKEN`)
- 토큰 발급 위치 (1차 출처 README 또는 해당 서비스 공식 페이지 URL)
- 보관 위치 선택지:
  - `.claude/settings.local.json` (gitignored, 프로젝트 단위 개인 설정)
  - OS 환경변수 (`~/.bashrc`·`~/.zshrc`·Windows 시스템 환경변수)
  - **절대 `settings.json` (VCS 커밋 대상)에는 평문으로 두지 않는다**
- `.mcp.json` 의 `env`/`headers` 에는 `${VAR}` 참조만 두어야 함을 1줄 명시

#### 7-5. 비밀값 패턴 자체 점검

생성한 스니펫과 명령 문자열에 다음 패턴이 평문으로 들어가지 않았는지 산출물 작성 직전 자체 점검한다 (Phase 9 가 동일 점검을 재수행):
- `sk-`, `ghp_`, `AKIA`, `xoxb-`, `Bearer ` 다음에 토큰이 오는 패턴
- 발견 시 즉시 `${VAR}` 참조로 교체하고 7-4 에 해당 변수 발급 안내 추가

#### 7-6. 사용자 검증 단계 안내

`## MCP Servers` 섹션 말미에 사용자가 본인 환경에서 등록 후 동작을 확인할 절차를 1줄 명시:

```
> 설치 검증: 위 스니펫 또는 명령을 적용한 뒤 `claude mcp list` 로 추가된 서버가 ✓ Connected 상태인지 확인한다. 인증이 필요한 서버는 환경변수를 먼저 설정해야 한다.
```

### Step 8: Phase 9로 전환

훅 설계와 MCP 추천 산출물이 완료되면 Phase 9 검증으로 전환한다.
Phase 9는 산출물의 정적 정확성(출처·스니펫·비밀값)을 검증하며, 실제 등록 동작 검증은 사용자가 본인 환경에서 수행한다.

## Output Contract (필수 산출물 명세)

산출물 파일 `docs/{요청명}/06-hooks-mcp.md`에는 다음을 **반드시** 포함한다.

### 필수 섹션
- [ ] `## Summary` (~200단어)
- [ ] `## Hooks Installed` — 각 훅: 이벤트, matcher, 스크립트 경로, 목적
- [ ] `## MCP Servers` — **추천 후보 목록 + 각 항목의 메타·스니펫·명령·환경변수 안내·출처**. 등록 실행 내역이 아님. 각 항목에 7-1 ~ 7-6 의 정보가 모두 포함되어야 한다. 0건이면 섹션 헤더를 유지하고 본문에 `없음`으로 명시한다 — 섹션 자체 생략 금지(`validate-phase-artifact.sh` false positive 방지).
- [ ] `## Settings.json Changes` — **섹션 헤더명은 그대로 유지**. 본문을 두 하위 블록으로 분리:
  - `### Hooks (settings.json)` — `.claude/settings.json` hooks 섹션 변경 diff 요약
  - `### MCP (사용자 적용 가이드)` — MCP는 `settings.json` 대상이 아니므로 이 블록은 "사용자가 적용할 스니펫·명령 모음" 으로 사용한다. project 스코프 후보의 `.mcp.json` 병합 스니펫과 local/user 스코프 후보의 `claude mcp add` 명령을 후보별로 묶어 기재한다. 추천 0건이면 `없음` 명시.
- [ ] `## Verification Targets` — Phase 9가 검증할 파일 목록 (산출물 자체 + 훅 파일·settings.json). MCP 는 사용자 환경에 등록되지 않으므로 검증 대상에서 제외.
- [ ] `## Context for Next Phase` — Phase 9가 필요한 정보:
  - 설치된 훅 파일 경로 + 실행 권한 상태
  - **MCP 추천 후보 목록 (등록 여부 아님)** + 각 후보의 출처 URL
  - 검증 대상 파일 목록 (훅, settings.json, 규칙, 에이전트, 스킬)
- [ ] `## Files Generated`
- [ ] `## Escalations`
- [ ] `## Next Steps` — "Phase 9: phase-validate 에이전트 소환 권장. MCP 추천 후보를 사용자가 본인 환경에 등록 후 `claude mcp list` 로 동작 확인 권장."

### 대상 프로젝트 반영
- `.claude/hooks/*.sh` — 훅 스크립트 파일 (해당 시)
- `.claude/settings.json` 업데이트 — hooks 섹션만 (MCP는 `settings.json`에 쓰지 않음)
- **MCP 등록 파일은 본 Phase에서 작성하지 않는다** — `.mcp.json` 생성·수정, `~/.claude.json` 편집, `claude mcp add` 실행 모두 사용자 책임. 산출물의 스니펫·명령이 곧 사용자 적용 가이드다.
- 동작 요약: "PreToolUse에서 X를 검증하고, PostToolUse에서 Y를 실행합니다. MCP는 추천 {N}건이 산출물에 기록되어 있으며 사용자가 본인 환경에 적용합니다."

## Guardrails
- 모든 훅/MCP 결정은 Escalations에 기록. 묻지 않고 추천하지 않음.
- MCP 후보가 1건 이상이면 반드시 `[ASK]`로 기록한다 (`[NOTE]` 금지) — 사용자 결정 없이 흘려보내지 않는다.
- **Phase 8 에이전트는 MCP 등록을 실행하지 않는다** — `claude mcp add` 호출, `.mcp.json` 생성·수정, `~/.claude.json` 편집 모두 금지. 산출물 생성만 수행.
- 비밀값(API 키, 토큰)은 절대 산출물·스니펫·명령 어디에도 평문으로 포함하지 않음. `${VAR}` 환경변수 치환 참조만 사용. Step 7-5 자체 점검 의무.
- 추천한 패키지의 네임스페이스·1차 출처 URL을 산출물에 의무 기재 (Step 7-1). 출처 없는 추천 금지.
- 훅 스크립트 실행 시간 2초 이내 권장. 과도한 검증은 개발 흐름을 방해.
- MCP 서버가 불필요(후보 0건 또는 사용자 전부 거절)하면 Phase 8 추천 단계 종료 — 단 `## MCP Servers` 섹션은 `없음`으로 명시하고 Phase 전환 알림에 결과를 1줄 노출한다.
