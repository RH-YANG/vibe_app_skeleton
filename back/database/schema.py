from typing import Optional
from datetime import datetime

from pydantic import BaseModel


class Golem(BaseModel):
    golem_seq: Optional[int] = None
    email: Optional[str] = None
    pwd: Optional[str] = None
    name: Optional[str] = None


class GolemJoinRequest(BaseModel):
    email: str
    pwd: str
    name: str


class GolemResponse(BaseModel):
    golem_seq: int
    email: str
    name: str
