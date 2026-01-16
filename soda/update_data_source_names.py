#!/usr/bin/env python3
"""
Update Data Source Names in Soda Configuration Files

This script updates the data source names in all Soda configuration files
based on the SNOWFLAKE_DATABASE environment variable.

Usage:
    python3 soda/update_data_source_names.py
"""

import os
import re
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add project root to Python path for imports
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from soda.helpers import database_to_data_source_name, get_database_name

# Load environment variables
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


def update_config_file(config_path: Path, layer: str):
    """
    Update data source name in a configuration file.
    
    Args:
        config_path: Path to configuration file
        layer: Layer name (raw, staging, mart, quality)
    """
    if not config_path.exists():
        print(f"Warning: {config_path} does not exist, skipping...")
        return False
    
    database_name = get_database_name()
    new_data_source_name = database_to_data_source_name(database_name, layer)
    
    # Read the file
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Find the current data source name pattern
    # Pattern: data_source <name>:
    pattern = r'data_source\s+(\w+):'
    match = re.search(pattern, content)
    
    if not match:
        print(f"Warning: Could not find data_source in {config_path}")
        return False
    
    old_data_source_name = match.group(1)
    
    if old_data_source_name == new_data_source_name:
        print(f"✓ {config_path.name}: Already using '{new_data_source_name}'")
        return True
    
    # Replace the data source name (use more specific pattern to avoid replacing comments)
    # Match: data_source <name>: (not in comments)
    lines = content.split('\n')
    updated_lines = []
    replaced = False
    
    for line in lines:
        # Check if this line contains the data_source definition (not a comment)
        if not line.strip().startswith('#') and re.search(pattern, line):
            if not replaced:
                # Replace the data source name in this line
                line = re.sub(
                    pattern,
                    f'data_source {new_data_source_name}:',
                    line,
                    count=1
                )
                replaced = True
        updated_lines.append(line)
    
    if not replaced:
        print(f"Warning: Could not replace data_source in {config_path}")
        return False
    
    # Write back
    content = '\n'.join(updated_lines)
    with open(config_path, 'w') as f:
        f.write(content)
    
    print(f"✓ {config_path.name}: Updated '{old_data_source_name}' → '{new_data_source_name}'")
    return True


def main():
    """Update all configuration files."""
    config_dir = Path(__file__).parent / 'configuration'
    
    if not config_dir.exists():
        print(f"Error: Configuration directory not found: {config_dir}")
        sys.exit(1)
    
    database_name = get_database_name()
    print(f"Database name: {database_name}")
    print(f"Updating data source names in configuration files...\n")
    
    layers = {
        'raw': config_dir / 'configuration_raw.yml',
        'staging': config_dir / 'configuration_staging.yml',
        'mart': config_dir / 'configuration_mart.yml',
        'quality': config_dir / 'configuration_quality.yml',
    }
    
    updated_count = 0
    for layer, config_path in layers.items():
        if update_config_file(config_path, layer):
            updated_count += 1
    
    print(f"\n✓ Updated {updated_count}/{len(layers)} configuration files")
    print(f"\nData source names are now:")
    for layer in layers.keys():
        data_source_name = database_to_data_source_name(database_name, layer)
        print(f"  {layer}: {data_source_name}")


if __name__ == "__main__":
    main()

