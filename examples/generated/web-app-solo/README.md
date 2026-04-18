<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 예시: 솔로 React/Node 웹앱 (Fast Track)

이 디렉터리는 `harness-architect`가 솔로 React + Node.js 웹앱 프로젝트에 대해
Fast Track(10–15분)으로 생성한 하네스의 **공개용 참조 예시**입니다.

> 이 파일은 공개용으로 단순화된 참조 예시입니다. 실제 생성 결과는 프로젝트 스캔
> 결과와 인터뷰 답변에 따라 달라집니다.

## 생성 조건

| 항목 | 값 |
|------|----|
| 플러그인 버전 | v0.3.3 |
| 진행 경로 | Fast Track |
| 프로젝트 유형 | 웹 앱 |
| 솔로/팀 | 솔로 |
| 성능 수준 | 균형형 |
| 주요 기술 스택 | React, Node.js, Express, PostgreSQL |

## 포함된 파일

```
examples/generated/web-app-solo/
├── README.md               ← 이 파일
├── CLAUDE.md               ← 프로젝트 정체성·개발 원칙
├── settings.json           ← 권한·훅 구조
└── .claude/
    └── rules/
        └── dev-conventions.md  ← 항상 적용되는 코딩 규약
```

## 이 하네스를 활용하는 방법

프로젝트 디렉터리에서 `claude`를 실행하면:

1. `CLAUDE.md`가 자동 로딩되어 프로젝트 컨텍스트(기술 스택, 개발 원칙)가 주입됩니다.
2. `.claude/rules/dev-conventions.md`가 항상 적용되어 코딩 규약이 유지됩니다.
3. `settings.json`의 권한 설정으로 npm, git 등 자주 쓰는 명령어는 확인 없이 실행됩니다.

에이전트 프로젝트 예시는 `../agent-pipeline/` 디렉터리를 참조하세요.
