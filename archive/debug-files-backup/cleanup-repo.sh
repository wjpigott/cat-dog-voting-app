#!/bin/bash
# Repository Cleanup Script - Remove debug and test files, keep only production essentials

echo "🧹 Cleaning up repository - removing debug and test files..."

# Create backup directory
mkdir -p ./archive/debug-files-backup
echo "📦 Creating backup of debug files in ./archive/debug-files-backup/"

# Move debug/test files to archive
echo "📁 Archiving debug and test files..."

# Debug YAML files
mv debug-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv test-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv fix-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv quick-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv *-debug-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv enhanced-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true

# Debug shell scripts
mv debug-*.sh ./archive/debug-files-backup/ 2>/dev/null || true
mv test-*.sh ./archive/debug-files-backup/ 2>/dev/null || true
mv fix-*.sh ./archive/debug-files-backup/ 2>/dev/null || true
mv force-*.sh ./archive/debug-files-backup/ 2>/dev/null || true
mv discover-*.sh ./archive/debug-files-backup/ 2>/dev/null || true
mv find-*.sh ./archive/debug-files-backup/ 2>/dev/null || true

# PowerShell debug scripts
mv *-Azure-*.ps1 ./archive/debug-files-backup/ 2>/dev/null || true
mv Query-*.ps1 ./archive/debug-files-backup/ 2>/dev/null || true
mv Deploy-Enhanced-*.ps1 ./archive/debug-files-backup/ 2>/dev/null || true

# Temporary deployment files
mv deployment-only-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv low-memory-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv network-test-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv postgres-only-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true

# Various test and temp files
mv azure-db-test.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv azure-simple-voting.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv complete-database-deploy.yaml ./archive/debug-files-backup/ 2>/dev/null || true
mv cross-environment-voting-*.yaml ./archive/debug-files-backup/ 2>/dev/null || true

echo "✅ Essential files preserved:"
echo "   📄 azure-voting-app-complete.yaml (Final Azure deployment)"
echo "   📄 onprem-azure-direct-fixed.yaml (Final OnPrem deployment)"  
echo "   📄 .github/workflows/deploy-multi-env.yml (CI/CD pipeline)"
echo "   📄 README.md & FINAL_PROJECT_DOCUMENTATION.md (Documentation)"
echo "   📄 Dockerfile & azure-voting-app.py (Application code)"

echo ""
echo "🗑️  Debug files moved to: ./archive/debug-files-backup/"
echo "🎯 Repository cleaned - only essential production files remain!"