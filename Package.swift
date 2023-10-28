// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SteelyardCore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .singleLibrary(name: "ApplicationArchive"),
        .singleLibrary(name: "AppStoreConnect"),
        .singleLibrary(name: "Platform"),
        .singleLibrary(name: "TreeMap"),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Kitura/Swift-JWT", .upToNextMajor(from: "4.0.1")),
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMajor(from: "2.1.0")),
    ],
    targets: [
        .target(
            name: "ApplicationArchive",
            dependencies: [
                .target(name: "Platform"),
                .product(name: "Zip", package: "Zip"),
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
            name: "Platform"
        ),
        .target(
            name: "SquarifyPartitioner"
        ),
        .target(
            name: "TreeMap",
            dependencies: [
                .target(name: "Platform"),
                .target(name: "SquarifyPartitioner"),
            ]
        ),
    ]
)

extension PackageDescription.Product {

    fileprivate static func singleLibrary(name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
