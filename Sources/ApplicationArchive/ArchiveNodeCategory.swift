//
//  Copyright © Marc Rollin.
//

import Foundation

public enum ArchiveNodeCategory: Int, Sendable, Comparable {
    case app = 001
    case appExtension = 010
    case assetCatalog = 040
    case binary = 000
    case bundle = 030
    case content = 500
    case data = 600
    case folder = 100
    case font = 400
    case framework = 020
    case localization = 200
    case model = 300

    // MARK: Lifecycle

    init(contentType: ContentType?, resourceType: URLFileResourceType?) {
        self = switch contentType {
        case .asset?:
            .assetCatalog
        case .binary?:
            .binary
        case .binarySection?:
            .binary
        case .package(let packageExtension)?:
            switch packageExtension {
            case .app: .app
            case .appex: .appExtension
            case .bundle: .bundle
            case .car: .assetCatalog
            case .framework: .framework
            case .lproj: .localization
            case .mlmodelc, .momd: .model
            }
        case .universal(let utType)?:
            if utType.isSubtype(of: .content) { .content }
            else if utType.isSubtype(of: .data) { .data }
            else if utType.isSubtype(of: .font) { .font }
            else { .data }
        case nil:
            resourceType == .directory ? .folder : .data
        }
    }

    // MARK: Public

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
