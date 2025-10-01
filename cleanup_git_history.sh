#!/bin/bash

# 🔒 Git History Cleanup Script
# This script removes sensitive files from Git history
# ⚠️ WARNING: This rewrites Git history! Coordinate with your team before running.

echo "🔒 AgriSense Git History Cleanup Script"
echo "========================================"
echo ""
echo "⚠️  WARNING: This will rewrite Git history!"
echo "⚠️  Make sure all team members have pushed their changes"
echo "⚠️  After running this, everyone must re-clone the repository"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo ""
echo "📦 Creating backup branch..."
git branch backup-before-cleanup-$(date +%Y%m%d_%H%M%S)

echo ""
echo "🧹 Removing Secrets.swift from history..."
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Agrisense/Models/Secrets.swift" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "🧹 Removing test files from history..."
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch test_gemini_api.py test_gemini_api.sh" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "🧹 Removing GoogleService-Info.plist from history..."
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Agrisense/GoogleService-Info.plist" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "🗑️  Cleaning up references..."
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "✅ Git history cleaned!"
echo ""
echo "📋 Next steps:"
echo "1. Verify the cleanup: git log --all -- '*Secrets.swift'"
echo "2. Force push to remote: git push origin --force --all"
echo "3. Force push tags: git push origin --force --tags"
echo "4. Notify team members to re-clone the repository"
echo ""
echo "⚠️  IMPORTANT: Before pushing, make sure you've rotated all exposed API keys!"
echo "   See SECURITY_CLEANUP_INSTRUCTIONS.md for details"
