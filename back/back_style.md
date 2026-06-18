# Backend Coding Style Guide

FastAPI + PostgreSQL(psycopg2) 백엔드 개발 컨벤션.

---

## 1. 프로젝트 구조

3-tier 아키텍처를 엄격하게 분리한다.

```
project/
├── api/                    # 라우터, 요청/응답만 담당
│   └── {domain}_api.py
├── service/                # 비즈니스 로직, 에러 핸들링
│   └── {domain}_service.py
├── database/
│   ├── dao/                # 순수 SQL 실행만 담당
│   │   └── {domain}_dao.py
│   ├── schema.py           # Pydantic 모델 (내부 모델 + 요청/응답 모델)
│   └── dbms_control.py     # DB 커넥션 데코레이터
├── config/
│   └── env_config.py
├── main.py
└── .env
```

레이어 간 호출 방향: `api → service → dao`  
역방향 호출 금지. api가 dao를 직접 호출하지 않는다.

패키지 폴더(`api/`, `service/`, `database/`, `database/dao/`, `config/`)에는 `__init__.py`를 두지 않는다. Python 3.3+ namespace package로 인식되어 `from api import ...` 같은 절대경로 임포트가 `__init__.py` 없이도 정상 동작한다.

---

## 2. 네이밍 컨벤션

### 파일
- 소문자 + 언더스코어: `member_api.py`, `verify_email_service.py`
- 레이어 접미사 필수: `*_api.py` / `*_service.py` / `*_dao.py`

### 클래스 (Pydantic 모델)
- PascalCase
- 내부 모델: 도메인명 그대로 (`Member`, `Protein`)
- 요청 모델: `{Domain}{Action}Request` (`MemberJoinRequest`)
- 응답 모델: `{Domain}Response` (`MemberResponse`)

### 함수 / 변수
- snake_case
- 동작 동사 포함: `check_email`, `select_by_email`, `db_fail_routine`
- DB 시퀀스 컬럼 변수: `mem_seq`, `pro_seq`, `sta_seq` (도메인 약어 + `_seq`)

### 라우터
```python
router = APIRouter(prefix="/{domain}", tags=["{domain}"])
```

---

## 3. Pydantic 스키마 패턴

### 내부 모델 (DB 조회 결과 매핑용)
모든 필드를 `Optional[T] = None`으로 선언한다.

```python
class Member(BaseModel):
    mem_seq: Optional[int] = None
    email: Optional[str] = None
    pwd: Optional[str] = None
    name: Optional[str] = None
    phone: Optional[str] = None
    birth: Optional[datetime] = None
    role: Optional[str] = None
    token: Optional[str] = None
    join_at: Optional[datetime] = None
```

### 요청 모델 (API 입력)
필수 필드는 타입만, 선택 필드는 `Optional[T] = None`으로 선언한다.

```python
class MemberJoinRequest(BaseModel):
    email: str
    pwd: str
    name: str
    phone: Optional[str] = None
    birth: Optional[datetime] = None
```

### 응답 모델 (API 출력)
클라이언트에 노출할 필드만 선언한다. `pwd` 같은 민감 필드는 포함하지 않는다.

```python
class MemberResponse(BaseModel):
    mem_seq: int
    email: str
    name: str
    role: str
```

---

## 4. API 레이어

- 라우팅과 요청/응답 변환만 담당한다.
- 비즈니스 로직을 작성하지 않는다.
- 요청 모델과 응답 모델을 명시적으로 구분해서 사용한다.

```python
router = APIRouter(prefix="/member", tags=["member"])

@router.post("/join")
def join(request: MemberJoinRequest) -> MemberResponse:
    return member_service.insert(request)

@router.get("/available")
def check_duplicate(email: str) -> bool:
    return member_service.check_email(email)
```

---

## 5. Service 레이어

- 비즈니스 로직과 에러 핸들링을 담당한다.
- `@connect_db` 데코레이터로 DB 커넥션을 주입받는다.
- 함수 시그니처는 항상 `(conn, cur, ...)` 순서로 시작한다.
- DML 후 반드시 `conn.commit()` 또는 `db_fail_routine(conn)`을 호출한다.

```python
@connect_db
def insert(conn, cur, request: MemberJoinRequest):
    result = member_dao.insert(cur, request)

    if not result:
        db_fail_routine(conn)
    conn.commit()

@connect_db
def check_email(conn, cur, email: str) -> bool:
    return member_dao.check_email(cur, email)
```

### 에러 핸들링
`HTTPException`으로 처리한다. 에러가 발생하면 이후 로직은 실행되지 않는다.

```python
from fastapi import HTTPException, status

if not db_member.mem_seq:
    raise HTTPException(status.HTTP_403_FORBIDDEN, "User Not Found")

if not match:
    raise HTTPException(status.HTTP_403_FORBIDDEN, "Password Not Matched")
```

---

## 6. DAO 레이어

- 순수 SQL 실행만 담당한다.
- 커넥션 관리를 하지 않는다 (service의 데코레이터가 담당).
- 첫 번째 파라미터는 항상 `cur`.
- 조회 결과는 내부 모델로 변환해서 반환한다.

```python
def select_by_email(cur, email: str) -> Member:
    query = '''
        SELECT mem_seq
             , email
             , pwd
             , name
             , phone
             , birth
             , role
          FROM member
         WHERE email = %s
    '''
    cur.execute(query, (email,))
    record = cur.fetchone()

    if record:
        return Member(**record)
    return Member()

def insert(cur, request: MemberJoinRequest) -> int:
    query = '''
        INSERT INTO member (email, pwd, name, phone, birth)
        VALUES (%s, %s, %s, %s, %s)
    '''
    cur.execute(query, (request.email, request.pwd, request.name, request.phone, request.birth))
    return cur.rowcount
```

---

## 7. SQL 스타일

- 키워드 대문자
- 컬럼 세로 정렬 (`,`를 줄 앞에)
- `FROM`, `WHERE`는 `SELECT` 기준 우측 정렬
- 파라미터는 `%s` 또는 `%(name)s` 플레이스홀더 사용 (f-string 금지)
- 동적 컬럼명은 화이트리스트 검증 후 삽입

```python
# 기본 쿼리
query = '''
    SELECT mem_seq
         , email
         , name
      FROM member
     WHERE email = %s
'''

# 동적 조건 쿼리
allowed_list = {"pdb_id", "title", "classification"}
filters = ["1=1"]
sql_params = {}

if page.keyword and search_field in allowed_list:
    filters.append(f"{search_field} ILIKE %(kw)s")
    sql_params["kw"] = f"%{page.keyword}%"

query = "SELECT * FROM protein WHERE " + " AND ".join(filters)
cur.execute(query, sql_params)
```

---

## 8. DB 커넥션 데코레이터

`dbms_control.py`에 정의된 데코레이터를 사용한다.

| 데코레이터 | 커서 타입 | 반환 형태 |
|---|---|---|
| `@connect_db` | DictCursor | 딕셔너리 |
| `@connect_db_tuple` | 기본 커서 | 튜플 |
| `@connect_db_log_tuple` | 기본 커서 | 튜플 + SQL 로그 출력 |

DML 실패 처리:
```python
def db_fail_routine(conn):
    conn.rollback()
    raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Failure without errors")
```

---

## 9. 임포트 순서

1. 표준 라이브러리
2. 서드파티
3. 로컬 (service, dao, schema 순)

```python
# api 레이어
from fastapi import APIRouter
import service.member_service as member_service
from database.schema import MemberJoinRequest, MemberResponse

# service 레이어
from fastapi import HTTPException, status
from database.dbms_control import connect_db, db_fail_routine
import database.dao.member_dao as member_dao
from database.schema import Member, MemberJoinRequest
```

- 서비스/DAO 모듈: `import ... as ...` (전체 모듈 임포트)
- 스키마 클래스: `from ... import ...` (클래스 선택 임포트)

---

## 10. main.py 구조

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import member_api, auth_api

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

router = APIRouter()
router.include_router(member_api.router)
router.include_router(auth_api.router)
app.include_router(router)
```
