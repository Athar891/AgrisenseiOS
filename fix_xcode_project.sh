#!/bin/bash

# Script to fix the Xcode project with duplicate GUID references

echo "Starting fix for Agrisense Xcode project..."

# Step 1: Clean derived data
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Agrisense-*

# Step 2: Clean Swift Package Manager cache
echo "Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm/

# Step 3: Reset Package Manager state in the project
echo "Resetting Package Manager state..."
rm -rf .swiftpm
rm -rf .build

# Step 4: Remove Package.resolved if it exists
if [ -f "Package.resolved" ]; then
    echo "Removing Package.resolved..."
    rm Package.resolved
fi

echo "Fix completed. Please open the project in Xcode and manually resolve package dependencies by:"
echo "1. Select the project in the Project Navigator"
echo "2. Go to Package Dependencies tab"
echo "3. Remove all existing packages"
echo "4. Add them back with correct versions"
echo ""
echo "Alternatively, you can try building again with xcodebuild to see if the issue is resolved."

exit 0
