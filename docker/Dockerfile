FROM apache/airflow:2.9.3-python3.11

# Switch to root to install system dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Switch back to airflow user
USER airflow

# Install Python dependencies
RUN pip install --no-cache-dir \
    dbt-core==1.10.11 \
    dbt-snowflake==1.10.2 \
    soda-core==3.5.5 \
    soda-core-snowflake==3.5.5 \
    python-dotenv \
    pandas \
    pyarrow \
    setuptools \
    Faker

# Set working directory
WORKDIR /opt/airflow

# Copy project files (these will be mounted as volumes in docker-compose.yml)
# No need to copy files here as they are mounted as volumes

# Set permissions (scripts will be mounted as volumes)
# RUN chmod +x /opt/airflow/scripts/*.sh
