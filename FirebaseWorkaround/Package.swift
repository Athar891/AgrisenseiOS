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
