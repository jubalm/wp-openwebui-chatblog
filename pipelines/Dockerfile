FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy pipeline code
COPY wordpress_oauth.py .
COPY wordpress_client.py .
COPY content_automation.py .
COPY openwebui_wordpress_pipeline.py .

# Create data directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 9099

# Run the pipeline
CMD ["python", "wordpress_oauth.py"]