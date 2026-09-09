from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field
class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
class TaskRead(BaseModel):
    id: int
    title: str
    description: str | None = None
    status: str
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
class ExportJobRead(BaseModel):
    id: UUID
    status: str
    requested_at: datetime
    completed_at: datetime | None = None
    error_message: str | None = None
    model_config = ConfigDict(from_attributes=True)
