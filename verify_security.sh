#!/bin/bash

# 🔍 Security Verification Script
# This script checks for potential security issues in the codebase

echo "🔍 AgriSense Security Verification"
echo "===================================="
echo ""

ISSUES_FOUND=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Verify Secrets.swift is not tracked
echo "1️⃣  Checking if Secrets.swift is tracked by git..."
if git ls-files --error-unmmatch Agrisense/Models/Secrets.swift 2>/dev/null; then
    echo -e "${RED}❌ FAIL: Secrets.swift is tracked by git!${NC}"
    echo "   Run: git rm --cached Agrisense/Models/Secrets.swift"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ PASS: Secrets.swift is not tracked${NC}"
fi
echo ""

# Check 2: Verify GoogleService-Info.plist is not tracked
echo "2️⃣  Checking if GoogleService-Info.plist is tracked by git..."
if git ls-files --error-unmatch Agrisense/GoogleService-Info.plist 2>/dev/null; then
    echo -e "${RED}❌ FAIL: GoogleService-Info.plist is tracked by git!${NC}"
    echo "   Run: git rm --cached Agrisense/GoogleService-Info.plist"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ PASS: GoogleService-Info.plist is not tracked${NC}"
fi
echo ""

# Check 3: Search for exposed API keys in tracked files
echo "3️⃣  Searching for potential API keys in tracked files..."
EXPOSED_KEYS=$(git grep -i "AIzaSy\|sk-\|pk_\|api.*key.*=.*[\"'][a-zA-Z0-9]{20}" -- "*.swift" "*.plist" "*.json" 2>/dev/null | grep -v "YOUR_\|PLACEHOLDER\|example")
if [ -n "$EXPOSED_KEYS" ]; then
    echo -e "${RED}❌ FAIL: Potential API keys found in tracked files:${NC}"
    echo "$EXPOSED_KEYS"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ PASS: No exposed API keys found in tracked files${NC}"
fi
echo ""

# Check 4: Check for backup/temp files
echo "4️⃣  Checking for backup/temp files..."
BACKUP_FILES=$(find . -name "*.backup*" -o -name "*.temp" -o -name "*.old" 2>/dev/null | grep -v ".git")
if [ -n "$BACKUP_FILES" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Backup/temp files found:${NC}"
    echo "$BACKUP_FILES"
    echo "   Consider running: find . -name '*.backup*' -o -name '*.temp' -o -name '*.old' | xargs rm -f"
else
    echo -e "${GREEN}✅ PASS: No backup/temp files found${NC}"
fi
echo ""

# Check 5: Check git history for Secrets.swift
echo "5️⃣  Checking git history for Secrets.swift..."
HISTORY_CHECK=$(git log --all --full-history --oneline -- "Agrisense/Models/Secrets.swift" 2>/dev/null | head -5)
if [ -n "$HISTORY_CHECK" ]; then
    echo -e "${RED}❌ FAIL: Secrets.swift found in git history!${NC}"
    echo "   Git history commits:"
    echo "$HISTORY_CHECK"
    echo "   Run: ./cleanup_git_history.sh to clean history"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ PASS: Secrets.swift not in git history${NC}"
fi
echo ""

# Check 6: Verify .gitignore has proper rules
echo "6️⃣  Checking .gitignore configuration..."
if grep -q "Secrets.swift" .gitignore && grep -q "GoogleService-Info.plist" .gitignore; then
    echo -e "${GREEN}✅ PASS: .gitignore properly configured${NC}"
else
    echo -e "${RED}❌ FAIL: .gitignore missing important rules${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 7: Check for hardcoded credentials patterns
echo "7️⃣  Scanning for hardcoded credential patterns..."
HARDCODED=$(git grep -i "password\s*=\s*[\"'][^\"']*[\"']\|token\s*=\s*[\"'][^\"']*[\"']" -- "*.swift" 2>/dev/null | grep -v "placeholder\|example\|YOUR_\|TODO\|test" | head -10)
if [ -n "$HARDCODED" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Potential hardcoded credentials found:${NC}"
    echo "$HARDCODED"
else
    echo -e "${GREEN}✅ PASS: No obvious hardcoded credentials found${NC}"
fi
echo ""

# Check 8: Verify Secrets.swift exists locally
echo "8️⃣  Checking if Secrets.swift exists locally..."
if [ -f "Agrisense/Models/Secrets.swift" ]; then
    echo -e "${GREEN}✅ PASS: Secrets.swift exists locally${NC}"
    
    # Check if it has placeholder values
    if grep -q "YOUR_.*_HERE" "Agrisense/Models/Secrets.swift"; then
        echo -e "${YELLOW}⚠️  WARNING: Secrets.swift contains placeholder values${NC}"
        echo "   Please update with your actual API keys"
    else
        echo -e "${GREEN}✅ Secrets.swift appears to be configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  WARNING: Secrets.swift not found${NC}"
    echo "   Copy from template: cp Agrisense/Models/_Secrets.example.swift Agrisense/Models/Secrets.swift"
fi
echo ""

# Check 9: Check for test files with keys
echo "9️⃣  Checking for test files with exposed keys..."
TEST_FILES=$(find . -name "test_*.py" -o -name "test_*.sh" 2>/dev/null | grep -v ".git")
if [ -n "$TEST_FILES" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Test files found:${NC}"
    echo "$TEST_FILES"
    echo "   These files might contain API keys. Review and delete if necessary."
else
    echo -e "${GREEN}✅ PASS: No test files with potential keys found${NC}"
fi
echo ""

# Summary
echo "=================================================="
echo "📊 SECURITY VERIFICATION SUMMARY"
echo "=================================================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo ""
    echo "⚠️  IMPORTANT REMINDERS:"
    echo "1. Rotate all API keys if they were ever committed to git"
    echo "2. Run this script regularly (weekly recommended)"
    echo "3. Keep Secrets.swift updated with current keys"
    echo "4. Never commit Secrets.swift or GoogleService-Info.plist"
else
    echo -e "${RED}❌ Found $ISSUES_FOUND critical issue(s)${NC}"
    echo ""
    echo "🔧 NEXT STEPS:"
    echo "1. Fix the issues listed above"
    echo "2. Run this script again to verify fixes"
    echo "3. If Secrets.swift was in git history, run: ./cleanup_git_history.sh"
    echo "4. Rotate all exposed API keys immediately"
fi
echo ""

exit $ISSUES_FOUND
