// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CeedAdsSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CeedAdsSDK",
            targets: ["CeedAdsSDK"]
        ),
    ],
    targets: [
        .target(
            name: "CeedAdsSDK"
        ),
    ]
)
