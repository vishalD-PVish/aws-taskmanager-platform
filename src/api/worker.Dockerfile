FROM public.ecr.aws/lambda/python:3.12
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
COPY requirements-worker.txt ./
RUN pip install --no-cache-dir \
    --target "${LAMBDA_TASK_ROOT}" \
    -r requirements-worker.txt
COPY database.py models.py worker.py ${LAMBDA_TASK_ROOT}/
CMD ["worker.handler"]
