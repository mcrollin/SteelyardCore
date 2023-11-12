//
//  Copyright © Marc Rollin.
//

import Foundation

public struct ArchiveApp: Sendable, Identifiable {

    // MARK: Lifecycle

    init?(_ node: ArchiveNode) {
        guard case .app(let infoPlist) = node.metadata
        else {
            return nil
        }
        let scales = ["@3x", "@2x", ""]

        url = node.url
        icon = if let iconNames = infoPlist.icons?.primaryIcon?.iconFiles {
            iconNames.lazy
                .flatMap { iconName in
                    scales.map { scale in
                        node.url.appendingPathComponent("\(iconName)\(scale).png")
                    }
                }
                .first { FileManager.default.fileExists(atPath: $0.path) }
                .flatMap { try? Data(contentsOf: $0) }
        } else if let iconFile = infoPlist.iconFile {
            try? Data(
                contentsOf: url.appending(component: "Contents")
                    .appending(component: "Resources")
                    .appending(component: "\(iconFile).icns")
            )
        } else {
            nil
        }
        platforms = infoPlist.supportedPlatforms.compactMap(Platform.init)
        name = infoPlist.displayName ?? infoPlist.name
        version = "\(infoPlist.shortVersion) (\(infoPlist.version))"
        self.node = node
    }

    // MARK: Public

    public enum Platform: String, Sendable {
        case ipad = "iPadOS"
        case iphone = "iPhoneOS"
        case mac = "MacOSX"
        case tv = "TVOS"
        case watch = "WatchOS"
    }

    public let url: URL
    public let icon: Data?
    public let platforms: [Platform]
    public let name: String
    public let version: String
    public let node: ArchiveNode

    public var id: URL {
        url
    }
}
