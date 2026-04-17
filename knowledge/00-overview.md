<!-- File: 00-overview.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 1 -->
## SECTION 1: Claude Code 지침 시스템 개요

### 1.1 설계 철학: "지침(Context) vs 설정(Config)" 이원 분리

Claude Code의 지침 시스템은 두 가지 근본적으로 다른 메커니즘으로 나뉜다. 이 이원 분리를 정확히 이해하지 못하면 하네스 설계 시 "왜 Claude가 말을 안 듣는가"와 "왜 Claude가 도구를 못 쓰는가"를 혼동하게 된다.

#### 지침(Context) 계열 파일

| 파일 유형 | 대표 파일 | 적용 방식 |
|-----------|-----------|-----------|
| CLAUDE.md | `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` | 시스템 프롬프트에 텍스트로 주입 |
| Rules | `rules/*.md` | 조건부/무조건부로 시스템 프롬프트에 주입 |
| Skills | `skills/*/SKILL.md` | 슬래시 명령이나 트리거 시 시스템 프롬프트에 주입 |
| Memory | `memory/MEMORY.md`, `memory/*.md` | 세션 시작 시(인덱스) 또는 온디맨드(토픽) |

**핵심 특성**: Claude가 프롬프트 컨텍스트로 **읽고 따르려고 노력(best-effort)**하는 정보다. LLM의 본질적 한계로 인해 100% 준수가 보장되지 않는다. 지침이 길수록, 상충하는 내용이 많을수록 준수율이 떨어진다. 이것은 Cursor의 `.cursorrules`, `AGENTS.md`, `.cursor/rules/*.mdc` 파일들이 작동하는 방식과 동일한 패러다임이다.

#### 설정(Config) 계열 파일

| 파일 유형 | 대표 파일 | 적용 방식 |
|-----------|-----------|-----------|
| Settings | `settings.json`, `settings.local.json`, `managed-settings.json` | 클라이언트 런타임이 파싱하여 강제 적용 |

**핵심 특성**: Claude Code CLI 클라이언트가 **코드 레벨에서 강제 적용(hard enforcement)**한다. `permissions.deny`에 등록된 명령은 Claude가 아무리 실행하려 해도 클라이언트가 차단한다. 환경 변수(`env`)는 프로세스 환경에 직접 주입된다. 모델 선택(`model`)은 API 호출 파라미터를 결정한다. 이것들은 LLM의 판단과 무관하게 기계적으로 작동한다.

#### 왜 이 구분이 하네스 설정에 중요한가

1. **보안 정책은 반드시 Config(settings.json)의 `deny`로 구현해야 한다.** CLAUDE.md에 "절대 `rm -rf /`를 실행하지 마"라고 써도 LLM이 무시할 수 있다. `permissions.deny: ["Bash(rm -rf /)"]`는 물리적으로 차단된다.

2. **코딩 스타일, 작업 철학, 프로젝트 맥락은 Context(CLAUDE.md/rules)에 넣어야 한다.** settings.json에는 이런 자유형 텍스트를 넣을 곳이 없다.

3. **자동화 워크플로우(매번 X 전에 Y를 실행)는 Hooks로 구현해야 한다.** CLAUDE.md에 "파일 저장 전에 lint를 돌려"라고 써도 Claude가 잊을 수 있지만, `PreToolUse` 훅은 매번 실행된다. 훅은 settings.json의 `hooks` 필드에 설정한다.

4. **환경 변수, 프록시, 모델 선택은 Config에서만 제어 가능하다.** CLAUDE.md에 "opus 모델을 사용해"라고 써도 실제 모델 선택에 영향을 주지 못한다.

```
[하네스 설계 의사결정 트리]

"이 규칙이 위반되면 어떤 결과가 발생하는가?"
  │
  ├── 보안 사고 또는 시스템 장애 → settings.json의 permissions.deny
  ├── 자동화가 누락되면 품질 저하 → settings.json의 hooks
  ├── 코드 품질·스타일 저하 → CLAUDE.md 또는 rules/*.md
  └── 맥락 부족으로 비효율 → CLAUDE.md의 @import 참조 또는 memory
```

### 1.2 Cursor 생태계와의 대응 관계

| Cursor 개념 | Claude Code 대응 | 비고 |
|-------------|-------------------|------|
| `.cursorrules` (deprecated) | `CLAUDE.md` (프로젝트 루트) | 1:1 대응 |
| `AGENTS.md` | `CLAUDE.md` (프로젝트 루트) | 동일 역할 |
| `.cursor/rules/*.mdc` (alwaysApply) | `.claude/rules/*.md` (프론트매터 없음) | 확장자만 `.md`로 변경 |
| `.cursor/rules/*.mdc` (glob 기반) | `.claude/rules/*.md` (`paths:` 프론트매터) | `glob:` -> `paths:` |
| Global User Settings | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` | Context와 Config 분리 |
| Cursor Settings (JSON) | `~/.claude/settings.json` | 필드 구조 상이 |
| `workflow-skill-bindings` | `.claude/skills/*/SKILL.md` | YAML 프론트매터 기반 |
| 없음 (Cursor에 대응 없음) | Managed Scope (`/etc/claude-code/`) | 조직 정책 강제. Cursor에 없는 개념 |
| 없음 (수동 session_handoff) | Auto Memory (`~/.claude/projects/`) | Claude가 자동 축적 |

---

