from fastapi import APIRouter

import service.golem_service as golem_service
from database.schema import GolemJoinRequest, GolemResponse

router = APIRouter(prefix="/golem", tags=["golem"])


@router.post("/join")
def join(request: GolemJoinRequest) -> GolemResponse:
    return golem_service.insert(request)
