# Soda Certification Project Makefile
PY?=python3.11
VENV=.venv

.PHONY: help all venv deps pipeline fresh smooth airflow-up airflow-down airflow-status airflow-trigger clean clean-logs clean-all

help: ## Show this help message
	@echo "Soda Certification Project - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

all: venv deps ## Setup environment

venv: ## Create virtual environment
	@if [ ! -d "$(VENV)" ]; then \
		$(PY) -m venv $(VENV); \
		echo "[OK] Virtual environment created"; \
	else \
		echo "[OK] Virtual environment exists"; \
	fi

deps: venv ## Install dependencies
	@. $(VENV)/bin/activate && pip install -q --upgrade pip && pip install -q -r scripts/setup/requirements.txt && echo "[OK] Dependencies installed"

pipeline: venv ## Run standard pipeline (via Airflow)
	@echo "Use Airflow DAGs for pipeline execution:"
	@echo "  make airflow-trigger-init    # First-time setup"
	@echo "  make airflow-trigger-pipeline # Regular runs"

airflow-up: ## Start Airflow services with Docker
	@echo "🚀 Starting Airflow services..."
	@echo "📥 Loading environment variables..."
	@bash -c "source load_env.sh"
	@echo "🐳 Starting Docker containers..."
	@cd airflow/docker && docker-compose up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	@echo "▶️  Unpausing all Soda DAGs..."
	@docker exec soda-airflow-webserver airflow dags unpause soda_initialization || true
	@docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_run || true
	@echo "[OK] Airflow services started with Docker"
	@echo "[INFO] Web UI: http://localhost:8080 (admin/admin)"
	@echo "[INFO] Available DAGs:"
	@make airflow-list

superset-up: ## Start Superset visualization service (separate setup)
	@echo "📊 Starting Superset services..."
	@echo "📥 Loading environment variables..."
	@bash -c "source load_env.sh"
	@echo "🐳 Starting Docker containers..."
	@cd superset && docker-compose up -d
	@echo "⏳ Waiting for Superset to be ready..."
	@sleep 45
	@echo "[OK] Superset started with Docker"
	@echo "[INFO] Superset UI: http://localhost:8089 (admin/admin)"

all-up: ## Start all services (Airflow + Superset)
	@echo "🚀 Starting all services..."
	@echo "📥 Loading environment variables..."
	@bash -c "source load_env.sh"
	@echo "🐳 Starting Airflow containers..."
	@cd airflow/docker && docker-compose up -d
	@echo "🐳 Starting Superset containers..."
	@cd superset && docker-compose up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 45
	@echo "▶️  Unpausing all Soda DAGs..."
	@docker exec soda-airflow-webserver airflow dags unpause soda_initialization || true
	@docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_run || true
	@echo "[OK] All services started with Docker"
	@echo "[INFO] Airflow UI: http://localhost:8080 (admin/admin)"
	@echo "[INFO] Superset UI: http://localhost:8089 (admin/admin)"

airflow-down: ## Stop Airflow services
	@cd airflow/docker && docker-compose down
	@echo "[OK] Airflow services stopped"

superset-down: ## Stop Superset services
	@cd superset && docker-compose down
	@echo "[OK] Superset services stopped"

superset-status: ## Check Superset services status
	@echo "🔍 Checking Superset services..."
	@cd superset && docker-compose ps

superset-logs: ## View Superset logs
	@cd superset && docker-compose logs -f superset

superset-reset: ## Reset Superset database and restart
	@echo "🔄 Resetting Superset..."
	@cd superset && docker-compose down
	@cd superset && docker volume rm superset_superset-postgres-data superset_superset-data 2>/dev/null || true
	@cd superset && docker-compose up -d
	@echo "⏳ Waiting for Superset to be ready..."
	@sleep 45
	@echo "[OK] Superset reset and restarted"


	@echo "✅ Complete Soda data workflow finished!"

dump-databases: ## Dump all databases (Superset, Airflow, Soda data)
	@echo "🗄️  Dumping all databases..."
	@./scripts/dump_databases.sh --all
	@echo "[OK] All databases dumped"

dump-superset: ## Dump Superset database only
	@echo "📊 Dumping Superset database..."
	@./scripts/dump_databases.sh --superset-only
	@echo "[OK] Superset database dumped"

dump-airflow: ## Dump Airflow database only
	@echo "🔄 Dumping Airflow database..."
	@./scripts/dump_databases.sh --airflow-only
	@echo "[OK] Airflow database dumped"

dump-soda: ## Dump Soda data only
	@echo "📈 Dumping Soda data..."
	@./scripts/dump_databases.sh --soda-only
	@echo "[OK] Soda data dumped"

airflow-status: ## Check Airflow services status
	@echo "🔍 Checking Airflow services..."
	@cd airflow/docker && docker-compose ps

airflow-logs: ## View Airflow logs
	@cd airflow/docker && docker-compose logs -f

airflow-unpause-all: ## Unpause all Soda DAGs
	@echo "▶️  Unpausing all Soda DAGs..."
	@docker exec soda-airflow-webserver airflow dags unpause soda_initialization
	@docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_run
	@echo "[OK] All Soda DAGs unpaused"

airflow-pause-all: ## Pause all Soda DAGs
	@echo "⏸️  Pausing all Soda DAGs..."
	@docker exec soda-airflow-webserver airflow dags pause soda_initialization
	@docker exec soda-airflow-webserver airflow dags pause soda_pipeline_run
	@echo "[OK] All Soda DAGs paused"

airflow-rebuild: ## Rebuild Airflow containers
	@cd airflow/docker && docker-compose down
	@cd airflow/docker && docker-compose build --no-cache
	@cd airflow/docker && docker-compose up -d
	@echo "[OK] Airflow containers rebuilt and started"

airflow-trigger-init: ## Trigger initialization DAG (fresh setup only)
	@echo "🚀 Triggering initialization DAG..."
	@docker exec soda-airflow-webserver airflow dags trigger soda_initialization
	@echo "[OK] Initialization DAG triggered"

airflow-trigger-pipeline: ## Trigger layered pipeline DAG (layer-by-layer processing)
	@echo "🔄 Triggering layered pipeline DAG..."
	@docker exec soda-airflow-webserver airflow dags trigger soda_pipeline_run
	@echo "[OK] Layered pipeline DAG triggered"

soda-dump: ## Extract Soda Cloud data to CSV files
	@echo "📊 Extracting Soda Cloud data..."
	@./scripts/run_soda_dump.sh
	@echo "[OK] Soda Cloud data extracted to CSV files"


airflow-list: ## List available DAGs
	@echo "📋 Listing available DAGs..."
	@docker exec soda-airflow-webserver airflow dags list | grep soda


docs: ## Open documentation
	@echo "📚 Available Documentation:"
	@echo "  📖 README.md - Complete project documentation"
	@echo "  🔧 Makefile - Development commands and automation"
	@echo "  📋 Airflow UI - http://localhost:8080 (admin/admin)"
	@echo "  📊 Superset UI - http://localhost:8089 (admin/admin)"
	@echo ""
	@echo "💡 Quick commands:"
	@echo "  make help - Show all available commands"
	@echo "  make all-up - Start all services (Airflow + Superset)"
	@echo "  make airflow-trigger-init - Fresh initialization (first time)"
	@echo "  make airflow-trigger-pipeline - Layered pipeline runs"

setup: venv deps ## Complete environment setup
	@echo "🔧 Setting up environment..."
	@if [ ! -f .env ]; then \
		echo "⚠️  .env file not found!"; \
		echo "   Please create .env file with your Snowflake credentials"; \
		echo "   Required: SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD"; \
		echo "   Optional: SODA_CLOUD_API_KEY_ID, SODA_CLOUD_API_KEY_SECRET"; \
		exit 1; \
	else \
		echo "✅ .env file found"; \
	fi
	@echo "[OK] Environment setup completed"
	@echo "[INFO] Next steps:"
	@echo "  1. Ensure .env file has your credentials"
	@echo "  2. Run: make airflow-up"
	@echo "  3. Run: make airflow-trigger-init (first time setup)"
	@echo "  4. Access Airflow UI: http://localhost:8080"

clean: ## Clean up artifacts and temporary files
	@echo "🧹 Cleaning up artifacts..."
	@rm -rf dbt/target dbt/logs snowflake_connection_test.log
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -rf airflow/airflow-logs 2>/dev/null || true
	@echo "[OK] Artifacts cleaned"

clean-logs: ## Clean up old Airflow logs
	@echo "🧹 Cleaning up old logs..."
	@rm -rf airflow/airflow-logs 2>/dev/null || true
	@echo "[OK] Old logs cleaned"

clean-all: clean clean-logs ## Deep clean: artifacts, logs, and cache
	@echo "🧹 Deep cleaning project..."
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@echo "[OK] Deep clean completed"

# =============================================================================
# SODA DATA MANAGEMENT
# =============================================================================

	@echo "✅ Complete Soda data workflow finished!"

organize-soda-data: ## Organize Soda dump data in user-friendly structure
	@echo "📁 Organizing Soda dump data..."
	@python3 scripts/organize_soda_data.py
	@echo "✅ Data organized successfully!"

superset-upload-data: ## Complete Soda workflow: dump + organize + upload to Superset
	@echo "📤 Complete Soda data workflow..."
	@echo "1. Extracting data from Soda Cloud..."
	@make soda-dump
	@echo "2. Organizing data..."
	@make organize-soda-data
	@echo "3. Uploading to Superset..."
	@cp scripts/upload_soda_data_docker.py superset/data/
	@cd superset && docker-compose exec superset python /app/soda_data/upload_soda_data_docker.py
	@echo "✅ Complete Soda data workflow finished!"

superset-clean-restart: ## Clean restart Superset (removes all data)
	@echo "🧹 Performing clean Superset restart..."
	@make superset-down
	@cd superset && docker-compose down -v
	@echo "🗑️  Removed all Superset data and volumes"
	@make superset-up
	@echo "✅ Superset clean restart completed!"

superset-reset-data: ## Reset only Superset data (keep containers)
	@echo "🔄 Resetting Superset data..."
	@cd superset && docker-compose exec superset-db psql -U superset -d superset -c "DROP SCHEMA IF EXISTS soda CASCADE;"
	@echo "✅ Superset data reset completed!"

superset-reset-schema: ## Reset only the soda schema (fixes table structure issues)
	@echo "🔄 Resetting soda schema..."
	@cd superset && docker-compose exec superset-db psql -U superset -d superset -c "DROP SCHEMA IF EXISTS soda CASCADE;"
	@echo "✅ Soda schema reset complete"

# Soda Agent Infrastructure Commands
soda-agent-bootstrap: ## Bootstrap Soda Agent infrastructure (one-time setup)
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-bootstrap ENV=dev"; \
		exit 1; \
	fi
	@echo "🏗️  Bootstrapping Soda Agent infrastructure for $(ENV)..."
	@cd soda/soda-agent && ./bootstrap.sh $(ENV) create
	@echo "✅ Bootstrap completed for $(ENV) environment"

soda-agent-bootstrap-destroy: ## Destroy Soda Agent bootstrap infrastructure (with automatic S3 cleanup)
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-bootstrap-destroy ENV=dev"; \
		exit 1; \
	fi
	@echo "⚠️  Destroying Soda Agent bootstrap infrastructure for $(ENV)..."
	@echo "This will permanently delete bootstrap resources (S3 bucket, DynamoDB table)."
	@echo "✅ Enhanced with automatic S3 versioning cleanup to prevent hanging issues."
	@echo "Continue? [y/N]"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@cd soda/soda-agent && ./bootstrap.sh $(ENV) delete
	@echo "✅ Bootstrap destruction completed for $(ENV) environment"

soda-agent-bootstrap-status: ## Check Soda Agent bootstrap status
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-bootstrap-status ENV=dev"; \
		exit 1; \
	fi
	@echo "🔍 Checking Soda Agent bootstrap status for $(ENV)..."
	@cd soda/soda-agent && ./bootstrap.sh $(ENV) status
	@echo "✅ Bootstrap status check completed for $(ENV) environment"

soda-agent-bootstrap-unlock: ## Force unlock Soda Agent bootstrap state (if stuck)
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-bootstrap-unlock ENV=dev"; \
		exit 1; \
	fi
	@echo "🔓 Force unlocking Soda Agent bootstrap state for $(ENV)..."
	@echo "⚠️  This should only be used if bootstrap is stuck or locked."
	@echo "Continue? [y/N]"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@cd soda/soda-agent && ./bootstrap.sh $(ENV) unlock
	@echo "✅ Bootstrap unlock completed for $(ENV) environment"

soda-agent-deploy: ## Deploy Soda Agent infrastructure (auto-creates bootstrap if missing)
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-deploy ENV=dev"; \
		exit 1; \
	fi
	@echo "🚀 Deploying Soda Agent infrastructure for $(ENV)..."
	@echo "📋 Note: Bootstrap will be created automatically if missing"
	@cd soda/soda-agent && ./deploy.sh $(ENV)
	@echo "✅ Deployment completed for $(ENV) environment"

soda-agent-destroy: ## Destroy Soda Agent infrastructure
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-destroy ENV=dev"; \
		exit 1; \
	fi
	@echo "⚠️  Destroying Soda Agent infrastructure for $(ENV)..."
	@echo "This will permanently delete all resources. Continue? [y/N]"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@cd soda/soda-agent && ./destroy.sh $(ENV)
	@echo "✅ Destruction completed for $(ENV) environment"

soda-agent-destroy-all: ## Destroy Soda Agent infrastructure AND bootstrap
	@if [ -z "$(ENV)" ]; then \
		echo "❌ Error: ENV parameter required. Usage: make soda-agent-destroy-all ENV=dev"; \
		exit 1; \
	fi
	@echo "⚠️  Destroying Soda Agent infrastructure AND bootstrap for $(ENV)..."
	@echo "This will permanently delete ALL resources including bootstrap. Continue? [y/N]"
	@read -r confirm && [ "$$confirm" = "y" ] || exit 1
	@cd soda/soda-agent && ./destroy.sh $(ENV) --destroy-bootstrap
	@echo "✅ Complete destruction completed for $(ENV) environment"


