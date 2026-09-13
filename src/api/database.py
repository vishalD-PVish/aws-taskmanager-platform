import json
import os
from collections.abc import Generator
from urllib.parse import quote_plus
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
load_dotenv()
def get_database_credentials_from_secret(
    secret_arn: str,
) -> tuple[str, str]:
    """Read PostgreSQL credentials from an AWS Secrets Manager JSON secret."""
    import boto3
    response = boto3.client("secretsmanager").get_secret_value(
        SecretId=secret_arn,
    )
    secret_string = response.get("SecretString")
    if not secret_string:
        raise RuntimeError("Database secret does not contain a SecretString.")
    try:
        secret = json.loads(secret_string)
        username = secret["username"]
        password = secret["password"]
    except (json.JSONDecodeError, KeyError) as error:
        raise RuntimeError(
            "Database secret must contain username and password fields."
        ) from error
    return username, password
database_url = os.getenv("DATABASE_URL")
if not database_url:
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("DB_NAME")
    db_username = os.getenv("DB_USERNAME")
    db_password = os.getenv("DB_PASSWORD")
    if not db_username or not db_password:
        db_secret_arn = os.getenv("DB_SECRET_ARN")
        if db_secret_arn:
            db_username, db_password = get_database_credentials_from_secret(
                db_secret_arn,
            )
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
            f"Database configuration is missing: {missing}"
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
