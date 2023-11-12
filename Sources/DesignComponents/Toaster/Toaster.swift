//
//  Copyright © Marc Rollin.
//

import Dependencies
import SwiftUI

// MARK: - ToasterKey

private enum ToasterKey: DependencyKey {
    public static let liveValue = Toaster()
}

extension DependencyValues {
    public var toaster: Toaster {
        get { self[ToasterKey.self] }
        set { self[ToasterKey.self] = newValue }
    }
}

// MARK: - Toaster

@Observable
public final class Toaster {

    // MARK: Public

    public func show(message: String, level: Toast.Level = .info, duration: Double = 5) {
        let toast = Toast(message: message, level: level, duration: duration)
        Task { @MainActor in
            withAnimation {
                toasts.append(toast)
            }

            try await Task.sleep(for: .seconds(toast.duration))
            remove(toast: toast)
        }
    }

    public func remove(toast: Toast) {
        Task { @MainActor in
            withAnimation {
                toasts.removeAll { $0.id == toast.id }
            }
        }
    }

    // MARK: Internal

    private(set) var toasts = [Toast]()
}
