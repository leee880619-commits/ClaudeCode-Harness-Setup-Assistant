# 예시: 슬래시 커맨드 경로 인자 사용

**목적**: 대상 프로젝트 경로가 이미 확정된 상태에서 Phase 0의 "경로 입력" 질문을 생략하고, 인터뷰로 바로 진입한다.

## 시나리오

당신이 방금 `/path/to/my-dashboard` 에 새 프로젝트를 만들었고, 곧바로 하네스를 구축하려 한다. 터미널에서 `pwd` 를 확인할 필요 없이 경로를 슬래시 커맨드에 넣어 호출한다.

## 사용법

```
/harness-architect:harness-setup /path/to/my-dashboard
```

## 동작 차이

### 인자 없이 호출한 경우 (기본)

```
> /harness-architect:harness-setup

[AskUserQuestion: Phase 0]
  1. 대상 프로젝트 경로를 입력하세요.
  2. 프로젝트 이름 + 한 줄 설명은?
  3. 프로젝트 유형? (웹앱/CLI/에이전트/데이터/콘텐츠/기타)
  4. 솔로 / 팀?
```

### 인자로 경로를 넘긴 경우

```
> /harness-architect:harness-setup /path/to/my-dashboard

[오케스트레이터] 경로 확인됨: /path/to/my-dashboard → TARGET_PROJECT_ROOT export.

[AskUserQuestion: Phase 0]
  1. 프로젝트 이름 + 한 줄 설명은?
  2. 프로젝트 유형? (웹앱/CLI/에이전트/데이터/콘텐츠/기타)
  3. 솔로 / 팀?
```

경로 질문 1건이 사라져 인터뷰 시작이 빨라진다.

## 주의 사항

- 경로에 **공백이나 한글이 포함**된 경우 오케스트레이터가 절대 경로로 정규화해 `TARGET_PROJECT_ROOT` 에 export한다.
- 유효하지 않은 경로를 넘기면 오케스트레이터가 경로를 다시 요청하는 AskUserQuestion을 띄운다 (입력값을 에러 메시지에 포함해서).
- 인자를 안 넘겨도 기존 동작 그대로 — 첫 번째 AskUserQuestion에 경로 질문이 포함된다.

## 경로와 함께 프로젝트 설명도 전달

자연어 설명을 함께 넘기면 Phase 1-2 인터뷰가 더 빨라진다:

```
/harness-architect:harness-setup /path/to/my-dashboard 이 프로젝트는 Next.js 14 + tRPC 로 만드는 내부 운영 대시보드야. 테스트는 Vitest, 배포는 Vercel. 솔로 개발.
```

오케스트레이터는 첫 토큰을 경로로 인식하고, 나머지를 프로젝트 설명으로 사용한다.

## 관련 문서

- 전체 워크플로우: [ARCHITECTURE.md §4](../ARCHITECTURE.md)
- 재개 동작: [ARCHITECTURE.md §5 중단/재개](../ARCHITECTURE.md)
- Phase 0 프로토콜: `.claude/rules/orchestrator-protocol.md` "Phase 0 상세 프로토콜"
