//
//  Copyright © Marc Rollin.
//

import Foundation

// MARK: - InfoPlist

public struct InfoPlist: Sendable, Codable, Equatable {

    // MARK: Public

    public struct BundleIcons: Sendable, Codable, Equatable {
        public struct Icon: Sendable, Codable, Equatable {
            public let iconFiles: [String]?
            public let iconName: String?

            enum CodingKeys: String, CodingKey {
                case iconFiles = "CFBundleIconFiles"
                case iconName = "CFBundleIconName"
            }
        }

        public let primaryIcon: Icon?
        public let alternateIcons: [String: Icon]?

        enum CodingKeys: String, CodingKey {
            case primaryIcon = "CFBundlePrimaryIcon"
            case alternateIcons = "CFBundleAlternateIcons"
        }
    }

    public let associatedDomains: [String]?
    public let developmentRegion: String?
    public let displayName: String?
    public let embeddedBinaries: [String]?
    public let executable: String?
    public let iconFile: String?
    public let iconName: String?
    public let icons: BundleIcons?
    public let identifier: String
    public let linkedFrameworks: [String]?
    public let minimumOSVersion: String?
    public let name: String
    public let requiredDeviceCapabilities: [String]?
    public let shortVersion: String
    public let supportedDevices: [String]?
    public let supportedInterfaceOrientations: [String]?
    public let supportedLanguages: [String]?
    public let supportedPlatforms: [String]
    public let version: String

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case associatedDomains = "com.apple.developer.associated-domains"
        case developmentRegion = "CFBundleDevelopmentRegion"
        case displayName = "CFBundleDisplayName"
        case embeddedBinaries = "CFBundleExecutableBinaries"
        case executable = "CFBundleExecutable"
        case iconFile = "CFBundleIconFile"
        case iconName = "CFBundleIconName"
        case icons = "CFBundleIcons"
        case identifier = "CFBundleIdentifier"
        case linkedFrameworks = "CFBundleExecutableFrameworks"
        case minimumOSVersion = "MinimumOSVersion"
        case name = "CFBundleName"
        case requiredDeviceCapabilities = "UIRequiredDeviceCapabilities"
        case shortVersion = "CFBundleShortVersionString"
        case supportedDevices = "UISupportedDevices"
        case supportedInterfaceOrientations = "UISupportedInterfaceOrientations"
        case supportedLanguages = "CFBundleLocalizations"
        case supportedPlatforms = "CFBundleSupportedPlatforms"
        case version = "CFBundleVersion"
    }
}

extension URL {

    var infoPlist: InfoPlist {
        get throws {
            let potentialPaths = [
                appendingPathComponent("Info.plist"),
                appendingPathComponent("Contents/Info.plist"),
            ]

            guard let plistURL = potentialPaths
                .first(where: { FileManager.default.fileExists(atPath: $0.path) }),
                let plistData = try? Data(contentsOf: plistURL)
            else {
                throw NSError(
                    domain: "InfoPlistError",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Info.plist not found"]
                )
            }

            return try PropertyListDecoder().decode(InfoPlist.self, from: plistData)
        }
    }
}
