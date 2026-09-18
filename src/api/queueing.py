import json
import os
from uuid import UUID

import boto3
from botocore.exceptions import BotoCoreError, ClientError


class ExportQueueError(Exception):
    """Raised when an export job cannot be published to SQS."""


def publish_export_job(export_job_id: UUID) -> None:
    """Publish one export job identifier to the configured SQS queue."""
    queue_url = os.getenv("EXPORT_QUEUE_URL")

    if not queue_url:
        raise ExportQueueError(
            "EXPORT_QUEUE_URL environment variable is required."
        )

    message_body = json.dumps(
        {
            "export_job_id": str(export_job_id),
        }
    )

    try:
        boto3.client("sqs").send_message(
            QueueUrl=queue_url,
            MessageBody=message_body,
        )
    except (BotoCoreError, ClientError) as error:
        raise ExportQueueError(
            "Export job could not be published to SQS."
        ) from error
