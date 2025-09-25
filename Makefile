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
	@cd docker && docker-compose up -d
	@echo "[OK] Airflow services started with Docker"
	@echo "[INFO] Web UI: http://localhost:8080 (admin/admin)"

airflow-down: ## Stop Airflow services
	@cd docker && docker-compose down
	@echo "[OK] Airflow services stopped"

airflow-status: ## Check Airflow status
	@cd docker && docker-compose ps

airflow-logs: ## View Airflow logs
	@cd docker && docker-compose logs -f

airflow-rebuild: ## Rebuild Airflow containers
	@cd docker && docker-compose down
	@cd docker && docker-compose build --no-cache
	@cd docker && docker-compose up -d
	@echo "[OK] Airflow containers rebuilt and started"

airflow-trigger: venv ## Trigger main Airflow DAG (full pipeline)
	@. $(VENV)/bin/activate && export AIRFLOW_HOME=$${AIRFLOW_HOME:-$$HOME/airflow} && airflow dags trigger soda_certification_pipeline && echo "[OK] Main DAG triggered"

airflow-trigger-pipeline: venv ## Trigger pipeline-only DAG (dbt + Soda checks)
	@. $(VENV)/bin/activate && export AIRFLOW_HOME=$${AIRFLOW_HOME:-$$HOME/airflow} && airflow dags trigger soda_pipeline_only && echo "[OK] Pipeline-only DAG triggered"

airflow-list: venv ## List available DAGs
	@. $(VENV)/bin/activate && export AIRFLOW_HOME=$${AIRFLOW_HOME:-$$HOME/airflow} && airflow dags list

clean: ## Clean up temporary files and artifacts
	@rm -rf dbt/target dbt/logs *.log soda_raw_test.log || true
	@echo "[OK] Cleanup completed"

docs: ## Open documentation
	@echo "📚 Available Documentation:"
	@echo "  📖 README.md - Complete project documentation"
	@echo "  🚀 QUICK_START.md - Quick start guide"
	@echo "  🏗️ DEPLOYMENT.md - Production deployment guide"
	@echo ""
	@echo "💡 Quick commands:"
	@echo "  make help - Show all available commands"
	@echo "  make airflow-up - Start Airflow services"
	@echo "  make airflow-trigger - Complete setup (first time)"
	@echo "  make airflow-trigger-pipeline - Regular pipeline runs"

setup: venv deps ## Complete environment setup
	@echo "[OK] Environment setup completed"
	@echo "[INFO] Next steps:"
	@echo "  1. Configure .env file with your credentials"
	@echo "  2. Run: make airflow-up"
	@echo "  3. Run: make airflow-trigger (first time setup)"
	@echo "  4. Access Airflow UI: http://localhost:8080"


