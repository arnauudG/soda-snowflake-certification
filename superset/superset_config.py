#!/usr/bin/env python3
"""
Superset Configuration

Configuration settings for Apache Superset integration with the Data Governance Platform project.
Includes database connections, security settings, and feature flags.
"""

import os

# Database configuration
SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'postgresql://superset:superset@superset-db:5432/superset')

# Redis configuration for caching
REDIS_URL = os.environ.get('REDIS_URL', 'redis://superset-redis:6379/0')

# Security
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'your-superset-secret-key-here')

# Feature flags
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_NATIVE_FILTERS": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "DASHBOARD_RBAC": True,
    "ALLOW_FILE_UPLOAD": True,
    "ENABLE_EXPLORE_JSON_CSRF_PROTECTION": False,
}

# Data quality specific configurations
ENABLE_PROXY_FIX = True
WTF_CSRF_ENABLED = True

# File upload settings
UPLOAD_FOLDER = '/app/soda_data'
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size

# Database connection settings for file uploads
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'superset',
        'USER': 'superset',
        'PASSWORD': 'superset',
        'HOST': 'superset-db',
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'disable',  # Disable SSL for local database
        }
    }
}

# Logging
LOG_LEVEL = 'INFO'
