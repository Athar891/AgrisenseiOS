#!/bin/bash

echo "🧹 Comprehensive Xcode Cache Cleanup Script"
echo "==========================================="
echo ""

# Close Xcode if running
echo "1. Closing Xcode..."
killall Xcode 2>/dev/null
sleep 2

# Navigate to project directory
cd "$(dirname "$0")"

echo "2. Cleaning project derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Agrisense-*

echo "3. Cleaning Xcode module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

echo "4. Cleaning Swift Package Manager caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm

echo "5. Removing Package.resolved..."
rm -rf Agrisense.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "6. Cleaning user data..."
rm -rf Agrisense.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Agrisense.xcodeproj/xcuserdata

echo "7. Cleaning project build folder..."
rm -rf build/

echo "8. Resolving package dependencies..."
xcodebuild -project Agrisense.xcodeproj -scheme Agrisense -resolvePackageDependencies

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Open the project: Agrisense.xcodeproj"
echo "3. Clean Build Folder: Product > Clean Build Folder (Cmd+Shift+K)"
echo "4. Build: Product > Build (Cmd+B)"
echo ""
