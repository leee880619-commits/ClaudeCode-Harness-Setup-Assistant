<!-- File: 10-agent-design.md | Source: architecture-report Section 11 -->
## SECTION 11: 하네스 환경 세팅 에이전트 설계 명세

### 11.0 서브에이전트 모델 정책

이 도구(Harness Setup Assistant)의 모든 Phase 서브에이전트와 Red-team Advisor는 **opus**로 실행한다.
각 Phase의 설계 품질이 대상 프로젝트의 전체 수명에 걸쳐 영향을 미치므로, 목적 기반 역추론 능력이 필요하다.
대상 프로젝트용 에이전트 모델 선택은 사용자에게 질문하여 결정한다 (이 도구의 정책과 혼동 금지).

### 11.1 에이전트 목적

하네스 환경 세팅 에이전트(이하 "Harness Agent")는 사용자의 프로젝트를 분석하여 Claude Code가 최적의 성능을 발휘할 수 있는 지침 환경(하네스)을 구축하는 것을 목적으로 한다.

**핵심 가치:**
- **분석 기반**: 추측이 아닌 실제 프로젝트 구조 분석에 기반한 설계
- **최소 마찰**: 사용자의 기존 워크플로우를 최대한 존중하며 점진적 도입
- **완전성 보장**: 4개 스코프(Managed, User, Project, Local) 전부를 고려한 완전한 구성
- **전환 지원**: Cursor/Copilot 등 기존 AI 도구 구성이 있으면 자동 변환

**대상 시나리오:**

| 시나리오 | 설명 | 복잡도 |
|---------|------|-------|
| 신규 프로젝트 | 아무 것도 없는 상태에서 하네스 구축 | 중 |
| 기존 프로젝트 (무구성) | 프로젝트는 있지만 Claude Code 구성 없음 | 중 |
| Cursor 전환 | Cursor 구성을 Claude Code로 변환 | 상 |
| 하네스 감사 | 기존 Claude Code 구성의 문제점 진단/개선 | 중 |
| User Scope 초기화 | 전역 사용자 설정 구축 (프로젝트 무관) | 하 |

### 11.2 에이전트 워크플로우

#### Step 1: 환경 진단 (Diagnosis)

**목적:** 현재 상태를 완전히 파악하여 "무엇이 있고 무엇이 없는지" 명확히 한다.

**1.1 User Scope 스캔:**
```bash
# 존재 여부 확인
ls -la ~/.claude/CLAUDE.md
ls -la ~/.claude/settings.json
ls -la ~/.claude/settings.local.json    # 비표준 위치 감지
ls -la ~/.claude/rules/
ls -la ~/.claude/skills/
ls -la ~/.claude/agents/                # 커스텀 서브에이전트 정의
ls -la ~/.claude/projects/              # Auto Memory 디렉토리

# 내용 분석 (존재하는 경우)
cat ~/.claude/settings.json | jq .       # JSON 유효성 + 내용 확인
wc -l ~/.claude/CLAUDE.md               # 줄 수 확인 (200줄 초과 여부)
du -sh ~/.claude/settings.json           # 파일 크기 확인
```

**1.2 Managed Scope 스캔:**
```bash
ls -la /etc/claude-code/CLAUDE.md
ls -la /etc/claude-code/managed-settings.json
ls -la /etc/claude-code/managed-settings.d/
```

**1.3 Project Scope 스캔:**
```bash
# 프로젝트 루트 기준
ls -la CLAUDE.md
ls -la CLAUDE.local.md
ls -la .claude/settings.json
ls -la .claude/settings.local.json
ls -la .claude/rules/
ls -la .claude/skills/
ls -la .claude/agents/                   # 커스텀 서브에이전트 정의

# 크기 및 줄 수 확인
wc -l CLAUDE.md                          # 200줄 초과?
du -sh .claude/settings.local.json       # 비대화?
find .claude/rules/ -name "*.md" | wc -l # 규칙 수
find .claude/skills/ -name "SKILL.md" | wc -l # 스킬 수
```

**1.4 기존 AI 도구 구성 감지:**
```bash
# Cursor
ls -la .cursor/rules/*.mdc
ls -la .cursor/mcp.json
ls -la .cursor/hooks.json
ls -la AGENTS.md
ls -la .agents/skills/

# 기타
ls -la .cursorrules
ls -la .github/copilot-instructions.md
ls -la .windsurfrules
ls -la .aider*
```

**1.5 진단 보고서 생성:**

진단 보고서는 다음 형식으로 출력:

```markdown
# Claude Code 하네스 환경 진단 보고서

## 현재 상태 요약
| 스코프 | 구성 상태 | 건강도 |
|--------|---------|--------|
| Managed | 없음 (개인 사용) | 정상 |
| User | 부분 구성 | ⚠️ 개선 필요 |
| Project | 미구성 | ❌ 즉시 조치 |
| Local | 미구성 | 대기 |

## 발견된 문제
1. [심각도] 문제 설명 — 영향 — 권장 조치
2. ...

## 기존 AI 도구 구성
- Cursor: .cursor/rules/ 에 12개 .mdc 파일 발견 → 변환 가능
- Copilot: .github/copilot-instructions.md 발견 → 참조 가능

## 권장 액션 플랜
1. (우선순위 순)
```

#### Step 2: 프로젝트 분석 (Analysis)

**목적:** 프로젝트의 기술적 특성을 파악하여 하네스 설계의 기초 데이터를 수집한다.

**2.1 프로젝트 구조 분석:**
```bash
# 디렉토리 트리 (깊이 3까지)
find . -maxdepth 3 -type d | head -100

# 주요 파일 유형 분포
find . -type f -name "*.js" | wc -l
find . -type f -name "*.ts" | wc -l
find . -type f -name "*.py" | wc -l
find . -type f -name "*.go" | wc -l
find . -type f -name "*.rs" | wc -l
find . -type f -name "*.java" | wc -l
find . -type f -name "*.md" | wc -l

# 프로젝트 크기
find . -type f | wc -l
du -sh .
```

**2.2 기술 스택 식별:**
```bash
# 패키지 매니저 / 의존성
cat package.json | jq '.dependencies, .devDependencies' 2>/dev/null
cat requirements.txt 2>/dev/null
cat pyproject.toml 2>/dev/null
cat Cargo.toml 2>/dev/null
cat go.mod 2>/dev/null
cat pom.xml 2>/dev/null
cat Gemfile 2>/dev/null

# 프레임워크 감지
grep -l "react" package.json 2>/dev/null
grep -l "next" package.json 2>/dev/null
grep -l "express" package.json 2>/dev/null
grep -l "django" requirements.txt 2>/dev/null
grep -l "flask" requirements.txt 2>/dev/null

# 빌드 도구
ls -la Makefile webpack.config.* vite.config.* tsconfig.json .babelrc 2>/dev/null
ls -la Dockerfile docker-compose.yml 2>/dev/null
```

**2.3 프로젝트 유형 판별:**

| 탐지 신호 | 프로젝트 유형 | 하네스 전략 |
|----------|-------------|-----------|
| `src/index.html` + Canvas API 사용 | 웹 게임 | 게임 로직/렌더링 분리 규칙, 성능 규칙 |
| `src/app/` + React/Next | 웹 앱 | 컴포넌트 규칙, 상태 관리 규칙 |
| `bin/` + CLI argument parsing | CLI 도구 | 입출력 규칙, 에러 처리 규칙 |
| `lib/` + `test/` + `package.json` "main" | 라이브러리 | API 호환성 규칙, 문서 규칙 |
| `server/` + `client/` | 클라이언트-서버 | 프로토콜 규칙, 동기화 규칙 |
| `packages/` + `lerna.json`/`pnpm-workspace.yaml` | 모노레포 | 패키지별 CLAUDE.md, 의존성 규칙 |
| `.ipynb` 파일들 | 데이터/연구 | 실험 추적 규칙, 데이터 안전 규칙 |

**2.4 Git 구성 분석:**
```bash
cat .gitignore
git log --oneline -20                    # 커밋 메시지 스타일 파악
git branch -a                            # 브랜치 전략 파악
git remote -v                            # 원격 저장소 확인
```

**2.5 팀 규모 및 협업 패턴 추정:**
```bash
git log --format='%aN' | sort -u | wc -l  # 기여자 수
ls -la .github/PULL_REQUEST_TEMPLATE.md    # PR 템플릿
ls -la .github/CODEOWNERS                 # 코드 소유자
ls -la .eslintrc* .prettierrc* .editorconfig # 코드 스타일 도구
```

#### Step 3: 구조 설계 (Design)

**목적:** 분석 결과를 바탕으로 최적의 하네스 구조를 설계한다.

**3.1 CLAUDE.md 설계 원칙:**

```markdown
# CLAUDE.md 구조 템플릿

## 프로젝트 아이덴티티 (필수, 5줄 이내)
- 프로젝트명, 한 줄 설명
- 핵심 기술 스택

## 기술 스택 상세 (필수, 10줄 이내)
- 언어, 프레임워크, 빌드 도구
- 패키지 매니저, 테스트 도구

## 개발 원칙 (필수, 5-10개)
- 프로젝트 고유 원칙
- 코딩 스타일 가이드 요약

## 사전 확인 필요 사항 (권장)
- 위험도 높은 작업 목록

## 작업 워크플로우 (선택)
- 프로젝트 고유 개발 단계 정의

## @import 참조 (선택)
- 코드맵, 설계 문서 등 외부 참조

총 줄 수 제한: 200줄 이내 (초과 시 rules/로 분리)
```

**3.2 Rules 설계 원칙:**

```
Always-Apply 규칙 후보:
├── git-safety.md       — 모든 프로젝트에서 필수
├── test-policy.md      — 테스트 정책 (포트, 범위)
├── code-style.md       — 코딩 스타일 (ESLint/Prettier 규칙 요약)
└── dependency-mgmt.md  — 의존성 관리 정책

Path-Scoped 규칙 후보:
├── server-rules.md     — paths: ["server/**", "api/**", "backend/**"]
├── client-rules.md     — paths: ["client/**", "web/**", "frontend/**"]
├── test-rules.md       — paths: ["test/**", "**/*.test.*", "**/*.spec.*"]
├── config-rules.md     — paths: ["*.config.*", ".env*", "*.json"]
└── docs-rules.md       — paths: ["docs/**", "*.md"]
```

**3.3 Skills 설계 원칙:**

```
스킬 후보 식별 기준:
1. 프로젝트 내 독립적 도메인이 있는가? → 도메인별 스킬
2. 반복적 워크플로우가 있는가? → 워크플로우 스킬
3. 전문 지식이 필요한 영역이 있는가? → 전문가 스킬

예시 매핑:
  웹 게임 프로젝트:
    → tech-lead (아키텍처 분석)
    → gameplay (게임 로직)
    → rendering (렌더링 최적화)
    → netcode (네트워크, 해당 시)
    → qa-whitebox (코드 QA)
    → qa-blackbox (실행 QA)

  웹 앱 프로젝트:
    → tech-lead (아키텍처)
    → frontend (UI/UX 구현)
    → backend (API/서버)
    → database (스키마/쿼리)
    → qa (테스트)

  CLI 도구 프로젝트:
    → architect (설계)
    → implementation (구현)
    → qa (테스트)
```

**3.4 Settings 설계 원칙:**

```json
{
  "permissions": {
    "allow": [
      // 프로젝트에 필요한 최소 권한만
      "Bash(npm run *)",
      "Bash(node *)",
      "Bash(git add:*)",
      "Bash(git commit:*)"
    ],
    "deny": [
      // 위험한 명령 명시적 차단
      "Bash(rm -rf /)",
      "Bash(git push --force *)",
      "Bash(sudo rm *)"
    ]
  },
  "env": {
    // 프로젝트 환경변수
    "NODE_ENV": "development",
    "PORT": "3000"
  },
  "hooks": {
    // 프로젝트에 필요한 훅만
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'quality gate placeholder'"
          }
        ]
      }
    ]
  }
}
```

#### Step 4: 파일 생성 (Creation)

**목적:** 설계를 실제 파일로 구현한다. 모든 생성은 사용자 승인 하에 수행.

**4.1 생성 순서 (의존성 기반):**

```
1단계: 디렉토리 구조 생성
  mkdir -p .claude/rules
  mkdir -p .claude/skills/<domain>/

2단계: CLAUDE.md 생성 (최상위 지침)
  → 사용자에게 초안 제시 → 승인/수정 → 생성

3단계: settings.json 생성 (권한 및 설정)
  → JSON 유효성 검증 → 사용자에게 제시 → 승인 → 생성

4단계: rules/*.md 생성 (규칙 파일들)
  → 각 파일별 사용자 승인

5단계: skills/*/SKILL.md 생성 (스킬 파일들)
  → 각 스킬별 사용자 승인

6단계: 템플릿 파일 생성
  → CLAUDE.local.md 템플릿
  → .claude/settings.local.json 템플릿

7단계: .gitignore 업데이트
  → CLAUDE.local.md 추가
  → .claude/settings.local.json 추가
```

**4.2 검증 체크리스트 (각 파일 생성 시):**

```
[ ] JSON 파일: jq로 파싱 가능 여부
[ ] YAML frontmatter: 정상 파싱 여부 (paths 배열 등)
[ ] 경로 패턴: 실제 프로젝트 구조와 매칭 여부
[ ] 인코딩: UTF-8 (BOM 없음)
[ ] 줄 끝: LF (Windows에서도 Git이 처리하도록)
[ ] CLAUDE.md: 200줄 이내
[ ] @import: 참조 파일 존재 여부
[ ] 권한: deny가 allow보다 넓지 않은지 (의도치 않은 차단 방지)
```

#### Step 5: 검증 (Verification)

**목적:** 생성된 하네스가 정상 작동하는지 종합 검증한다.

**5.1 구문 검증:**
```bash
# JSON 파일 검증
jq . .claude/settings.json > /dev/null
jq . .claude/settings.local.json > /dev/null 2>&1

# YAML frontmatter 검증 (rules 파일)
for f in .claude/rules/*.md; do
  head -1 "$f" | grep -q "^---" && echo "frontmatter detected: $f"
done
```

**5.2 일관성 검증:**
```
[ ] settings.json의 deny가 allow를 무효화하지 않는지
[ ] path-scoped rules의 paths가 실제 디렉토리와 매칭되는지
[ ] @import 참조가 실제 파일을 가리키는지
[ ] skills 디렉토리 내 SKILL.md가 존재하는지
[ ] .gitignore에 CLAUDE.local.md와 settings.local.json이 포함되는지
```

**5.3 시뮬레이션 검증:**
```
"만약 사용자가 X를 요청하면, Claude는 어떤 파일을 참조하게 되는가?"
시나리오별로 파일 참조 체인을 추적하여 누락된 파일이 없는지 확인
```

**5.4 최종 보고서:**
```markdown
# 하네스 환경 검증 보고서

## 생성된 파일 목록
| 파일 | 크기 | 줄 수 | 유효성 |
|------|------|------|--------|
| CLAUDE.md | 4.2KB | 128줄 | ✓ |
| .claude/settings.json | 1.1KB | 45줄 | ✓ JSON |
| .claude/rules/git-safety.md | 0.8KB | 32줄 | ✓ |
| ... | ... | ... | ... |

## 검증 결과
- 구문 검증: PASS
- 일관성 검증: PASS
- 시뮬레이션 검증: PASS

## 다음 단계 안내
1. CLAUDE.local.md를 개인 취향에 맞게 편집하세요
2. 첫 세션에서 Claude에게 "현재 하네스 구성을 확인해줘"라고 요청하세요
3. ...
```

### 11.3 에이전트가 갖추어야 할 지식

Harness Agent가 정확하게 작동하기 위해 내장해야 하는 지식 영역:

#### 11.3.1 파일 명세 지식 (Section 4 기반)

```
필수 지식:
- 각 파일의 정확한 위치 (4개 스코프별)
- 각 파일의 포맷 (Markdown, JSON, YAML frontmatter)
- 각 파일의 크기 제한 (CLAUDE.md 200줄 권장, MEMORY.md 200줄/25KB 로딩)
- 각 파일의 Git 포함/제외 규칙
- settings.json의 모든 필드와 유효값 범위
- rules 파일의 frontmatter 스펙 (paths, description, alwaysApply)
- skills 파일의 SKILL.md 구조 (title, description, instructions)
- hooks의 matcher 패턴 문법 (glob 매칭)
```

#### 11.3.2 구성 규칙 지식 (Section 3 기반)

```
필수 지식:
- 4개 스코프의 계층 구조: Managed > User > Project > Local
- 병합 규칙: allow 합집합, deny 합집합, 구체적 allow > 일반적 deny
- 충돌 해결: Managed deny 불변, User/Project/Local은 아래가 우선
- settings 병합: 배열은 합산, 객체는 깊은 병합, 스칼라는 아래가 덮어씀
- env 병합: Project가 User를 덮어씀, Local이 최종
```

#### 11.3.3 로딩 순서 지식 (Section 9 기반)

```
필수 지식:
- 9단계 로딩 순서 정확히 암기
- always-apply vs path-scoped 분기 로직
- @import 해석 규칙 (상대 경로 기준점, 5홉 제한)
- on-demand 로딩 트리거 조건 (Read/Edit/Write)
- Memory 로딩 제한 (200줄/25KB)
- 디렉토리 워크업 로직 (cwd → root)
```

#### 11.3.4 베스트 프랙티스 지식 (Section 6-7 기반)

```
필수 지식:
- 실제 프로젝트의 하네스 패턴 (Co-optris, GUI2WEBAPP 등)
- 효과적인 CLAUDE.md 구조 (아이덴티티 → 스택 → 원칙 → 워크플로우)
- 규칙 분리 기준 (always-apply vs path-scoped)
- 스킬 설계 기준 (도메인 분리, 워크플로우 캡슐화)
- 훅 설계 패턴 (PreToolUse 가드, PostToolUse 게이트)
- Memory 활용 패턴 (인덱스 + 토픽 구조)
```

#### 11.3.5 변환 규칙 지식 (Section 8 기반)

```
필수 지식:
- Cursor .mdc → Claude Code .md 변환 규칙
- AGENTS.md → CLAUDE.md 변환 규칙
- .agents/skills/ → .claude/skills/ 변환 규칙
- Cursor hooks → Claude Code hooks 변환 규칙
- MCP 설정 변환 규칙
- session-continuity → Auto Memory 변환 전략
```

#### 11.3.6 안티패턴 지식

에이전트는 다음 안티패턴을 감지하고 교정할 수 있어야 한다:

```
[CRITICAL] CLAUDE.md 200줄 초과
  증상: 하나의 CLAUDE.md에 모든 지침이 밀집
  원인: rules/ 분리를 모름, 초기 설정 후 지속적 추가
  교정: 주제별로 rules/*.md로 분리, CLAUDE.md는 핵심만 유지
  기준: 200줄 초과 시 경고, 300줄 초과 시 필수 분리

[CRITICAL] sudo rm:* 전역 allow
  증상: ~/.claude/settings.json에 sudo rm:* 허용
  원인: 한 번의 필요로 영구 허용 추가 후 방치
  교정: 특정 경로로 제한 (sudo rm /tmp/*) 또는 프로젝트 레벨로 이동
  위험: 시스템 파일 삭제 가능

[HIGH] settings.local.json 과도 축적
  증상: settings.local.json이 50KB 이상
  원인: 세션마다 "Allow once" → "Allow always" 선택이 누적
  교정: 정기적 감사, 불필요한 항목 정리, 필요한 항목은 settings.json으로 이동
  기준: 10KB 이상 시 경고, 50KB 이상 시 필수 정리

[HIGH] 유저 레벨 settings.local.json 존재
  증상: ~/.claude/settings.local.json 파일 존재
  원인: 프로젝트 레벨과 유저 레벨의 구분 혼동
  교정: 내용을 ~/.claude/settings.json에 병합 후 삭제

[MED] 유저 전역 CLAUDE.md 없음
  증상: ~/.claude/CLAUDE.md 미존재
  원인: 초기 설정 미완료
  교정: 개인 코딩 원칙, Git 컨벤션, 언어/인코딩 규칙 작성
  영향: 모든 프로젝트에서 일관된 개인 지침 부재

[MED] 유저 전역 rules/ 없음
  증상: ~/.claude/rules/ 디렉토리 미존재 또는 비어있음
  원인: 초기 설정 미완료
  교정: git-safety.md, korean-encoding.md 등 공통 규칙 생성

[MED] 프로젝트 CLAUDE.md 없음
  증상: 프로젝트 루트에 CLAUDE.md 없음
  원인: 프로젝트 설정 미완료
  교정: 프로젝트 분석 후 CLAUDE.md 생성
  영향: Claude가 프로젝트 맥락 없이 일반적 응답만 제공

[LOW] Memory 미활용
  증상: Auto Memory 비활성화 또는 MEMORY.md 없음
  원인: 기능 미인지 또는 의도적 비활성화
  교정: Auto Memory 활성화 안내, 초기 MEMORY.md 부트스트랩
  영향: 세션 간 연속성 상실, 같은 실수 반복

[LOW] @import 미활용
  증상: CLAUDE.md가 200줄에 근접하지만 @import 없음
  원인: @import 기능 미인지
  교정: 코드맵, 설계 문서 등을 @import로 분리
  효과: CLAUDE.md 간결화 + 풍부한 컨텍스트 유지

[INFO] .gitignore 누락
  증상: CLAUDE.local.md 또는 settings.local.json이 .gitignore에 없음
  원인: 하네스 설정 시 누락
  교정: .gitignore에 추가
  영향: 개인 설정이 팀 저장소에 커밋될 수 있음
```

### 11.4 에이전트 출력물 목록

각 출력물의 포맷, 필수 필드, 품질 기준을 명세한다.

#### 11.4.1 진단 보고서

```
파일명: (화면 출력, 파일 생성하지 않음)
포맷: Markdown 테이블 + 목록

필수 섹션:
1. 현재 상태 매트릭스 (스코프 × 파일 테이블)
2. 발견된 문제 목록 (심각도별 정렬)
3. 기존 AI 도구 구성 목록 (변환 가능 여부)
4. 권장 액션 플랜 (우선순위순)

품질 기준:
- 모든 4개 스코프를 빠짐없이 검사
- 파일 크기/줄 수 등 정량적 지표 포함
- 심각도 분류가 합리적 (보안 > 기능 > 편의)
- 액션 플랜이 구체적 (어떤 파일을, 어떻게)
```

#### 11.4.2 CLAUDE.md

```
파일명: <project-root>/CLAUDE.md
포맷: Markdown

필수 섹션:
1. 프로젝트 아이덴티티 (이름, 한 줄 설명)
2. 기술 스택 (언어, 프레임워크, 도구)
3. 개발 원칙 (5-10개, 프로젝트 고유)
4. 사전 확인 목록 (위험 작업 나열)

선택 섹션:
5. 작업 워크플로우 (단계별 프로세스)
6. @import 참조 (외부 문서 링크)
7. 디렉토리 구조 개요

품질 기준:
- 200줄 이내 (초과 시 rules/로 분리)
- 프로젝트 고유 정보만 (일반론 금지)
- @import는 실존 파일만 참조
- 원칙이 검증 가능 (모호한 "좋은 코드 작성" 금지)
```

#### 11.4.3 .claude/settings.json

```
파일명: <project-root>/.claude/settings.json
포맷: JSON (strict, trailing comma 불가)

필수 필드:
- permissions.allow: 프로젝트에 필요한 최소 권한
- permissions.deny: 위험 명령 차단 목록

선택 필드:
- env: 프로젝트 환경변수
- hooks: PreToolUse/PostToolUse 훅
- mcpServers: MCP 서버 구성

품질 기준:
- jq로 파싱 가능
- allow에 sudo rm 없음 (필요 시 구체적 경로만)
- deny가 allow를 불필요하게 차단하지 않음
- 훅 스크립트가 실존하고 실행 가능
- 환경변수에 비밀값(API 키 등) 없음
```

#### 11.4.4 .claude/rules/*.md

```
파일명: .claude/rules/<rule-name>.md
포맷: Markdown (선택적 YAML frontmatter)

Always-Apply 규칙:
- frontmatter 없음 또는 paths 키 없음
- 파일 크기: 50줄 이내 권장
- 주제 하나에 집중 (단일 책임)

Path-Scoped 규칙:
- YAML frontmatter 필수:
  ---
  paths:
    - "pattern1"
    - "pattern2"
  description: "규칙 설명"
  ---
- paths 패턴이 실제 디렉토리와 매칭
- 파일 크기: 100줄 이내 권장

품질 기준:
- 규칙이 구체적이고 실행 가능
- "~해야 한다" 형식 (검증 가능한 진술)
- 예시 코드 포함 시 실제 프로젝트 코드 기반
- 중복 규칙 없음 (다른 규칙 파일과)
```

#### 11.4.5 .claude/skills/*/SKILL.md

```
파일명: .claude/skills/<skill-name>/SKILL.md
포맷: Markdown

필수 구조:
# <스킬 이름>

## Description
(스킬이 무엇을 하는지 1-3문장)

## Instructions
(스킬 실행 시 Claude가 따라야 할 구체적 지침)
(단계별 프로세스, 참조 파일, 출력 포맷 등)

품질 기준:
- Description이 명확 (Claude가 "이 스킬이 필요한가" 판단 가능)
- Instructions가 구체적 (모호한 지시 금지)
- 프로젝트 도메인 지식 포함
- 독립적 실행 가능 (다른 스킬에 의존하지 않음)
```

#### 11.4.6 CLAUDE.local.md 템플릿

```
파일명: <project-root>/CLAUDE.local.md
포맷: Markdown

내용 (템플릿):
# 개인 오버라이드

## 개인 개발 환경
- OS: (Windows/macOS/Linux)
- 에디터: (VSCode/IntelliJ/etc)
- 터미널: (bash/zsh/PowerShell)

## 개인 선호
- (여기에 프로젝트 CLAUDE.md를 보충하거나 오버라이드할 내용 추가)

## 개인 주의사항
- (개인 환경에서만 적용되는 주의사항)

품질 기준:
- .gitignore에 포함되어 있는지 확인
- 템플릿에 실제 개인 정보가 없음 (예시만)
- 수정 방법 안내 주석 포함
```

#### 11.4.7 .claude/settings.local.json 템플릿

```
파일명: <project-root>/.claude/settings.local.json
포맷: JSON

내용 (템플릿):
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "env": {}
}

품질 기준:
- .gitignore에 포함되어 있는지 확인
- 비어있는 상태로 시작 (사용자가 필요에 따라 추가)
- JSON 유효성 확인
```

#### 11.4.8 검증 보고서

```
파일명: (화면 출력, 파일 생성하지 않음)
포맷: Markdown 테이블 + 체크리스트

필수 섹션:
1. 생성된 파일 목록 (경로, 크기, 줄 수, 유효성)
2. 구문 검증 결과 (JSON, YAML, Markdown)
3. 일관성 검증 결과 (권한 충돌, 경로 매칭)
4. 시뮬레이션 결과 (대표 시나리오 1-2개)
5. 다음 단계 안내

품질 기준:
- 모든 생성 파일 포함
- 검증 항목 전부 PASS/FAIL 명시
- 실패 항목에 대한 교정 방법 제시
```

### 11.5 Cursor → Claude Code 자동 변환 규칙

#### 11.5.1 .mdc → .md 변환

**파일 확장자 변경:** `.mdc` → `.md`

**Frontmatter 변환:**

```yaml
# Cursor .mdc 원본
---
description: 서버 파일 검증 규칙
globs:
  - "server/**/*.js"
  - "server/**/*.ts"
alwaysApply: false
---

# Claude Code .md 변환 결과
---
paths:
  - "server/**/*.js"
  - "server/**/*.ts"
description: 서버 파일 검증 규칙
---
```

**변환 규칙 상세:**

| Cursor 필드 | Claude Code 필드 | 변환 로직 |
|------------|-----------------|----------|
| `globs` | `paths` | 키 이름 변경, 값 동일 (glob 문법 호환) |
| `alwaysApply: true` | (frontmatter 제거) | alwaysApply=true면 frontmatter 자체를 제거 |
| `alwaysApply: false` | `paths` 필수 | globs → paths로 변환 |
| `description` | `description` | 동일 (선택적) |
| Cursor 전용 메타 | 삭제 | `priority`, `version` 등 Cursor 전용 필드 삭제 |

**`alwaysApply: true` 처리 예시:**

```yaml
# Cursor 원본 (.mdc)
---
description: Git 안전 규칙
alwaysApply: true
---

# Git 안전 규칙
- force push 금지
- main 직접 커밋 금지
```

```markdown
# Claude Code 변환 결과 (.md)
(frontmatter 없음 — always-apply로 자동 인식)

# Git 안전 규칙
- force push 금지
- main 직접 커밋 금지
```

#### 11.5.2 AGENTS.md → CLAUDE.md 변환

```
변환 규칙:
1. 파일명 변경: AGENTS.md → CLAUDE.md
2. 내부 참조 업데이트:
   - ".cursor/rules/" → ".claude/rules/"
   - ".agents/skills/" → ".claude/skills/"
   - "AGENTS.md" → "CLAUDE.md"
3. Cursor 전용 기능 참조 제거:
   - Composer 관련 지침 → 제거 또는 일반화
   - Tab completion 관련 → 제거
   - .cursorrules 참조 → 제거
4. Claude Code 기능으로 대체:
   - "Cursor Chat" → "Claude Code"
   - "Composer" → "Claude Code"
   - "Apply" → "Edit/Write 도구"
```

#### 11.5.3 .agents/skills/ → .claude/skills/ 변환

```
변환 규칙:
1. 디렉토리 이동: .agents/skills/ → .claude/skills/
2. SKILL.md 포맷 확인:
   - Cursor의 스킬 포맷이 Claude Code와 호환되는 경우 → 그대로 유지
   - 비호환 필드가 있는 경우 → 제거 또는 변환
3. 스킬 내부 참조 업데이트:
   - 경로 참조 수정 (.agents/ → .claude/)
   - 도구 참조 수정 (Cursor 전용 도구 → Claude Code 도구)
```

#### 11.5.4 .cursor/hooks.json → settings.json hooks 변환

```json
// Cursor hooks.json 원본
{
  "hooks": [
    {
      "event": "file_saved",
      "pattern": "*.js",
      "command": "eslint --fix ${file}"
    },
    {
      "event": "pre_edit",
      "command": "echo 'checking ownership'"
    }
  ]
}
```

```json
// Claude Code settings.json hooks 변환 결과
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "eslint --fix $CLAUDE_FILE_PATH"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'checking ownership'"
          }
        ]
      }
    ]
  }
}
```

**이벤트 매핑:**

| Cursor Event | Claude Code Event | 비고 |
|-------------|------------------|------|
| `file_saved` | `PostToolUse` (Write\|Edit) | 파일 저장 → 도구 사용 후 |
| `pre_edit` | `PreToolUse` (Write\|Edit) | 편집 전 → 도구 사용 전 |
| `pre_command` | `PreToolUse` (Bash) | 명령 실행 전 |
| `post_command` | `PostToolUse` (Bash) | 명령 실행 후 |
| `session_start` | (해당 없음) | Claude Code에 세션 시작 훅 없음 |
| `session_end` | (해당 없음) | Auto Memory로 대체 |

**변수 매핑:**

| Cursor 변수 | Claude Code 변수 | 비고 |
|------------|-----------------|------|
| `${file}` | `$CLAUDE_FILE_PATH` | 현재 파일 경로 |
| `${workspace}` | `$CLAUDE_PROJECT_DIR` | 프로젝트 루트 |
| `${language}` | (해당 없음) | 직접 감지 필요 |

#### 11.5.5 .cursor/mcp.json → Claude Code MCP 설정 변환

```json
// Cursor mcp.json 원본
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    }
  }
}
```

```json
// Claude Code settings.json에 병합
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    }
  }
}
```

MCP 서버 설정은 대부분 호환됨. 주의점:
- Cursor 전용 MCP 서버가 있는 경우 Claude Code 호환 대안으로 대체
- 인증 방식이 다를 수 있으므로 토큰/키 설정 확인 필요

#### 11.5.6 session-continuity.mdc → Auto Memory 부트스트랩

Cursor의 `session-continuity.mdc`는 세션 종료 시 핸드오프 파일 생성을 지시하는 규칙이다. Claude Code에서는 Auto Memory가 이를 자동화한다.

**변환 전략:**

```
Cursor 방식:
  session-continuity.mdc
    → 세션 종료 시 handoff-YYYYMMDD.md 생성 지시
    → 다음 세션 시작 시 최신 handoff 파일 읽기 지시

Claude Code 변환:
  1. session-continuity.mdc 삭제 (Auto Memory가 대체)
  2. 기존 handoff-*.md 파일에서 정보 추출
  3. 초기 MEMORY.md 생성:

     # Memory Index
     ## Topics
     - [project_context](project_context.md) — 프로젝트 아키텍처 및 현재 상태
     - [decisions](decisions.md) — 주요 결정 사항 이력
     - [feedback](feedback.md) — 사용자 피드백 반영 이력

  4. handoff 내용을 토픽 파일로 분배:
     - 아키텍처 관련 → project_context.md
     - 결정 사항 → decisions.md
     - 피드백 → feedback.md
```

#### 11.5.7 workflow-skill-bindings.mdc → CLAUDE.md @import + 스킬 연결

Cursor의 `workflow-skill-bindings.mdc`는 워크플로우 단계와 스킬을 매핑하는 규칙이다.

```yaml
# Cursor 원본 (workflow-skill-bindings.mdc)
---
description: 워크플로우-스킬 바인딩
alwaysApply: true
---

## 워크플로우 바인딩
- STEP 1 (Research) → tech-lead skill
- STEP 2 (Planning) → tech-lead skill + design-doc
- STEP 5 (Implementation) → gameplay skill
- STEP 6.0 (QA) → qa-whitebox skill
```

```markdown
# Claude Code 변환: CLAUDE.md에 직접 통합

## 작업 워크플로우
### STEP 1: Research
- `.claude/skills/tech-lead/SKILL.md` 활용
- @docs/architecture/code-map.md 참조

### STEP 2: Planning
- `.claude/skills/tech-lead/SKILL.md` 활용
- @docs/design/ 참조

### STEP 5: Implementation
- `.claude/skills/gameplay/SKILL.md` 활용

### STEP 6.0: White-box QA
- `.claude/skills/qa-whitebox/SKILL.md` 활용
```

**변환 로직:**
1. bindings 규칙의 매핑 정보 추출
2. CLAUDE.md의 워크플로우 섹션에 스킬 참조 삽입
3. bindings 규칙 파일 자체는 삭제 (CLAUDE.md에 통합되었으므로)
4. 스킬 참조가 `.claude/skills/` 경로를 정확히 가리키는지 확인

---

