#!/usr/bin/env python3
"""
Generate Soda Configuration Files

This script generates Soda configuration files with data source names
derived from the SNOWFLAKE_DATABASE environment variable.

Usage:
    python3 soda/generate_config.py
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
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

def generate_config_file(layer: str, template_path: Path, output_path: Path):
    """
    Generate a Soda configuration file for a given layer.
    
    Args:
        layer: Layer name (raw, staging, mart, quality)
        template_path: Path to template file
        output_path: Path to output file
    """
    database_name = get_database_name()
    data_source_name = database_to_data_source_name(database_name, layer)
    
    # Read template
    with open(template_path, 'r') as f:
        content = f.read()
    
    # Replace data source name placeholder
    content = content.replace('{{DATA_SOURCE_NAME}}', data_source_name)
    
    # Write output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(content)
    
    print(f"Generated {output_path} with data source: {data_source_name}")

def main():
    """Generate all configuration files."""
    config_dir = Path(__file__).parent / 'configuration'
    template_dir = Path(__file__).parent / 'configuration_templates'
    
    # Create template directory if it doesn't exist
    template_dir.mkdir(exist_ok=True)
    
    layers = ['raw', 'staging', 'mart', 'quality']
    
    for layer in layers:
        template_path = template_dir / f'configuration_{layer}.yml.template'
        output_path = config_dir / f'configuration_{layer}.yml'
        
        # If template exists, use it; otherwise use existing config as template
        if not template_path.exists():
            # Use existing config as base and update data source name
            if output_path.exists():
                with open(output_path, 'r') as f:
                    content = f.read()
                
                # Find and replace the data source name
                import re
                pattern = r'data_source\s+\w+_raw:|data_source\s+\w+_staging:|data_source\s+\w+_mart:|data_source\s+\w+_quality:'
                database_name = get_database_name()
                data_source_name = database_to_data_source_name(database_name, layer)
                replacement = f'data_source {data_source_name}:'
                
                content = re.sub(pattern, replacement, content)
                
                with open(output_path, 'w') as f:
                    f.write(content)
                
                print(f"Updated {output_path} with data source: {data_source_name}")
        else:
            generate_config_file(layer, template_path, output_path)

if __name__ == "__main__":
    main()

