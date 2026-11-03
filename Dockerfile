# Stage 1: Build dependencies
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Final lightweight & secure runtime
FROM python:3.11-slim AS runner
WORKDIR /app

RUN adduser --disabled-password --gecos "" appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY app /app/app

USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
