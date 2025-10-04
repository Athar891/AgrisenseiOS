#!/bin/bash

# verify_implementation.sh
# Verifies that all changes for UI & Camera improvements are in place

set -e

echo "🔍 Verifying AgriSense UI & Camera Improvements Implementation..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
    else
        echo -e "${RED}✗${NC} Missing: $1"
        ((ERRORS++))
    fi
}

# Function to check if file contains string
check_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $3"
    else
        echo -e "${RED}✗${NC} $3"
        ((ERRORS++))
    fi
}

# Function to check if file does NOT contain string
check_file_not_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${RED}✗${NC} $3"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓${NC} $3"
    fi
}

echo "📁 Checking Files..."
echo "-------------------"

# Check new files
check_file "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift"
check_file "UI_CAMERA_IMPROVEMENTS_IMPLEMENTATION.md"

# Check modified files
check_file "Agrisense/Views/Assistant/LiveAIInteractionView.swift"
check_file "Agrisense/Services/CameraService.swift"

# Check Info.plist has camera permissions
check_file "Agrisense/Info.plist"

echo ""
echo "🔍 Checking Implementation Details..."
echo "--------------------------------------"

# Check ChatGPTStyleOrb.swift implementation
if [ -f "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift" ]; then
    check_file_contains "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift" "struct ChatGPTStyleOrb" "ChatGPTStyleOrb struct defined"
    check_file_contains "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift" "AngularGradient" "Angular gradient implemented"
    check_file_contains "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift" "rotationAngle" "Rotation animation implemented"
    check_file_contains "Agrisense/Views/Assistant/ChatGPTStyleOrb.swift" "breathingScale" "Breathing animation implemented"
else
    echo -e "${RED}✗${NC} ChatGPTStyleOrb.swift not found - skipping content checks"
    ((ERRORS++))
fi

# Check LiveAIInteractionView.swift modifications
if [ -f "Agrisense/Views/Assistant/LiveAIInteractionView.swift" ]; then
    check_file_contains "Agrisense/Views/Assistant/LiveAIInteractionView.swift" "ChatGPTStyleOrb" "ChatGPTStyleOrb integrated in LiveAIInteractionView"
    check_file_contains "Agrisense/Views/Assistant/LiveAIInteractionView.swift" "isGenericGreeting" "Generic greeting filter implemented"
    check_file_contains "Agrisense/Views/Assistant/LiveAIInteractionView.swift" "how can i help you" "Generic greeting phrase check exists"
else
    echo -e "${RED}✗${NC} LiveAIInteractionView.swift not found"
    ((ERRORS++))
fi

# Check CameraService.swift enhancements
if [ -f "Agrisense/Services/CameraService.swift" ]; then
    check_file_contains "Agrisense/Services/CameraService.swift" "sessionQueue" "Session queue for thread safety"
    check_file_contains "Agrisense/Services/CameraService.swift" "CameraPreviewView" "Enhanced CameraPreviewView class"
    check_file_contains "Agrisense/Services/CameraService.swift" "AVCaptureVideoPreviewLayer" "Preview layer implementation"
    check_file_contains "Agrisense/Services/CameraService.swift" "checkCameraPermission" "Camera permission check"
else
    echo -e "${RED}✗${NC} CameraService.swift not found"
    ((ERRORS++))
fi

# Check Info.plist for camera permission
if [ -f "Agrisense/Info.plist" ]; then
    check_file_contains "Agrisense/Info.plist" "NSCameraUsageDescription" "Camera usage description in Info.plist"
    check_file_contains "Agrisense/Info.plist" "NSMicrophoneUsageDescription" "Microphone usage description in Info.plist"
else
    echo -e "${RED}✗${NC} Info.plist not found"
    ((ERRORS++))
fi

echo ""
echo "⚠️  Checking for Potential Issues..."
echo "-------------------------------------"

# Check if old SimplifiedKrishiAISphere is still being used in LiveAIInteractionView
if [ -f "Agrisense/Views/Assistant/LiveAIInteractionView.swift" ]; then
    if grep -q "SimplifiedKrishiAISphere(" "Agrisense/Views/Assistant/LiveAIInteractionView.swift" 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} Warning: SimplifiedKrishiAISphere still referenced in LiveAIInteractionView"
        echo "   Consider removing old orb references"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓${NC} Old orb (SimplifiedKrishiAISphere) not used"
    fi
fi

# Check if Secrets.swift exists (required for Gemini API)
if [ ! -f "Agrisense/Models/Secrets.swift" ]; then
    echo -e "${YELLOW}⚠${NC} Warning: Secrets.swift not found (copy from _Secrets.example.swift)"
    echo "   App will not work without API keys"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓${NC} Secrets.swift exists"
fi

echo ""
echo "📊 Summary"
echo "----------"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open Agrisense.xcodeproj in Xcode"
    echo "2. Manually add ChatGPTStyleOrb.swift to the Agrisense target if not already"
    echo "3. Build and run on a real iPhone device (camera won't work in simulator)"
    echo "4. Test all functionality according to UI_CAMERA_IMPROVEMENTS_IMPLEMENTATION.md"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  All critical checks passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Review warnings above and proceed with caution."
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi
