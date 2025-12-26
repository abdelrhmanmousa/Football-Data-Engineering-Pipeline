FROM python:3.12-slim

RUN apt-get update && apt-get install -y git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


WORKDIR /app


# Chunk 2: dbt-core (Medium)
# Installing this separately saves a successful upload chunk
RUN pip install --no-cache-dir dbt-core

# Chunk 3: dbt-snowflake (The heavy one)
# Breaking this out means if it succeeds once, you're done forever
RUN pip install --no-cache-dir dbt-snowflake
# Install dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
# Copy dbt project
COPY . . 

RUN dbt deps