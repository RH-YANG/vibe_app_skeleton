# DevOps Convention

FastAPI(back) + PostgreSQL(db) + React/Vite(front) MSA 구조의 개발 환경 컨테이너 구성 컨벤션.

---

## 1. 폴더 구조

각 서비스 폴더 하위에 자기 Dockerfile을 두고 프로젝트 루트의 `docker-compose.yml`이 이를 묶는다.

```
project-root/
├── .env                     # 전체 서비스 공용 환경변수 (gitignore)
├── .env.example             # 키 목록 공유용 (커밋)
├── .gitignore
├── docker-compose.yml
├── back/
│   ├── Dockerfile
│   └── ...
├── db/
│   ├── Dockerfile
│   └── ...
└── front/
    ├── Dockerfile
    └── ...
```

---

## 2. 환경변수 (.env)

- `.env`는 **루트 한 곳에서만** 관리한다. 서비스 폴더별 `.env`를 두지 않는다.
- docker-compose는 루트 `.env`를 자동으로 읽는다.
- 각 컨테이너는 compose의 `environment:` 블록으로 필요한 변수를 주입받는다.
- `.env`는 gitignore. `.env.example`만 커밋해서 키 목록을 공유한다.
- `DB_HOST`는 컨테이너 서비스명(`db`)으로 설정한다. 로컬 직접 실행이 필요할 경우 `127.0.0.1`로 임시 변경한다.

---

## 3. Dockerfile

### back
- `CMD`는 prod 기준(`--reload` 없음). dev에서의 `--reload`는 compose `command:`로 오버라이드한다.

### front
- `CMD`에 `--host` 플래그 필수. 없으면 컨테이너 외부에서 접근 불가.

### db
- 커스텀 init 스크립트를 넣지 않는다. base 이미지 그대로 사용.
- 유저/DB 생성은 `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` 환경변수에 위임한다.
- 데이터 디렉토리가 비어있을 때만 자동 생성되므로 idempotent하다.

---

## 4. docker-compose.yml

- **서비스 기동 순서**: `depends_on` + `healthcheck`로 해결한다. `sleep N` 대기 스크립트를 작성하지 않는다.
- **db healthcheck**: `pg_isready -U {user} -d {dbname}` — `-d` 옵션으로 실제 대상 DB까지 확인한다.
- **hot reload**: back은 소스 볼륨 마운트 + `--reload`, front는 소스 볼륨 마운트 + node_modules 익명 볼륨 조합.
- **node_modules 보호**: `- /app/node_modules` 익명 볼륨을 반드시 추가한다. 없으면 호스트의 node_modules가 컨테이너 node_modules를 덮어쓴다.
- **네트워크**: 프로젝트별 커스텀 bridge 네트워크를 사용한다. 컨테이너 간 통신은 서비스명을 호스트명으로 사용한다 (예: `http://back:8000`).
- **front 프록시 타겟**: `VITE_API_URL=http://back:8000`을 compose `environment:`로 주입한다. front의 `vite.config.ts`가 이 값을 프록시 타겟으로 읽는다.

---

## 5. .gitignore

- 루트 `.env` — 공통
- `back/__pycache__/`, `**/*.pyc` — Python 캐시
- `front/node_modules/`, `front/dist/` — 프론트 빌드 산출물
- `db/data_directory/` — PostgreSQL 데이터 볼륨
- `db/backup/` — 덤프 파일

---

## 6. DB 스키마 초기 적용

postgres 공식 이미지는 유저/DB만 자동 생성한다. 테이블은 첫 기동 후 수동으로 한 번 적용한다.

```bash
docker exec -i db psql -U {DB_USER} -d {DB_NAME} < db/schema/schema.sql
```

이후 스키마 변경은 `db/migration/`에 번호 prefix SQL 파일로 관리한다. (DB 컨벤션 참조)

---

## 7. 기동 / 종료

```bash
# 빌드 + 기동
docker compose up -d --build

# 기동만 (이미지 변경 없을 때)
docker compose up -d

# 로그 확인
docker compose logs -f
docker compose logs -f back   # 특정 서비스만

# 종료 (컨테이너 삭제, 볼륨은 유지)
docker compose down

# 컨테이너 상태 확인
docker compose ps
```

---

## 8. 통신 구조

```
브라우저
  │
  ├─ http://localhost:3000        → front 컨테이너 (Vite dev server)
  │     │ /api/*  proxy          → back:8000 (내부 네트워크)
  │     └─ /health proxy         → back:8000 (내부 네트워크)
  │
  └─ http://localhost:8000        → back 컨테이너 (직접 접근 / Swagger)

back 컨테이너
  └─ psycopg2 → db:5432          → db 컨테이너 (내부 네트워크)

호스트
  └─ localhost:5432               → db 컨테이너 (직접 접근 / DB 클라이언트)
```

---

## 9. 프로젝트 시작 체크리스트

1. `back/`, `db/`, `front/` 폴더가 생성되어 있는지 확인
2. 각 서비스 스켈레톤(최소 실행 가능 코드)이 있는지 확인
   - back: `requirements.txt`, `main.py`(`/health` 엔드포인트 포함)
   - front: `package.json`, Vite 초기화 완료
   - db: `schema/schema.sql`, `migration/` 폴더
3. `db/data_directory/`, `db/backup/` 폴더를 미리 생성 (없으면 Docker가 파일로 만든다)
4. 루트 `.env`를 `.env.example` 기반으로 작성, 실제 값 채우기
5. `docker compose build` → `docker compose up -d` → 통신 검증 순으로 진행
6. 첫 기동 후 DB 스키마 수동 적용 (6번 항목)
