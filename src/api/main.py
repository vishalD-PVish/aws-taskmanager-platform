from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import get_db
from models import Task
from schemas import TaskCreate, TaskRead

app = FastAPI(
    title="AWS Task Manager Platform API",
    version="0.2.0",
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


@app.post(
    "/tasks",
    response_model=TaskRead,
    status_code=status.HTTP_201_CREATED,
    tags=["tasks"],
)
def create_task(
    payload: TaskCreate,
    db: Session = Depends(get_db),
) -> Task:
    task = Task(**payload.model_dump())

    db.add(task)
    db.commit()
    db.refresh(task)

    return task


@app.get(
    "/tasks",
    response_model=list[TaskRead],
    tags=["tasks"],
)
def list_tasks(
    db: Session = Depends(get_db),
) -> list[Task]:
    statement = select(Task).order_by(Task.id.desc())

    return list(db.scalars(statement).all())


@app.get(
    "/tasks/{task_id}",
    response_model=TaskRead,
    tags=["tasks"],
)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
) -> Task:
    task = db.get(Task, task_id)

    if task is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found",
        )

    return task
