//
//  Copyright © Marc Rollin.
//

import Dependencies
import SwiftUI

// MARK: - ToastContainer

private struct ToastContainer<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .overlay(ToastOverlay())
            .environment(toaster)
    }

    @Dependency(\.toaster) private var toaster
}

extension View {

    public func withToaster() -> some View {
        ToastContainer(content: self)
    }
}
