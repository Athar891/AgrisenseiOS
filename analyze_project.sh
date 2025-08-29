#!/bin/bash

# This script will help identify and fix the duplicate GUID references in your Xcode project

echo "Starting analysis of Agrisense Xcode project..."

# Step 1: Create a backup of the project file
echo "Creating backup of project.pbxproj..."
cp Agrisense.xcodeproj/project.pbxproj Agrisense.xcodeproj/project.pbxproj.backup.$(date +%Y%m%d%H%M%S)

# Step 2: Find package references in the project file
echo "Analyzing package references..."
echo "Package references found:"
grep -n "XCRemoteSwiftPackageReference" Agrisense.xcodeproj/project.pbxproj

echo ""
echo "Swift package product dependencies found:"
grep -n "XCSwiftPackageProductDependency" Agrisense.xcodeproj/project.pbxproj

echo ""
echo "Package dependency GUIDs found:"
grep -n "PACKAGE:" Agrisense.xcodeproj/project.pbxproj

echo ""
echo "Based on the analysis, you need to open Xcode and manually remove all package dependencies."
echo "Then add them back with specific versions:"
echo "   - Firebase iOS SDK: version 10.15.0"
echo "   - GoogleSignIn-iOS: version 7.0.0"
echo ""
echo "Please refer to FINAL_SOLUTION.md for detailed instructions."

exit 0
