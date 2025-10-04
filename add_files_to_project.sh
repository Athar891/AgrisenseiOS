#!/bin/bash

# Add new Swift files to Xcode project
echo "Adding new Swift files to Xcode project..."

# Files to add
FILES=(
    "Agrisense/Views/Assistant/EnhancedKrishiAISphere.swift"
    "Agrisense/Services/EnhancedTTSService.swift"
)

# Add files using xcodebuild (we'll manually add them if this doesn't work)
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ Found: $file"
    else
        echo "✗ Missing: $file"
    fi
done

echo "Files need to be added to the Xcode project manually or via Xcode."
echo "Please open the project in Xcode and add these files to the target."
