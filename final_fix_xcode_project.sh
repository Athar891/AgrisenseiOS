#!/bin/bash

# Final script to fix Xcode project with package reference issues

echo "Starting final fix for Agrisense Xcode project..."

# Step 1: Clean derived data
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Agrisense-*

# Step 2: Clean Swift Package Manager cache
echo "Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm/

# Step 3: Create a backup of the project file
echo "Creating backup of project.pbxproj..."
cp Agrisense.xcodeproj/project.pbxproj Agrisense.xcodeproj/project.pbxproj.backup

# Step 4: Edit the project file to remove all package references
echo "Removing package references from project file..."

# Create a temporary file to hold the modified project file
cat Agrisense.xcodeproj/project.pbxproj | grep -v "XCRemoteSwiftPackageReference" | grep -v "XCSwiftPackageProductDependency" | grep -v "packageProductDependencies" | grep -v "packageReferences" > Agrisense.xcodeproj/project.pbxproj.tmp

# Replace the original project file with the modified version
mv Agrisense.xcodeproj/project.pbxproj.tmp Agrisense.xcodeproj/project.pbxproj

echo "Fix completed. Please follow these steps:"
echo "1. Open Xcode and open your project"
echo "2. Add Firebase packages manually with specific versions:"
echo "   - Firebase iOS SDK: version 10.15.0"
echo "   - GoogleSignIn-iOS: version 7.0.0"
echo ""
echo "If the issue persists, please refer to FIXING_PACKAGE_GUID_ERROR.md for more detailed instructions."

exit 0
