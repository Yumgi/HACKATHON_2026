FROM python:3.11-slim

WORKDIR /opt/acme-app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libldap2-dev libsasl2-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

RUN mkdir -p /opt/acme-app/logs \
    && useradd -r -u 1001 appuser \
    && chown -R appuser:appuser /opt/acme-app

USER appuser

EXPOSE 5000

ENV FLASK_ENV=production \
    PYTHONUNBUFFERED=1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", \
     "--access-logfile", "/opt/acme-app/logs/access.log", \
     "--error-logfile", "/opt/acme-app/logs/error.log", \
     "app:create_app()"]
