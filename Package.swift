// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bidding-mobile-ios-sdk",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "bidding-mobile-ios-sdk",
            targets: ["bidding-mobile-ios-sdk"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "bidding-mobile-ios-sdk",
            dependencies: [],
            path: "bidding-mobile-ios-sdk",
            exclude: [
                "bidding_mobile_ios_sdk.docc"
            ],
            sources: [
                "MimedaSDK.swift",
                "MimedaSDKErrorCallback.swift",
                "SDKConfig.swift",
                "SDKEnvironment.swift",
                "API",
                "Events",
                "Utils"
            ]
        ),
        .testTarget(
            name: "bidding-mobile-ios-sdkTests",
            dependencies: ["bidding-mobile-ios-sdk"],
            path: "bidding-mobile-ios-sdkTests"
        )
    ]
}


