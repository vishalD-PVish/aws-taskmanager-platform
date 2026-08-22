from fastapi import FastAPI

app = FastAPI(
    title="AWS Task Manager Platform API",
    version="0.1.0",
    description="API for the AWS Task Manager portfolio project.",
)


@app.get("/", tags=["service"])
def root() -> dict[str, str]:
    return {
        "service": "aws-taskmanager-api",
        "message": "API is running",
    }


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    return {
        "status": "ok",
    }
