#!/bin/bash
# Soda Certification Pipeline - Complete End-to-End Pipeline
# This script runs the complete data pipeline: Snowflake setup → dbt models → Soda checks
# Designed for Airflow integration and production use

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
log() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC}  $*"; }
step() { echo -e "${PURPLE}[STEP]${NC} $*"; }
layer() { echo -e "${CYAN}[LAYER]${NC} $*"; }

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

log "Project root: $ROOT_DIR"

# Args
FRESH=0
SMOOTH=0
if [[ ${1:-} == "--fresh" ]]; then
  FRESH=1
  ok "Fresh run requested"
elif [[ ${1:-} == "--smooth" ]]; then
  SMOOTH=1
  ok "Smooth pipeline requested (layer-by-layer processing)"
fi

# Activate venv if present
if [[ -f .venv/bin/activate ]]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
  ok "Virtual env activated"
else
  warn "No .venv found; proceeding with system Python"
fi

# Load env
log "Loading environment variables (.env)"
if [ -f ".env" ]; then
    set -a  # automatically export all variables
    source .env
    set +a  # stop automatically exporting
    ok "Environment variables loaded from .env file"
else
    err "No .env file found. Please create one with your Snowflake credentials."
    exit 1
fi

# Fresh reset (Snowflake)
if [[ $FRESH -eq 1 ]]; then
  log "Resetting Snowflake database (fresh)"
  python3 scripts/setup/reset_snowflake.py --force
  ok "Snowflake reset complete"
fi

# Snowflake setup (idempotent)
log "Running Snowflake setup (idempotent)"
python3 scripts/setup/setup_snowflake.py
ok "Snowflake setup complete"

# Smooth pipeline processing (layer-by-layer)
if [[ $SMOOTH -eq 1 ]]; then
  log "Starting smooth pipeline processing..."
  
  # Define layers in order
  layers=("raw" "staging" "mart" "quality")
  
  for layer in "${layers[@]}"; do
    layer "Processing $layer layer..."
    echo "----------------------------------------"
    
    # Step 1: Run dbt models for this layer
    if [[ "$layer" == "raw" ]]; then
      warn "Raw layer: No dbt models to run (source data)"
    else
      step "Running dbt models for $layer layer..."
      if dbt run --select "tag:$layer" --target prod --profiles-dir dbt --project-dir dbt --vars '{"start_date": "2024-01-01", "end_date": "2024-12-31"}'; then
        ok "dbt models for $layer layer completed successfully"
      else
        err "dbt models for $layer layer failed"
        exit 1
      fi
    fi
    
    # Step 2: Run dbt tests for this layer
    if [[ "$layer" == "raw" ]]; then
      warn "Raw layer: No dbt tests to run (source data)"
    else
      step "Running dbt tests for $layer layer..."
      if dbt test --select "tag:$layer" --target prod --profiles-dir dbt --project-dir dbt; then
        ok "dbt tests for $layer layer completed successfully"
      else
        warn "dbt tests for $layer layer had some failures (check logs for details)"
      fi
    fi
    
    # Step 3: Run Soda checks for this layer
    step "Running Soda checks for $layer layer..."
    config_file="soda/configuration/configuration_${layer}.yml"
    checks_dir="soda/checks/${layer}"
    
    if [[ -f "$config_file" && -d "$checks_dir" ]]; then
      # Test connection first
      if soda test-connection -d "soda_certification_${layer}" -c "$config_file" >/dev/null 2>&1; then
        # Run checks for each table in the layer
        check_files=($(find "$checks_dir" -name "*.yml" -type f))
        total_checks=0
        passed_checks=0
        
        for check_file in "${check_files[@]}"; do
          table_name=$(basename "$check_file" .yml)
          log "  Testing $table_name table..."
          
          if soda scan -d "soda_certification_${layer}" -c "$config_file" "$check_file"; then
            ok "    $table_name: All checks passed"
            ((passed_checks++))
          else
            warn "    $table_name: Some checks failed (check logs for details)"
          fi
          ((total_checks++))
        done
        
        log "Soda checks for $layer layer completed: $passed_checks/$total_checks tables passed"
      else
        err "Connection test failed for $layer layer"
        exit 1
      fi
    else
      warn "Configuration or checks directory not found for $layer layer"
    fi
    
    ok "$layer layer processing completed successfully"
    echo ""
  done
  
  ok "Smooth pipeline processing completed successfully"
  exit 0
fi

# dbt build
log "Running dbt build"
pushd dbt >/dev/null
dbt debug --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir . || true
popd >/dev/null
ok "dbt build complete"

# Soda scans
if command -v soda >/dev/null 2>&1; then
  log "Running Soda scans"
  # RAW
  soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/customers.yml || true
  soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/products.yml || true
  soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/orders.yml || true
  soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/order_items.yml || true
  # Give Snowflake a moment to register objects
  sleep 2
  # STAGING
  soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/stg_customers.yml || true
  soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/stg_products.yml || true
  soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/stg_orders.yml || true
  soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/stg_order_items.yml || true
  # MART
  soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/dim_customers.yml || true
  soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/dim_products.yml || true
  soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/fact_orders.yml || true
  # QUALITY
  soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality/check_results.yml || true
  ok "Soda scans completed"
else
  warn "soda CLI not found; skipping Soda scans"
fi

# Cleanup artifacts
log "Cleaning artifacts"
rm -rf dbt/target dbt/logs || true
rm -f snowflake_connection_test.log || true
ok "Cleanup complete"

ok "Pipeline completed"

