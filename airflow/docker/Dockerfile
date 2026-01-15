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

# Copy requirements file
COPY requirements.txt /tmp/requirements.txt

# Install Python dependencies from requirements file
# Install critical dependencies first to establish correct versions
RUN pip install --no-cache-dir \
    "protobuf>=6.30.0,<6.31.0" \
    "pydantic>=2.5.2,<3.0.0" \
    "pyarrow>=15.0.0,<22.0.0" \
    python-dotenv==1.0.1 \
    "pandas>=2.2.2,<2.4" \
    setuptools \
    Faker \
    dbt-core==1.10.11 \
    dbt-snowflake==1.10.2
# Upgrade conflicting packages to support protobuf 6.x
RUN pip install --no-cache-dir --upgrade \
    "google-api-core>=2.23.0" \
    "googleapis-common-protos>=1.66.0" \
    "proto-plus>=1.26.0" || true
# Install soda-snowflake from Soda Cloud PyPI index with pinned version
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed -i https://pypi.cloud.soda.io "soda-snowflake==1.12.24"
# Ensure critical dependencies remain at correct versions (dbt requires protobuf>=6.0,<7.0)
RUN pip install --no-cache-dir --upgrade \
    "protobuf>=6.30.0,<6.31.0" \
    "pydantic>=2.5.2,<3.0.0" \
    "pyarrow>=15.0.0,<22.0.0"

# Set working directory
WORKDIR /opt/airflow

# Copy project files (these will be mounted as volumes in docker-compose.yml)
# No need to copy files here as they are mounted as volumes

# Set permissions (scripts will be mounted as volumes)
# RUN chmod +x /opt/airflow/scripts/*.sh
