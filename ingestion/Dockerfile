FROM python:3.12-slim

WORKDIR /app

COPY . .

# Install the package in editable mode or just install requirements if present
# Assuming pyproject.toml is present
RUN pip install --no-cache-dir .

RUN useradd -m appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["python", "main.py"]
CMD ["--help"]