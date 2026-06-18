import uvicorn
from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware

import config.env_config as env_config
from api import golem_api

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


router = APIRouter()
router.include_router(golem_api.router)
app.include_router(router)


@app.get("/health")
def health() -> str:
    return "Hello World? HI?"


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=env_config.APP_PORT, reload=True)
