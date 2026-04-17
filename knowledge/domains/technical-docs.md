---
name: Technical Documentation (Codebase-Driven)
slug: technical-docs
quality: full
sources_count: 4
last_verified: 2026-04-17
---

# Technical Documentation — 코드베이스 분석 기반 문서화

코드·설정·히스토리에서 추출한 증거를 바탕으로, 독자 의도별 4축(학습/탐색/레퍼런스/해결)에 맞춰 기술 문서를 생성·유지하는 시스템.

## 표준 워크플로우

1. **Repository Audit** — 기존 문서 인벤토리, 공개 API 표면, 빌드/배포 스크립트 추출. 완료 조건: 문서화 대상 엔티티 목록 확보.
2. **Audience Segmentation** — 독자를 Diataxis 4축으로 분류: Tutorial(학습자), How-to(작업자), Reference(확인자), Explanation(이해자). 완료 조건: 각 축별 필요 문서 리스트.
3. **Draft Generation** — 축별로 문서 초안 작성. 코드 예시는 실제 코드베이스에서 추출 + 테스트 가능해야 함. 완료 조건: 각 문서에 코드 인용 1개 이상 + 실행 가능한 예시.
4. **Technical Review** — 엔지니어가 사실 정확성 검증 (API 시그니처, 동작 설명). 완료 조건: 사실 오류 0건.
5. **Editorial Review** — 테크니컬 라이터가 문체·구조·용어 일관성 검증. 완료 조건: 용어집과 일치.
6. **Publish & Link** — 사이트/Wiki에 배포, 내부 링크 그래프 검증. 완료 조건: 깨진 링크 0건.
7. **Drift Monitoring** — 코드 변경 시 영향받는 문서 자동 감지 (docstring-as-source-of-truth 또는 ADR 업데이트).

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Technical Writer | 구조 설계, 초안 집필, 에디토리얼 리뷰 | 글쓰기, Diataxis, 정보 아키텍처 | 1~2 |
| Subject Matter Engineer | 사실 검증, 코드 예시 제공, 리뷰 | 해당 시스템 심층 이해 | 1+ per 영역 |
| Docs Ops / Site Maintainer | 빌드 파이프라인, 링크 검증, 검색 | SSG(Docusaurus/MkDocs/Sphinx), CI | 1 |
| Product/Dev Advocate | 독자 페르소나 정의, 피드백 수집 | 커뮤니티 인터뷰, 분석 | 1 (대규모 프로덕트) |

## 표준 도구·스킬 스택

- **정적 사이트 생성**: Docusaurus, MkDocs, Sphinx, Docsify, Hugo
- **API 문서**: TypeDoc, JSDoc, Sphinx autodoc, OpenAPI/Swagger, Protobuf docs
- **다이어그램**: Mermaid (코드로 관리), PlantUML, draw.io (소스 포함)
- **리뷰/버전 관리**: Git(docs-as-code), Vale(문체 린터), markdownlint, Netlify/Vercel preview
- **프레임워크**: Diataxis (독자 의도 4축), Divio Documentation System, Write the Docs 원칙
- **ADR**: MADR (Markdown Any Decision Records), adr-tools

## 흔한 안티패턴

1. **튜토리얼과 레퍼런스 혼재** — "시작하기" 페이지에 전체 API 덤프. 학습자는 길 잃고, 확인자는 못 찾음. 해결: Diataxis로 명확 분리. 출처: Diataxis Framework.
2. **코드와 문서의 drift** — 리팩터링 후 문서 갱신 누락. 해결: docstring 기반 자동 추출 + ADR 의무화 + CI에서 예시 코드 실행 테스트. 출처: Write the Docs.
3. **검색 불가** — 문서가 많은데 검색 UX 없음. 해결: Algolia/Typesense 통합, 태그 메타데이터. 검증되지 않은 추정.
4. **독자 페르소나 부재** — "누구에게 쓰는지" 불명확하여 전문용어와 초보 설명이 뒤섞임. 해결: 각 페이지 상단에 "대상 독자" 명시. 출처: Divio Documentation System.
5. **스크린샷 과다** — UI 스크린샷이 많아 UI 변경마다 대량 업데이트 필요. 해결: 텍스트 중심, 스크린샷은 필수일 때만. 검증되지 않은 추정.

## Reference Sources

- [Diataxis] Daniele Procida's "Diataxis Framework" — https://diataxis.fr/ — 문서를 Tutorial / How-to / Reference / Explanation 4축으로 구조화. 발췌일 2026-04-17.
- [Divio] "The documentation system" — https://documentation.divio.com/ — Diataxis의 원형. 발췌일 2026-04-17.
- [Write the Docs] "Documentation guide" — https://www.writethedocs.org/guide/ — 테크니컬 라이팅 커뮤니티의 종합 가이드. 발췌일 2026-04-17.
- [Google] "Technical Writing courses" — https://developers.google.com/tech-writing — 구글 테크니컬 라이팅 공개 교재. 발췌일 2026-04-17.
