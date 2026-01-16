#!/usr/bin/env python3
"""
Soda Configuration Helpers

Helper functions to derive data source names and other configuration values
from environment variables, particularly the database name.
"""

import os
from pathlib import Path
from dotenv import load_dotenv


def get_database_name():
    """
    Get the database name from environment variable.
    
    Returns:
        str: Database name (default: DATA_GOVERNANCE_PLATFORM)
    """
    # Try to load .env file if it exists
    env_paths = [
        Path('/opt/airflow/.env'),  # Airflow Docker container
        Path('.env'),  # Current directory
        Path(__file__).parent.parent / '.env',  # Project root
    ]
    
    for env_path in env_paths:
        if env_path.exists():
            load_dotenv(env_path, override=True)
            break
    else:
        load_dotenv(override=True)
    
    return os.getenv('SNOWFLAKE_DATABASE', 'DATA_GOVERNANCE_PLATFORM')


def database_to_data_source_name(database_name: str = None, layer: str = None) -> str:
    """
    Convert database name to data source name format.
    
    Converts database name (e.g., "DATA_GOVERNANCE_PLATFORM") to lowercase
    with underscores and appends the layer name.
    
    Args:
        database_name: Database name (if None, reads from environment)
        layer: Layer name (raw, staging, mart, quality)
    
    Returns:
        str: Data source name (e.g., "data_governance_platform_raw")
    
    Examples:
        >>> database_to_data_source_name("DATA_GOVERNANCE_PLATFORM", "raw")
        'data_governance_platform_raw'
        >>> database_to_data_source_name("MY_DB", "staging")
        'my_db_staging'
    """
    if database_name is None:
        database_name = get_database_name()
    
    # Convert to lowercase and ensure underscores
    data_source_base = database_name.lower().replace('-', '_')
    
    if layer:
        return f"{data_source_base}_{layer}"
    else:
        return data_source_base


def get_data_source_name(layer: str) -> str:
    """
    Get the data source name for a given layer.
    
    Args:
        layer: Layer name (raw, staging, mart, quality)
    
    Returns:
        str: Data source name for the layer
    """
    return database_to_data_source_name(layer=layer)


def get_all_data_source_names() -> dict:
    """
    Get all data source names for all layers.
    
    Returns:
        dict: Dictionary mapping layer names to data source names
    """
    layers = ['raw', 'staging', 'mart', 'quality']
    return {layer: get_data_source_name(layer) for layer in layers}


if __name__ == "__main__":
    # Test the functions
    print("Database name:", get_database_name())
    print("\nData source names:")
    for layer, name in get_all_data_source_names().items():
        print(f"  {layer}: {name}")

