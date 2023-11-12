//
//  Copyright © Marc Rollin.
//

import SwiftUI

// MARK: - ToastOverlayView

struct ToastOverlay: View {
    @State private var toasts: [Toast] = []

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            ForEach(toaster.toasts) { toast in
                ToastView(toast: toast)
            }
            Spacer()
        }
    }

    @Environment(Toaster.self) private var toaster
}
