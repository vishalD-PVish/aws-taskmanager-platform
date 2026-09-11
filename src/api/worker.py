import csv
import json
import logging
import os
from datetime import datetime, timezone
from io import StringIO
from typing import Any
from uuid import UUID
import boto3
from sqlalchemy import select
from sqlalchemy.orm import Session
from database import SessionLocal
from models import ExportJob, Task
logger = logging.getLogger()
logger.setLevel(logging.INFO)
s3_client = boto3.client("s3")
class PermanentMessageError(Exception):
    """Raised when an SQS message cannot ever be processed."""
def handler(event: dict[str, Any], context: Any) -> dict[str, list[dict[str, str]]]:
    """Process export requests delivered from the primary SQS queue."""
    batch_item_failures = []
    for record in event.get("Records", []):
        try:
            export_job_id = get_export_job_id(record)
            process_export_job(export_job_id)
        except PermanentMessageError as error:
            logger.error("Discarding permanently invalid export message: %s", error)
        except Exception:
            logger.exception(
                "Export processing failed for SQS message %s",
                record.get("messageId"),
            )
            batch_item_failures.append(
                {"itemIdentifier": record["messageId"]}
            )
    return {"batchItemFailures": batch_item_failures}
def dlq_handler(
    event: dict[str, Any],
    context: Any,
) -> dict[str, list[dict[str, str]]]:
    """Mark jobs as failed after the primary queue exhausts its retries."""
    batch_item_failures = []
    for record in event.get("Records", []):
        try:
            export_job_id = get_export_job_id(record)
            mark_export_job_failed(export_job_id)
        except PermanentMessageError as error:
            logger.error("Discarding permanently invalid DLQ message: %s", error)
        except Exception:
            logger.exception(
                "Could not mark export job as failed for DLQ message %s",
                record.get("messageId"),
            )
            batch_item_failures.append(
                {"itemIdentifier": record["messageId"]}
            )
    return {"batchItemFailures": batch_item_failures}
def get_export_job_id(record: dict[str, Any]) -> UUID:
    """Extract and validate an export job ID from an SQS message body."""
    try:
        message = json.loads(record["body"])
        return UUID(message["export_job_id"])
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        raise PermanentMessageError(
            "Message body must contain a valid export_job_id."
        ) from error
def process_export_job(export_job_id: UUID) -> None:
    """Create a CSV export, store it privately in S3, and update the job."""
    db = SessionLocal()
    try:
        export_job = db.get(ExportJob, export_job_id)
        if export_job is None:
            logger.warning("Export job %s no longer exists.", export_job_id)
            return
        if export_job.status == "completed":
            logger.info("Export job %s is already complete.", export_job_id)
            return
        export_job.status = "processing"
        export_job.error_message = None
        db.commit()
        csv_contents = build_tasks_csv(db)
        s3_key = f"exports/{export_job.id}.csv"
        s3_client.put_object(
            Bucket=get_export_bucket_name(),
            Key=s3_key,
            Body=csv_contents.encode("utf-8"),
            ContentType="text/csv; charset=utf-8",
        )
        export_job.status = "completed"
        export_job.completed_at = datetime.now(timezone.utc)
        export_job.s3_key = s3_key
        export_job.error_message = None
        db.commit()
        logger.info("Export job %s completed successfully.", export_job_id)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
def mark_export_job_failed(export_job_id: UUID) -> None:
    """Persist a safe final failure status after SQS retries are exhausted."""
    db = SessionLocal()
    try:
        export_job = db.get(ExportJob, export_job_id)
        if export_job is None:
            logger.warning("Export job %s no longer exists.", export_job_id)
            return
        if export_job.status == "completed":
            logger.info(
                "Export job %s completed before DLQ processing.",
                export_job_id,
            )
            return
        export_job.status = "failed"
        export_job.completed_at = datetime.now(timezone.utc)
        export_job.error_message = (
            "Export processing failed after all retry attempts."
        )
        db.commit()
        logger.error("Export job %s marked as failed.", export_job_id)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
def build_tasks_csv(db: Session) -> str:
    """Serialize the current task collection into CSV format."""
    output = StringIO()
    writer = csv.DictWriter(
        output,
        fieldnames=[
            "id",
            "title",
            "description",
            "status",
            "created_at",
            "updated_at",
        ],
        lineterminator="\n",
    )
    writer.writeheader()
    statement = select(Task).order_by(Task.id.asc())
    for task in db.scalars(statement):
        writer.writerow(
            {
                "id": task.id,
                "title": task.title,
                "description": task.description or "",
                "status": task.status,
                "created_at": task.created_at.isoformat(),
                "updated_at": task.updated_at.isoformat(),
            }
        )
    return output.getvalue()
def get_export_bucket_name() -> str:
    """Return the required private S3 bucket name from Lambda configuration."""
    bucket_name = os.getenv("EXPORT_BUCKET_NAME")
    if not bucket_name:
        raise RuntimeError("EXPORT_BUCKET_NAME environment variable is required.")
    return bucket_name
