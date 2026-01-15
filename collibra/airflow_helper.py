#!/usr/bin/env python3
"""
Airflow Helper Functions for Collibra Metadata Synchronization

This module provides Python functions that can be used as Airflow PythonOperators
to trigger Collibra metadata synchronization.
"""

import os
import sys
import yaml
import logging
from pathlib import Path
from typing import Optional

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from collibra.metadata_sync import CollibraMetadataSync

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def load_config():
    """Load Collibra configuration from config.yml."""
    config_path = PROJECT_ROOT / "collibra" / "config.yml"
    
    if not config_path.exists():
        raise FileNotFoundError(
            f"Collibra config file not found at {config_path}. "
            "Please create collibra/config.yml with your database and schema IDs."
        )
    
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    return config


def get_database_connection_id(config: dict, sync_client: CollibraMetadataSync) -> Optional[str]:
    """Get database connection ID from config or resolve it."""
    # Check if explicitly provided in config
    if 'database_connection_id' in config and config['database_connection_id']:
        return config['database_connection_id']
    
    # Otherwise, resolve from database asset ID
    database_id = config.get('database_id')
    if not database_id:
        return None
    
    try:
        return sync_client.get_database_connection_id(database_id)
    except Exception as e:
        logger.warning(f"Could not resolve database connection ID: {e}")
        return None


def sync_raw_metadata(**context):
    """Airflow task function to sync RAW layer metadata."""
    logger.info("Starting Collibra metadata sync for RAW layer")
    
    try:
        config = load_config()
        database_id = config['database_id']
        # Config contains schema asset IDs, not connection IDs
        schema_asset_ids = config.get('raw', {}).get('schema_connection_ids', [])
        
        if not schema_asset_ids:
            logger.warning("No schema asset IDs configured for RAW layer. Skipping sync.")
            return
        
        sync_client = CollibraMetadataSync()
        
        # Resolve schema asset IDs to connection IDs
        database_connection_id = get_database_connection_id(config, sync_client)
        schema_connection_ids = sync_client.resolve_schema_connection_ids(
            database_id=database_id,
            schema_asset_ids=schema_asset_ids,
            database_connection_id=database_connection_id
        )
        
        result = sync_client.sync_and_wait(
            database_id=database_id,
            schema_connection_ids=schema_connection_ids,  # Use resolved connection IDs
            max_wait_time=3600,  # 1 hour timeout
            poll_interval=10     # Check every 10 seconds
        )
        
        logger.info(f"RAW layer metadata sync completed: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to sync RAW layer metadata: {e}")
        raise


def sync_staging_metadata(**context):
    """Airflow task function to sync STAGING layer metadata."""
    logger.info("Starting Collibra metadata sync for STAGING layer")
    
    try:
        config = load_config()
        database_id = config['database_id']
        # Config contains schema asset IDs, not connection IDs
        schema_asset_ids = config.get('staging', {}).get('schema_connection_ids', [])
        
        if not schema_asset_ids:
            logger.warning("No schema asset IDs configured for STAGING layer. Skipping sync.")
            return
        
        sync_client = CollibraMetadataSync()
        
        # Resolve schema asset IDs to connection IDs
        database_connection_id = get_database_connection_id(config, sync_client)
        schema_connection_ids = sync_client.resolve_schema_connection_ids(
            database_id=database_id,
            schema_asset_ids=schema_asset_ids,
            database_connection_id=database_connection_id
        )
        
        result = sync_client.sync_and_wait(
            database_id=database_id,
            schema_connection_ids=schema_connection_ids,  # Use resolved connection IDs
            max_wait_time=3600,  # 1 hour timeout
            poll_interval=10     # Check every 10 seconds
        )
        
        logger.info(f"STAGING layer metadata sync completed: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to sync STAGING layer metadata: {e}")
        raise


def sync_mart_metadata(**context):
    """Airflow task function to sync MART layer metadata."""
    logger.info("Starting Collibra metadata sync for MART layer")
    
    try:
        config = load_config()
        database_id = config['database_id']
        # Config contains schema asset IDs, not connection IDs
        schema_asset_ids = config.get('mart', {}).get('schema_connection_ids', [])
        
        if not schema_asset_ids:
            logger.warning("No schema asset IDs configured for MART layer. Skipping sync.")
            return
        
        sync_client = CollibraMetadataSync()
        
        # Resolve schema asset IDs to connection IDs
        database_connection_id = get_database_connection_id(config, sync_client)
        schema_connection_ids = sync_client.resolve_schema_connection_ids(
            database_id=database_id,
            schema_asset_ids=schema_asset_ids,
            database_connection_id=database_connection_id
        )
        
        result = sync_client.sync_and_wait(
            database_id=database_id,
            schema_connection_ids=schema_connection_ids,  # Use resolved connection IDs
            max_wait_time=3600,  # 1 hour timeout
            poll_interval=10     # Check every 10 seconds
        )
        
        logger.info(f"MART layer metadata sync completed: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to sync MART layer metadata: {e}")
        raise

