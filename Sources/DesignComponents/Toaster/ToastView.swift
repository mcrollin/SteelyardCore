//
//  Copyright © Marc Rollin.
//

import DesignSystem
import SwiftUI

// MARK: - ToastView

struct ToastView: View {

    // MARK: Internal

    let toast: Toast

    var body: some View {
        Text(toast.message)
            .padding()
            .background(background)
            .foregroundColor(.white)
            .cornerRadius(8)
            .onTapGesture {
                toaster.remove(toast: toast)
            }
    }

    // MARK: Private

    @Environment(Toaster.self) private var toaster
    @Environment(DesignSystem.self) private var designSystem

    private var background: some View {
        switch toast.level {
        case .error:
            designSystem.color(.negative).opacity(designSystem.opacity(.medium))
        default:
            designSystem.color(.background).opacity(designSystem.opacity(.medium))
        }
    }

}

