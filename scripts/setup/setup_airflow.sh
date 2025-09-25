#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log(){ echo -e "${BLUE}[INFO]${NC} $*"; }
ok(){  echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR]${NC} $*"; }

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Activate venv
if [[ -f .venv/bin/activate ]]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
  ok "Virtual env activated"
else
  err "No .venv found. Create with: python3.11 -m venv .venv && source .venv/bin/activate"; exit 1
fi

# AIRFLOW_HOME
export AIRFLOW_HOME="${AIRFLOW_HOME:-$HOME/airflow}"
mkdir -p "$AIRFLOW_HOME/dags"
ok "AIRFLOW_HOME=$AIRFLOW_HOME"

# Install Airflow with constraints (Python 3.11)
AIRFLOW_VERSION="2.9.3"
PYVER="3.11"
CONSTRAINTS_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYVER}.txt"

log "Installing Apache Airflow ${AIRFLOW_VERSION} (constraints for Python ${PYVER})"
pip install -q "apache-airflow==${AIRFLOW_VERSION}" --constraint "$CONSTRAINTS_URL" || warn "Airflow install reported warnings"
ok "Airflow installed"

# Init / migrate DB
log "Initializing Airflow DB"
airflow db migrate || airflow db init
ok "Airflow DB ready"

# Create admin user if not exists
if ! airflow users list 2>/dev/null | grep -q " admin "; then
  log "Creating Airflow admin user (admin / admin)"
  airflow users create --username admin --firstname Admin --lastname User --role Admin --email admin@example.com --password admin >/dev/null
  ok "Admin user created"
else
  ok "Admin user already exists"
fi

# Install DAG
log "Installing project DAG"
cp -f "$PROJECT_ROOT/airflow/dags/soda_certification_dag.py" "$AIRFLOW_HOME/dags/"
ok "DAG installed to $AIRFLOW_HOME/dags"

# Start webserver if not running
if pgrep -f "airflow webserver" >/dev/null; then
  ok "Airflow webserver already running"
else
  log "Starting Airflow webserver on port 8080"
  nohup airflow webserver -p 8080 >/dev/null 2>&1 &
  ok "Webserver started at http://localhost:8080"
fi

# Start scheduler if not running
if pgrep -f "airflow scheduler" >/dev/null; then
  ok "Airflow scheduler already running"
else
  log "Starting Airflow scheduler"
  nohup airflow scheduler >/dev/null 2>&1 &
  ok "Scheduler started"
fi

ok "Airflow setup complete. Open http://localhost:8080 and trigger 'soda_certification_pipeline'"
