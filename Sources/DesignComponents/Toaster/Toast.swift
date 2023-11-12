//
//  Copyright © Marc Rollin.
//

import Dependencies
import Foundation

// MARK: - Toast

public struct Toast: Identifiable {
    @Dependency(\.uuid) private static var uuid
    public let id = Self.uuid()
    public let message: String
    public let level: Level
    public let duration: Double

    public enum Level {
        case debug, info, notice, success, warn, error
    }

    public init(message: String, level: Level, duration: Double) {
        self.message = message
        self.level = level
        self.duration = duration
    }
}
