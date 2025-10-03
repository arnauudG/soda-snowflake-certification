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
# Install soda-snowflake from Soda Cloud PyPI index
RUN pip install --no-cache-dir -i https://pypi.cloud.soda.io soda-snowflake
# Install other dependencies from standard PyPI
RUN pip install --no-cache-dir python-dotenv==1.0.1 pandas>=2.2.2 pyarrow setuptools Faker dbt-core==1.10.11 dbt-snowflake==1.10.2

# Set working directory
WORKDIR /opt/airflow

# Copy project files (these will be mounted as volumes in docker-compose.yml)
# No need to copy files here as they are mounted as volumes

# Set permissions (scripts will be mounted as volumes)
# RUN chmod +x /opt/airflow/scripts/*.sh
