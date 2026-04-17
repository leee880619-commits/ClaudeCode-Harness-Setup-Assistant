<!-- File: 11-anti-patterns.md | Source: Derivative commentary based on Claude Code documentation (https://docs.claude.com/en/docs/claude-code). Original section mapping: 11-B -->
## SECTION 11-B: Claude Code 하네스 안티패턴

에이전트가 감지하고 교정할 수 있어야 하는 안티패턴 목록.

### 11-B.1 CRITICAL 안티패턴

**CLAUDE.md 200줄 초과**
- 증상: 하나의 CLAUDE.md에 모든 지침이 밀집
- 원인: rules/ 분리를 모름, 초기 설정 후 지속적 추가
- 교정: 주제별로 rules/*.md로 분리, CLAUDE.md는 핵심만 유지
- 기준: 200줄 초과 시 경고, 300줄 초과 시 필수 분리

**sudo rm:* 전역 allow**
- 증상: ~/.claude/settings.json에 sudo rm:* 허용
- 원인: 한 번의 필요로 영구 허용 추가 후 방치
- 교정: 특정 경로로 제한 (sudo rm /tmp/*) 또는 프로젝트 레벨로 이동
- 위험: 시스템 파일 삭제 가능

**Bash(*) 전역 allow**
- 증상: permissions.allow에 Bash(*) 패턴
- 원인: 편의를 위해 모든 명령 허용
- 교정: 필요한 명령만 개별 allow 등록
- 위험: 모든 셸 명령이 확인 없이 실행

### 11-B.2 HIGH 안티패턴

**settings.local.json 과도 축적**
- 증상: settings.local.json이 50KB 이상
- 원인: 세션마다 "Allow once" → "Allow always" 선택이 누적
- 교정: 정기적 감사, 불필요한 항목 정리, 필요한 항목은 settings.json으로 이동
- 기준: 10KB 이상 시 경고, 50KB 이상 시 필수 정리

**유저 레벨 settings.local.json 존재**
- 증상: ~/.claude/settings.local.json 파일 존재
- 원인: 프로젝트 레벨과 유저 레벨의 구분 혼동
- 교정: 내용을 ~/.claude/settings.json에 병합 후 삭제

**deny 목록 없음**
- 증상: settings.json에 permissions.deny가 없거나 빈 배열
- 원인: 초기 설정 시 deny 미구성
- 교정: 최소 deny 목록 추가: rm -rf /, sudo rm *, git push --force *
- 위험: 위험 명령이 무제한 실행

**path-scoped 규칙의 패턴이 실제 구조와 불일치**
- 증상: paths: ["server/**"] 이지만 server/ 디렉터리가 없음
- 원인: 프로젝트 구조 변경 후 규칙 미갱신
- 교정: 규칙의 paths 패턴과 실제 디렉터리 매칭 검증

### 11-B.3 MEDIUM 안티패턴

**유저 전역 CLAUDE.md 없음**
- 증상: ~/.claude/CLAUDE.md 미존재
- 원인: 초기 설정 미완료
- 교정: 개인 코딩 원칙, Git 컨벤션, 언어/인코딩 규칙 작성
- 영향: 모든 프로젝트에서 일관된 개인 지침 부재

**유저 전역 rules/ 없음**
- 증상: ~/.claude/rules/ 디렉터리 미존재 또는 비어있음
- 원인: 초기 설정 미완료
- 교정: git-safety.md, korean-encoding.md 등 공통 규칙 생성

**프로젝트 CLAUDE.md 없음**
- 증상: 프로젝트 루트에 CLAUDE.md 없음
- 원인: 프로젝트 설정 미완료
- 교정: 프로젝트 분석 후 CLAUDE.md 생성
- 영향: Claude가 프로젝트 맥락 없이 일반적 응답만 제공

**비밀값이 settings.json에 포함**
- 증상: API 키, 토큰이 git-committed 파일에 존재
- 원인: env 필드에 직접 입력
- 탐지 패턴: sk-, ghp_, gho_, AKIA, xoxb-, glpat-, Bearer
- 교정: settings.local.json(gitignored)으로 이동 또는 환경변수 사용

### 11-B.4 LOW 안티패턴

**Memory 미활용**
- 증상: Auto Memory 비활성화 또는 MEMORY.md 없음
- 원인: 기능 미인지 또는 의도적 비활성화
- 교정: Auto Memory 활성화 안내
- 영향: 세션 간 연속성 상실, 같은 실수 반복

**@import 미활용**
- 증상: CLAUDE.md가 200줄에 근접하지만 @import 없음
- 원인: @import 기능 미인지
- 교정: 코드맵, 설계 문서 등을 @import로 분리
- 효과: CLAUDE.md 간결화 + 풍부한 컨텍스트 유지

**.gitignore 누락**
- 증상: CLAUDE.local.md 또는 settings.local.json이 .gitignore에 없음
- 원인: 하네스 설정 시 누락
- 교정: .gitignore에 추가
- 영향: 개인 설정이 팀 저장소에 커밋될 수 있음

### 11-B.5 불가능한 기능 (Claude Code 제한사항)

에이전트가 "할 수 있다"고 약속하면 안 되는 기능:

| 요청 | 왜 불가능 | 대안 |
|------|---------|------|
| 세션 시작 훅 | Claude Code에 session_start 이벤트 없음 | Auto Memory로 대체 |
| 실시간 파일 감시 | Claude Code가 filesystem watcher 아님 | PostToolUse 훅으로 변경 감지 |
| GUI 조작 | Claude Code는 CLI 도구 | Playwright/Puppeteer 스킬로 우회 |
| 다른 AI 모델 호출 | Claude Code는 Claude 전용 | MCP 서버로 외부 API 호출 가능 |
| 사용자 파일 자동 백업 | Stop 훅은 완료 시점이지 저장 시점이 아님 | PostToolUse(Write) 훅으로 백업 |
