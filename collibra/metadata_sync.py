#!/usr/bin/env python3
"""
Collibra Metadata Synchronization Module

This module provides functions to trigger and monitor Collibra metadata synchronization
for database assets and schema connections.
"""

import os
import time
import requests
import logging
from typing import List, Optional, Dict
from pathlib import Path
from dotenv import load_dotenv

# Configure logging first
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
# Try multiple locations: current directory, /opt/airflow (Docker), and parent directories
env_paths = [
    Path('/opt/airflow/.env'),  # Airflow Docker container (priority)
    Path('.env'),  # Current directory
    Path(__file__).parent.parent / '.env',  # Project root (if running locally)
]

env_loaded = False
for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path, override=True)
        logger.info(f"Loaded environment variables from {env_path}")
        env_loaded = True
        break

if not env_loaded:
    # Fallback: try default load_dotenv behavior
    load_dotenv(override=True)
    logger.info("Loaded environment variables using default dotenv behavior")


class CollibraMetadataSync:
    """Handles Collibra metadata synchronization operations."""
    
    def __init__(self):
        """Initialize Collibra client with credentials from environment."""
        self.base_url = os.getenv('COLLIBRA_BASE_URL')
        self.username = os.getenv('COLLIBRA_USERNAME')
        self.password = os.getenv('COLLIBRA_PASSWORD')
        
        # Debug logging
        logger.debug(f"COLLIBRA_BASE_URL: {'SET' if self.base_url else 'NOT SET'}")
        logger.debug(f"COLLIBRA_USERNAME: {'SET' if self.username else 'NOT SET'}")
        logger.debug(f"COLLIBRA_PASSWORD: {'SET' if self.password else 'NOT SET'}")
        
        if not all([self.base_url, self.username, self.password]):
            missing = []
            if not self.base_url:
                missing.append('COLLIBRA_BASE_URL')
            if not self.username:
                missing.append('COLLIBRA_USERNAME')
            if not self.password:
                missing.append('COLLIBRA_PASSWORD')
            
            raise ValueError(
                f"Missing Collibra credentials: {', '.join(missing)}. "
                "Please set COLLIBRA_BASE_URL, COLLIBRA_USERNAME, and COLLIBRA_PASSWORD "
                "in your .env file or as environment variables."
            )
        
        # Remove trailing slash from base URL if present
        self.base_url = self.base_url.rstrip('/')
        
        # Create session for authentication
        self.session = requests.Session()
        self.session.auth = (self.username, self.password)
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
        
        logger.info(f"Initialized Collibra client for {self.base_url}")
    
    def get_database_connection_id(self, database_id: str) -> str:
        """
        Get the database connection ID from a database asset ID.
        
        Args:
            database_id: The UUID of the Database asset in Collibra
        
        Returns:
            The database connection ID
        
        Raises:
            requests.exceptions.RequestException: If the API request fails
            ValueError: If database connection not found
        """
        # Get database asset details to find connection ID
        url = f"{self.base_url}/rest/2.0/assets/{database_id}"
        
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            asset = response.json()
            # The connection ID is typically in a relation or attribute
            # Try to find it in relations or attributes
            relations = asset.get('relations', [])
            for relation in relations:
                if relation.get('type', {}).get('name') == 'Database Connection':
                    target_id = relation.get('target', {}).get('id')
                    if target_id:
                        logger.info(f"Found database connection ID: {target_id}")
                        return target_id
            
            # Alternative: check if there's a direct attribute
            # This might vary by Collibra setup, so we'll try a common pattern
            raise ValueError(
                f"Could not find database connection ID for database {database_id}. "
                "Please check your Collibra setup or provide database connection ID directly."
            )
            
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error getting database connection: {e}")
            if e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error getting database connection: {e}")
            raise
    
    def list_schema_connections(
        self,
        database_connection_id: str,
        schema_id: Optional[str] = None,
        limit: int = 500,
        offset: int = 0
    ) -> List[Dict]:
        """
        List schema connections for a database connection.
        
        Args:
            database_connection_id: The UUID of the database connection
            schema_id: Optional schema asset ID to filter by
            limit: Maximum number of results (default: 500)
            offset: Offset for pagination (default: 0)
        
        Returns:
            List of schema connection dictionaries
        
        Raises:
            requests.exceptions.RequestException: If the API request fails
        """
        url = f"{self.base_url}/rest/catalogDatabase/v1/schemaConnections"
        
        params = {
            'databaseConnectionId': database_connection_id,
            'limit': limit,
            'offset': offset
        }
        
        if schema_id:
            params['schemaId'] = schema_id
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            connections = result.get('results', [])
            
            logger.info(f"Found {len(connections)} schema connection(s)")
            return connections
            
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error listing schema connections: {e}")
            if e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error listing schema connections: {e}")
            raise
    
    def resolve_schema_connection_ids(
        self,
        database_id: str,
        schema_asset_ids: List[str],
        database_connection_id: Optional[str] = None
    ) -> List[str]:
        """
        Resolve schema asset IDs to schema connection IDs.
        
        Args:
            database_id: The UUID of the Database asset
            schema_asset_ids: List of schema asset UUIDs
            database_connection_id: Optional database connection ID (if not provided, will be resolved)
        
        Returns:
            List of schema connection UUIDs
        
        Raises:
            ValueError: If schema connections cannot be resolved
        """
        # Get the database connection ID if not provided
        if not database_connection_id:
            database_connection_id = self.get_database_connection_id(database_id)
        
        # Then, find schema connection IDs for each schema asset ID
        connection_ids = []
        
        for schema_asset_id in schema_asset_ids:
            connections = self.list_schema_connections(
                database_connection_id=database_connection_id,
                schema_id=schema_asset_id
            )
            
            if not connections:
                raise ValueError(
                    f"Could not find schema connection for schema asset {schema_asset_id}. "
                    "Make sure the schema has been synchronized at least once."
                )
            
            # Get the connection ID from the first matching result
            connection_id = connections[0].get('id')
            if not connection_id:
                raise ValueError(
                    f"Schema connection for {schema_asset_id} has no ID"
                )
            
            connection_ids.append(connection_id)
            logger.info(
                f"Resolved schema asset {schema_asset_id} to connection {connection_id}"
            )
        
        return connection_ids
    
    def trigger_metadata_sync(
        self,
        database_id: str,
        schema_connection_ids: Optional[List[str]] = None
    ) -> Dict:
        """
        Trigger metadata synchronization for a database asset.
        
        Args:
            database_id: The UUID of the Database asset in Collibra
            schema_connection_ids: Optional list of schema connection UUIDs.
                                  If None or empty, all schemas with rules are synchronized.
        
        Returns:
            Dict containing the job ID and response details
        
        Raises:
            requests.exceptions.RequestException: If the API request fails
        """
        url = f"{self.base_url}/rest/catalogDatabase/v1/databases/{database_id}/synchronizeMetadata"
        
        # Prepare request body
        body = {}
        if schema_connection_ids:
            body["schemaConnectionIds"] = schema_connection_ids
        
        logger.info(f"Triggering metadata sync for database {database_id}")
        if schema_connection_ids:
            logger.info(f"Synchronizing schemas: {', '.join(schema_connection_ids)}")
        else:
            logger.info("Synchronizing all schemas with rules defined")
        
        try:
            response = self.session.post(url, json=body, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            job_id = result.get('jobId')
            
            logger.info(f"Metadata sync triggered successfully. Job ID: {job_id}")
            return {
                'jobId': job_id,
                'databaseId': database_id,
                'schemaConnectionIds': schema_connection_ids or [],
                'status': 'triggered',
                'response': result
            }
            
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error triggering metadata sync: {e}")
            if e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error triggering metadata sync: {e}")
            raise
    
    def get_job_status(self, job_id: str) -> Dict:
        """
        Get the status of a Collibra job.
        
        Args:
            job_id: The UUID of the job
        
        Returns:
            Dict containing job status information
        
        Raises:
            requests.exceptions.RequestException: If the API request fails
        """
        url = f"{self.base_url}/rest/jobs/{job_id}"
        
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            return result
            
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error getting job status: {e}")
            if e.response is not None:
                logger.error(f"Response: {e.response.text}")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error getting job status: {e}")
            raise
    
    def wait_for_job_completion(
        self,
        job_id: str,
        max_wait_time: int = 3600,
        poll_interval: int = 10
    ) -> Dict:
        """
        Wait for a job to complete and return the final status.
        
        Args:
            job_id: The UUID of the job to monitor
            max_wait_time: Maximum time to wait in seconds (default: 1 hour)
            poll_interval: Time between status checks in seconds (default: 10 seconds)
        
        Returns:
            Dict containing the final job status
        
        Raises:
            TimeoutError: If the job doesn't complete within max_wait_time
            RuntimeError: If the job fails
        """
        logger.info(f"Monitoring job {job_id} for completion...")
        start_time = time.time()
        
        while True:
            elapsed_time = time.time() - start_time
            
            if elapsed_time > max_wait_time:
                raise TimeoutError(
                    f"Job {job_id} did not complete within {max_wait_time} seconds"
                )
            
            status = self.get_job_status(job_id)
            job_status = status.get('status', 'UNKNOWN')
            
            logger.info(
                f"Job {job_id} status: {job_status} "
                f"(elapsed: {int(elapsed_time)}s)"
            )
            
            if job_status == 'COMPLETED':
                logger.info(f"Job {job_id} completed successfully")
                return status
            elif job_status == 'FAILED':
                error_msg = status.get('errorMessage', 'Unknown error')
                raise RuntimeError(f"Job {job_id} failed: {error_msg}")
            elif job_status in ['CANCELLED', 'CANCELED']:
                raise RuntimeError(f"Job {job_id} was cancelled")
            
            # Wait before next poll
            time.sleep(poll_interval)
    
    def sync_and_wait(
        self,
        database_id: str,
        schema_connection_ids: Optional[List[str]] = None,
        schema_asset_ids: Optional[List[str]] = None,
        max_wait_time: int = 3600,
        poll_interval: int = 10
    ) -> Dict:
        """
        Trigger metadata synchronization and wait for completion.
        
        This is a convenience method that combines trigger_metadata_sync
        and wait_for_job_completion.
        
        Args:
            database_id: The UUID of the Database asset in Collibra
            schema_connection_ids: Optional list of schema connection UUIDs (used directly)
            schema_asset_ids: Optional list of schema asset UUIDs (resolved to connection IDs)
            max_wait_time: Maximum time to wait in seconds (default: 1 hour)
            poll_interval: Time between status checks in seconds (default: 10 seconds)
        
        Returns:
            Dict containing the final job status
        
        Note:
            If both schema_connection_ids and schema_asset_ids are provided,
            schema_connection_ids takes precedence.
        """
        # Resolve schema asset IDs to connection IDs if needed
        if schema_asset_ids and not schema_connection_ids:
            logger.info(f"Resolving {len(schema_asset_ids)} schema asset ID(s) to connection IDs")
            schema_connection_ids = self.resolve_schema_connection_ids(
                database_id,
                schema_asset_ids
            )
        
        # Trigger sync
        sync_result = self.trigger_metadata_sync(database_id, schema_connection_ids)
        job_id = sync_result['jobId']
        
        # Wait for completion
        final_status = self.wait_for_job_completion(
            job_id,
            max_wait_time=max_wait_time,
            poll_interval=poll_interval
        )
        
        return {
            'jobId': job_id,
            'databaseId': database_id,
            'schemaConnectionIds': schema_connection_ids or [],
            'schemaAssetIds': schema_asset_ids or [],
            'finalStatus': final_status
        }


def sync_layer_metadata(
    layer: str,
    database_id: str,
    schema_connection_ids: Optional[List[str]] = None
) -> Dict:
    """
    Convenience function to sync metadata for a specific layer.
    
    Args:
        layer: Layer name (e.g., 'RAW', 'STAGING', 'MART')
        database_id: The UUID of the Database asset in Collibra
        schema_connection_ids: Optional list of schema connection UUIDs
    
    Returns:
        Dict containing the sync result
    """
    logger.info(f"Starting metadata sync for {layer} layer")
    
    sync_client = CollibraMetadataSync()
    result = sync_client.sync_and_wait(
        database_id=database_id,
        schema_connection_ids=schema_connection_ids
    )
    
    logger.info(f"Metadata sync completed for {layer} layer")
    return result


if __name__ == "__main__":
    """Example usage when run as a script."""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python metadata_sync.py <database_id> [schema_connection_id1] [schema_connection_id2] ...")
        sys.exit(1)
    
    database_id = sys.argv[1]
    schema_ids = sys.argv[2:] if len(sys.argv) > 2 else None
    
    try:
        sync_client = CollibraMetadataSync()
        result = sync_client.sync_and_wait(
            database_id=database_id,
            schema_connection_ids=schema_ids
        )
        print(f"Sync completed successfully: {result}")
    except Exception as e:
        logger.error(f"Sync failed: {e}")
        sys.exit(1)

