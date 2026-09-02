import os
from collections.abc import Generator
from urllib.parse import quote_plus
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
load_dotenv()
database_url = os.getenv("DATABASE_URL")
if not database_url:
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("DB_NAME")
    db_username = os.getenv("DB_USERNAME")
    db_password = os.getenv("DB_PASSWORD")
    required_values = {
        "DB_HOST": db_host,
        "DB_NAME": db_name,
        "DB_USERNAME": db_username,
        "DB_PASSWORD": db_password,
    }
    missing_values = [
        name for name, value in required_values.items() if not value
    ]
    if missing_values:
        missing = ", ".join(missing_values)
        raise RuntimeError(
            f"Oops! Looks like your database config is missing: {missing}"
        )
    database_url = (
        "postgresql+psycopg://"
        f"{quote_plus(db_username)}:{quote_plus(db_password)}"
        f"@{db_host}:{db_port}/{db_name}"
    )
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
