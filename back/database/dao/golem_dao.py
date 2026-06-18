from database.schema import Golem, GolemJoinRequest


def select_by_email(cur, email: str) -> Golem:
    query = '''
        SELECT golem_seq
             , email
             , pwd
             , name
          FROM golem
         WHERE email = %s
    '''
    cur.execute(query, (email,))
    record = cur.fetchone()

    if record:
        return Golem(**record)
    return Golem()


def insert(cur, request: GolemJoinRequest) -> int:
    query = '''
        INSERT INTO golem (email, pwd, name)
        VALUES (%s, %s, %s)
    '''
    cur.execute(query, (request.email, request.pwd, request.name))
    return cur.rowcount
