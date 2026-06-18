from fastapi import HTTPException, status

from database.dbms_control import connect_db, db_fail_routine
import database.dao.golem_dao as golem_dao
from database.schema import Golem, GolemJoinRequest


@connect_db
def insert(conn, cur, request: GolemJoinRequest):
    result = golem_dao.insert(cur, request)

    if not result:
        db_fail_routine(conn)
    conn.commit()
