//
//  Copyright © Marc Rollin.
//

import Foundation
import UniformTypeIdentifiers

// MARK: - ContentType

enum ContentType: Sendable, Equatable, CustomStringConvertible {
    case asset
    case binary(BinaryFileType)
    case binarySection
    case package(PackageExtension)
    case universal(UTType)

    // MARK: Internal

    enum PackageExtension: String, Equatable, CustomStringConvertible {
        case app
        case appex
        case bundle
        case car
        case framework
        case lproj
        case mlmodelc
        case momd

        // MARK: Internal

        var description: String {
            switch self {
            case .app:
                "Application"
            case .appex:
                "App Extension"
            case .bundle:
                "Bundle"
            case .car:
                "Asset Catalog"
            case .framework:
                "Framework"
            case .mlmodelc:
                "Core ML Model"
            case .momd:
                "Core Data Model"
            case .lproj:
                "Localization Files"
            }
        }
    }

    var description: String {
        switch self {
        case .asset:
            "Asset"
        case .binary(let binaryExtension):
            binaryExtension.description
        case .binarySection:
            "Binary Section"
        case .package(let packageExtension):
            packageExtension.description
        case .universal(let type):
            type.localizedDescription ?? type.description
        }
    }

    var displayName: String? {
        switch self {
        case .asset, .binarySection:
            nil
        default:
            description
        }
    }
}

extension URL {

    var contentType: ContentType? {
        if let type = binaryFileType {
            .binary(type)
        } else if let packageExtension = ContentType.PackageExtension(rawValue: pathExtension) {
            .package(packageExtension)
        } else if let type = UTType(filenameExtension: pathExtension) {
            .universal(type)
        } else {
            nil
        }
    }
}
