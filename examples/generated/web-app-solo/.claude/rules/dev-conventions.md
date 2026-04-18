<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# 개발 규약

## 코드 스타일

- TypeScript strict 모드 준수. `any` 타입 사용 금지.
- 컴포넌트 파일: PascalCase (`UserProfile.tsx`)
- 유틸리티·훅 파일: camelCase (`useAuth.ts`)
- 상수: SCREAMING_SNAKE_CASE

## 커밋 규약

Conventional Commits 형식 준수:
- `feat:` — 새 기능
- `fix:` — 버그 수정
- `docs:` — 문서 변경
- `refactor:` — 기능 변경 없는 코드 개선
- `test:` — 테스트 추가·수정

## 테스트 원칙

- 새 API 엔드포인트는 통합 테스트 필수
- 비즈니스 로직 함수는 유닛 테스트 필수
- UI 컴포넌트는 핵심 인터랙션만 E2E 테스트

## 금지 패턴

- `console.log`를 프로덕션 코드에 남기지 않는다
- `// TODO` 주석은 이슈 번호를 함께 기재 (`// TODO #42`)
- 환경변수는 반드시 `.env.example`에 키 이름을 문서화
