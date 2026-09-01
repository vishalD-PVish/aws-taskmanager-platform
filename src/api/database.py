import os
from collections.abc import Generator
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
load_dotenv()
database_url = os.getenv("DATABASE_URL")
if not database_url:
    raise RuntimeError("Oops! The DATABASE_URL environment variable is missing. Please set it up.")
engine = create_engine(
    database_url,
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)
class Base(DeclarativeBase):
    pass
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
