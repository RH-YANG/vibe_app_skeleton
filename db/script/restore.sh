#!/bin/bash
# DB 복원 스크립트 (되돌릴 수 없음 — 실행 전 반드시 확인)
# 호스트 터미널(db/ 디렉토리)에서 실행한다(컨테이너에 직접 들어갈 필요 없음).
# docker exec로 컨테이너 안의 pg_dump를 원격 실행하는 방식.
#
# 사용법 (docker compose up 상태에서 실행):
#   ./script/restore.sh <파일명>
#
# 예시:
#   ./script/restore.sh backup_20260619.dump
#
# 복원 대상 파일 위치: ./backup/<파일명>
# 의존성: docker
set -e
source "$(dirname "$0")/../.env"
FILE=$1
BACKUP_DIR="$(dirname "$0")/../backup"

if [ -z "$FILE" ]; then
    echo "사용법: ./script/restore.sh <파일명>"
    exit 1
fi
if [ ! -f "$BACKUP_DIR/$FILE" ]; then
    echo "[오류] 파일이 존재하지 않음: backup/$FILE"
    exit 1
fi

read -p "⚠️  $DB_NAME 의 기존 데이터를 $FILE 로 덮어씁니다. 계속할까요? (y/N) " confirm
[ "$confirm" = "y" ] || { echo "취소됨"; exit 0; }

docker exec -e PGPASSWORD=$DB_PWD -i $DB_CONTAINER \
    pg_restore -U $DB_USER -d $DB_NAME --clean --if-exists < "$BACKUP_DIR/$FILE"
echo "복원 완료: $FILE"
