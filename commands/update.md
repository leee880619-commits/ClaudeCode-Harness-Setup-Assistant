---
description: 설치된 harness-architect 버전을 확인하고, 새 버전이 있으면 변경사항과 함께 안내한다.
---

아래 절차를 순서대로 실행하세요. AskUserQuestion 없이 정보를 수집하고 결과를 출력합니다.

## 실행 절차

### Step 1 — 현재 설치 버전 확인

`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` 을 읽어 `version` 필드를 추출합니다.

`CLAUDE_PLUGIN_ROOT` 환경변수가 없거나 파일이 없으면:
> "harness-architect 플러그인 경로를 찾을 수 없습니다. `claude --plugin-dir` 옵션으로 실행 중인지 확인하세요."
를 출력하고 종료합니다.

### Step 2 — GitHub 최신 릴리즈 조회

아래 명령을 실행합니다:

```bash
curl -sf --max-time 5 \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/latest"
```

실패(네트워크 오류, 타임아웃)하면:
> "GitHub에 연결할 수 없습니다. 네트워크 상태를 확인하세요."
를 출력하고 종료합니다.

응답에서 `tag_name`(최신 버전)과 `body`(릴리즈 노트)를 추출합니다.
`tag_name` 앞의 `v` 접두어는 제거해 순수 semver(예: `0.9.1`)로 정규화합니다.

### Step 3 — 버전 비교 및 결과 출력

**최신 버전 ≤ 현재 버전인 경우:**

```
harness-architect v{현재버전} — 최신 버전입니다.
```

**최신 버전 > 현재 버전인 경우:**

아래 형식으로 출력합니다:

```
harness-architect 업데이트 available

  설치됨:  v{현재버전}
  최신:    v{최신버전}

변경사항:
{릴리즈 노트 body — 마크다운 그대로 출력, 최대 30줄}

업데이트하려면:
  /plugin update harness-architect
```

릴리즈 노트가 30줄을 초과하면 30줄만 출력 후 "... (전체 내용: GitHub Releases 참조)" 를 추가합니다.

### Step 4 — 캐시 무효화 (업데이트 있을 때만)

업데이트가 있는 경우, 아래 명령으로 check-update 캐시를 삭제합니다.
(삭제 후 다음 세션 시작 시 최신 버전이 즉시 반영되도록)

```bash
rm -f "/tmp/harness-architect-update-check-$(id -u 2>/dev/null || echo 0)" 2>/dev/null || true
```
