---
name: Data Pipeline (End-to-End Data Workflow)
slug: data-pipeline
quality: full
sources_count: 4
last_verified: 2026-04-17
---

# Data Pipeline — 엔드투엔드 데이터 워크플로우

다양한 출처의 원시 데이터를 수집·정제·변환·적재하여 분석·ML·프로덕트에 공급하는 신뢰성 있는 파이프라인.

## 표준 워크플로우

1. **Source Ingestion** — DB/API/파일/스트림에서 원시 데이터 수집. 완료 조건: 데이터 세트가 스토리지(레이크/웨어하우스)에 적재 + 스키마 기록.
2. **Data Validation** — 스키마·NULL·범위·참조 무결성 검증. 완료 조건: 실패 레코드 < 허용 임계, 위반 시 격리.
3. **Transformation** — SQL/DataFrame 기반 정제·조인·집계. 모델링(스타·스노우플레이크). 완료 조건: 테스트 통과 + 리니지 기록.
4. **Storage & Partitioning** — 웨어하우스(Snowflake/BigQuery/Redshift) 또는 레이크(Iceberg/Delta) 적재, 파티셔닝·클러스터링. 완료 조건: 쿼리 SLA 충족.
5. **Serving** — BI 대시보드, 피처 스토어, API, 알림. 완료 조건: 소비자 SLA 충족.
6. **Monitoring & Data Quality** — 프레시니스, 볼륨, 분포 편차 감지. 완료 조건: SLO 위반 시 온콜 알림.
7. **Lineage & Governance** — 데이터 계보, PII 분류, 액세스 제어. 감사 가능성 유지.

## 표준 역할/팀 분업

| 역할 | 책임 | 필요 역량 | 인원 |
|------|------|----------|------|
| Data Engineer | 수집·변환·스토리지 구축 | SQL, Python, Spark, 웨어하우스 | 1~3 |
| Analytics Engineer | 변환 모델링(dbt), 비즈니스 로직 | SQL, 데이터 모델링, 도메인 | 1~2 |
| Data Analyst / Scientist | 대시보드·분석·실험 | SQL, Python, 통계 | 1+ per 도메인 |
| ML Engineer | 피처 스토어, 모델 서빙(해당 시) | MLOps, Kubernetes, 서빙 프레임워크 | 1 (해당 시) |
| Data Platform / DevOps | 인프라, 스케줄러, CI/CD | Airflow/Dagster, Terraform, IAM | 1 |
| Data Governance | PII 정책, 접근 제어, 감사 | 규제·컴플라이언스 지식 | 1 (대기업) |

## 표준 도구·스킬 스택

- **워크플로우 오케스트레이션**: Airflow, Dagster, Prefect, Temporal (이벤트 기반)
- **수집**: Airbyte, Fivetran, Meltano (SaaS 커넥터), Kafka/Kinesis (스트림), Debezium (CDC)
- **변환**: dbt (SQL-first), Spark/PySpark, Polars, Pandas (소규모)
- **스토리지**: Snowflake, BigQuery, Redshift (웨어하우스) / Iceberg, Delta Lake, Hudi (레이크하우스)
- **BI**: Looker, Tableau, Metabase, Superset, Mode
- **데이터 품질**: Great Expectations, Soda, Elementary (dbt), Monte Carlo (관측성)
- **계보/카탈로그**: DataHub, OpenLineage + Marquez, Atlan, Amundsen
- **피처 스토어** (ML): Feast, Tecton, AWS SageMaker Feature Store
- **개발 방법론**: DataOps (CI/CD for data), Medallion Architecture (bronze/silver/gold)

## 흔한 안티패턴

1. **테스트 없는 변환** — dbt 모델·SQL 변환에 테스트(not null, unique, referential) 없음. 잘못된 데이터가 하류로 전파. 해결: dbt test 의무, Great Expectations 스위트. 출처: dbt Docs "Testing".
2. **풀 리프레시 재실행** — 증분 처리 없이 매일 전체 리빌드. 비용·시간 낭비. 해결: 증분 재료화(incremental materialization), 파티션별 재처리. 출처: dbt Docs "Materializations".
3. **하드 삭제 데이터 유실** — 원본을 덮어쓰거나 지워서 과거 재현 불가. 해결: immutable bronze 계층 유지, SCD(Slowly Changing Dimensions) 패턴. 출처: Kimball Group 문헌 / Medallion 참조.
4. **관측성 없음 = 조용한 실패** — 파이프라인이 멈춰도 며칠 뒤 발견. 해결: 프레시니스·볼륨·스키마 모니터 + 온콜. 출처: Monte Carlo "Data Observability".
5. **PII 무분별 복제** — 개인정보를 하류 테이블에 복사 후 접근 제어 실패. 해결: PII 태깅, row/column 레벨 보안, 마스킹. 검증되지 않은 추정 (일반 권고).

## Reference Sources

- [dbt Labs] "dbt documentation — Tests & Materializations" — https://docs.getdbt.com/ — Analytics Engineering의 사실상 표준. 발췌일 2026-04-17.
- [Apache Airflow] "Airflow documentation" — https://airflow.apache.org/docs/ — 오케스트레이션 기준 구현. 발췌일 2026-04-17.
- [DataOps Manifesto] — https://dataopsmanifesto.org/ — 데이터 파이프라인의 DevOps 원칙. 발췌일 2026-04-17.
- [Databricks] "Medallion Architecture" — https://www.databricks.com/glossary/medallion-architecture — bronze/silver/gold 계층화. 발췌일 2026-04-17.
