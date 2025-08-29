# Fixing the "unable to load transferred PIF: The workspace contains multiple references with the same GUID" Error

This document provides detailed steps to fix the "unable to load transferred PIF: The workspace contains multiple references with the same GUID" error in your Xcode project.

## Understanding the Issue

This error occurs when there are duplicate references to the same package or main group in your Xcode project configuration. The error specifically mentions `PACKAGE:1VVAAQN25J7QI0AC1GQK1QB8YD93ZPYW5::MAINGROUP`, which indicates a duplicate reference to a package in the main group of your project.

## Solution Steps

### Method 1: Using the Provided Fix Script (Recommended)

1. Run the provided fix script: `./advanced_fix_xcode_project.sh`
2. Open your project in Xcode
3. Go to File > Add Packages...
4. Add the local package from the FirebaseWorkaround directory
5. Build your project

### Method 2: Manual Fix

If the script doesn't work, follow these manual steps:

1. Close Xcode completely
2. Clean Xcode's derived data:
   ```
   rm -rf ~/Library/Developer/Xcode/DerivedData/Agrisense-*
   ```
3. Clean Swift Package Manager cache:
   ```
   rm -rf ~/Library/Caches/org.swift.swiftpm/
   ```
4. Open your project in Xcode
5. Remove all package dependencies:
   - Select the project in the Project Navigator
   - Go to the "Package Dependencies" tab
   - Select all packages and click the minus (-) button
6. Save the project
7. Close Xcode
8. Open Xcode and open your project again
9. Add the packages back one by one:
   - Add Firebase iOS SDK (https://github.com/firebase/firebase-ios-sdk.git) with version 10.15.0
   - Add GoogleSignIn-iOS (https://github.com/google/GoogleSignIn-iOS) with version 7.0.0
   - Add any other required packages
10. Build your project

### Method 3: Reset Xcode Project (Last Resort)

If all else fails:

1. Create a new Xcode project with the same name and configuration
2. Copy all your source files to the new project
3. Re-add all package dependencies
4. Configure project settings to match your original project

## Firebase Version Issues

If you're having issues with the Firebase package version:

1. The script creates a local package wrapper that uses Firebase 10.15.0
2. This should resolve version compatibility issues
3. Make sure to use the local package instead of directly referencing the Firebase package

## Still Having Issues?

If you continue to experience problems:

1. Try using different versions of the Firebase SDK
2. Check for any Xcode updates that might resolve the issue
3. Contact Apple Developer Support for further assistance

## Prevention

To prevent this issue in the future:

1. Always use the Package Manager UI in Xcode to add/remove packages
2. Avoid manually editing the project.pbxproj file
3. Keep your Xcode and Swift packages updated to the latest versions
