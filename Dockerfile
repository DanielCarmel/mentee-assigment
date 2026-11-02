# syntax=docker/dockerfile:1

# ----- Builder stage: install dependencies into a venv -----
FROM python:3.12-slim AS builder

WORKDIR /app

# Create an isolated virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install deps first for better layer caching
COPY app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ----- Final stage: minimal runtime image -----
FROM python:3.12-slim AS runtime

# Version is injected at build time from the git tag and baked into the image
ARG APP_VERSION=0.0.0-dev
ENV APP_VERSION=${APP_VERSION}

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create a non-root user to run the service
RUN useradd --create-home --uid 10001 appuser

WORKDIR /app

# Copy the prepared virtual environment and the application code
COPY --from=builder /opt/venv /opt/venv
COPY app/ ./

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

CMD ["uvicorn", "hello_world:app", "--host", "0.0.0.0", "--port", "8000"]
