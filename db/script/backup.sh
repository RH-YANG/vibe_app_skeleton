#!/bin/bash
# DB 수동 백업 스크립트
# 호스트 터미널(db/ 디렉토리)에서 실행한다(컨테이너에 직접 들어갈 필요 없음).
# docker exec로 컨테이너 안의 pg_dump를 원격 실행하는 방식.
#
# 사용법 (docker compose up 상태에서 실행):
#   ./script/backup.sh
#
# 출력 파일: ./backup/backup_YYYYMMDD.dump
# 의존성: docker, pg_restore (호스트에 설치 필요 — 무결성 검증에 사용)
set -e
source "$(dirname "$0")/../.env"
TODAY=$(date +%Y%m%d)
BACKUP_DIR="$(dirname "$0")/../backup"

docker exec -e PGPASSWORD=$DB_PWD $DB_CONTAINER \
    pg_dump -U $DB_USER -d $DB_NAME -Fc > "$BACKUP_DIR/backup_$TODAY.dump"

pg_restore --list "$BACKUP_DIR/backup_$TODAY.dump" > /dev/null
echo "백업 완료: backup/backup_$TODAY.dump"
