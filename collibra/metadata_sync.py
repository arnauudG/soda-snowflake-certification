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
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class CollibraMetadataSync:
    """Handles Collibra metadata synchronization operations."""
    
    def __init__(self):
        """Initialize Collibra client with credentials from environment."""
        self.base_url = os.getenv('COLLIBRA_BASE_URL')
        self.username = os.getenv('COLLIBRA_USERNAME')
        self.password = os.getenv('COLLIBRA_PASSWORD')
        
        if not all([self.base_url, self.username, self.password]):
            raise ValueError(
                "Missing Collibra credentials. Please set COLLIBRA_BASE_URL, "
                "COLLIBRA_USERNAME, and COLLIBRA_PASSWORD in your .env file"
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
        max_wait_time: int = 3600,
        poll_interval: int = 10
    ) -> Dict:
        """
        Trigger metadata synchronization and wait for completion.
        
        This is a convenience method that combines trigger_metadata_sync
        and wait_for_job_completion.
        
        Args:
            database_id: The UUID of the Database asset in Collibra
            schema_connection_ids: Optional list of schema connection UUIDs
            max_wait_time: Maximum time to wait in seconds (default: 1 hour)
            poll_interval: Time between status checks in seconds (default: 10 seconds)
        
        Returns:
            Dict containing the final job status
        """
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

