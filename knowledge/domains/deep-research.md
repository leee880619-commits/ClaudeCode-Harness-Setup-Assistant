---
name: Deep Research (Multi-Agent Investigation)
slug: deep-research
quality: full
sources_count: 4
last_verified: 2026-04-17
---

# Deep Research — 멀티 에이전트 조사 팀

복합 질문에 대해 여러 서브에이전트가 병렬로 자료를 수집·검증·합성하는 심층 리서치 시스템.

## 표준 워크플로우

1. **Question Decomposition** — 사용자 질문을 검색 가능한 서브질문 3~10개로 분해. 완료 조건: 각 서브질문이 단일 사실/비교/반박 형태로 환원.
2. **Parallel Search (Fan-out)** — 서브질문마다 독립 searcher 에이전트 실행. 각자 별도 컨텍스트로 자료 수집. 완료 조건: 서브질문당 인용 가능한 1차 자료 3건 이상.
3. **Source Verification** — critic 에이전트가 수집 자료의 출처·날짜·저자 신뢰도 검증. 완료 조건: 미검증 자료 0건.
4. **Synthesis** — writer/synthesizer 에이전트가 검증된 자료만 사용해 답변 초안 작성. 완료 조건: 모든 주장에 인용 1:1 매핑.
5. **Contradiction Check** — critic이 초안의 내부 모순과 출처 모순 탐지. 완료 조건: BLOCK급 모순 0건.
6. **Final Answer** — 인용 포함한 최종 답변 반환.

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Planner / Lead | 질문 분해, 서브에이전트 오케스트레이션, 범위 관리 | 추론·계획, 토큰 예산 관리 | 1 |
| Searcher (병렬) | 단일 서브질문에 대한 자료 수집 (웹/API/파일) | 검색 쿼리 설계, 도구 사용 | 3~10 (서브질문당 1) |
| Critic / Verifier | 출처 신뢰도 검증, 모순 탐지 | 비판적 사고, 팩트체킹 | 1~2 |
| Synthesizer / Writer | 검증된 자료로 답변 합성 + 인용 관리 | 글쓰기, 구조화 | 1 |

## 표준 도구·스킬 스택

- **검색**: 웹검색(Brave/Google/SerpAPI), 도메인 특화 API(arXiv, PubMed, GitHub), 사내 문서 인덱스(RAG)
- **크롤링/본문 추출**: Firecrawl, Playwright, readability 라이브러리
- **인용 관리**: Zotero 스타일 citation graph, JSON 구조화 reference
- **오케스트레이션**: LangGraph, Anthropic multi-agent SDK 패턴, AutoGen, CrewAI
- **평가**: RAGAS, DeepEval (사실성/근거성/무모순성 메트릭)
- **추론 전략**: ReAct (reasoning+acting 교차), Reflexion (자기반성 루프), Tree-of-Thoughts (탐색)

## 흔한 안티패턴

1. **Searcher 간 중복 검색** — Planner가 서브질문 간 직교성을 보장하지 않아 동일 URL을 여러 searcher가 각자 수집. 토큰 낭비 + 편향 증폭. 출처: Anthropic 멀티에이전트 연구 글.
2. **인용 없는 합성** — Synthesizer가 기억에만 의존해 주장을 삽입, Critic이 검출 못 함. 해결: 합성 단계에서 "인용 없는 문장 0" 강제. 출처: ReAct 및 CoVe 논문 계열.
3. **Critic 생략** — 빠른 결과를 위해 verifier를 건너뜀. 환각 검출 실패율 급증. 검증되지 않은 추정.
4. **단일 소스 의존** — 서브질문당 1개 출처만 수집하여 확증 편향. 해결: 서브질문당 최소 2~3 독립 출처 강제. 출처: 팩트체킹 업계 표준.
5. **컨텍스트 누수** — searcher 간 긴 대화 히스토리 공유로 상호 오염. 해결: searcher를 isolated sub-agent로 실행, 결과만 Planner가 취합. 출처: Anthropic 엔지니어링 블로그.

## Reference Sources

- [Anthropic] "How we built our multi-agent research system" — https://www.anthropic.com/engineering/built-multi-agent-research-system — 2025년 다중 에이전트 리서치 아키텍처와 서브에이전트 컨텍스트 격리의 엔지니어링 경험. 발췌일 2026-04-17.
- [arXiv] "ReAct: Synergizing Reasoning and Acting in Language Models" (Yao et al., 2022) — https://arxiv.org/abs/2210.03629 — 추론+행동 교차 프롬프팅의 원형. 발췌일 2026-04-17.
- [arXiv] "Reflexion: Language Agents with Verbal Reinforcement Learning" (Shinn et al., 2023) — https://arxiv.org/abs/2303.11366 — 자기반성 루프. 발췌일 2026-04-17.
- [OpenAI Cookbook] "Techniques to improve reliability" — https://cookbook.openai.com/ — 인용 강제, self-consistency, 출처 기반 답변 생성 패턴. 발췌일 2026-04-17.
