
# User Scope Initialization

## 질문 소유권
이 스킬은 서브에이전트에서 실행된다. **AskUserQuestion 사용 금지**. Phase 2에 해당하는
Q1~Q9 답변은 오케스트레이터가 사전에 AskUserQuestion으로 수집하여 프롬프트로 전달한다.
스킬은 그 답변을 수신한다. 누락되거나 후속 확인이 필요한 사항은 Escalations에 기록한다.

## Goal
Set up the user-level Claude Code configuration that applies across ALL projects.

## Prerequisites
- The user's `~/.claude/` directory needs bootstrapping (missing CLAUDE.md or rules/)

## Knowledge References
Load ON-DEMAND with Read tool:
- `knowledge/01-scope-hierarchy.md` — Section 2.2: User Scope specification
- `knowledge/03-file-reference.md` — File format specs for user-level files

## Workflow

### Phase 1: Current State Scan

Scan `~/.claude/` and report:
- `CLAUDE.md` — exists? size?
- `settings.json` — exists? contents?
- `settings.local.json` — exists? (non-standard location, flag if found)
- `rules/` — exists? file count?
- `skills/` — exists? file count?
- `projects/` — how many project memory directories?

Present findings.

### Phase 2: Personal Preferences Questions

1. "주로 사용하는 OS는? (Windows/WSL, macOS, Linux)"
2. "자주 사용하는 프로그래밍 언어는? (여러 개 가능)"
3. "Claude의 응답 언어는? (한국어, English, 혼합)"
4. "Git 커밋 메시지 규칙이 있나요? (Conventional Commits, 한글 커밋 허용 여부)"
   - If Windows/WSL: "한글 커밋 시 인코딩 문제를 방지하는 규칙을 추가할까요?"
5. "모든 프로젝트에서 항상 차단해야 할 명령어가 있나요?"
6. "모든 프로젝트에서 자동 허용할 명령어가 있나요? (예: git status, npm test)"
7. "모든 프로젝트에 공통 적용할 코딩 원칙이 있나요? (예: 가독성 우선, TDD 등)"
8. "자동 메모리 기능을 활성화할까요? (세션 간 학습 자동 축적)"
9. "기본 모델은? (opus, sonnet, haiku) — 모르겠으면 건너뛰어도 됩니다."

### Phase 3: Generate User Config

Based on answers, generate:

1. **~/.claude/CLAUDE.md** — Personal coding principles:
   - Response language preference
   - Problem-solving philosophy (if Q7 had answers)
   - Git conventions (if Q4 had answers)
   - Common rules applicable to all projects

2. **~/.claude/settings.json** — Update or create:
   - model (from Q9, only if answered)
   - permissions.allow (from Q6)
   - permissions.deny (from Q5 + mandatory deny list)
   - autoMemoryEnabled (from Q8)

3. **~/.claude/rules/git-safety.md** — If Q4/Q5 had git-related answers:
   - Commit conventions
   - Forbidden git commands

4. **~/.claude/rules/korean-encoding.md** — If Q1 is Windows/WSL and Q4 mentions Korean:
   - UTF-8 file I/O requirement
   - git commit -F method for Korean messages
   - chcp 65001 verification

5. **~/.claude/rules/communication.md** — If Q3 had specific preferences:
   - Response language rules
   - Response style preferences

### Phase 4: Review & Write

Show each file, get approval, write.

### Phase 5: Cleanup Advice

If non-standard files were found:
- `~/.claude/settings.local.json` → Migrate useful settings to settings.json, then remove
- Oversized settings in project directories → Advise audit with /harness-audit

## Guardrails

- Never overwrite existing ~/.claude/settings.json without showing diff
- If settings.json already has content, MERGE rather than replace
- User-level rules should be UNIVERSAL, not project-specific
