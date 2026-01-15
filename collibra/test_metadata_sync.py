#!/usr/bin/env python3
"""
Test script for Collibra Metadata Synchronization Module

This script tests the Collibra metadata sync functionality without running
the full Airflow pipeline. Use this to verify your configuration and credentials.

Usage:
    python3 collibra/test_metadata_sync.py
"""

import os
import sys
import yaml
from pathlib import Path
from dotenv import load_dotenv

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Load environment variables
env_paths = [
    Path('.env'),  # Current directory
    Path('/opt/airflow/.env'),  # Airflow Docker container
    PROJECT_ROOT / '.env',  # Project root
]

env_loaded = False
for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path, override=True)
        print(f"✓ Loaded environment variables from {env_path}")
        env_loaded = True
        break

if not env_loaded:
    load_dotenv(override=True)
    print("✓ Loaded environment variables using default dotenv behavior")

# Import after loading env
from collibra.metadata_sync import CollibraMetadataSync

def print_section(title):
    """Print a formatted section header."""
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)

def print_success(message):
    """Print a success message."""
    print(f"✓ {message}")

def print_error(message):
    """Print an error message."""
    print(f"✗ {message}")

def print_info(message):
    """Print an info message."""
    print(f"  {message}")

def test_environment_variables():
    """Test that all required environment variables are set."""
    print_section("1. Testing Environment Variables")
    
    required_vars = {
        'COLLIBRA_BASE_URL': os.getenv('COLLIBRA_BASE_URL'),
        'COLLIBRA_USERNAME': os.getenv('COLLIBRA_USERNAME'),
        'COLLIBRA_PASSWORD': os.getenv('COLLIBRA_PASSWORD'),
    }
    
    all_set = True
    for var_name, var_value in required_vars.items():
        if var_value:
            print_success(f"{var_name}: SET")
        else:
            print_error(f"{var_name}: NOT SET")
            all_set = False
    
    return all_set

def test_collibra_client_initialization():
    """Test initializing the Collibra client."""
    print_section("2. Testing Collibra Client Initialization")
    
    try:
        client = CollibraMetadataSync()
        print_success("Collibra client initialized successfully")
        print_info(f"Base URL: {client.base_url}")
        return client
    except Exception as e:
        print_error(f"Failed to initialize Collibra client: {e}")
        return None

def test_load_config():
    """Test loading the configuration file."""
    print_section("3. Testing Configuration File")
    
    config_path = PROJECT_ROOT / "collibra" / "config.yml"
    
    if not config_path.exists():
        print_error(f"Config file not found at {config_path}")
        return None
    
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        
        print_success(f"Config file loaded from {config_path}")
        print_info(f"Database ID: {config.get('database_id', 'NOT SET')}")
        
        # Check each layer
        for layer in ['raw', 'staging', 'mart', 'quality']:
            if layer in config:
                schema_ids = config[layer].get('schema_connection_ids', [])
                print_info(f"{layer.upper()} layer: {len(schema_ids)} schema asset ID(s)")
                for idx, schema_id in enumerate(schema_ids, 1):
                    print_info(f"  {idx}. {schema_id}")
        
        return config
    except Exception as e:
        print_error(f"Failed to load config: {e}")
        return None

def test_get_database_connection_id(client, database_id):
    """Test getting database connection ID."""
    print_section("4. Testing Database Connection ID Resolution")
    
    try:
        connection_id = client.get_database_connection_id(database_id)
        print_success(f"Database connection ID resolved: {connection_id}")
        return connection_id
    except Exception as e:
        print_error(f"Failed to get database connection ID: {e}")
        return None

def test_list_schema_connections(client, database_connection_id, schema_asset_id=None):
    """Test listing schema connections."""
    print_section("5. Testing Schema Connections Listing")
    
    try:
        connections = client.list_schema_connections(
            database_connection_id=database_connection_id,
            schema_id=schema_asset_id
        )
        
        print_success(f"Found {len(connections)} schema connection(s)")
        
        for conn in connections:
            print_info(f"  - ID: {conn.get('id')}")
            print_info(f"    Name: {conn.get('name')}")
            print_info(f"    Schema ID: {conn.get('schemaId')}")
            print_info("")
        
        return connections
    except Exception as e:
        print_error(f"Failed to list schema connections: {e}")
        return []

def test_resolve_schema_connection_ids(client, database_id, schema_asset_ids, database_connection_id=None):
    """Test resolving schema asset IDs to connection IDs."""
    print_section("6. Testing Schema Asset ID to Connection ID Resolution")
    
    try:
        connection_ids = client.resolve_schema_connection_ids(
            database_id=database_id,
            schema_asset_ids=schema_asset_ids,
            database_connection_id=database_connection_id
        )
        
        print_success(f"Resolved {len(connection_ids)} schema connection ID(s)")
        for asset_id, conn_id in zip(schema_asset_ids, connection_ids):
            print_info(f"  Asset ID: {asset_id}")
            print_info(f"  → Connection ID: {conn_id}")
            print_info("")
        
        return connection_ids
    except Exception as e:
        print_error(f"Failed to resolve schema connection IDs: {e}")
        return []

def test_trigger_sync(client, database_id, schema_connection_ids, dry_run=True):
    """Test triggering metadata sync (optional, can be dry run)."""
    print_section("7. Testing Metadata Sync Trigger")
    
    if dry_run:
        print_info("DRY RUN MODE - Not actually triggering sync")
        print_info(f"Would trigger sync for database: {database_id}")
        print_info(f"Schema connection IDs: {schema_connection_ids}")
        return None
    
    try:
        result = client.trigger_metadata_sync(
            database_id=database_id,
            schema_connection_ids=schema_connection_ids
        )
        print_success(f"Metadata sync triggered successfully")
        print_info(f"Job ID: {result.get('jobId')}")
        return result
    except Exception as e:
        print_error(f"Failed to trigger metadata sync: {e}")
        return None

def main():
    """Run all tests."""
    print("=" * 60)
    print("  Collibra Metadata Sync Module Test")
    print("=" * 60)
    print("\nThis script tests the Collibra metadata synchronization")
    print("functionality to verify your configuration and credentials.\n")
    
    # Test 1: Environment variables
    if not test_environment_variables():
        print("\n✗ Environment variables test failed. Please set all required variables.")
        sys.exit(1)
    
    # Test 2: Client initialization
    client = test_collibra_client_initialization()
    if not client:
        print("\n✗ Client initialization failed. Please check your credentials.")
        sys.exit(1)
    
    # Test 3: Load config
    config = test_load_config()
    if not config:
        print("\n✗ Config loading failed. Please check your config.yml file.")
        sys.exit(1)
    
    database_id = config.get('database_id')
    if not database_id:
        print("\n✗ Database ID not found in config.yml")
        sys.exit(1)
    
    # Test 4: Get database connection ID
    database_connection_id = test_get_database_connection_id(client, database_id)
    if not database_connection_id:
        print("\n✗ Database connection ID resolution failed.")
        sys.exit(1)
    
    # Test 5: List schema connections for RAW layer (as example)
    raw_schema_ids = config.get('raw', {}).get('schema_connection_ids', [])
    if raw_schema_ids:
        test_list_schema_connections(
            client, 
            database_connection_id, 
            schema_asset_id=raw_schema_ids[0]
        )
    
    # Test 6: Resolve schema connection IDs for RAW layer
    if raw_schema_ids:
        connection_ids = test_resolve_schema_connection_ids(
            client,
            database_id,
            raw_schema_ids,
            database_connection_id
        )
        
        # Test 7: Trigger sync (dry run by default)
        if connection_ids:
            test_trigger_sync(
                client,
                database_id,
                connection_ids,
                dry_run=True  # Set to False to actually trigger
            )
    
    # Summary
    print_section("Test Summary")
    print_success("All tests completed!")
    print_info("If you want to actually trigger a metadata sync, set dry_run=False")
    print_info("in the test_trigger_sync() call at the end of this script.")
    print("\n" + "=" * 60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

