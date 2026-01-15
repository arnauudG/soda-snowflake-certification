# Collibra Metadata Synchronization

This directory contains the Collibra integration for automatic metadata synchronization after each pipeline layer.

## Overview

The Collibra metadata synchronization integration automatically triggers metadata sync jobs in Collibra after each data layer is processed (RAW, STAGING, MART). This ensures that the Collibra catalog is kept up-to-date with the latest schema and table metadata from Snowflake.

## Orchestration Philosophy: Quality Gates Metadata Sync

**Core Principle**: Quality checks gate metadata synchronization. Metadata sync only happens after quality validation, ensuring Collibra reflects commitments, not aspirations.

**Sequence per Layer**: Build → Validate → Govern
- **Build Phase**: dbt materializes models in Snowflake ("this model exists")
- **Validation Phase**: Soda quality checks validate the data ("this model is acceptable")
- **Governance Phase**: Collibra metadata sync ("this model is governable and discoverable")

**Benefits**:
- Collibra becomes a historical record of accepted states, not a live mirror of Snowflake's chaos
- Lineage reflects approved flows
- Ownership discussions happen on assets that passed validation
- No retroactive corrections needed - catalog stays clean and meaningful

## Configuration

### 1. Environment Variables

Ensure your `.env` file contains Collibra credentials:

```bash
COLLIBRA_BASE_URL=https://your-instance.collibra.com
COLLIBRA_USERNAME=your_username
COLLIBRA_PASSWORD=your_password
```

### 2. Configuration File

Edit `config.yml` with your Collibra asset IDs:

```yaml
database_id: "your-database-uuid-here"

# Optional: Database Connection ID (will be resolved automatically if not provided)
# database_connection_id: "your-database-connection-uuid-here"

raw:
  schema_connection_ids:  # Note: These are schema asset IDs, not connection IDs
    - "your-raw-schema-asset-uuid-here"

staging:
  schema_connection_ids:  # Note: These are schema asset IDs, not connection IDs
    - "your-staging-schema-asset-uuid-here"

mart:
  schema_connection_ids:  # Note: These are schema asset IDs, not connection IDs
    - "your-mart-schema-asset-uuid-here"
```

**How to find these IDs:**
- **Database ID**: Navigate to your Database asset in Collibra and copy its UUID from the URL or asset details
- **Schema Asset IDs**: Navigate to each Schema asset in Collibra (not Schema Connection) and copy their UUIDs

**Important:** The system automatically resolves schema asset IDs to schema connection IDs using the Collibra API. You only need to provide the schema asset IDs in the config file.

## Usage

### Testing the Module

Before running in Airflow, you can test the Collibra integration:

```bash
# Run the test script (recommended first step)
python3 collibra/test_metadata_sync.py
```

The test script will:
- Verify environment variables are loaded
- Test Collibra client initialization
- Load and validate configuration
- Test database connection ID resolution
- Test schema connection listing
- Test schema asset ID to connection ID resolution
- Optionally trigger a metadata sync (dry run by default)

### Standalone Script

You can run metadata synchronization manually:

```bash
# Sync all schemas for a database
python3 collibra/metadata_sync.py <database_id>

# Sync specific schemas
python3 collibra/metadata_sync.py <database_id> <schema_id_1> <schema_id_2>
```

### Airflow Integration

The metadata synchronization is automatically integrated into the Airflow pipeline with quality-gating:

**RAW Layer**:
1. Quality checks (Soda) → **Gates** → Metadata sync (Collibra)

**STAGING Layer**:
1. Build (dbt) → Quality checks (Soda) → **Gates** → Metadata sync (Collibra)

**MART Layer**:
1. Build (dbt) → Quality checks (Soda) → **Gates** → Metadata sync (Collibra)

Each sync task:
- **Only executes after quality checks pass** (quality-gated)
- Triggers the synchronization job in Collibra
- Waits for the job to complete (with timeout)
- Logs progress and status
- Fails the pipeline if sync fails

**Important**: Metadata sync is gated by quality validation. This ensures Collibra only contains validated, committed data that has passed quality checks.

## API Reference

### CollibraMetadataSync Class

Main class for interacting with Collibra metadata synchronization API.

#### Methods

**`trigger_metadata_sync(database_id, schema_connection_ids=None)`**
- Triggers metadata synchronization for a database
- Returns job ID and sync details

**`get_job_status(job_id)`**
- Gets the current status of a synchronization job
- Returns job status information

**`wait_for_job_completion(job_id, max_wait_time=3600, poll_interval=10)`**
- Waits for a job to complete
- Polls job status at specified intervals
- Raises exception if job fails or times out

**`sync_and_wait(database_id, schema_connection_ids=None, max_wait_time=3600, poll_interval=10)`**
- Convenience method that triggers sync and waits for completion
- Returns final job status

## Job Status

Collibra jobs can have the following statuses:
- **RUNNING**: Job is currently executing
- **COMPLETED**: Job finished successfully
- **FAILED**: Job encountered an error
- **CANCELLED**: Job was cancelled

## Error Handling

The integration includes comprehensive error handling:
- **HTTP Errors**: Logged with response details
- **Timeout Errors**: Raised if job doesn't complete within max_wait_time
- **Job Failures**: Raised with error message from Collibra
- **Authentication Errors**: Raised if credentials are invalid

## Timeout Configuration

Default timeout is 1 hour (3600 seconds). You can adjust this in the Airflow DAG or when calling the functions directly.

For large databases with many tables, you may need to increase the timeout.

## Monitoring

All synchronization operations are logged with:
- Job IDs for tracking
- Status updates during execution
- Completion times
- Error messages if failures occur

Check Airflow task logs for detailed synchronization progress.

## Troubleshooting

### Job Timeout
If jobs are timing out:
- Increase `max_wait_time` in the Airflow DAG
- Check Collibra job status manually in the UI
- Verify database and schema sizes

### Authentication Errors
- Verify credentials in `.env` file
- Check Collibra base URL is correct
- Ensure user has permissions to trigger metadata sync

### Job Failures
- Check Collibra job details in the UI
- Verify database and schema connection IDs are correct
- Check Collibra logs for detailed error messages

## Integration with Pipeline

The metadata synchronization is integrated into the Airflow DAG with quality-gating at these points:

```
RAW Layer:
  soda_scan_raw → collibra_sync_raw → raw_layer_end
  (Quality gates metadata sync)

STAGING Layer:
  dbt_run_staging → soda_scan_staging → collibra_sync_staging → staging_layer_end
  (Build → Validate → Govern)

MART Layer:
  dbt_run_mart → soda_scan_mart → collibra_sync_mart → mart_layer_end
  (Build → Validate → Govern, strictest standards)
```

**Quality Gating**: Each sync task only executes after quality checks pass. The pipeline waits for:
1. Quality validation to complete
2. Metadata sync job to complete
3. Then proceeds to the next layer

This ensures Collibra only syncs validated data, making it a historical record of accepted states.

