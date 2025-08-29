#!/bin/bash

# Advanced script to fix Xcode project with duplicate GUID references

echo "Starting advanced fix for Agrisense Xcode project..."

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

# Step 5: Clean Xcode's workspace data
echo "Cleaning Xcode workspace data..."
rm -rf Agrisense.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Agrisense.xcodeproj/xcuserdata

# Step 6: Fix Firebase version issues
echo "Creating Firebase version workaround..."
mkdir -p FirebaseWorkaround
cat > FirebaseWorkaround/Package.swift << EOL
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "FirebaseWorkaround",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "FirebaseWorkaround", targets: ["FirebaseWorkaroundTarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.15.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "FirebaseWorkaroundTarget",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "Sources"
        )
    ]
)
EOL

mkdir -p FirebaseWorkaround/Sources
touch FirebaseWorkaround/Sources/Dummy.swift
echo "import Foundation" > FirebaseWorkaround/Sources/Dummy.swift

echo "Fix completed. Please follow these steps:"
echo "1. Open Xcode and open your project"
echo "2. In Xcode, go to File > Add Packages..."
echo "3. Add the local package from the FirebaseWorkaround directory"
echo "4. This should fix the dependency issues with Firebase"
echo ""
echo "If the issue persists, you may need to recreate the Xcode project or contact Apple Support."

exit 0
