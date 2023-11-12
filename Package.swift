// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SteelyardCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .singleLibrary(name: "ApplicationArchive"),
        .singleLibrary(name: "AppStoreConnect"),
        .singleLibrary(name: "DesignComponents"),
        .singleLibrary(name: "DesignSystem"),
        .singleLibrary(name: "Platform"),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Kitura/Swift-JWT", .upToNextMajor(from: "4.0.1")),
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "ApplicationArchive",
            dependencies: [
                .target(name: "Platform"),
                .product(name: "Zip", package: "Zip"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "AppStoreConnect", dependencies: [
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                .product(name: "SwiftJWT", package: "Swift-JWT"),
            ]
        ),
        .target(
            name: "DesignComponents",
            dependencies: [
                .target(name: "ApplicationArchive"),
                .target(name: "DesignSystem"),
                .target(name: "Platform"),
                .target(name: "SquarifyPartitioner"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            resources: [
                .process("Colors.xcassets"),
            ]
        ),
        .target(
            name: "Platform",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "SquarifyPartitioner",
            dependencies: [
                .target(name: "Platform"),
            ]
        ),
    ]
)

extension PackageDescription.Product {

    fileprivate static func singleLibrary(name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
