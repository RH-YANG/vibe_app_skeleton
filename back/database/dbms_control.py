import functools

import psycopg2
import psycopg2.extras
from fastapi import HTTPException, status

import config.env_config as env_config


def get_connection():
    return psycopg2.connect(
        host=env_config.DB_HOST,
        port=env_config.DB_PORT,
        dbname=env_config.DB_NAME,
        user=env_config.DB_USER,
        password=env_config.DB_PWD,
    )


def connect_db(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        conn = get_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

        try:
            return func(conn, cur, *args, **kwargs)
        finally:
            cur.close()
            conn.close()

    return wrapper


def connect_db_tuple(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        conn = get_connection()
        cur = conn.cursor()

        try:
            return func(conn, cur, *args, **kwargs)
        finally:
            cur.close()
            conn.close()

    return wrapper


def connect_db_log_tuple(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        conn = get_connection()
        cur = conn.cursor()

        try:
            return func(conn, cur, *args, **kwargs)
        finally:
            print(f"[SQL LOG] {cur.query}")
            cur.close()
            conn.close()

    return wrapper


def db_fail_routine(conn):
    conn.rollback()
    raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Failure without errors")
