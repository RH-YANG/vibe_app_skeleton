#!/bin/bash
# 호스트 터미널(db/ 디렉토리)에서 실행한다(컨테이너에 직접 들어갈 필요 없음).
# docker exec로 컨테이너 안의 pg_dump를 원격 실행하는 방식.
# 스키마 변경 작업 후 실행해 schema.sql을 항상 최신 상태로 유지한다.
#
# 사용법 (docker compose up 상태에서 실행):
#   ./script/schema_dump.sh
#
# 출력 파일: ./schema.sql
# 의존성: docker
set -e
source "$(dirname "$0")/../.env"

docker exec -e PGPASSWORD=$DB_PWD $DB_CONTAINER \
    pg_dump -U $DB_USER -d $DB_NAME --schema-only --no-owner --no-acl > "$(dirname "$0")/../schema.sql"

echo "schema.sql 갱신 완료"
