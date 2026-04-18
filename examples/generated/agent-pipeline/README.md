<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 예시: 멀티에이전트 리서치 파이프라인 (Fast-Forward)

이 디렉터리는 `harness-architect`가 멀티에이전트 딥 리서치 파이프라인 프로젝트에 대해
Fast-Forward 경로(30–40분)로 생성한 하네스의 **공개용 참조 예시**입니다.

> 이 파일은 공개용으로 단순화된 참조 예시입니다. 실제 생성 결과는 프로젝트 스캔
> 결과와 인터뷰 답변에 따라 달라집니다.

## 생성 조건

| 항목 | 값 |
|------|----|
| 플러그인 버전 | v0.3.3 |
| 진행 경로 | Fast-Forward (에이전트 파이프라인 감지) |
| 프로젝트 유형 | 에이전트 파이프라인 |
| 솔로/팀 | 솔로 |
| 성능 수준 | 균형형 |
| 핵심 도메인 | 딥 리서치 |

## 포함된 파일

```
examples/generated/agent-pipeline/
├── README.md                       ← 이 파일
├── CLAUDE.md                       ← 프로젝트 정체성·에이전트 팀 참조
├── settings.json                   ← 권한·WebSearch/WebFetch 허용
└── .claude/
    └── agents/
        └── researcher.md           ← 리서치 에이전트 정의 패턴
```

## 이 하네스를 활용하는 방법

프로젝트 디렉터리에서 `claude`를 실행하면:

1. `CLAUDE.md`가 자동 로딩되어 에이전트 팀 구조와 파이프라인 개요가 주입됩니다.
2. `Agent(subagent_type: "researcher")` 패턴으로 리서치 에이전트를 소환합니다.
3. `settings.json`의 `WebSearch`·`WebFetch` 허용으로 에이전트가 웹 검색을 수행합니다.

솔로 웹앱 예시는 `../web-app-solo/` 디렉터리를 참조하세요.
