FROM python:3.12-slim

# System Dependencies (git for dbt, libpq for postgres)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dagster/app

COPY local_Ops/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Ingestion Package (Editable Mode logic handled in Compose)
# We copy it here for the build layer, but Compose over-mounts it.
COPY ingestion /opt/dagster/ingestion
RUN pip install -e /opt/dagster/ingestion

# Environment Variables for Paths
ENV DAGSTER_HOME=/opt/dagster/dagster_home
ENV PYTHONPATH="${PYTHONPATH}:/opt/dagster/ingestion"

# Create the Dagster Home directory
RUN mkdir -p $DAGSTER_HOME
