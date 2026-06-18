-- schema.sql — 최신 전체 스냅샷 (pg_dump -s 로 재생성)
-- 새 환경 셋업은 이 파일 한 번 적용으로 끝낸다

CREATE TABLE member (
    member_id  integer                  GENERATED ALWAYS AS IDENTITY CONSTRAINT member_pk PRIMARY KEY,
    email      character varying        NOT NULL,  -- 로그인 시 사용되는 이메일 계정
    pwd        character varying        NOT NULL,  -- 로그인 비밀번호 (해시 저장)
    name       character varying        NOT NULL,  -- 사용자 이름
    is_activate boolean                 NOT NULL DEFAULT true,  -- 활성 계정 여부
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE member IS '플랫폼의 회원 데이터를 저장하는 테이블.';
