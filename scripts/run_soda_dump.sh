#!/bin/bash
# Soda Cloud API Data Dump Runner Script
# This script runs the Soda Cloud API dump to extract datasets and checks data

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC}  $*"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log "Soda Cloud API Data Dump Runner"
log "Project root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if .env file exists
if [ ! -f ".env" ]; then
    err "No .env file found!"
    echo "Please create a .env file with your Soda Cloud credentials:"
    echo "  SODA_CLOUD_API_KEY_ID=your_api_key_id"
    echo "  SODA_CLOUD_API_KEY_SECRET=your_api_key_secret"
    echo "  SODA_CLOUD_HOST=https://cloud.us.soda.io  # or https://cloud.soda.io for EU"
    exit 1
fi

# Load environment variables
log "Loading environment variables..."
set -a  # automatically export all variables
source .env
set +a  # stop automatically exporting

# Check if required variables are set
if [ -z "${SODA_CLOUD_API_KEY_ID:-}" ] || [ -z "${SODA_CLOUD_API_KEY_SECRET:-}" ]; then
    err "Missing required Soda Cloud API credentials!"
    echo "Please set SODA_CLOUD_API_KEY_ID and SODA_CLOUD_API_KEY_SECRET in your .env file"
    exit 1
fi

ok "Environment variables loaded"

# Install additional requirements if needed
log "Installing additional requirements..."
if [ -f ".venv/bin/activate" ]; then
    log "Using existing virtual environment..."
    source .venv/bin/activate
    pip install -q -r scripts/requirements_dump.txt
elif command -v pip3 >/dev/null 2>&1; then
    pip3 install --user -q -r scripts/requirements_dump.txt
elif command -v pip >/dev/null 2>&1; then
    pip install --user -q -r scripts/requirements_dump.txt
else
    warn "pip not found, trying to install requirements with python3 -m pip..."
    python3 -m pip install --user -q -r scripts/requirements_dump.txt
fi

# Run the Soda Cloud dump script
log "Running Soda Cloud API data dump..."
python3 scripts/soda_dump_api.py

if [ $? -eq 0 ]; then
    ok "Soda Cloud API data dump completed successfully!"
    echo ""
    echo "📁 Output files are saved in the 'superset/data' directory:"
    echo "  - datasets_latest.csv: Latest dataset information"
    echo "  - checks_latest.csv: Latest check information"
    echo "  - summary_report_*.txt: Summary report with statistics"
    echo ""
    echo "💡 You can now use these CSV files to:"
    echo "  - Import into Snowflake for Sigma dashboard"
    echo "  - Analyze data quality trends"
    echo "  - Create custom reports"
    echo "  - Build business intelligence dashboards"
else
    err "Soda Cloud API data dump failed!"
    exit 1
fi
