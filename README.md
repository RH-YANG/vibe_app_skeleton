# vibe_app_skeleton

효율적인 바이브코딩을 위한 MSA 스켈레톤.
Backend + Frontend + Database 구조

각 서비스별 코딩 컨벤션을 style_back.md, style_front.md, styl_db.md 파일로 정리하고,
이를 LLM에 전달하여 스켈레톤을 구성한다.
서비스들을 총괄 할 컨벤션은 devops_style.md파일로 정리하였으며, 이를 기반으로 각 서비스를 실행한다.

---
<br>


## 개발 방식 정리

개발자가 개인에 맞춤화된 패턴을 기존 프로젝트에서 추출해
서비스별 스타일 가이드(`.md`)로 문서화했다.

| 문서 | 내용 요약 |
|---|---|
| [back/back_style.md](back/back_style.md) | FastAPI 3-tier 아키텍처, 레이어 규칙, SQL 스타일, DB 커넥션 데코레이터 |
| [db/db_style.MD](db/db_style.MD) | 테이블 설계 원칙, 마이그레이션 관리, Docker 구성, 백업 정책 |
| [front/front_style.md](front/front_style.md) | 컴포넌트 패턴, 커스텀 훅 구조, 네이밍 규칙, Context 패턴 |
| [devops_style.MD](devops_style.MD) | 환경변수 관리, Dockerfile 규칙, Compose 구성 원칙, 기동 절차 |

각 서비스의 폴더 구조, 레이어 분리, 파일 네이밍은 위 스타일 가이드를 그대로 따른다.
기능을 추가할 때 컨벤션을 새로 결정할 필요 없이 기존 패턴을 확장하면 된다.

---
<br>

## 아키텍처

MSA 구조로 front / back / db 세 서비스를 분리하고, Docker Compose로 오케스트레이션한다.

```
브라우저
  │
  ├─ :3000  →  front (Vite dev server)
  │               │ /api/* proxy
  │               └─────────────────→  back (:8000, FastAPI)
  │                                        │
  └─ :8000  →  back (직접 접근 / Swagger)  └→  db (:5432, PostgreSQL)
```

---
<br>

## 프로젝트 구조

```
to-my-x/
├── .env.example
├── docker-compose.yml
├── back/                  # FastAPI 백엔드
│   ├── Dockerfile
│   ├── api/               # 라우터 (요청/응답만 담당)
│   ├── service/           # 비즈니스 로직
│   ├── database/
│   │   ├── dao/           # 순수 SQL 실행
│   │   ├── schema.py      # Pydantic 모델
│   │   └── dbms_control.py
│   └── main.py
├── db/                    # PostgreSQL
│   ├── Dockerfile
│   ├── backup/            # 백업 파일 저장
│   ├── data_directory/    # 영속성을 위한 컨테이너 마운트 폴더(컨테이너 중단 대비)
│   └── script/            # 백업/복원 등 스크립트 모음
└── front/                 # React + Vite
    ├── Dockerfile
    └── src/
        ├── api/           # Axios 호출
        ├── hook/          # 커스텀 훅 (API 통신 + 비즈니스 로직)
        ├── component/     # 재사용 컴포넌트 모음
        ├── page/          # 라우트별 페이지 구성 컴포넌트
        └── types/         # 공통 TypeScript 타입
```

---
<br>

## 기술 스택

| 영역 | 기술 |
|---|---|
| Frontend | React 18, TypeScript, Vite, React Router DOM v6, Axios, CSS Modules |
| Backend | FastAPI, uvicorn, psycopg2 |
| Database | PostgreSQL 15 |
| Infra | Docker, Docker Compose |

---
<br>

## 시작하기

**1. 환경변수 설정**
```bash
cp .env.example .env
# .env 파일을 열어 실제 값으로 수정
```

**2. 컨테이너 빌드 및 기동**
```bash
docker compose up -d --build
```

**3. DB 스키마 초기 적용** (첫 실행 시 1회)
```bash
docker exec -i db psql -U {DB_USER} -d {DB_NAME} < db/schema/schema.sql
```

**4. 접속**
- 서비스: http://localhost:3000
- API 문서: http://localhost:8000/docs
