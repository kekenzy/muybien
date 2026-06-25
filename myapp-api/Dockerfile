FROM python:3.11-slim

WORKDIR /root/myapp-api

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY django/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY django/ .

EXPOSE 8000
