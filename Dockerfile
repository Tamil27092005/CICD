FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /opt/app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    APP_ENV=production

RUN useradd --create-home --shell /usr/sbin/nologin appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health', timeout=3)" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.main:app"]
