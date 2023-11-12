//
//  Copyright © Marc Rollin.
//

import Dependencies
import SwiftUI

// MARK: - DesignSystemKey

private enum DesignSystemKey: DependencyKey {
    public static let liveValue = DesignSystem()
}

extension DependencyValues {
    public var designSystem: DesignSystem {
        get { self[DesignSystemKey.self] }
        set { self[DesignSystemKey.self] = newValue }
    }
}

// MARK: - DesignSystem

@Observable
public final class DesignSystem {

    // MARK: Lifecycle

    public init(
        baseSpacing: CGFloat = 16,
        baseAnimationDuration: CGFloat = 0.2
    ) {
        self.baseSpacing = baseSpacing
        self.baseAnimationDuration = baseAnimationDuration
    }

    // MARK: Public

    public enum Token {
        public enum Animation {
            fileprivate enum Speed: CGFloat {
                /// 0.125
                case fastest = 0.125
                /// 0.25
                case faster = 0.25
                /// 0.5
                case fast = 0.5
                /// 1
                case normal = 1
                /// 1.5
                case slow = 1.5
                /// 3
                case slower = 3
                /// 6
                case slowest = 6
            }

            case expand, disclose, highlight, select
        }

        public enum Color: String {
            case accent = "Accent"
            case background = "Background"
            case backgroundSubdued = "BackgroundSubdued"
            case highlight = "Highlight"
            case negative = "Negative"
        }

        public enum Opacity: CGFloat {
            /// 0
            case clear = 0
            /// 0.000000001
            case veil = 0.000000001
            /// 0.05
            case hint = 0.05
            /// 0.3
            case faint = 0.3
            /// 0.6
            case medium = 0.6
            /// 0.8
            case dense = 0.8
            /// 1
            case opaque = 1
        }

        public enum Spacing: CGFloat {
            /// 0.125
            case extraExtraSmall = 0.125
            /// 0.25
            case extraSmall = 0.25
            /// 0.5
            case small = 0.5
            /// 0.75
            case semiSmall = 0.75
            /// 1
            case normal = 1
            /// 1.25
            case semiLarge = 1.25
            /// 1.5
            case large = 1.5
            /// 2
            case extraLarge = 2
            /// 4
            case extraExtraLarge = 4
        }
    }

    public var dynamicTypeSize: DynamicTypeSize = .medium

    public var spacing: CGFloat {
        spacing(.normal)
    }

    public func animation(_ animation: Token.Animation) -> Animation? {
        switch animation {
        case .expand: .easeInOut(duration: animationDuration(.normal))
        case .disclose: .easeOut(duration: animationDuration(.fast))
        case .highlight: .linear(duration: animationDuration(.faster))
        case .select: .none
        }
    }

    public func color(_ color: Token.Color) -> Color {
        .init(color.rawValue, bundle: .module)
    }

    public func opacity(_ opacity: Token.Opacity) -> CGFloat {
        opacity.rawValue
    }

    public func spacing(_ spacing: Token.Spacing) -> CGFloat {
        baseSpacing * spacing.rawValue
    }

    // MARK: Private

    private let baseSpacing: CGFloat
    private let baseAnimationDuration: CGFloat

    private func animationDuration(_ speed: Token.Animation.Speed) -> CGFloat {
        baseAnimationDuration * speed.rawValue
    }
}
