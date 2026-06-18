# DB Convention 

PostgreSQL

---

## 1. 테이블 설계

### PK 컬럼
- 모든 테이블의 PK 컬럼명은 **`{테이블명(단수)}_id`**
- `GENERATED ALWAYS AS IDENTITY` 사용 (시퀀스를 별도로 만들지 않는다)

```sql
CREATE TABLE member (
    member_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email     character varying NOT NULL,
    name      character varying
);
```

### FK 컬럼
- FK 컬럼명은 참조 테이블의 PK명과 항상 동일하게 (`member_id`는 어디에 있든 `member.member_id`를 가리킨다)
- 컬럼명만 보고 참조 테이블을 바로 추론할 수 있어야 한다 (약어 사용 금지)

```sql
CREATE TABLE protein (
    protein_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id  integer NOT NULL REFERENCES member(member_id),
    name       character varying
);
```

### 복합 PK
- 매핑/연결 테이블은 서러게이트 키 없이 자연 복합키 사용
```sql
CREATE TABLE my_protein (
    member_id  integer NOT NULL REFERENCES member(member_id),
    protein_id integer NOT NULL REFERENCES protein(protein_id),
    PRIMARY KEY (member_id, protein_id)
);
```

### 제약조건 네이밍
- PK: `{table}_pk`
- FK: `{table}_fk` (같은 테이블에 FK가 여러 개면 `{table}_fk_1`, `{table}_fk_2` 순번 부여)

### 공통 컬럼 규칙
- boolean 컬럼은 `is_` 접두어 (`is_public`, `is_activate`)
- 가변 문자열은 길이 제한 없는 `character varying`으로 통일
- 생성/수정 시각은 `created_at` / `updated_at`, 타입은 `timestamp with time zone DEFAULT CURRENT_TIMESTAMP`
- 생성/수정 주체를 남길 때는 `created_by` / `modified_by` (둘 다 `member_id`를 참조하는 FK)

### 문서화
- **테이블 단위**: `COMMENT ON TABLE`로 테이블의 목적을 남긴다 (유지)
  ```sql
  COMMENT ON TABLE member IS '플랫폼의 회원 데이터를 저장하는 테이블.';
  ```
- **컬럼 단위**: `COMMENT ON COLUMN`은 사용하지 않는다. 대신 CREATE TABLE 내부에 인라인 SQL 주석(`--`)으로 남긴다
  ```sql
  CREATE TABLE member (
      member_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      email     character varying NOT NULL,  -- 로그인시 사용되는 이메일 계정
      pwd       character varying NOT NULL,  -- 로그인 비밀번호
      name      character varying            -- 사용자 이름
  );
  ```
  - 이유: 컬럼당 8줄짜리 `COMMENT ON COLUMN` 블록이 schema.sql을 비대하게 만들고 git diff에서 노이즈를 키운다. 인라인 주석은 짧고 git diff에서도 바로 보인다.

---

## 2. 스키마 관리

실제 소스 오브 트루스는 **컨테이너 안의 DB**다. `schema.sql`은 현재 DB 스키마를 한눈에 보기 위한 스냅샷 파일이며, 변경 이력 추적은 git history로 한다.

```
컨테이너 DB에서 직접 작업
        ↓
script/schema_dump.sh 실행으로 schema.sql 갱신 (스냅샷 동기화)
```

### schema.sql 갱신

스키마를 변경한 뒤 아래 스크립트로 `schema.sql`을 동기화한다.

```bash
./script/schema_dump.sh
```

- 데이터 이전/적재용 1회성 스크립트는 별도 `data_migration/` 폴더에 둔다.

---


## 3. 백업 / 복원

### 백업 대상과 포함 범위

`pg_dump -Fc` (custom format)는 **스키마 + 데이터를 모두 포함**한다. 별도 스키마 덤프를 추가로 만들지 않는다. 스키마 이력 추적은 2번 섹션(`schema.sql` + git history)이 전담하므로 중복이다.

| 파일 | 스키마 | 데이터 | 용도 |
|---|---|---|---|
| `schema.sql` | O | X | 현재 구조 스냅샷, git으로 이력 추적 |
| `backup/*.dump` | O | O | 특정 시점 전체 복원용 |

### 실행 방식

수동 실행만 지원한다. 자동화(cron 등)는 프로덕션 전환 시점에 추가한다.

- 호스트 터미널 `db/` 디렉토리에서 실행한다. 컨테이너에 직접 들어갈 필요 없음.
- `docker exec`로 컨테이너 안의 `pg_dump`/`pg_restore`를 원격 실행하는 방식.
- `docker compose up` 상태에서 실행해야 한다.

```bash
./script/backup.sh                  # 오늘 날짜로 덤프 생성 (스키마 + 데이터)
./script/restore.sh <파일명>         # 지정 덤프 파일로 복원 (되돌릴 수 없음)
```

백업 파일 위치: `./backup/backup_YYYYMMDD.dump`
의존성: `docker`, `pg_restore` (호스트에 설치 필요 — 무결성 검증에 사용)