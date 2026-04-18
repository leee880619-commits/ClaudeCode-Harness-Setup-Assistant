<!-- generated-with: harness-architect v0.3.3 | sanitized for public use -->

# my-web-app

개인 포트폴리오 겸 사이드 프로젝트용 React + Node.js 웹 애플리케이션.
사용자 인증, 게시물 CRUD, 이미지 업로드 기능을 제공한다.

## 기술 스택

- **프론트엔드**: React 18, TypeScript, Tailwind CSS
- **백엔드**: Node.js 20, Express, Prisma ORM
- **데이터베이스**: PostgreSQL 15
- **테스트**: Vitest (유닛), Playwright (E2E)
- **배포**: Docker, Railway

## 개발 원칙

- 타입 안전성: TypeScript strict 모드 유지
- 테스트: 새 기능은 유닛 테스트 필수
- 커밋: Conventional Commits (`feat:`, `fix:`, `docs:`)
- 코드 리뷰: PR 머지 전 자기 리뷰 체크리스트 확인

## 디렉터리 구조

```
src/
├── client/     # React 프론트엔드
├── server/     # Express API 서버
└── shared/     # 공유 타입·유틸리티
```

## 자주 쓰는 명령어

```bash
npm run dev        # 개발 서버 (프론트 + 백 동시 실행)
npm run test       # 유닛 테스트
npm run test:e2e   # E2E 테스트
npm run build      # 프로덕션 빌드
```

## 규칙 및 설계 문서

@import .claude/rules/dev-conventions.md
