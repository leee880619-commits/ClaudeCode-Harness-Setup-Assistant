# Meta-Leakage Guard

이 도구는 Claude Code 프로젝트를 생성하는 Claude Code 프로젝트다. 자기 자신의 행동 규칙이 생성 파일에 유출되지 않도록 한다.

## 생성 파일 금지 내용
- 이 도구의 행동 규칙 ("ask everything", "assume nothing" 등)
- Claude Code 아키텍처 설명 (4-Tier scope, composition rules)
- 이 도구 참조 ("Harness Setup Assistant", "setup agent")
- 메타 지시 ("question-discipline", "progressive disclosure")
- 한국어 금지어: "질문을 먼저", "가정하지 마세요", "하네스 에이전트"

## 생성 파일이 담아야 하는 것
대상 프로젝트의 정체성·기술 스택·개발 원칙(사용자 답변 기반)·관례·자체 문서 `@import`. 범용 Claude Code 사용법이 아닌 대상 프로젝트 고유 규칙만.

## Self-Check (Write 직전)
1. 이 도구를 모르는 사람에게도 의미가 있는가?
2. 개발자가 이 CLAUDE.md를 읽고 자기 프로젝트를 더 잘 이해하게 되는가?
3. "하네스 세팅" 맥락에서만 이해 가능한 내용이 있는가? → 있으면 제거.
