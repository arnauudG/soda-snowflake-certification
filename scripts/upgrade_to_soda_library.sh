#!/bin/bash

# Upgrade to Soda Library Script
# This script rebuilds the Docker container with Soda Library instead of Soda Core

echo "🚀 Upgrading to Soda Library for Snowflake..."
echo "📦 This will enable template checks and advanced features"
echo "🔗 Using official Soda Library installation method"
echo ""

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker/docker-compose.yml down

# Remove old images to force rebuild
echo "🗑️  Removing old images..."
docker rmi soda-certification-airflow 2>/dev/null || true

# Rebuild with Soda Library
echo "🔨 Rebuilding with Soda Library..."
docker-compose -f docker/docker-compose.yml build --no-cache

# Start the services
echo "▶️  Starting services with Soda Library..."
docker-compose -f docker/docker-compose.yml up -d

echo ""
echo "✅ Upgrade complete!"
echo ""
echo "🎯 What's new with Soda Library:"
echo "   • Template checks now supported"
echo "   • Advanced analytics and anomaly detection"
echo "   • Statistical analysis capabilities"
echo "   • Business logic validation"
echo ""
echo "🔍 To verify the upgrade:"
echo "   docker exec -it soda-certification-airflow-1 soda --version"
echo ""
echo "📋 Next steps:"
echo "   1. Run the pipeline to see template checks in action"
echo "   2. Check Soda Cloud for advanced analytics"
echo "   3. Explore template-based quality monitoring"
echo ""
echo "🎉 Enjoy your enhanced data quality pipeline!"
