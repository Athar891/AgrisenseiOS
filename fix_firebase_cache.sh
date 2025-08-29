#!/bin/bash
# Script to fix Firebase SDK caching issues in Xcode

# Clean any existing Firebase SDK cached repositories
echo "Cleaning Firebase SDK cached repositories..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages/repositories/firebase-ios-sdk-*

# Clean the Xcode project
echo "Cleaning the Xcode project..."
xcodebuild clean -project Agrisense.xcodeproj -scheme Agrisense

# Optional: Reset package caches (uncomment if needed)
echo "Resetting package caches..."
# rm -rf ~/Library/Caches/org.swift.swiftpm/
# rm -rf .build/

echo "Cache cleaning complete. Try building your project again."
