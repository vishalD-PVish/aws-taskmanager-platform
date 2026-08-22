# Kick things off with a tiny, official Python Linux image—nice and lightweight!
FROM python:3.12-slim

# Keep Python neat inside containers—no unnecessary bytecode clutter.
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set a cozy, predictable spot for your app files.
WORKDIR /app

# Add a dedicated, non-root user for extra security—because safety first!
RUN addgroup --system app && adduser --system --ingroup app app

# Bring in your dependencies first—so Docker can reuse this layer if things change later!
COPY requirements.txt ./

# Install only the dependencies you need—no extra cache files, keeping things lean.
RUN pip install --no-cache-dir -r requirements.txt

# Copy your main app code, making sure it’s owned by the 'app' user.
COPY --chown=app:app main.py ./

# Run your FastAPI app as the safer, non-root user.
USER app

# Let Docker know your app’s listening on port 8080.
EXPOSE 8080

# to start your FastAPI app with Uvicorn when the container launches.
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
