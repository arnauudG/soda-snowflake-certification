# Soda Certification Project Makefile
PY?=python3.11
VENV=.venv

.PHONY: help all venv deps pipeline fresh smooth airflow-up airflow-down airflow-status airflow-trigger clean

help: ## Show this help message
	@echo "Soda Certification Project - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

all: venv deps pipeline ## Setup environment and run pipeline

venv: ## Create virtual environment
	@if [ ! -d "$(VENV)" ]; then \
		$(PY) -m venv $(VENV); \
		echo "[OK] Virtual environment created"; \
	else \
		echo "[OK] Virtual environment exists"; \
	fi

deps: venv ## Install dependencies
	@. $(VENV)/bin/activate && pip install -q --upgrade pip && pip install -q -r scripts/setup/requirements.txt && echo "[OK] Dependencies installed"

pipeline: venv ## Run standard pipeline
	@. $(VENV)/bin/activate && ./scripts/run_pipeline.sh && echo "[OK] Pipeline completed"

fresh: venv ## Run fresh pipeline (reset Snowflake first)
	@. $(VENV)/bin/activate && ./scripts/run_pipeline.sh --fresh && echo "[OK] Fresh pipeline completed"

smooth: venv ## Run smooth pipeline (layer-by-layer processing)
	@. $(VENV)/bin/activate && ./scripts/run_pipeline.sh --smooth && echo "[OK] Smooth pipeline completed"

airflow-up: ## Start Airflow services with Docker
	@echo "🚀 Starting Airflow services..."
	@cd docker && docker-compose up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	@echo "▶️  Unpausing all Soda DAGs..."
	@docker exec soda-airflow-webserver airflow dags unpause soda_initialization || true
	@docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_run || true
	@echo "[OK] Airflow services started with Docker"
	@echo "[INFO] Web UI: http://localhost:8080 (admin/admin)"
	@echo "[INFO] Available DAGs:"
	@make airflow-list

airflow-down: ## Stop Airflow services
	@cd docker && docker-compose down
	@echo "[OK] Airflow services stopped"

airflow-status: ## Check Airflow services status
	@echo "🔍 Checking Airflow services..."
	@cd docker && docker-compose ps

airflow-logs: ## View Airflow logs
	@cd docker && docker-compose logs -f

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
	@cd docker && docker-compose down
	@cd docker && docker-compose build --no-cache
	@cd docker && docker-compose up -d
	@echo "[OK] Airflow containers rebuilt and started"

airflow-trigger-init: ## Trigger initialization DAG (fresh setup only)
	@echo "🚀 Triggering initialization DAG..."
	@docker exec soda-airflow-webserver airflow dags trigger soda_initialization
	@echo "[OK] Initialization DAG triggered"

airflow-trigger-pipeline: ## Trigger pipeline run DAG (regular data processing)
	@echo "🔄 Triggering pipeline run DAG..."
	@docker exec soda-airflow-webserver airflow dags trigger soda_pipeline_run
	@echo "[OK] Pipeline run DAG triggered"


airflow-list: ## List available DAGs
	@echo "📋 Listing available DAGs..."
	@docker exec soda-airflow-webserver airflow dags list | grep soda

clean: ## Clean up temporary files and artifacts
	@rm -rf dbt/target dbt/logs *.log soda_raw_test.log || true
	@echo "[OK] Cleanup completed"

docs: ## Open documentation
	@echo "📚 Available Documentation:"
	@echo "  📖 README.md - Complete project documentation"
	@echo "  🔧 SETUP_GUIDE.md - Complete setup guide with all fixes"
	@echo "  🚀 CI_CD_TESTING.md - CI/CD testing strategy and implementation"
	@echo ""
	@echo "💡 Quick commands:"
	@echo "  make help - Show all available commands"
	@echo "  make airflow-up - Start Airflow services"
	@echo "  make airflow-trigger-init - Fresh initialization (first time)"
	@echo "  make airflow-trigger-pipeline - Regular pipeline runs"

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


